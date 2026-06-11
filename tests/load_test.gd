extends SceneTree
## Quick headless check that authored data resources load with correct types.
##
## Run:
##   godot --headless --path . -s tests/load_test.gd


func _init() -> void:
	var failures := 0

	var starter: Resource = load("res://data/decks/starter_deck.tres")
	if starter is DeckData:
		var deck := starter as DeckData
		print("starter_deck: %d cards" % deck.cards.size())
		if deck.cards.size() != 10:
			push_error("starter deck should have 10 cards")
			failures += 1
		for card in deck.cards:
			if card == null or not (card is ActionCardData):
				push_error("starter deck contains a non-ActionCardData entry")
				failures += 1
	else:
		push_error("starter_deck.tres did not load as DeckData")
		failures += 1

	var encounters := _load_dir("res://data/encounters")
	print("encounters: %d" % encounters.size())
	if encounters.size() < 4:
		push_error("expected at least 4 encounters")
		failures += 1
	for resource in encounters:
		if not (resource is EncounterData):
			push_error("non-EncounterData resource in data/encounters")
			failures += 1
			continue
		var encounter := resource as EncounterData
		if encounter.options.size() < 2:
			push_error("encounter '%s' has fewer than 2 options" % encounter.id)
			failures += 1
		for option in encounter.options:
			if option == null or not (option is EncounterOptionData):
				push_error("encounter '%s' has an invalid option" % encounter.id)
				failures += 1

	failures += _check_dzien50_data()

	if failures == 0:
		print("Load test OK")
	quit(0 if failures == 0 else 1)


## Dzien 50 skeleton data (concept: README.md) — not wired into gameplay yet,
## but authored resources must already load with correct types.
func _check_dzien50_data() -> int:
	var failures := 0

	var biomes := _load_dir("res://data/biomes")
	print("biomes: %d" % biomes.size())
	if biomes.size() < 3:
		push_error("expected at least 3 biomes")
		failures += 1
	for resource in biomes:
		if not (resource is BiomeData):
			push_error("non-BiomeData resource in data/biomes")
			failures += 1
			continue
		var biome := resource as BiomeData
		if biome.building_slots < 2 or biome.building_slots > 4:
			push_error("biome '%s' has building_slots outside 2-4" % biome.id)
			failures += 1
		if biome.corrupted_display_name.is_empty():
			push_error("biome '%s' is missing its corrupted face" % biome.id)
			failures += 1

	var buildings := _load_dir("res://data/buildings")
	print("buildings: %d" % buildings.size())
	if buildings.size() < 3:
		push_error("expected at least 3 buildings")
		failures += 1
	for resource in buildings:
		if not (resource is BuildingCardData):
			push_error("non-BuildingCardData resource in data/buildings")
			failures += 1
			continue
		if (resource as BuildingCardData).max_hp <= 0:
			push_error("building '%s' has non-positive max_hp" % (resource as BuildingCardData).id)
			failures += 1

	var monsters := _load_dir("res://data/monsters")
	print("monsters: %d" % monsters.size())
	for resource in monsters:
		if not (resource is MonsterCardData):
			push_error("non-MonsterCardData resource in data/monsters")
			failures += 1
			continue
		if (resource as MonsterCardData).disaster_id.is_empty():
			push_error("monster '%s' has no disaster_id" % (resource as MonsterCardData).id)
			failures += 1

	var disasters := _load_dir("res://data/disasters")
	print("disasters: %d" % disasters.size())
	if disasters.size() < 1:
		push_error("expected at least 1 disaster")
		failures += 1
	for resource in disasters:
		if not (resource is DisasterData):
			push_error("non-DisasterData resource in data/disasters")
			failures += 1
			continue
		var disaster := resource as DisasterData
		if disaster.monsters.is_empty():
			push_error("disaster '%s' has no monsters" % disaster.id)
			failures += 1
		for monster in disaster.monsters:
			if monster != null and monster.disaster_id != disaster.id:
				push_error("monster '%s' points at disaster '%s', not '%s'" % [monster.id, monster.disaster_id, disaster.id])
				failures += 1

	var classes := _load_dir("res://data/classes")
	print("classes: %d" % classes.size())
	if classes.size() < 1:
		push_error("expected at least 1 character class")
		failures += 1
	for resource in classes:
		if not (resource is CharacterClassData):
			push_error("non-CharacterClassData resource in data/classes")
			failures += 1
			continue
		if (resource as CharacterClassData).starter_deck == null:
			push_error("class '%s' has no starter deck" % (resource as CharacterClassData).id)
			failures += 1

	return failures


func _load_dir(dir_path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			result.append(load(dir_path.path_join(file_name)))
	return result
