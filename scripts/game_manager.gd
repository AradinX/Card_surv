extends Node
## Autoload "GameManager". Owns the high-level flow: menu -> run -> result.
## Creates the RunSystem and hands it to the run scene; the scene connects
## its UI to the system's signals, then calls begin_run().

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const RUN_SCENE := "res://scenes/run.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"
const ACTION_CARDS_DIR := "res://data/cards/actions"
const EVENT_CARDS_DIR := "res://data/cards/events"

## Placeholder for future meta-progression (camp, unlocks, deckbuilding).
var meta_state: MetaState = MetaState.new()
var run_system: RunSystem

var last_run_won := false
var last_run_days := 0


func start_new_run() -> void:
	run_system = RunSystem.new()
	run_system.run_ended.connect(_on_run_ended)
	_change_scene(RUN_SCENE)


## Called by the run scene AFTER its UI has connected to run_system signals,
## so no signal emitted during setup is lost.
func begin_run() -> void:
	var action_cards := CardLibrary.load_cards_from_dir(ACTION_CARDS_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	run_system.start_run(action_cards, event_cards)


func return_to_menu() -> void:
	run_system = null
	_change_scene(MAIN_MENU_SCENE)


func _on_run_ended(won: bool, days_survived: int) -> void:
	last_run_won = won
	last_run_days = days_survived
	_change_scene(RESULT_SCENE)


func _change_scene(path: String) -> void:
	# Deferred: scene changes can be triggered from signal/input callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
