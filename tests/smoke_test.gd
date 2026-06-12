extends SceneTree
## Headless smoke test of the full board-survival loop (no UI). A naive bot
## plays hand cards and biome gather actions greedily, wanders the board,
## and the test verifies every run terminates in a win or a loss.
##
## Run:
##   godot --headless --path . -s tests/smoke_test.gd

const RUNS := 50
const MAX_DAYS_GUARD := 200
const BOT_MOVES_PER_DAY := 2


func _init() -> void:
	var character_class: CharacterClassData = load("res://data/classes/cook.tres")
	var biome_pool := CardLibrary.load_biomes_from_dir("res://data/biomes")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var card_pool := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	card_pool.append_array(CardLibrary.load_cards_from_dir("res://data/buildings"))
	var disaster_pool: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir("res://data/disasters"):
		if resource is DisasterData:
			disaster_pool.append(resource)
	assert(character_class != null and character_class.starter_deck != null,
		"cook class with a starter deck is required")
	assert(biome_pool.size() >= 3, "expected at least 3 biomes")
	assert(event_cards.size() >= 10, "expected at least 10 event cards")
	assert(card_pool.size() >= 20, "expected at least 20 cards in the reward pool")
	assert(disaster_pool.size() >= 1, "expected at least 1 disaster type")
	print("Pool: %d biomes, %d events, %d reward cards, %d disasters, starter deck %d cards" % [
		biome_pool.size(), event_cards.size(), card_pool.size(), disaster_pool.size(),
		character_class.starter_deck.cards.size()
	])

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wins := 0
	var total_days := 0
	var total_levels := 0
	var bum_deaths := 0
	for run_index in RUNS:
		var outcome := _play_run(
			character_class, biome_pool, event_cards, card_pool, disaster_pool, rng
		)
		if not outcome.ended:
			push_error("Run %d did not terminate!" % run_index)
			quit(1)
			return
		wins += 1 if outcome.won else 0
		total_days += outcome.days
		total_levels += outcome.level
		if outcome.bum and not outcome.won:
			bum_deaths += 1
	print("Smoke test OK: %d/%d runs won (cel: dzień %d), śr. %.1f dni, śr. poziom %.1f, zgony po BUM: %d" % [
		wins, RUNS, SurvivalSystem.WIN_DAY,
		float(total_days) / RUNS, float(total_levels) / RUNS, bum_deaths
	])
	quit(0)


func _play_run(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData],
	disaster_pool: Array[DisasterData],
	rng: RandomNumberGenerator,
) -> Dictionary:
	var survival := SurvivalSystem.new()
	var outcome := {"ended": false, "won": false, "days": 0, "level": 1, "bum": false}
	survival.run_ended.connect(func(won: bool, days: int) -> void:
		outcome.ended = true
		outcome.won = won
		outcome.days = days
	)
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool)
	survival.begin()

	for day_guard in MAX_DAYS_GUARD:
		if outcome.ended:
			break
		_play_day(survival, outcome, rng)
	outcome.level = survival.state.level
	outcome.bum = survival.state.bum_happened
	return outcome


func _play_day(
	survival: SurvivalSystem, outcome: Dictionary, rng: RandomNumberGenerator
) -> void:
	var moves_left := BOT_MOVES_PER_DAY
	for step in 200:
		if outcome.ended:
			return

		# Claim pending level rewards with a random pick.
		while survival.has_pending_reward():
			match rng.randi_range(0, 2):
				0:
					survival.claim_max_energy()
				1:
					survival.claim_max_health()
				2:
					var rewards := survival.roll_card_rewards()
					if rewards.is_empty():
						survival.claim_max_energy()
					else:
						survival.claim_card(rewards[rng.randi_range(0, rewards.size() - 1)])

		# Greedy: first playable hand card...
		var played := false
		for i in survival.hand.size():
			if survival.can_play(survival.hand[i]) == "":
				survival.play_card(i)
				played = true
				break
		if played:
			continue

		# ...then the local biome's gather actions (skip self-harming cards
		# like Skazona zwierzyna unless food is actually running out)...
		for card in survival.gather_actions():
			if card.health_delta < 0 and survival.state.food >= 2:
				continue
			if survival.can_play_gather(card) == "":
				survival.play_gather(card)
				played = true
				break
		if played:
			continue

		# ...then patch up the local settlement (repairs, ruin tear-downs)...
		for i in survival.current_tile().buildings.size():
			if survival.can_repair(i) == "":
				survival.repair(i)
				played = true
				break
			if survival.can_demolish(i) == "":
				survival.demolish(i)
				played = true
				break
		if played:
			continue

		# ...then wander to a random adjacent tile.
		if moves_left > 0:
			var reachable: Array[int] = []
			for tile_index in survival.state.board.size():
				if survival.can_move(tile_index) == "":
					reachable.append(tile_index)
			if not reachable.is_empty():
				survival.move_to(reachable[rng.randi_range(0, reachable.size() - 1)])
				moves_left -= 1
				continue

		survival.end_day()
		return

	# Step guard tripped — end the day to keep the run moving.
	survival.end_day()
