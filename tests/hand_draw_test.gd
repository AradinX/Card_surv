extends SceneTree
## Survival opening hand: every dawn is dealt from the owned deck only, with a
## light correction only when the opening hand has no ECONOMY/SUSTAIN at all.
## The hand should avoid 3x the same id without lending not-yet-owned cards.
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
	var deck_has_economy := false
	var deck_has_sustain := false
	for c in survival.state.deck:
		if survival._card_role(c) == SurvivalSystem.HandRole.ECONOMY:
			deck_has_economy = true
		if survival._card_role(c) == SurvivalSystem.HandRole.SUSTAIN:
			deck_has_sustain = true
	var deck_has_survival := deck_has_economy or deck_has_sustain

	var limit := survival._hand_limit()
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

		# The correction prevents a totally non-survival opening, but it does not
		# force both ECONOMY and SUSTAIN every dawn.
		var hand_roles := {}
		for c in hand:
			hand_roles[survival._card_role(c)] = true
		var has_survival := hand_roles.has(SurvivalSystem.HandRole.ECONOMY) \
			or hand_roles.has(SurvivalSystem.HandRole.SUSTAIN)
		if deck_has_survival and not has_survival:
			push_error("dawn %d: missing any survival role despite owned support" % day)
			failures += 1

		# No guests: every hand card must belong to the player's deck.
		for c in hand:
			if not owned.has(c.id):
				push_error("dawn %d: guest card appeared: '%s'" % [day, c.id])
				failures += 1

		# Keep the run alive so we sample enough dawns (this tests draws, not survival).
		survival.state.hunger = RunState.MAX_HUNGER
		survival.state.thirst = RunState.MAX_THIRST
		survival.state.warmth = 10
		survival.end_day()
		survival.resolve_night()

	if failures == 0:
		print("Hand draw test OK: %d dawns, owned-only, survival safety, no triples" % dawns)
	quit(0 if failures == 0 else 1)
