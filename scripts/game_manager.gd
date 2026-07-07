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
const START_TRANSITION_IMAGE := "res://assets/art/backgrounds/run_screen/start_screen.png"
## Single autosave slot for an in-progress run (one playthrough at a time).
const RUN_SAVE_PATH := "user://run_save.json"
## Pre-JSON autosave (unsafe ResourceLoader format) — never loaded, only cleaned up.
const LEGACY_RUN_SAVE_PATH := "user://run_save.tres"
const RECENT_LOG_LIMIT := 8
const DREAM_IMAGE_FADE_TIME := 0.65
const DREAM_IMAGE_HOLD := 0.85
const DREAM_EYE_TIME := 1.05
const DREAM_CLOSED_HOLD := 0.28

## Meta-progression (coins + unlocked classes), persisted to user://.
var meta_state: MetaState
## All playable classes by id (Scout starts unlocked; the rest use the roulette).
var class_catalog: Dictionary = {}
## Which unlocked class the next run will use.
var selected_class_id := MetaState.STARTING_CLASS_ID
var survival: SurvivalSystem
var tutorial_mode := false

var last_run_won := false
var last_run_days := 0
## Set true when the just-finished run awarded a gold coin (won) — the result
## screen reads this to show the reward.
var last_run_coin_awarded := false
## Detailed end-of-run stats for the result screen (see SurvivalSystem.run_summary).
var last_run_summary: Dictionary = {}
var _recent_run_logs: Array[String] = []
var _scene_transition_active := false


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


## Spends SPIN_COST coins and unlocks the still-locked class with the lowest
## unlock_order (easiest first), so the difficulty ramps run after run — the
## roulette spin is show, the outcome is deterministic. Returns null when the
## player can't spin (caller should check can_spin first).
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
	locked.sort_custom(func(a: CharacterClassData, b: CharacterClassData) -> bool:
		return a.unlock_order < b.unlock_order)
	var won_class := locked[0]
	meta_state.unlock(won_class.id)
	meta_state.save(meta_save_path)
	return won_class


## Creates and starts the run system, then shows the run scene. The scene
## connects to survival's signals and calls survival.begin() — that order
## guarantees no signal is lost.
func start_new_run() -> void:
	tutorial_mode = false
	delete_saved_run()
	_recent_run_logs.clear()
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)
	survival.day_started.connect(_on_day_started_autosave)
	survival.log_message.connect(_on_run_log_message)

	var character_class: CharacterClassData = class_catalog.get(
		selected_class_id, class_catalog.get(MetaState.STARTING_CLASS_ID)
	)
	var biome_pool := CardLibrary.load_biomes_from_dir(BIOMES_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	# Reward pool = action cards only (minus gather_only, which stay pinned to
	# their biome); buildings live in the always-available build catalog.
	var card_pool := CardLibrary.load_reward_pool_from_dir(ACTION_CARDS_DIR)
	var building_catalog: Array[BuildingCardData] = []
	for resource in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if resource is BuildingCardData:
			building_catalog.append(resource)
	var disaster_pool: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir(DISASTERS_DIR):
		if resource is DisasterData:
			disaster_pool.append(resource)
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)

	_change_scene(RUN_SCENE, true)


func start_tutorial_run() -> void:
	tutorial_mode = true
	delete_saved_run()
	_recent_run_logs.clear()
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)
	survival.log_message.connect(_on_run_log_message)

	var character_class: CharacterClassData = class_catalog.get(
		MetaState.STARTING_CLASS_ID, class_catalog.get(selected_class_id)
	)
	var biome_pool := CardLibrary.load_biomes_from_dir(BIOMES_DIR)
	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	var card_pool := CardLibrary.load_reward_pool_from_dir(ACTION_CARDS_DIR)
	var building_catalog: Array[BuildingCardData] = []
	for resource in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if resource is BuildingCardData:
			building_catalog.append(resource)
	var disaster_pool: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir(DISASTERS_DIR):
		if resource is DisasterData:
			disaster_pool.append(resource)
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)
	survival.configure_tutorial_run()

	_change_scene(RUN_SCENE, true)


