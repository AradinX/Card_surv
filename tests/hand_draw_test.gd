extends SceneTree
## Role-bucketed opening hand (variant A): every dawn the hand must cover at least
## 3 distinct roles (when the deck supports it), never stack 3 cards of the same id,
## and the wildcard slot must sometimes lend a not-yet-owned "guest" card.
##
## Run:
##   godot --headless --path . -s tests/hand_draw_test.gd


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
	survival._rng.seed = 4242
	survival.begin()

	var owned := {}
	for c in survival.state.deck:
		owned[c.id] = true
	var deck_roles := {}
	for c in survival.state.deck:
		deck_roles[survival._card_role(c)] = true
	var deck_role_count: int = deck_roles.size()

	var limit := survival._hand_limit()
	var guest_seen := false
	var dawns := 0

	for day in 12:
		if survival._ended:
			break
		dawns += 1
		var hand := survival.hand

		if hand.size() != limit:
			push_error("dawn %d: hand size %d != limit %d" % [day, hand.size(), limit])
			failures += 1

		# No id appears 3+ times.
		var id_counts := {}
		for c in hand:
			id_counts[c.id] = int(id_counts.get(c.id, 0)) + 1
		for id in id_counts:
			if int(id_counts[id]) >= 3:
				push_error("dawn %d: %d copies of '%s' in hand" % [day, int(id_counts[id]), id])
				failures += 1

		# At least 3 distinct roles when the deck can supply them.
		var hand_roles := {}
		for c in hand:
			hand_roles[survival._card_role(c)] = true
		if hand_roles.size() < mini(3, deck_role_count):
			push_error("dawn %d: only %d distinct roles in hand" % [day, hand_roles.size()])
			failures += 1

		# Guest detection: a hand card the player does not own.
		for c in hand:
			if not owned.has(c.id):
				guest_seen = true

		# Keep the run alive so we sample enough dawns (this tests draws, not survival).
		survival.state.hunger = RunState.MAX_HUNGER
		survival.state.thirst = RunState.MAX_THIRST
		survival.state.warmth = 10
		survival.end_day()
		survival.resolve_night()

	if not guest_seen:
		push_error("no guest card appeared across %d dawns (expected with Act I chance)" % dawns)
		failures += 1

	if failures == 0:
		print("Hand draw test OK: %d dawns, >=3 roles each, no triples, guest seen" % dawns)
	quit(0 if failures == 0 else 1)
