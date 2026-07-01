class_name SecurePopupView
extends ColorRect
## Region-securing confirmation modal painted on the hand-made wooden "secure"
## panel. Unlike the plain confirm popup it carries a preview slot (the keyed-out
## placeholder zone) where the secured tile art can be shown. Layout of the
## children is meant to be tuned by hand in the editor; this script only fills
## text, swaps the Act I/II skin and emits the result.

signal confirmed
signal cancelled

const PANEL_ACT1 := "res://assets/art/ui/panels/secure_popup_panel_act1.png"
const PANEL_ACT2 := "res://assets/art/ui/panels/secure_popup_panel_act2.png"

@onready var _panel_art: TextureRect = $Panel/PanelArt
@onready var _panel: Control = $Panel
@onready var _title_label: Label = $Panel/TitleLabel
@onready var _preview: TextureRect = $Panel/RegionPreview
@onready var _body_label: Label = $Panel/BodyLabel
@onready var _close_button: Button = $Panel/CloseButton
@onready var _ok_button: Button = $Panel/OkButton

var _act := 1


func _ready() -> void:
	visible = false
	_refresh_panel()
	_refresh_skin()
	_ok_button.pressed.connect(_on_ok)
	_close_button.pressed.connect(_on_cancel)
	gui_input.connect(_on_backdrop_input)


## `preview` is optional art for the placeholder slot (e.g. the secured tile).
func open(title: String, body: String, ok_text: String = "Zabezpiecz", preview: Texture2D = null) -> void:
	_title_label.text = title
	_body_label.text = body
	_ok_button.text = ok_text
	_preview.texture = preview
	_preview.visible = preview != null
	visible = true
	move_to_front()


func close() -> void:
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
	ButtonSkin.apply_panel_action(_ok_button)
	ButtonSkin.apply_panel_close(_close_button)


func _on_ok() -> void:
	visible = false
	confirmed.emit()


func _on_cancel() -> void:
	visible = false
	cancelled.emit()


func _on_backdrop_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed \
			and not _panel.get_global_rect().has_point(event.global_position):
		_on_cancel()
