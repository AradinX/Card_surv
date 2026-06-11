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
	assert(character_class != null and character_class.starter_deck != null,
		"cook class with a starter deck is required")
	assert(biome_pool.size() >= 3, "expected at least 3 biomes")
	assert(event_cards.size() >= 10, "expected at least 10 event cards")
	print("Pool: %d biomes, %d events, starter deck %d cards" % [
		biome_pool.size(), event_cards.size(), character_class.starter_deck.cards.size()
	])

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wins := 0
	var total_days := 0
	for run_index in RUNS:
		var outcome := _play_run(character_class, biome_pool, event_cards, rng)
		if not outcome.ended:
			push_error("Run %d did not terminate!" % run_index)
			quit(1)
			return
		wins += 1 if outcome.won else 0
		total_days += outcome.days
	print("Smoke test OK: %d/%d runs won (cel: dzień %d), śr. %.1f dni" % [
		wins, RUNS, SurvivalSystem.WIN_DAY, float(total_days) / RUNS
	])
	quit(0)


func _play_run(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	rng: RandomNumberGenerator,
) -> Dictionary:
	var survival := SurvivalSystem.new()
	var outcome := {"ended": false, "won": false, "days": 0}
	survival.run_ended.connect(func(won: bool, days: int) -> void:
		outcome.ended = true
		outcome.won = won
		outcome.days = days
	)
	survival.start(character_class, biome_pool, event_cards)
	survival.begin()

	for day_guard in MAX_DAYS_GUARD:
		if outcome.ended:
			break
		_play_day(survival, outcome, rng)
	return outcome


func _play_day(
	survival: SurvivalSystem, outcome: Dictionary, rng: RandomNumberGenerator
) -> void:
	var moves_left := BOT_MOVES_PER_DAY
	for step in 200:
		if outcome.ended:
			return

		# Greedy: first playable hand card...
		var played := false
		for i in survival.hand.size():
			if survival.can_play(survival.hand[i]) == "":
				survival.play_card(i)
				played = true
				break
		if played:
			continue

		# ...then the local biome's gather actions...
		for card in survival.gather_actions():
			if survival.can_play_gather(card) == "":
				survival.play_gather(card)
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
