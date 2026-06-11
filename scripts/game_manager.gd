extends Node
## Autoload "GameManager". Owns the high-level flow:
## menu -> run (the whole expedition happens on one screen) -> result.
## Creates the SurvivalSystem; scenes connect to its signals and call back
## through the few methods below.

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const RUN_SCENE := "res://scenes/run.tscn"
const RESULT_SCENE := "res://scenes/result.tscn"

const ACTION_CARDS_DIR := "res://data/cards/actions"
const EVENT_CARDS_DIR := "res://data/cards/events"
const BIOMES_DIR := "res://data/biomes"
## The only playable class for now (more classes unlock via meta-progression).
const CLASS_PATH := "res://data/classes/cook.tres"

## Placeholder for future meta-progression (collection, unlocks, ladder).
var meta_state: MetaState = MetaState.new()
var survival: SurvivalSystem

var last_run_won := false
var last_run_days := 0


## Creates and starts the run system, then shows the run scene. The scene
## connects to survival's signals and calls survival.begin() — that order
## guarantees no signal is lost.
func start_new_run() -> void:
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)

	var character_class: CharacterClassData = load(CLASS_PATH)
	var biome_pool := CardLibrary.load_biomes_from_dir(BIOMES_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	var card_pool := CardLibrary.load_cards_from_dir(ACTION_CARDS_DIR)
	survival.start(character_class, biome_pool, event_cards, card_pool)

	_change_scene(RUN_SCENE)


func return_to_menu() -> void:
	survival = null
	_change_scene(MAIN_MENU_SCENE)


func _on_run_ended(won: bool, days_survived: int) -> void:
	last_run_won = won
	last_run_days = days_survived
	_change_scene(RESULT_SCENE)


func _change_scene(path: String) -> void:
	# Deferred: scene changes can be triggered from signal/input callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
