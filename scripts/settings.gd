class_name Settings
extends RefCounted
## Persistent player settings (display + audio), stored in user://settings.cfg.
## Static-only — GameManager calls load_and_apply() once on launch; the settings
## overlay in the main menu calls the set_* helpers (each applies AND saves).

const PATH := "user://settings.cfg"
const SECTION := "settings"
const MASTER_BUS := "Master"

static var fullscreen := false
static var vsync := true
## Linear 0..1 (0 = muted).
static var master_volume := 1.0
static var music_volume := 1.0
static var sfx_volume := 1.0


## Load from disk (or keep defaults) and apply to the display/audio servers.
static func load_and_apply() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		fullscreen = bool(cfg.get_value(SECTION, "fullscreen", fullscreen))
		vsync = bool(cfg.get_value(SECTION, "vsync", vsync))
		master_volume = clampf(
			float(cfg.get_value(SECTION, "master_volume", master_volume)), 0.0, 1.0
		)
		music_volume = clampf(float(cfg.get_value(SECTION, "music_volume", music_volume)), 0.0, 1.0)
		sfx_volume = clampf(float(cfg.get_value(SECTION, "sfx_volume", sfx_volume)), 0.0, 1.0)
	_apply_fullscreen()
	_apply_vsync()
	_apply_master_volume()
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)


static func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_fullscreen()
	save()


static func set_vsync(value: bool) -> void:
	vsync = value
	_apply_vsync()
	save()


static func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_master_volume()
	save()


static func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Music", music_volume)
	save()


static func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	save()


static func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, "fullscreen", fullscreen)
	cfg.set_value(SECTION, "vsync", vsync)
	cfg.set_value(SECTION, "master_volume", master_volume)
	cfg.set_value(SECTION, "music_volume", music_volume)
	cfg.set_value(SECTION, "sfx_volume", sfx_volume)
	cfg.save(PATH)


## Set a named bus's volume from a linear 0..1 value (0 = muted).
static func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_mute(bus, value <= 0.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(value, 0.0001)))


static func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen
		else DisplayServer.WINDOW_MODE_WINDOWED
	)


static func _apply_vsync() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)


static func _apply_master_volume() -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if bus < 0:
		bus = 0
	AudioServer.set_bus_mute(bus, master_volume <= 0.0)
	# Avoid -inf dB at zero; mute flag handles true silence.
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
