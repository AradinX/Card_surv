class_name TopStatusBarView
extends Control
## Compact single-strip HUD: day/season and level/XP on the left, stat and
## resource cells (icon + "value/max", no progress bars) on the right. Every
## cell reserves a thin badge line above its value for the "+2 / -1" card
## effect preview, so showing/hiding badges never shifts the layout — and the
## preview survives drag & drop.

# Optional painted strip frames (plug-and-play like StatIcons): drop the file
# in and it replaces the flat panel automatically.
const SLIM_FRAME_ACT1 := "res://assets/art/ui/panels/top_status_bar_slim_act1.png"
const SLIM_FRAME_ACT2 := "res://assets/art/ui/panels/top_status_bar_slim_act2.png"

const VALUE_COLOR := Color(0.98, 0.93, 0.78)
const RESOURCE_COLOR := Color(0.92, 0.88, 0.69)
const LOW_COLOR := Color(1.0, 0.78, 0.4)
const CRITICAL_COLOR := Color(1.0, 0.42, 0.34)
const BADGE_UP_COLOR := Color(0.55, 1.0, 0.45)
const BADGE_DOWN_COLOR := Color(1.0, 0.4, 0.32)
const SHADOW_COLOR := Color(0.04, 0.05, 0.025)

# Caption under every cell — names what the icon means (feedback: the icons
# alone weren't obvious). Doubles as the fallback when an icon file is missing.
const CAPTION_WORDS := {
	"health": "Zdrowie", "hunger": "Sytość", "thirst": "Nawodnienie",
	"warmth": "Ciepło", "energy": "Energia", "food": "Jedzenie",
	"water": "Woda", "wood": "Drewno", "materials": "Kamień", "tools": "Narzędzia",
}
const CAPTION_COLOR := Color(0.85, 0.78, 0.62, 0.9)

@onready var _panel: Panel = $Panel
@onready var _frame: NinePatchRect = $Frame
@onready var _row: HBoxContainer = $Row

var _day_label: Label
var _season_label: Label
var _level_label: Label
var _xp_label: Label
var _cells := {}  # key -> {"value": Label, "badge": Label}


func _ready() -> void:
	_apply_panel_style(1)
	var day_box := VBoxContainer.new()
	day_box.add_theme_constant_override("separation", 0)
	day_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_day_label = _make_label(16, VALUE_COLOR)
	_day_label.name = "DayLabel"
	_season_label = _make_label(12, VALUE_COLOR)
	_season_label.name = "SeasonLabel"
	day_box.add_child(_day_label)
	day_box.add_child(_season_label)
	_row.add_child(day_box)

	var level_box := VBoxContainer.new()
	level_box.add_theme_constant_override("separation", 0)
	level_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_level_label = _make_label(13, RESOURCE_COLOR)
	_level_label.name = "LevelLabel"
	_xp_label = _make_label(11, RESOURCE_COLOR)
	_xp_label.name = "XPLabel"
	level_box.add_child(_level_label)
	level_box.add_child(_xp_label)
	_row.add_child(level_box)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(spacer)

	_add_cell("health", "health",
		tr("Zdrowie\nGdy spadnie do 0, run się kończy.\nTracisz je od ran, potworów i pustych potrzeb."))
	_add_cell("hunger", "hunger",
		tr("Sytość\nSpada każdej nocy.\nJeśli jest niska, zapasy jedzenia są automatycznie zjadane."))
	_add_cell("thirst", "thirst",
		tr("Nawodnienie\nSpada każdej nocy.\nLatem i na suchych biomach spada szybciej."))
	_add_cell("warmth", "warmth",
		tr("Ciepło\nSpada każdej nocy.\nOgnisko, schronienie i część kart pomagają utrzymać temperaturę."))
	_add_cell("energy", "energy",
		tr("Energia\nOdnawia się o świcie do aktualnego maksimum.\nAwans może zwiększać maksimum bez twardego limitu."))

	var divider := ColorRect.new()
	divider.color = Color(0.66, 0.52, 0.26, 0.45)
	divider.custom_minimum_size = Vector2(2, 0)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_child(divider)

	_add_cell("food", "food",
		tr("Jedzenie\nZapas automatycznie zjadany nocą, gdy sytość jest niska."))
	_add_cell("water", "water",
		tr("Woda\nZapas automatycznie pity nocą, gdy nawodnienie jest niskie."))
	_add_cell("wood", "wood",
		tr("Drewno\nBudowa, naprawy, dokładanie do ogniska i część akcji budynków."))
	_add_cell("materials", "stone",
		tr("Kamień\nKoszty budynków, zabezpieczanie rejonów i odbudowa po katastrofie."))
	_add_cell("tools", "tools",
		tr("Narzędzia\nGdy są gotowe, karty z jedzeniem i drewnem dają większy zysk."))


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", SHADOW_COLOR)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


