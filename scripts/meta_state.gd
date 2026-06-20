class_name MetaState
extends Resource
## Meta-progression that persists between runs (roguelike layer).
## Currently: gold coins (one per won run) spent on a roulette that unlocks new
## playable character classes. Saved to user:// so it survives app restarts.

const SAVE_PATH := "user://meta_state.tres"
## Cost of one roulette spin (in gold coins). TODO: przywrócić 3 po testach.
const SPIN_COST := 0
## The class everyone starts with — always unlocked.
const STARTING_CLASS_ID := "scout"

@export var gold_coins: int = 0
@export var unlocked_class_ids: PackedStringArray = PackedStringArray([STARTING_CLASS_ID])


## Loads the saved meta-state, or returns a fresh one (cook unlocked).
static func load_or_new() -> MetaState:
	if ResourceLoader.exists(SAVE_PATH):
		var res := ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res is MetaState:
			var meta := res as MetaState
			if not meta.unlocked_class_ids.has(STARTING_CLASS_ID):
				meta.unlocked_class_ids.append(STARTING_CLASS_ID)
			return meta
	return MetaState.new()


func save() -> void:
	ResourceSaver.save(self, SAVE_PATH)


func is_unlocked(class_id: String) -> bool:
	return unlocked_class_ids.has(class_id)


func unlock(class_id: String) -> void:
	if not unlocked_class_ids.has(class_id):
		unlocked_class_ids.append(class_id)


## True when the player can afford a spin AND there is something left to win.
func can_spin(total_class_count: int) -> bool:
	return gold_coins >= SPIN_COST and unlocked_class_ids.size() < total_class_count
