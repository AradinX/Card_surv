extends Node
## Autoload "AudioManager": one music player + one looping ambience layer (Music
## bus) + a small SFX pool (SFX bus). Everything is keyed and format-agnostic
## (.ogg/.wav/.mp3) and guarded, so the game runs silently when files are absent
## and plays the moment they are dropped into assets/audio/ — zero further code.

## Paths are written with .ogg but resolved against any supported extension.
const MUSIC := {
	"menu": "res://assets/audio/music/music_menu.ogg",
	"act1": "res://assets/audio/music/music_act1.ogg",
	"act2": "res://assets/audio/music/music_act2.ogg",
	"act2_plague": "res://assets/audio/music/music_act2_plague.ogg",
	"act2_eclipse": "res://assets/audio/music/music_act2_eclipse.ogg",
	"act2_rift": "res://assets/audio/music/music_act2_rift.ogg",
	"act2_flood": "res://assets/audio/music/music_act2_flood.ogg",
	"win": "res://assets/audio/music/music_win.ogg",
}
## Organised into subfolders by the player; paths point there (ext resolved).
const SFX := {
	"card_play": "res://assets/audio/sfx/cards/card_play.ogg",
	"build": "res://assets/audio/sfx/cards/build_place.ogg",
	"repair": "res://assets/audio/sfx/cards/repair.ogg",
	"discover": "res://assets/audio/sfx/cards/discover.ogg",
	"alarm": "res://assets/audio/sfx/cards/alarm_clock.ogg",
	"bum": "res://assets/audio/sfx/bum/bum_explosion.ogg",
	"monster": "res://assets/audio/sfx/monsters/monster_attack.ogg",
	"level_up": "res://assets/audio/sfx/day_cycle/level_up.ogg",
	"eat": "res://assets/audio/sfx/day_cycle/eat.ogg",
	"drink": "res://assets/audio/sfx/day_cycle/drink.ogg",
	"button": "res://assets/audio/sfx/ui/button_click.ogg",
	"coin": "res://assets/audio/sfx/ui/coin.ogg",
}
## Looping nature/atmosphere layer under the music (forest birds in Act I, bleak
## wind / per-disaster dread in Act II). Real ambience = field recordings.
const AMBIENCE := {
	"forest": "res://assets/audio/ambience/ambience_forest.ogg",
	"act2": "res://assets/audio/ambience/ambience_act2.ogg",
	"act2_plague": "res://assets/audio/ambience/ambience_act2_plague.ogg",
	"act2_eclipse": "res://assets/audio/ambience/ambience_act2_eclipse.ogg",
	"act2_rift": "res://assets/audio/ambience/ambience_act2_rift.ogg",
	"act2_flood": "res://assets/audio/ambience/ambience_act2_flood.ogg",
}
const EXTENSIONS := [".ogg", ".wav", ".mp3"]
const SFX_VOICES := 6

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _current_music_key := ""
var _current_ambience_key := ""


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Music"
	add_child(_ambience)
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_sfx_pool.append(voice)


## First existing file for a key's path, trying .ogg/.wav/.mp3 ("" if none).
func _resolve(catalog: Dictionary, key: String) -> String:
	var base: String = catalog.get(key, "")
	if base == "":
		return ""
	base = base.trim_suffix(".ogg")
	for ext in EXTENSIONS:
		if ResourceLoader.exists(base + ext):
			return base + ext
	return ""


func _set_loop(stream: Resource) -> void:
	if stream == null:
		return
	# WAV uses loop_mode; OGG/MP3 use a bool `loop`.
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif "loop" in stream:
		stream.set("loop", true)


## Switch the looping background track (no-op if already playing that key/missing).
func play_music(key: String) -> void:
	if key == _current_music_key and _music.playing:
		return
	var path := _resolve(MUSIC, key)
	if path == "":
		return
	_current_music_key = key
	var stream := load(path)
	_set_loop(stream)
	_music.stream = stream
	_music.play()


## Pick the Act II track for the rolled disaster (falls back to generic "act2").
func play_act2_music(disaster_id: String) -> void:
	var key := "act2_" + disaster_id
	if _resolve(MUSIC, key) == "":
		key = "act2"
	play_music(key)


func stop_music() -> void:
	_music.stop()
	_current_music_key = ""


## Switch the looping ambience layer (forest birds, wind...). Guarded + looped.
func play_ambience(key: String) -> void:
	if key == _current_ambience_key and _ambience.playing:
		return
	var path := _resolve(AMBIENCE, key)
	if path == "":
		return
	_current_ambience_key = key
	var stream := load(path)
	_set_loop(stream)
	_ambience.stream = stream
	_ambience.play()


## Per-disaster ambience (falls back to generic "act2").
func play_act2_ambience(disaster_id: String) -> void:
	var key := "act2_" + disaster_id
	if _resolve(AMBIENCE, key) == "":
		key = "act2"
	play_ambience(key)


func stop_ambience() -> void:
	_ambience.stop()
	_current_ambience_key = ""


## Fire a one-shot sound effect by key (uses a free voice, else steals the first).
func play_sfx(key: String) -> void:
	var path := _resolve(SFX, key)
	if path == "":
		return
	var stream := load(path)
	for voice in _sfx_pool:
		if not voice.playing:
			voice.stream = stream
			voice.play()
			return
	_sfx_pool[0].stream = stream
	_sfx_pool[0].play()