## Cell = [icon | badge-over-value] with the stat's name captioned underneath.
## The badge line is always there (empty text when no preview), so the row
## never reflows on hover.
func _add_cell(key: String, icon_key: String, tooltip: String) -> void:
	var cell := VBoxContainer.new()
	cell.name = key.capitalize() + "Cell"
	cell.add_theme_constant_override("separation", 0)
	cell.tooltip_text = tooltip
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 4)
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texture := StatIcons.texture(icon_key)
	if texture != null:
		var icon := TextureRect.new()
		icon.texture = texture
		icon.custom_minimum_size = Vector2(24, 24)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.add_child(icon)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge := _make_label(10, BADGE_UP_COLOR)
	badge.custom_minimum_size = Vector2(0, 13)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var value := _make_label(13, VALUE_COLOR)
	value.name = key.capitalize() + "Value"
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(badge)
	column.add_child(value)
	top.add_child(column)
	cell.add_child(top)
	var caption := _make_label(8, CAPTION_COLOR)
	caption.text = tr(CAPTION_WORDS.get(key, key))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.add_child(caption)
	_row.add_child(cell)
	_cells[key] = {"value": value, "badge": badge}


## Hover/drag preview: "+2 / -1" badges over the stats/resources a card would
## change. `deltas` keys: health, hunger, thirst, warmth, energy, food, water,
## wood, materials. Cleared with clear_effect_preview().
func show_effect_preview(deltas: Dictionary) -> void:
	for key: String in _cells:
		var badge: Label = _cells[key]["badge"]
		var value := int(deltas.get(key, 0))
		if value == 0:
			badge.text = ""
			continue
		badge.text = "%+d" % value
		badge.add_theme_color_override("font_color",
			BADGE_UP_COLOR if value > 0 else BADGE_DOWN_COLOR)


func clear_effect_preview() -> void:
	for key: String in _cells:
		(_cells[key]["badge"] as Label).text = ""


## Bars are gone — maxima now arrive with every set_state. Kept for run.gd.
func setup_max_values() -> void:
	pass


func set_day(day: int, win_day: int, season: int = RunState.Season.SPRING, disaster: DisasterData = null) -> void:
	_day_label.text = tr("Dzień %d/%d") % [day, win_day]
	_season_label.text = RunState.season_name(season)
	_apply_season_style(season, disaster)


func _apply_season_style(season: int, disaster: DisasterData = null) -> void:
	var color := Color(0.98, 0.9, 0.76, 1.0)
	var tooltip := ""
	match season:
		RunState.Season.SPRING:
			color = Color(0.62, 0.94, 0.52, 1.0)
			tooltip = tr("Wiosna\nBuff: akcje zbierające jedzenie dają +1 jedzenia.\nDebuff: brak.")
		RunState.Season.SUMMER:
			color = Color(1.0, 0.76, 0.32, 1.0)
			tooltip = tr("Lato\nBuff: brak.\nDebuff: nocny spadek nawodnienia jest o 1 mocniejszy.")
		RunState.Season.AUTUMN:
			color = Color(0.95, 0.58, 0.24, 1.0)
			tooltip = tr("Jesień\nBuff: akcje z drewnem dają +1 drewna.\nDebuff: brak.")
		RunState.Season.WINTER:
			color = Color(0.62, 0.84, 1.0, 1.0)
			tooltip = tr("Zima\nBuff: brak.\nDebuff: nocny spadek ciepła jest o 1 mocniejszy.")
	if disaster != null and tr(disaster.act2_rule_text) != "":
		tooltip += "\n\nKatastrofa: %s\n%s" % [tr(disaster.display_name), tr(disaster.act2_rule_text)]
	_season_label.add_theme_color_override("font_color", color)
	_season_label.tooltip_text = tooltip
	_season_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_day_label.tooltip_text = tooltip
	_day_label.mouse_filter = Control.MOUSE_FILTER_STOP