## Loads the autosaved run and resumes it. Caller should check has_saved_run().
func continue_run() -> void:
	if not has_saved_run():
		return
	tutorial_mode = false
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var loaded := RunState.from_dict(JSON.parse_string(file.get_as_text()), _save_catalog())
	if loaded == null:
		delete_saved_run()
		return
	_recent_run_logs.clear()
	survival = SurvivalSystem.new()
	survival.run_ended.connect(_on_run_ended)
	survival.day_started.connect(_on_day_started_autosave)
	survival.log_message.connect(_on_run_log_message)

	var event_cards := CardLibrary.load_cards_from_dir(EVENT_CARDS_DIR)
	var card_pool := CardLibrary.load_reward_pool_from_dir(ACTION_CARDS_DIR)
	var building_catalog: Array[BuildingCardData] = []
	for resource in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if resource is BuildingCardData:
			building_catalog.append(resource)
	survival.resume(loaded, event_cards, card_pool, building_catalog)

	_change_scene(RUN_SCENE, true)


func has_saved_run() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


## Class id stored in the autosave ("" when none/invalid). A run always resumes
## with the class it was started with — the menu shows that on "Kontynuuj",
## because the class selector applies only to a NEW run.
func saved_run_class_id() -> String:
	if not has_saved_run():
		return ""
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if file == null:
		return ""
	var data: Variant = JSON.parse_string(file.get_as_text())
	return str(data.get("class_id", "")) if data is Dictionary else ""


## Persists the current run's state (called at every dawn via day_started).
func save_run() -> void:
	if survival != null and survival.state != null:
		var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(JSON.stringify(survival.state.to_dict()))


