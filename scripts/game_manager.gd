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
const BUILDINGS_DIR := "res://data/buildings"
const DISASTERS_DIR := "res://data/disasters"
const CLASSES_DIR := "res://data/classes"
## Single autosave slot for an in-progress run (one playthrough at a time).
const RUN_SAVE_PATH := "user://run_save.tres"

## Meta-progression (coins + unlocked classes), persisted to user://.
var meta_state: MetaState
## All playable classes by id (Scout starts unlocked; the rest use the roulette).
var class_catalog: Dictionary = {}
## Which unlocked class the next run will use.
var selected_class_id := MetaState.STARTING_CLASS_ID
var survival: SurvivalSystem

var last_run_won := false
var last_run_days := 0
## Set true when the just-finished run awarded a gold coin (won) — the result
## screen reads this to show the reward.
var last_run_coin_awarded := false
## Detailed end-of-run stats for the result screen (see SurvivalSystem.run_summary).
var last_run_summary: Dictionary = {}


func _ready() -> void:
	Settings.load_and_apply()
	meta_state = MetaState.load_or_new()
	_load_class_catalog()


func _load_class_catalog() -> void:
	for resource in CardLibrary.load_resources_from_dir(CLASSES_DIR):
		if resource is CharacterClassData:
			class_catalog[resource.id] = resource


func class_count() -> int:
	return class_catalog.size()


## Class resources the player has unlocked (Scout always present), easiest first.
func unlocked_classes() -> Array[CharacterClassData]:
	var result: Array[CharacterClassData] = []
	for class_id in meta_state.unlocked_class_ids:
		if class_catalog.has(class_id):
			result.append(class_catalog[class_id])
	result.sort_custom(func(a: CharacterClassData, b: CharacterClassData) -> bool:
		return a.unlock_order < b.unlock_order)
	return result


## Spends SPIN_COST coins and unlocks a RANDOM still-locked class. Returns null
## when the player can't spin (caller should check can_spin first).
## The optional save path is used by the isolated meta-progression test.
func spin_roulette(meta_save_path: String = MetaState.SAVE_PATH) -> CharacterClassData:
	if not meta_state.can_spin(class_count()):
		return null
	var locked: Array[CharacterClassData] = []
	for class_id in class_catalog:
		if not meta_state.is_unlocked(class_id):
			locked.append(class_catalog[class_id])
	if locked.is_empty():
		return null
	meta_state.gold_coins -= MetaState.SPIN_COST
	var won_class := locked[randi() % locked.size()]
	meta_state.unlock(won_class.id)
	meta_state.save(meta_save_path)
	return won_class


## Creates and starts the run system, then shows the run scene. The scene
## connects to survival's signals and calls survival.begin() — that order
## guarantees no signal is lost.
func start_new_run() -> void:
	delete_saved_run()
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)
	survival.day_started.connect(_on_day_started_autosave)

	var character_class: CharacterClassData = class_catalog.get(
		selected_class_id, class_catalog.get(MetaState.STARTING_CLASS_ID)
	)
	var biome_pool := CardLibrary.load_biomes_from_dir(BIOMES_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	# Reward pool = action cards only; buildings live in the always-available
	# build catalog (no longer drawn from the deck or won as rewards).
	var card_pool := CardLibrary.load_cards_from_dir(ACTION_CARDS_DIR)
	var building_catalog: Array[BuildingCardData] = []
	for resource in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if resource is BuildingCardData:
			building_catalog.append(resource)
	var disaster_pool: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir(DISASTERS_DIR):
		if resource is DisasterData:
			disaster_pool.append(resource)
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)

	_change_scene(RUN_SCENE)


## Loads the autosaved run and resumes it. Caller should check has_saved_run().
func continue_run() -> void:
	if not has_saved_run():
		return
	var loaded: Resource = ResourceLoader.load(
		RUN_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE
	)
	if not (loaded is RunState):
		delete_saved_run()
		return
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)
	survival.day_started.connect(_on_day_started_autosave)

	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	var card_pool := CardLibrary.load_cards_from_dir(ACTION_CARDS_DIR)
	var building_catalog: Array[BuildingCardData] = []
	for resource in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if resource is BuildingCardData:
			building_catalog.append(resource)
	survival.resume(loaded as RunState, event_cards, card_pool, building_catalog)

	_change_scene(RUN_SCENE)


func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


## Persists the current run's state (called at every dawn via day_started).
func save_run() -> void:
	if survival != null and survival.state != null:
		ResourceSaver.save(survival.state, RUN_SAVE_PATH)


func delete_saved_run() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)


func _on_day_started_autosave(_day: int) -> void:
	save_run()


func return_to_menu() -> void:
	survival = null
	_change_scene(MAIN_MENU_SCENE)


func _on_run_ended(won: bool, days_survived: int) -> void:
	last_run_won = won
	last_run_days = days_survived
	last_run_summary = survival.run_summary() if survival != null else {}
	# The run is over — no resume point.
	delete_saved_run()
	# One gold coin per won run — currency for the character roulette.
	last_run_coin_awarded = won
	if won:
		meta_state.gold_coins += 1
		meta_state.save()
	_change_scene(RESULT_SCENE)


func _change_scene(path: String) -> void:
	# Deferred: scene changes can be triggered from signal/input callbacks.
	get_tree().change_scene_to_file.call_deferred(path)
