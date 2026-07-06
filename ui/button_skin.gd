class_name ButtonSkin
extends RefCounted

const ACT1_DIR := "res://assets/art/ui/buttons/act1/"
const ACT2_DIR := "res://assets/art/ui/buttons/act2/"

# 9-slice cut matching the constant ~20 px border band of the 448x224 button
# art (2026-07-06 set) — corners stay crisp at any button size.
const _TEXTURE_MARGINS := {
	"left": 20,
	"top": 20,
	"right": 20,
	"bottom": 20,
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
	# Focus draws ON TOP of the current state — a hover texture here made the
	# clicked button look permanently highlighted until focus moved elsewhere.
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
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


## Minimalist flat skin: dark translucent fill + thin gold border + gold text,
## brightening on hover. For clean menu-like screens (main menu, result, pause,
## settings) where the ornate textured skin is too busy. Gameplay buttons on the
## run board keep apply_primary.
static func apply_minimal(button: Button) -> void:
	button.add_theme_stylebox_override("normal",
		_flat(Color(0.06, 0.08, 0.06, 0.55), Color(0.66, 0.52, 0.26)))
	button.add_theme_stylebox_override("hover",
		_flat(Color(0.10, 0.13, 0.09, 0.66), Color(1.0, 0.84, 0.40)))
	button.add_theme_stylebox_override("pressed",
		_flat(Color(0.03, 0.05, 0.03, 0.74), Color(0.85, 0.68, 0.32)))
	button.add_theme_stylebox_override("hover_pressed",
		_flat(Color(0.03, 0.05, 0.03, 0.74), Color(0.85, 0.68, 0.32)))
	button.add_theme_stylebox_override("disabled",
		_flat(Color(0.05, 0.06, 0.05, 0.4), Color(0.34, 0.34, 0.30)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color(0.93, 0.87, 0.66))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.80))
	button.add_theme_color_override("font_pressed_color", Color(0.86, 0.74, 0.48))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.52, 0.46))
	button.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))


static func apply_minimal_many(buttons: Array) -> void:
	for button in buttons:
		apply_minimal(button as Button)


static func apply_panel_action(button: Button, act: int = 1) -> void:
	if button == null:
		return
	_clear_styleboxes(button)
	button.flat = true
	button.clip_text = true
	if act == 2:
		# Jasny krem na ciemnych, skorodowanych tabliczkach Act II (brąz z Act I
		# spada tam do kontrastu ~1.5-2.8).
		button.add_theme_color_override("font_color", Color(0.95, 0.9, 0.74, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.8, 0.74, 0.58, 1))
		button.add_theme_color_override("font_hover_color", Color(1.0, 0.97, 0.82, 1))
		button.add_theme_color_override("font_disabled_color", Color(0.6, 0.58, 0.5, 0.62))
	else:
		button.add_theme_color_override("font_color", Color(0.13, 0.08, 0.035, 1))
		button.add_theme_color_override("font_pressed_color", Color(0.08, 0.05, 0.025, 1))
		button.add_theme_color_override("font_hover_color", Color(0.29, 0.14, 0.05, 1))
		button.add_theme_color_override("font_disabled_color", Color(0.3, 0.25, 0.18, 0.62))
	button.add_theme_font_size_override("font_size", 18)


static func apply_panel_close(button: Button) -> void:
	if button == null:
		return
	_clear_styleboxes(button)
	button.flat = true
	button.clip_text = true
	button.text = "X"
	button.add_theme_color_override("font_color", Color(0.7372549, 0.05882353, 0.0, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.08, 0.03, 0.02, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.62, 0.12, 0.06, 1.0))
	button.add_theme_font_size_override("font_size", 24)


static func _clear_styleboxes(button: Button) -> void:
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty_style)


static func _flat(fill: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.set_border_width_all(2)
	sb.border_color = border
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 26.0
	sb.content_margin_right = 26.0
	sb.content_margin_top = 10.0
	sb.content_margin_bottom = 10.0
	return sb


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
