extends SceneTree
## Headless diagnostics for the audio catalog, buses and player setup.
##
## Run:
##   godot --headless --path . -s tests/audio_test.gd

const AUDIO_MANAGER_SCRIPT := preload("res://scripts/audio_manager.gd")


func _init() -> void:
	var failures := 0
	print("Audio driver: %s" % AudioServer.get_driver_name())
	var manager: Node = root.get_node_or_null("AudioManager")
	var owns_manager := manager == null
	if owns_manager:
		manager = AUDIO_MANAGER_SCRIPT.new()
		root.add_child(manager)
		await process_frame

	for bus_name in ["Master", "Music", "SFX"]:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0:
			push_error("missing audio bus: %s" % bus_name)
			failures += 1
		else:
			print("Bus %s: mute=%s volume=%.1f dB" % [
				bus_name,
				str(AudioServer.is_bus_mute(bus)),
				AudioServer.get_bus_volume_db(bus),
			])

	failures += _check_catalog(manager, "music", manager.MUSIC, ["act2"])
	failures += _check_catalog(manager, "ambience", manager.AMBIENCE)
	failures += _check_catalog(manager, "sfx", manager.SFX)

	manager.play_music("menu")
	await create_timer(0.25).timeout
	var music_player: AudioStreamPlayer = manager.get_child(0)
	if music_player.stream == null:
		push_error("menu music did not load into AudioStreamPlayer")
		failures += 1
	elif not music_player.playing:
		push_error("menu music player did not enter playing state")
		failures += 1
	else:
		print("Menu music playing: %.1fs on bus %s" % [
			music_player.stream.get_length(), music_player.bus
		])

	manager.play_sfx("button")
	await create_timer(0.1).timeout
	var sfx_playing := false
	for child in manager.get_children():
		if child is AudioStreamPlayer and child.bus == "SFX" and child.playing:
			sfx_playing = true
			break
	if not sfx_playing:
		push_error("button SFX player did not enter playing state")
		failures += 1

	manager.stop_music()
	manager.stop_ambience()
	for child in manager.get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
	if owns_manager:
		manager.free()
	await process_frame
	if failures == 0:
		print("Audio test OK: catalogs, buses, music and SFX players verified")
	call_deferred("_finish", 0 if failures == 0 else 1)


func _finish(exit_code: int) -> void:
	quit(exit_code)


func _check_catalog(
	manager: Node, label: String, catalog: Dictionary, optional_keys: Array = []
) -> int:
	var failures := 0
	for key in catalog:
		var path: String = manager._resolve(catalog, key)
		if path == "":
			if key in optional_keys:
				print("Optional %s missing: %s" % [label, key])
			else:
				push_error("missing %s resource for key: %s" % [label, key])
				failures += 1
			continue
		var stream: Resource = load(path)
		if stream == null:
			push_error("failed to load %s '%s' from %s" % [label, key, path])
			failures += 1
		else:
			print("%s %s -> %s (%.1fs)" % [
				label.capitalize(), key, path, stream.get_length()
			])
	return failures