func delete_saved_run() -> void:
	for path in [RUN_SAVE_PATH, LEGACY_RUN_SAVE_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


## Lookup tables (id -> authored res:// resource) used by RunState.from_dict.
## Deck entries can be action OR building cards, so both land in "cards".
func _save_catalog() -> Dictionary:
	var cards: Dictionary = CardLibrary.load_deck_card_lookup()
	var buildings: Dictionary = {}
	for card in CardLibrary.load_cards_from_dir(BUILDINGS_DIR):
		if card is BuildingCardData:
			buildings[card.id] = card
			cards[card.id] = card
	var biomes: Dictionary = {}
	for biome in CardLibrary.load_biomes_from_dir(BIOMES_DIR):
		biomes[biome.id] = biome
	var disasters: Dictionary = {}
	for resource in CardLibrary.load_resources_from_dir(DISASTERS_DIR):
		if resource is DisasterData:
			disasters[resource.id] = resource
	return {
		"classes": class_catalog,
		"cards": cards,
		"biomes": biomes,
		"buildings": buildings,
		"disasters": disasters,
	}


func _on_day_started_autosave(_day: int) -> void:
	save_run()


func _on_run_log_message(text: String) -> void:
	if text.strip_edges() == "":
		return
	_recent_run_logs.append(text)
	while _recent_run_logs.size() > RECENT_LOG_LIMIT:
		_recent_run_logs.pop_front()


func return_to_menu() -> void:
	tutorial_mode = false
	survival = null
	_change_scene(MAIN_MENU_SCENE)


func _on_run_ended(won: bool, days_survived: int) -> void:
	last_run_won = won
	last_run_days = days_survived
	last_run_summary = survival.run_summary() if survival != null else {}
	last_run_summary["recent_logs"] = _recent_run_logs.duplicate()
	# The run is over — no resume point.
	delete_saved_run()
	# One gold coin per won run — currency for the character roulette.
	last_run_coin_awarded = won
	if won:
		meta_state.gold_coins += 1
		meta_state.save()
	_change_scene(RESULT_SCENE)


func _change_scene(path: String, dream_transition: bool = false) -> void:
	# Deferred: scene changes can be triggered from signal/input callbacks.
	if dream_transition:
		_run_dream_transition.call_deferred(path)
		return
	get_tree().change_scene_to_file.call_deferred(path)


func _run_dream_transition(path: String) -> void:
	if _scene_transition_active:
		return
	_scene_transition_active = true
	var layer := _make_dream_transition_layer()
	add_child(layer)
	await get_tree().process_frame

	var root := layer.get_node("Root") as Control
	var image := root.get_node("StartImage") as TextureRect
	var top_lid := root.get_node("TopLid") as ColorRect
	var bottom_lid := root.get_node("BottomLid") as ColorRect
	_layout_dream_lids(top_lid, bottom_lid, 0.0)

	var close_tween := create_tween().set_parallel(true)
	close_tween.tween_property(image, "modulate:a", 1.0, DREAM_IMAGE_FADE_TIME) \
		.set_trans(Tween.TRANS_SINE)
	close_tween.tween_property(top_lid, "size:y", _dream_closed_lid_height(), DREAM_EYE_TIME) \
		.set_delay(DREAM_IMAGE_FADE_TIME + DREAM_IMAGE_HOLD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	close_tween.tween_property(bottom_lid, "position:y", _dream_bottom_closed_y(), DREAM_EYE_TIME) \
		.set_delay(DREAM_IMAGE_FADE_TIME + DREAM_IMAGE_HOLD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	close_tween.tween_property(bottom_lid, "size:y", _dream_closed_lid_height(), DREAM_EYE_TIME) \
		.set_delay(DREAM_IMAGE_FADE_TIME + DREAM_IMAGE_HOLD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await close_tween.finished
	await get_tree().create_timer(DREAM_CLOSED_HOLD).timeout

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	image.visible = false
	_layout_dream_lids(top_lid, bottom_lid, _dream_closed_lid_height())

	var open_tween := create_tween().set_parallel(true)
	open_tween.tween_property(top_lid, "size:y", 0.0, DREAM_EYE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	open_tween.tween_property(bottom_lid, "position:y", get_viewport().get_visible_rect().size.y, DREAM_EYE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	open_tween.tween_property(bottom_lid, "size:y", 0.0, DREAM_EYE_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await open_tween.finished
	layer.queue_free()
	_scene_transition_active = false


func _make_dream_transition_layer() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "DreamSceneTransition"
	layer.layer = 1000

	var root := Control.new()
	root.name = "Root"
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(root)

	var image := TextureRect.new()
	image.name = "StartImage"
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.set_anchors_preset(Control.PRESET_FULL_RECT)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(1, 1, 1, 0)
	image.texture = _load_start_transition_texture()
	root.add_child(image)

	var top_lid := ColorRect.new()
	top_lid.name = "TopLid"
	top_lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_lid.color = Color.BLACK
	root.add_child(top_lid)

	var bottom_lid := ColorRect.new()
	bottom_lid.name = "BottomLid"
	bottom_lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_lid.color = Color.BLACK
	root.add_child(bottom_lid)

	return layer


func _layout_dream_lids(top_lid: ColorRect, bottom_lid: ColorRect, lid_height: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	top_lid.position = Vector2.ZERO
	top_lid.size = Vector2(viewport_size.x, lid_height)
	bottom_lid.position = Vector2(0.0, viewport_size.y - lid_height)
	bottom_lid.size = Vector2(viewport_size.x, lid_height)


func _dream_closed_lid_height() -> float:
	return get_viewport().get_visible_rect().size.y * 0.56


func _dream_bottom_closed_y() -> float:
	return get_viewport().get_visible_rect().size.y - _dream_closed_lid_height()


func _load_start_transition_texture() -> Texture2D:
	if ResourceLoader.exists(START_TRANSITION_IMAGE):
		return load(START_TRANSITION_IMAGE) as Texture2D
	var file_image := Image.new()
	if file_image.load(START_TRANSITION_IMAGE) != OK:
		return null
	return ImageTexture.create_from_image(file_image)
