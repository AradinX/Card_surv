extends Control
## Main menu: pick an unlocked character, start a run, or spend gold coins on the
## character roulette (3 coins -> unlock a random new class).

@onready var _coins_label: Label = $Center/VBox/CoinsLabel
@onready var _class_selector: OptionButton = $Center/VBox/ClassRow/ClassSelector
@onready var _continue_button: Button = $Center/VBox/ContinueButton
@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _roulette_button: Button = $Center/VBox/RouletteButton
@onready var _quit_button: Button = $Center/VBox/QuitButton
@onready var _roulette_overlay: ColorRect = $RouletteOverlay
@onready var _roulette_label: Label = $RouletteOverlay/Panel/PanelMargin/VBox/RouletteLabel
@onready var _roulette_result: Label = $RouletteOverlay/Panel/PanelMargin/VBox/ResultLabel
@onready var _roulette_close: Button = $RouletteOverlay/Panel/PanelMargin/VBox/CloseButton

## Class ids parallel to the selector's item list (item index -> class id).
var _selector_class_ids: Array[String] = []
var _spin_tween: Tween


func _ready() -> void:
	ButtonSkin.apply_many([
		_continue_button, _start_button, _roulette_button, _quit_button, _roulette_close
	])
	_continue_button.disabled = not GameManager.has_saved_run()
	_continue_button.pressed.connect(GameManager.continue_run)
	_start_button.pressed.connect(_on_start_pressed)
	_roulette_button.pressed.connect(_on_roulette_pressed)
	_quit_button.pressed.connect(get_tree().quit)
	_class_selector.item_selected.connect(_on_class_selected)
	_roulette_close.pressed.connect(func() -> void: _roulette_overlay.visible = false)
	_refresh_meta_ui()


func _refresh_meta_ui() -> void:
	_coins_label.text = "Złote monety: %d" % GameManager.meta_state.gold_coins
	_populate_class_selector()
	var can_spin: bool = GameManager.meta_state.can_spin(GameManager.class_count())
	_roulette_button.disabled = not can_spin
	if GameManager.meta_state.unlocked_class_ids.size() >= GameManager.class_count():
		_roulette_button.text = "Wszystkie postacie odblokowane"
	else:
		_roulette_button.text = "Ruletka postaci (%d monety)" % MetaState.SPIN_COST


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
	var won: CharacterClassData = GameManager.spin_roulette()
	if won == null:
		return
	_coins_label.text = "Złote monety: %d" % GameManager.meta_state.gold_coins
	_roulette_button.disabled = true
	_roulette_overlay.visible = true
	_roulette_result.text = ""
	_roulette_close.disabled = true
	_animate_spin(won)


func _animate_spin(won: CharacterClassData) -> void:
	var names: Array[String] = []
	for character_class in GameManager.class_catalog.values():
		names.append(character_class.display_name)

	if _spin_tween != null:
		_spin_tween.kill()
	_spin_tween = create_tween()
	# Flash through random names, decelerating, then land on the winner.
	for i in 18:
		var flash_name: String = names[randi() % names.size()]
		_spin_tween.tween_callback(func() -> void: _roulette_label.text = flash_name)
		_spin_tween.tween_interval(0.05 + i * 0.014)
	_spin_tween.tween_callback(func() -> void:
		_roulette_label.text = won.display_name
		_roulette_result.text = "Odblokowano: %s!" % won.display_name
		_roulette_close.disabled = false
		# Make the freshly won class the active pick and refresh the menu.
		GameManager.selected_class_id = won.id
		_refresh_meta_ui()
	)
