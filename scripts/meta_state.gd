class_name MetaState
extends Resource
## Meta-progression that persists between runs (roguelike layer).
## Currently: gold coins (one per won run) spent on a roulette that unlocks new
## playable character classes. Saved to user:// so it survives app restarts.

const SAVE_PATH := "user://meta_state.json"
## Pre-JSON save (ResourceLoader-based, unsafe with untrusted files).
## Migrated once by load_or_new(), then deleted.
const LEGACY_SAVE_PATH := "user://meta_state.tres"
## Cost of one roulette spin (in gold coins).
const SPIN_COST := 1
## The class everyone starts with — always unlocked.
const STARTING_CLASS_ID := "herbalist"

@export var gold_coins: int = 0
@export var unlocked_class_ids: PackedStringArray = PackedStringArray([STARTING_CLASS_ID])
## Set once the player has seen the how-to-play tutorial (auto-shown on first launch).
@export var seen_tutorial: bool = false


## Loads the saved meta-state, or returns a fresh one (starting class unlocked).
## The optional path keeps tests isolated from the player's real save.
static func load_or_new(path: String = SAVE_PATH) -> MetaState:
	var meta := _from_file(path)
	if meta == null and path == SAVE_PATH:
		meta = _migrate_legacy()
	if meta == null:
		meta = MetaState.new()
	if not meta.unlocked_class_ids.has(STARTING_CLASS_ID):
		meta.unlocked_class_ids.append(STARTING_CLASS_ID)
	return meta


## Parses the JSON save. The file is untrusted input, so every field is
## type-checked instead of cast. Returns null when missing or unusable.
static func _from_file(path: String) -> MetaState:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not (data is Dictionary):
		return null
	var meta := MetaState.new()
	var coins: Variant = data.get("gold_coins")
	if coins is int or coins is float:
		meta.gold_coins = maxi(int(coins), 0)
	var ids: Variant = data.get("unlocked_class_ids")
	if ids is Array:
		meta.unlocked_class_ids = PackedStringArray()
		for class_id in ids:
			if class_id is String and not meta.unlocked_class_ids.has(class_id):
				meta.unlocked_class_ids.append(class_id)
	var seen: Variant = data.get("seen_tutorial")
	meta.seen_tutorial = seen is bool and seen
	return meta


## One-time migration of the old .tres save so players keep their unlocks.
## This is the only remaining ResourceLoader read from user:// — it targets
## a file this game wrote itself and deletes it immediately after.
static func _migrate_legacy() -> MetaState:
	if not ResourceLoader.exists(LEGACY_SAVE_PATH):
		return null
	var res := ResourceLoader.load(LEGACY_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	DirAccess.remove_absolute(LEGACY_SAVE_PATH)
	if not (res is MetaState):
		return null
	var meta := res as MetaState
	meta.save()
	return meta


func save(path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify({
		"gold_coins": gold_coins,
		"unlocked_class_ids": unlocked_class_ids,
		"seen_tutorial": seen_tutorial,
	}))
	return OK


func is_unlocked(class_id: String) -> bool:
	return unlocked_class_ids.has(class_id)


func unlock(class_id: String) -> void:
	if not unlocked_class_ids.has(class_id):
		unlocked_class_ids.append(class_id)


## True when the player can afford a spin AND there is something left to win.
func can_spin(total_class_count: int) -> bool:
	return gold_coins >= SPIN_COST and unlocked_class_ids.size() < total_class_count
