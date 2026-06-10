extends SceneTree
## Headless smoke test of the full expedition loop (no UI). A naive bot
## traverses the map, plays days greedily, picks random rewards/options,
## and the test verifies every expedition terminates in a win or a loss.
##
## Run:
##   godot --headless --path . -s tests/smoke_test.gd

const RUNS := 50
const MAX_STEPS_PER_RUN := 500


func _init() -> void:
	var starter_deck: DeckData = load("res://data/decks/starter_deck.tres")
	var action_pool := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var encounters := CardLibrary.load_encounters_from_dir("res://data/encounters")
	assert(action_pool.size() >= 20, "expected at least 20 action cards")
	assert(event_cards.size() >= 10, "expected at least 10 event cards")
	assert(encounters.size() >= 4, "expected at least 4 encounters")
	print("Pool: %d actions, %d events, %d encounters" % [
		action_pool.size(), event_cards.size(), encounters.size()
	])

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wins := 0
	var total_days := 0
	for run_index in RUNS:
		var outcome := _play_expedition(starter_deck, action_pool, event_cards, encounters, rng)
		if not outcome.ended:
			push_error("Expedition %d did not terminate!" % run_index)
			quit(1)
			return
		wins += 1 if outcome.won else 0
		total_days += outcome.days
	print("Smoke test OK: %d/%d expeditions won, avg %.1f days" % [
		wins, RUNS, float(total_days) / RUNS
	])
	quit(0)


func _play_expedition(
	starter_deck: DeckData,
	action_pool: Array[CardData],
	event_cards: Array[CardData],
	encounters: Array[EncounterData],
	rng: RandomNumberGenerator,
) -> Dictionary:
	var expedition := ExpeditionSystem.new()
	var outcome := {"ended": false, "won": false, "days": 0}
	expedition.expedition_ended.connect(func(won: bool, days: int) -> void:
		outcome.ended = true
		outcome.won = won
		outcome.days = days
	)
	expedition.start(starter_deck, action_pool, event_cards, encounters)

	for step in MAX_STEPS_PER_RUN:
		if outcome.ended:
			break
		var available := expedition.get_available_node_ids()
		if available.is_empty():
			break
		var node := expedition.enter_node(available[rng.randi_range(0, available.size() - 1)])
		match node.type:
			MapNodeData.TYPE_TERRAIN, MapNodeData.TYPE_FINALE:
				_play_day(expedition, outcome)
			MapNodeData.TYPE_FIND:
				var rewards := expedition.roll_card_rewards()
				if not rewards.is_empty() and rng.randi_range(0, 1) == 0:
					expedition.add_card_to_deck(rewards[rng.randi_range(0, rewards.size() - 1)])
			MapNodeData.TYPE_REST:
				if expedition.state.health <= RunState.MAX_HEALTH - 3:
					expedition.rest_heal()
				elif expedition.state.deck.size() > 8:
					expedition.remove_card_from_deck(
						rng.randi_range(0, expedition.state.deck.size() - 1)
					)
			MapNodeData.TYPE_EVENT:
				var encounter := expedition.roll_encounter()
				var choosable: Array[EncounterOptionData] = []
				for option in encounter.options:
					if expedition.can_choose_option(option):
						choosable.append(option)
				if not choosable.is_empty():
					var option := choosable[rng.randi_range(0, choosable.size() - 1)]
					expedition.apply_encounter_option(option)
					if option.grants_card_choice and not outcome.ended:
						var rewards := expedition.roll_card_rewards()
						if not rewards.is_empty():
							expedition.add_card_to_deck(rewards[0])
	return outcome


func _play_day(expedition: ExpeditionSystem, outcome: Dictionary) -> void:
	expedition.prepare_day()
	var day := expedition.day_system
	expedition.start_prepared_day()
	for step in 100:
		if outcome.ended:
			return
		var played := false
		for i in day.hand.size():
			if day.can_play(day.hand[i]) == "":
				day.play_card(i)
				played = true
				break
		if not played:
			day.end_day()
			return