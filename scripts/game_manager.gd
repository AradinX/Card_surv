extends Node
## Autoload "GameManager". Owns the high-level flow:
## menu -> map -> day node -> map -> ... -> finale -> result.
## Creates the ExpeditionSystem; scenes connect to its signals and call back
## through the few methods below.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const MAP_SCENE := "res://scenes/map.tscn"
const RUN_SCENE := "res://scenes/run.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

const ACTION_CARDS_DIR := "res://data/cards/actions"
const EVENT_CARDS_DIR := "res://data/cards/events"
const ENCOUNTERS_DIR := "res://data/encounters"
const STARTER_DECK_PATH := "res://data/decks/starter_deck.tres"

## Placeholder for future meta-progression (camp, unlocks, deckbuilding).
var meta_state: MetaState = MetaState.new()
var expedition: ExpeditionSystem

var last_run_won := false
var last_run_days := 0


func start_new_run() -> void:
	expedition = ExpeditionSystem.new()
	expedition.return_to_map.connect(_on_return_to_map)
	expedition.expedition_ended.connect(_on_expedition_ended)

	var starter_deck: DeckData = load(STARTER_DECK_PATH)
	var action_pool := CardLibrary.load_cards_from_dir(ACTION_CARDS_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	var encounters := CardLibrary.load_encounters_from_dir(ENCOUNTERS_DIR)
	expedition.start(starter_deck, action_pool, event_cards, encounters)

	_change_scene(MAP_SCENE)


## Called by the map scene after the player picks a terrain/finale node.
## The run scene connects to expedition.day_system, then starts the day.
func go_to_day() -> void:
	expedition.prepare_day()
	_change_scene(RUN_SCENE)


func return_to_menu() -> void:
	expedition = null
	_change_scene(MAIN_MENU_SCENE)


func _on_return_to_map() -> void:
	_change_scene(MAP_SCENE)


func _on_expedition_ended(won: bool, days_survived: int) -> void:
	last_run_won = won
	last_run_days = days_survived
	_change_scene(RESULT_SCENE)


func _change_scene(path: String) -> void:
	# Deferred: scene changes can be triggered from signal/input callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
