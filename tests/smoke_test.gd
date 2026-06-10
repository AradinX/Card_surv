extends SceneTree
## Headless smoke test of the core loop (no UI). Plays several full runs
## with a naive "play the first playable card" policy and verifies that
## every run terminates with a win or a loss within the day limit.
##
## Run:
##   godot --headless --path . -s tests/smoke_test.gd

const RUNS := 50
const MAX_ACTIONS_PER_RUN := 1000


func _init() -> void:
	var action_cards := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	assert(action_cards.size() >= 8, "expected at least 8 action cards")
	assert(event_cards.size() >= 10, "expected at least 10 event cards")
	print("Loaded %d action cards, %d event cards" % [action_cards.size(), event_cards.size()])

	var wins := 0
	for run_index in RUNS:
		var result := _play_run(action_cards, event_cards)
		if result == -1:
			push_error("Run %d did not terminate!" % run_index)
			quit(1)
			return
		wins += result
	print("Smoke test OK: %d/%d runs won (losses are fine — balance, not bugs)" % [wins, RUNS])
	quit(0)


## Returns 1 on win, 0 on loss, -1 if the run failed to terminate.
func _play_run(action_cards: Array[CardData], event_cards: Array[CardData]) -> int:
	var system := RunSystem.new()
	var outcome := {"ended": false, "won": false}
	system.run_ended.connect(func(won: bool, _days: int) -> void:
		outcome.ended = true
		outcome.won = won
	)
	system.start_run(action_cards, event_cards)

	for step in MAX_ACTIONS_PER_RUN:
		if outcome.ended:
			break
		var played := false
		for i in system.hand.size():
			if system.can_play(system.hand[i]) == "":
				system.play_card(i)
				played = true
				break
		if not played:
			system.end_day()

	if not outcome.ended:
		return -1
	assert(system.state.health >= 0, "health below zero")
	assert(system.state.day <= RunState.TARGET_DAYS, "day exceeded target")
	return 1 if outcome.won else 0
