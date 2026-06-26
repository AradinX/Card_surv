extends Control
## Main menu: pick an unlocked character, start a run, or spend gold coins on the
## character roulette (1 coin -> unlock a random new class).

@onready var _coins_label: Label = $Center/VBox/CoinsLabel
@onready var _class_selector: OptionButton = $Center/VBox/ClassRow/ClassSelector
@onready var _continue_button: Button = $Center/VBox/ContinueButton
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _roulette_button: Button = $Center/VBox/RouletteButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _roulette_overlay: ColorRect = $RouletteOverlay
@onready var _roulette_label: Label = $RouletteOverlay/Panel/PanelMargin/VBox/RouletteLabel
@onready var _roulette_portrait: TextureRect = $RouletteOverlay/Panel/PanelMargin/VBox/RoulettePortrait
@onready var _roulette_result: Label = $RouletteOverlay/Panel/PanelMargin/VBox/ResultLabel
@onready var _roulette_close: Button = $RouletteOverlay/Panel/PanelMargin/VBox/CloseButton
@onready var _settings_button: Button = $Center/VBox/SettingsButton
@onready var _settings_overlay: SettingsOverlayView = $SettingsOverlay
@onready var _characters_button: Button = $Center/VBox/CharactersButton
@onready var _characters_overlay: ColorRect = $CharactersOverlay
@onready var _characters_list: VBoxContainer = $CharactersOverlay/Panel/PanelMargin/VBox/Scroll/List
@onready var _characters_close: Button = $CharactersOverlay/Panel/PanelMargin/VBox/CloseButton
@onready var _help_button: Button = $Center/VBox/HelpButton
@onready var _help_overlay: HelpOverlayView = $HelpOverlay

const MARKER_DIR := "res://assets/art/characters"

## Class ids parallel to the selector's item list (item index -> class id).
var _selector_class_ids: Array[String] = []
var _spin_tween: Tween


func _ready() -> void:
	ButtonSkin.apply_minimal_many([
		_continue_button, _start_button, _roulette_button, _characters_button,
		_settings_button, _help_button, _quit_button, _roulette_close, _characters_close
	])
	_continue_button.disabled = not GameManager.has_saved_run()
	_continue_button.pressed.connect(GameManager.continue_run)
	_start_button.pressed.connect(_on_start_pressed)
	_roulette_button.pressed.connect(_on_roulette_pressed)
	_quit_button.pressed.connect(get_tree().quit)
	_class_selector.item_selected.connect(_on_class_selected)
	_roulette_close.pressed.connect(func() -> void: _roulette_overlay.visible = false)
	_settings_button.pressed.connect(_settings_overlay.open)
	_characters_button.pressed.connect(_open_characters)
	_characters_close.pressed.connect(func() -> void: _characters_overlay.visible = false)
	_help_button.pressed.connect(_help_overlay.open)
	AudioManager.play_music("menu")
	AudioManager.stop_ambience()
	_refresh_meta_ui()
	# First launch: show the how-to-play once automatically.
	if not GameManager.meta_state.seen_tutorial:
		GameManager.meta_state.seen_tutorial = true
		GameManager.meta_state.save()
		_help_overlay.open()


## Gallery of unlocked characters: medallion portrait + name + flavour + the
## ability bullets from CharacterClassData.ability_summary().
func _open_characters() -> void:
	for child in _characters_list.get_children():
		child.queue_free()
	for character_class in GameManager.unlocked_classes():
		_characters_list.add_child(_make_character_card(character_class))
	_characters_overlay.visible = true


func _make_character_card(character_class: CharacterClassData) -> PanelContainer:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.06, 0.55)
	style.set_border_width_all(1)
	style.border_color = Color(0.5, 0.42, 0.22)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(96, 96)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var marker_path := "%s/marker_%s.png" % [MARKER_DIR, character_class.id]
	if ResourceLoader.exists(marker_path):
		portrait.texture = load(marker_path)
	row.add_child(portrait)

	var text := VBoxContainer.new()
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_theme_constant_override("separation", 4)
	row.add_child(text)

	var name_label := Label.new()
	name_label.text = character_class.display_name
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.40))
	text.add_child(name_label)

	if character_class.description != "":
		var desc := Label.new()
		desc.text = character_class.description
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(560, 0)
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.86, 0.82, 0.70))
		text.add_child(desc)

	var summary := character_class.ability_summary()
	if summary != "":
		var abilities := Label.new()
		abilities.text = summary
		abilities.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		abilities.custom_minimum_size = Vector2(560, 0)
		abilities.add_theme_font_size_override("font_size", 14)
		abilities.add_theme_color_override("font_color", Color(0.72, 0.88, 0.66))
		text.add_child(abilities)

	return card


