extends SceneTree
## Round-trips a run through the JSON save format (to_dict -> file -> from_dict)
## and resume(): a saved RunState must reload with identical persistent fields
## and rebuild into a working SurvivalSystem.
##
## Run:
##   godot --headless --path . -s tests/save_load_test.gd

const SAVE_PATH := "user://test_run_save.json"


func _init() -> void:
	var failures := 0

	var character_class: CharacterClassData = load("res://data/classes/cook.tres")
	var biome_pool := CardLibrary.load_biomes_from_dir("res://data/biomes")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var card_pool := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	var catalog: Array[BuildingCardData] = []
	for res in CardLibrary.load_cards_from_dir("res://data/buildings"):
		if res is BuildingCardData:
			catalog.append(res)
	var disaster_pool: Array[DisasterData] = []
	for res in CardLibrary.load_resources_from_dir("res://data/disasters"):
		if res is DisasterData:
			disaster_pool.append(res)

	var survival := SurvivalSystem.new()
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, catalog)
	survival.begin()

	# Move around a bit to discover tiles and spend energy (exercises board state).
	for step in 3:
		var moved := false
		for tile_index in survival.state.board.size():
			if survival.can_move(tile_index) == "":
				survival.move_to(tile_index)
				moved = true
				break
		if not moved:
			break

	var before := _snapshot(survival.state)

	var save_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		push_error("cannot open save file for writing: %d" % FileAccess.get_open_error())
		quit(1)
		return
	save_file.store_string(JSON.stringify(survival.state.to_dict()))
	save_file.close()

	var read_file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var loaded := RunState.from_dict(
		JSON.parse_string(read_file.get_as_text()),
		_save_catalog(character_class, biome_pool, catalog, disaster_pool)
	)
	if loaded == null:
		push_error("loaded save is not a valid RunState")
		quit(1)
		return

	var resumed := SurvivalSystem.new()
	resumed.resume(loaded, event_cards, card_pool, catalog)
	var after := _snapshot(resumed.state)

	for key in before:
		if before[key] != after[key]:
			push_error("field '%s' changed across save/load: %s -> %s" % [
				key, str(before[key]), str(after[key])
			])
			failures += 1

	# A save from a different schema version must be rejected outright
	# (a post-release patch must never half-load an incompatible save).
	var future_save: Dictionary = survival.state.to_dict()
	future_save["version"] = RunState.SAVE_VERSION + 1
	if RunState.from_dict(future_save, _save_catalog(character_class, biome_pool, catalog, disaster_pool)) != null:
		push_error("save with a mismatched version should be rejected")
		failures += 1

	# The resumed system must start its day without errors and expose the
	# current tile's gather actions (proves helpers were rebuilt).
	resumed.begin()
	if not resumed.current_tile().is_discovered:
		push_error("resumed current tile should be discovered")
		failures += 1

	# Clean up the test save file.
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

	if failures == 0:
		print("Save/load test OK: round-tripped day %d, %d tiles discovered" % [
			int(before["day"]), int(before["discovered"])
		])
	quit(0 if failures == 0 else 1)


func _save_catalog(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	building_catalog: Array[BuildingCardData],
	disaster_pool: Array[DisasterData],
) -> Dictionary:
	var cards: Dictionary = CardLibrary.load_deck_card_lookup()
	var buildings: Dictionary = {}
	for building in building_catalog:
		buildings[building.id] = building
		cards[building.id] = building
	var biomes: Dictionary = {}
	for biome in biome_pool:
		biomes[biome.id] = biome
	var disasters: Dictionary = {}
	for disaster in disaster_pool:
		disasters[disaster.id] = disaster
	return {
		"classes": {character_class.id: character_class},
		"cards": cards,
		"biomes": biomes,
		"buildings": buildings,
		"disasters": disasters,
	}


func _snapshot(state: RunState) -> Dictionary:
	var discovered := 0
	for tile in state.board:
		if tile.is_discovered:
			discovered += 1
	return {
		"day": state.day,
		"season": state.season,
		"health": state.health,
		"hunger": state.hunger,
		"thirst": state.thirst,
		"warmth": state.warmth,
		"energy": state.energy,
		"food": state.food,
		"water": state.water,
		"wood": state.wood,
		"materials": state.materials,
		"max_health": state.max_health,
		"max_energy": state.max_energy,
		"level": state.level,
		"xp": state.xp,
		"current_tile": state.current_tile,
		"bum_happened": state.bum_happened,
		"bum_day": state.bum_day,
		"class_id": state.character_class.id,
		"deck": state.deck.size(),
		"board": state.board.size(),
		"discovered": discovered,
	}
