class_name BuildingPopupView
extends Control

signal use_pressed(building_index: int)
signal repair_pressed(building_index: int)
signal demolish_pressed(building_index: int)

const PANEL_ACT1 := "res://assets/art/ui/panels/building_popup_panel_act1.png"
const PANEL_ACT2 := "res://assets/art/ui/panels/building_popup_panel_act2.png"
const BUILDING_ART_DIR := "res://assets/art/cards/illustrations/buildings_act1_candidates"
const BUILDING_ART_ALIASES := {
	"building_stone_storage": "building_quarry",
}
const POPUP_SIZE := Vector2(640, 480)
const CHROMA_SHADER := "shader_type canvas_item;
uniform vec3 outside_key = vec3(1.0, 0.0, 1.0);
uniform vec3 art_key = vec3(0.0, 0.31, 1.0);
uniform float tolerance = 0.18;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float outside_dist = distance(col.rgb, outside_key);
	float art_dist = distance(col.rgb, art_key);
	if (col.a < 0.01 || outside_dist < tolerance || art_dist < tolerance) {
		col.a = 0.0;
	} else {
		col.a = 1.0;
	}
	COLOR = col;
}"

@onready var _building_art: TextureRect = $Root/BuildingArt
@onready var _panel_art: TextureRect = $Root/PanelArt
@onready var _title_label: Label = $Root/TitleLabel
@onready var _hp_label: Label = $Root/HPLabel
@onready var _status_label: Label = get_node_or_null("Root/StatusLabel") as Label
@onready var _effects_label: Label = $Root/EffectsLabel
@onready var _action_label: Label = $Root/ActionLabel
@onready var _repair_label: Label = $Root/RepairLabel
@onready var _demolish_label: Label = $Root/DemolishLabel
@onready var _close_button: Button = $Root/CloseButton
@onready var _use_button: Button = $Root/UseButton
@onready var _repair_button: Button = $Root/RepairButton
@onready var _demolish_button: Button = $Root/DemolishButton

var _selected_building_index := -1
var _panel_shader: Shader


func _ready() -> void:
	visible = false
	if _panel_art.material == null:
		_panel_art.material = _panel_material()
	_close_button.pressed.connect(hide)
	_use_button.pressed.connect(func() -> void:
		use_pressed.emit(_selected_building_index)
	)
	_repair_button.pressed.connect(func() -> void:
		repair_pressed.emit(_selected_building_index)
	)
	_demolish_button.pressed.connect(func() -> void:
		demolish_pressed.emit(_selected_building_index)
	)


func selected_building_index() -> int:
	return _selected_building_index


func set_content(data: Dictionary) -> void:
	_selected_building_index = int(data.get("index", -1))
	var building_data := data.get("building_data") as BuildingCardData
	var is_act2 := bool(data.get("act2", false))
	_panel_art.texture = load(PANEL_ACT2 if is_act2 and ResourceLoader.exists(PANEL_ACT2) else PANEL_ACT1)
	_building_art.texture = _building_texture(building_data)

	_title_label.text = building_data.display_name if building_data != null else ""
	_hp_label.text = str(data.get("hp_text", ""))
	_hp_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.42, 0.38, 1.0) if bool(data.get("hp_low", false)) else Color(0.15, 0.09, 0.04, 1.0)
	)
	if _status_label != null:
		var status_text := str(data.get("status_text", ""))
		_status_label.text = status_text
		_status_label.visible = status_text != ""
	_set_optional_label(_effects_label, str(data.get("effects_text", "")))
	_set_optional_label(_action_label, str(data.get("action_text", "")))
	_set_optional_label(_repair_label, str(data.get("repair_text", "")))
	_set_optional_label(_demolish_label, str(data.get("demolish_text", "")))

	_use_button.visible = bool(data.get("use_visible", true))
	_use_button.disabled = bool(data.get("use_disabled", false))
	_use_button.text = str(data.get("use_text", "Użyj"))
	_use_button.tooltip_text = str(data.get("use_tooltip", ""))

	_repair_button.disabled = bool(data.get("repair_disabled", false))
	_repair_button.text = str(data.get("repair_button_text", "Napraw"))
	_repair_button.tooltip_text = str(data.get("repair_tooltip", ""))

	_demolish_button.disabled = bool(data.get("demolish_disabled", false))
	_demolish_button.tooltip_text = str(data.get("demolish_tooltip", ""))
	_fit_content_text()


func _set_optional_label(label: Label, text: String) -> void:
	label.text = text
	label.visible = text != ""


func _fit_content_text() -> void:
	_fit_label_font(_hp_label, 14, 9, 2)
	_fit_label_font(_effects_label, 12, 8, 5)
	_fit_label_font(_action_label, 11, 8, 4)
	_fit_label_font(_repair_label, 11, 8, 4)
	_fit_label_font(_demolish_label, 11, 8, 4)


func _fit_label_font(label: Label, max_size: int, min_size: int, max_lines: int) -> void:
	if not label.visible:
		return
	label.add_theme_constant_override("line_spacing", 0)
	label.max_lines_visible = max_lines
	for font_size in range(max_size, min_size - 1, -1):
		label.add_theme_font_size_override("font_size", font_size)
		if label.get_line_count() <= max_lines and label.get_line_count() <= label.get_visible_line_count():
			return
	label.add_theme_font_size_override("font_size", min_size)


func popup_for(data: Dictionary, anchor: Rect2, viewport_size: Vector2) -> void:
	set_content(data)
	var popup_size := _scaled_size(viewport_size)
	var pos := _popup_position(anchor, popup_size, viewport_size)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = pos
	size = popup_size
	custom_minimum_size = popup_size
	visible = true
	move_to_front()


func _panel_material() -> ShaderMaterial:
	if _panel_shader == null:
		_panel_shader = Shader.new()
		_panel_shader.code = CHROMA_SHADER
	var material := ShaderMaterial.new()
	material.shader = _panel_shader
	return material


func _building_texture(building_data: BuildingCardData) -> Texture2D:
	if building_data == null:
		return null
	var art_id := str(BUILDING_ART_ALIASES.get(building_data.id, building_data.id))
	var path := "%s/%s.png" % [BUILDING_ART_DIR, art_id]
	return load(path) if ResourceLoader.exists(path) else null


func _scaled_size(viewport_size: Vector2) -> Vector2:
	var popup_scale := minf(1.0, minf(
		maxf(viewport_size.x - 32.0, 280.0) / POPUP_SIZE.x,
		maxf(viewport_size.y - 32.0, 260.0) / POPUP_SIZE.y
	))
	return POPUP_SIZE * popup_scale


func _popup_position(anchor: Rect2, popup_size: Vector2, viewport_size: Vector2) -> Vector2:
	var pos := Vector2(
		viewport_size.x - popup_size.x - 28.0,
		viewport_size.y - popup_size.y - 112.0
	)
	if anchor.size.x > 0.0 and anchor.size.y > 0.0:
		pos = anchor.position + Vector2(anchor.size.x + 12.0, 0.0)
		if pos.x + popup_size.x > viewport_size.x - 16.0:
			pos.x = anchor.position.x - popup_size.x - 12.0
		pos.y = anchor.position.y
	return Vector2(
		clampf(pos.x, 16.0, maxf(viewport_size.x - popup_size.x - 16.0, 16.0)),
		clampf(pos.y, 16.0, maxf(viewport_size.y - popup_size.y - 16.0, 16.0))
	)
