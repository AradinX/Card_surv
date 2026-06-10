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

	if failures == 0:
		print("Load test OK")
	quit(0 if failures == 0 else 1)


func _load_dir(dir_path: String) -> Array[Resource]:
	var result: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			result.append(load(dir_path.path_join(file_name)))
	return result