func _refresh_meta_ui() -> void:
	_coins_label.text = "Złote monety: %d" % GameManager.meta_state.gold_coins
	_populate_class_selector()
	var can_spin: bool = GameManager.meta_state.can_spin(GameManager.class_count())
	_roulette_button.disabled = not can_spin
	if GameManager.meta_state.unlocked_class_ids.size() >= GameManager.class_count():
		_roulette_button.text = "Wszystkie postacie odblokowane"
	else:
		var coin_label := "moneta" if MetaState.SPIN_COST == 1 else "monety"
		_roulette_button.text = "Ruletka postaci (%d %s)" % [MetaState.SPIN_COST, coin_label]


func _populate_class_selector() -> void:
	_class_selector.clear()
	_selector_class_ids.clear()
	for character_class in GameManager.unlocked_classes():
		_class_selector.add_item(character_class.display_name)
		_class_selector.set_item_tooltip(
			_class_selector.item_count - 1, character_class.description
		)
		_selector_class_ids.append(character_class.id)
		if character_class.id == GameManager.selected_class_id:
			_class_selector.select(_class_selector.item_count - 1)


func _on_class_selected(index: int) -> void:
	if index >= 0 and index < _selector_class_ids.size():
		GameManager.selected_class_id = _selector_class_ids[index]


func _on_start_pressed() -> void:
	GameManager.start_new_run()


## Spend coins, perform the unlock immediately, then play a slot-machine style
## reveal that settles on the won class.
func _on_roulette_pressed() -> void:
	if not GameManager.meta_state.can_spin(GameManager.class_count()):
		return
	# Capture the still-locked classes BEFORE the spin — these are the reel's
	# candidates (the won one is among them; spin_roulette unlocks it next).
	var candidates := _locked_classes()
	var won: CharacterClassData = GameManager.spin_roulette()
	if won == null:
		return
	_coins_label.text = "Złote monety: %d" % GameManager.meta_state.gold_coins
	_roulette_button.disabled = true
	_roulette_overlay.visible = true
	_roulette_result.text = ""
	_roulette_close.disabled = true
	_animate_spin(won, candidates)


## Classes the player has NOT unlocked yet (the roulette can only roll these).
func _locked_classes() -> Array:
	var locked: Array = []
	for character_class in GameManager.class_catalog.values():
		if not GameManager.meta_state.is_unlocked(character_class.id):
			locked.append(character_class)
	return locked


func _animate_spin(won: CharacterClassData, candidates: Array) -> void:
	var classes: Array = candidates if not candidates.is_empty() else [won]

	if _spin_tween != null:
		_spin_tween.kill()
	_spin_tween = create_tween()
	# Flash through random characters (name + portrait), decelerating, then land
	# on the winner.
	for i in 18:
		var flash: CharacterClassData = classes[randi() % classes.size()]
		_spin_tween.tween_callback(func() -> void:
			_roulette_label.text = flash.display_name
			_set_roulette_portrait(flash.id)
		)
		_spin_tween.tween_interval(0.05 + i * 0.014)
	_spin_tween.tween_callback(func() -> void:
		_roulette_label.text = won.display_name
		_set_roulette_portrait(won.id)
		_roulette_result.text = "Odblokowano: %s!" % won.display_name
		_roulette_close.disabled = false
		# Make the freshly won class the active pick and refresh the menu.
		GameManager.selected_class_id = won.id
		_refresh_meta_ui()
	)


func _set_roulette_portrait(class_id: String) -> void:
	var path := "%s/marker_%s.png" % [MARKER_DIR, class_id]
	_roulette_portrait.texture = load(path) if ResourceLoader.exists(path) else null
