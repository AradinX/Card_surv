class_name ButtonSkin
extends RefCounted

const ACT1_DIR := "res://assets/art/ui/buttons/act1/"
const ACT2_DIR := "res://assets/art/ui/buttons/act2/"

const _TEXTURE_MARGINS := {
	"left": 0,
	"top": 0,
	"right": 0,
	"bottom": 0,
}

const _CONTENT_MARGINS := {
	"left": 26,
	"top": 10,
	"right": 26,
	"bottom": 10,
}


static func apply_primary(button: Button, act: int = 1) -> void:
	button.add_theme_stylebox_override("normal", _make_style(_path(act, "button_primary.png")))
	button.add_theme_stylebox_override("hover", _make_style(_path(act, "button_primary_hover.png")))
	button.add_theme_stylebox_override("pressed", _make_style(_path(act, "button_primary_pressed.png")))
	button.add_theme_stylebox_override("hover_pressed", _make_style(_path(act, "button_primary_pressed.png")))
	button.add_theme_stylebox_override("disabled", _make_style(_path(act, "button_disabled.png")))
	button.add_theme_stylebox_override("focus", _make_style(_path(act, "button_primary_hover.png")))
	button.add_theme_color_override("font_color", Color(0.98, 0.93, 0.76))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.78))
	button.add_theme_color_override("font_pressed_color", Color(0.86, 0.78, 0.54))
	button.add_theme_color_override("font_disabled_color", Color(0.58, 0.57, 0.48))
	button.add_theme_color_override("font_shadow_color", Color(0.035, 0.025, 0.015))
	button.add_theme_constant_override("shadow_offset_x", 1)
	button.add_theme_constant_override("shadow_offset_y", 1)


static func apply_many(buttons: Array, act: int = 1) -> void:
	for button in buttons:
		apply_primary(button as Button, act)


static func _path(act: int, file_name: String) -> String:
	return (ACT2_DIR if act == 2 else ACT1_DIR) + file_name


static func _make_style(path: String) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load(path)
	style.texture_margin_left = _TEXTURE_MARGINS.left
	style.texture_margin_top = _TEXTURE_MARGINS.top
	style.texture_margin_right = _TEXTURE_MARGINS.right
	style.texture_margin_bottom = _TEXTURE_MARGINS.bottom
	style.content_margin_left = _CONTENT_MARGINS.left
	style.content_margin_top = _CONTENT_MARGINS.top
	style.content_margin_right = _CONTENT_MARGINS.right
	style.content_margin_bottom = _CONTENT_MARGINS.bottom
	style.expand_margin_left = 3
	style.expand_margin_top = 3
	style.expand_margin_right = 3
	style.expand_margin_bottom = 3
	return style