func set_state(state: RunState, xp_to_next: int, resource_caps: Dictionary = {}) -> void:
	_level_label.text = tr("Poziom %d") % state.level
	_xp_label.text = "XP %d/%d" % [state.xp, xp_to_next]
	_set_value("health", state.health, state.max_health, true)
	_set_value("hunger", state.hunger, RunState.MAX_HUNGER, true)
	_set_value("thirst", state.thirst, RunState.MAX_THIRST, true)
	_set_value("warmth", state.warmth, RunState.MAX_WARMTH, true)
	_set_value("energy", state.energy, state.max_energy, true)
	_set_value("food", state.food, int(resource_caps.get("food", RunState.MAX_FOOD)))
	_set_value("water", state.water, int(resource_caps.get("water", RunState.MAX_WATER)))
	_set_value("wood", state.wood, int(resource_caps.get("wood", RunState.MAX_WOOD)))
	_set_value("materials", state.materials, int(resource_caps.get("materials", RunState.MAX_MATERIALS)))
	var tools: Label = _cells["tools"]["value"]
	tools.text = "TAK" if state.has_tools else "nie"
	tools.add_theme_color_override("font_color",
		Color(0.95, 0.82, 0.4) if state.has_tools else Color(0.62, 0.6, 0.52))


## Stats color-shift as they drop (the old bars' job); resources stay neutral.
func _set_value(key: String, value: int, max_value: int, ratio_colors: bool = false) -> void:
	var label: Label = _cells[key]["value"]
	label.text = "%d/%d" % [value, max_value]
	var color := VALUE_COLOR if ratio_colors else RESOURCE_COLOR
	if ratio_colors and max_value > 0:
		var ratio := float(value) / float(max_value)
		if ratio <= 0.25:
			color = CRITICAL_COLOR
		elif ratio <= 0.5:
			color = LOW_COLOR
	label.add_theme_color_override("font_color", color)


func set_act2() -> void:
	_apply_panel_style(2)


## Flat translucent panel with a thin gold border (matches ButtonSkin's
## minimal look); a painted slim strip PNG replaces it when the file exists.
func _apply_panel_style(act: int) -> void:
	var art := SLIM_FRAME_ACT2 if act == 2 else SLIM_FRAME_ACT1
	if ResourceLoader.exists(art):
		var tex: Texture2D = load(art)
		_frame.texture = tex
		# 9-slice: the braid border keeps its thickness no matter how wide the
		# bar gets (stretch/aspect="expand" widens it past the art's aspect).
		# Margin derived from the art so a regenerated file needs no code edit.
		var margin := int(round(tex.get_height() * 0.16))
		_frame.patch_margin_left = margin
		_frame.patch_margin_right = margin
		_frame.patch_margin_top = margin
		_frame.patch_margin_bottom = margin
		_frame.visible = true
		_panel.visible = false
		return
	var style := StyleBoxFlat.new()
	if act == 2:
		style.bg_color = Color(0.055, 0.04, 0.05, 0.74)
		style.border_color = Color(0.52, 0.42, 0.3, 0.9)
	else:
		style.bg_color = Color(0.045, 0.07, 0.04, 0.72)
		style.border_color = Color(0.66, 0.52, 0.26, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", style)
	_frame.visible = false
	_panel.visible = true
