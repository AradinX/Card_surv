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

	if failures == 0:
		print("Load test OK")
	quit(0 if failures == 0 else 1)
