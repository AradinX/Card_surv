extends SceneTree
## Isolated test of the persistent meta loop:
## win currency -> roulette affordability -> spend -> unlock -> save/load.
##
## Run:
##   godot --headless --path . -s tests/meta_progression_test.gd

const SAVE_PATH := "user://test_meta_state.json"


func _init() -> void:
	var failures := 0
	_cleanup()

	var game_manager_script: Script = load("res://scripts/game_manager.gd")
	var manager: Node = game_manager_script.new()

	var catalog: Dictionary = {}
	for resource in CardLibrary.load_resources_from_dir("res://data/classes"):
		if resource is CharacterClassData:
			catalog[resource.id] = resource

	var meta := MetaState.new()
	manager.meta_state = meta
	manager.class_catalog = catalog

	if MetaState.SPIN_COST != 1:
		push_error("roulette should cost 1 coin, got %d" % MetaState.SPIN_COST)
		failures += 1
	if meta.can_spin(catalog.size()):
		push_error("fresh meta-state must not afford a roulette spin")
		failures += 1
	if manager.spin_roulette(SAVE_PATH) != null:
		push_error("roulette must reject a spin without enough coins")
		failures += 1

	meta.gold_coins = MetaState.SPIN_COST
	var unlocked_before := meta.unlocked_class_ids.size()
	var won: CharacterClassData = manager.spin_roulette(SAVE_PATH)
	if won == null:
		push_error("roulette should unlock a class when exactly 1 coin is available")
		failures += 1
	else:
		if meta.gold_coins != 0:
			push_error("roulette should spend exactly 1 coin")
			failures += 1
		if meta.unlocked_class_ids.size() != unlocked_before + 1:
			push_error("roulette should unlock exactly one new class")
			failures += 1
		if not meta.is_unlocked(won.id):
			push_error("won class should be present in unlocked_class_ids")
			failures += 1

	var loaded := MetaState.load_or_new(SAVE_PATH)
	if loaded.gold_coins != meta.gold_coins:
		push_error("gold coin count changed across meta save/load")
		failures += 1
	if loaded.unlocked_class_ids != meta.unlocked_class_ids:
		push_error("unlocked classes changed across meta save/load")
		failures += 1
	if not loaded.is_unlocked(MetaState.STARTING_CLASS_ID):
		push_error("starting class must always remain unlocked")
		failures += 1

	loaded.gold_coins = 999
	loaded.unlocked_class_ids = PackedStringArray(catalog.keys())
	manager.meta_state = loaded
	if loaded.can_spin(catalog.size()):
		push_error("roulette must be disabled when every class is unlocked")
		failures += 1
	if manager.spin_roulette(SAVE_PATH) != null:
		push_error("roulette must not return a class when the catalog is complete")
		failures += 1

	manager.free()
	_cleanup()

	if failures == 0:
		print("Meta progression test OK: cost 1, unlock, spend and save/load verified")
	quit(0 if failures == 0 else 1)


func _cleanup() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
