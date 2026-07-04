class_name DeckPopupView
extends ColorRect
## Deck viewer modal painted on the hand-made wooden "deck" panel. Shows the
## player's current deck contents as a scrollable grid. Layout of the children
## (title, scroll list, close button) is meant to be tuned by hand in the editor.

signal closed

const PANEL_ACT1 := "res://assets/art/ui/panels/deck_popup_panel_act1.png"
const PANEL_ACT2 := "res://assets/art/ui/panels/deck_popup_panel_act2.png"
const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const MINI_CARD_SIZE := Vector2(92, 138)
const ZOOM_CARD_SIZE := Vector2(198, 297)

@onready var _panel_art: TextureRect = $Panel/PanelArt
@onready var _panel: Control = $Panel
@onready var _title_label: Label = $Panel/TitleLabel
@onready var _deck_grid: GridContainer = $Panel/DeckScroll/DeckGrid
@onready var _close_button: Button = $Panel/CloseButton
@onready var _ok_button: Button = _find_ok_button()

var _act := 1
var _zoom_layer: ColorRect
var _zoom_slot: CenterContainer


func _ready() -> void:
	visible = false
	_refresh_panel()
	_refresh_skin()
	_close_button.pressed.connect(_on_close)
	if _ok_button != null:
		_ok_button.pressed.connect(_on_close)
	_create_zoom_layer()
	gui_input.connect(_on_backdrop_input)


func open(cards: Array[CardData], title: String = "Talia") -> void:
	_title_label.text = title
	_rebuild_cards(cards)
	visible = true
	move_to_front()


func close() -> void:
	_hide_card_zoom()
	visible = false


func set_act2() -> void:
	_act = 2
	_refresh_panel()
	_refresh_skin()


func _refresh_panel() -> void:
	if _panel_art == null:
		return
	var path := PANEL_ACT2 if _act == 2 and ResourceLoader.exists(PANEL_ACT2) else PANEL_ACT1
	if ResourceLoader.exists(path):
		_panel_art.texture = load(path)


func _refresh_skin() -> void:
	ButtonSkin.apply_panel_close(_close_button)
	ButtonSkin.apply_panel_action(_ok_button)


func _rebuild_cards(cards: Array[CardData]) -> void:
	for child in _deck_grid.get_children():
		_deck_grid.remove_child(child)
		child.queue_free()
	for card in cards:
		if card == null:
			continue
		var view := CARD_VIEW_SCENE.instantiate() as CardView
		view.custom_minimum_size = MINI_CARD_SIZE
		view.size = MINI_CARD_SIZE
		_deck_grid.add_child(view)
		view.setup(card, "")
		view.tooltip_text = "%s\n%s" % [tr(card.display_name), tr(card.description)]
		view.pressed.connect(_show_card_zoom.bind(card))


func _find_ok_button() -> Button:
	var button := get_node_or_null("Panel/OkButton") as Button
	if button == null:
		button = get_node_or_null("Panel/ButtonOK") as Button
	return button


func _create_zoom_layer() -> void:
	_zoom_layer = ColorRect.new()
	_zoom_layer.name = "CardZoomLayer"
	_zoom_layer.visible = false
	_zoom_layer.z_index = 600
	_zoom_layer.z_as_relative = false
	_zoom_layer.color = Color(0.0, 0.0, 0.0, 0.68)
	_zoom_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_zoom_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zoom_layer.gui_input.connect(_on_zoom_backdrop_input)
	add_child(_zoom_layer)

	_zoom_slot = CenterContainer.new()
	_zoom_slot.mouse_filter = Control.MOUSE_FILTER_PASS
	_zoom_slot.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zoom_layer.add_child(_zoom_slot)


func _show_card_zoom(card: CardData) -> void:
	for child in _zoom_slot.get_children():
		_zoom_slot.remove_child(child)
		child.queue_free()
	var view := CARD_VIEW_SCENE.instantiate() as CardView
	view.custom_minimum_size = ZOOM_CARD_SIZE
	view.size = ZOOM_CARD_SIZE
	view.mouse_filter = Control.MOUSE_FILTER_STOP
	_zoom_slot.add_child(view)
	view.setup(card, "")
	_zoom_layer.visible = true
	_zoom_layer.move_to_front()


func _hide_card_zoom() -> void:
	if _zoom_layer != null:
		_zoom_layer.visible = false


func _on_zoom_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
		_hide_card_zoom()
		accept_event()


func _on_close() -> void:
	visible = false
	closed.emit()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and not _panel.get_global_rect().has_point(event.global_position):
		_on_close()
