class_name TopStatusBarView
extends Control
## Self-contained top HUD. Keeps day, level, stats and resources inside fixed
## text/bar windows over the act-specific wreath frame.

const ACT2_FRAME := "res://assets/art/ui/panels/top_status_bar_panel_act2_withered_candidate.png"

@onready var _frame: TextureRect = $Frame
@onready var _day_label: Label = $Inset/Rows/TopRow/DayLabel
@onready var _level_label: Label = $Inset/Rows/TopRow/LevelLabel
@onready var _xp_bar: TextureProgressBar = $Inset/Rows/TopRow/XPBar
@onready var _health_box: Control = $Inset/Rows/TopRow/HealthBox
@onready var _health_label: Label = $Inset/Rows/TopRow/HealthBox/HealthLabel
@onready var _health_bar: TextureProgressBar = $Inset/Rows/TopRow/HealthBox/HealthBar
@onready var _hunger_box: Control = $Inset/Rows/TopRow/HungerBox
@onready var _hunger_label: Label = $Inset/Rows/TopRow/HungerBox/HungerLabel
@onready var _hunger_bar: TextureProgressBar = $Inset/Rows/TopRow/HungerBox/HungerBar
@onready var _thirst_box: Control = $Inset/Rows/TopRow/ThirstBox
@onready var _thirst_label: Label = $Inset/Rows/TopRow/ThirstBox/ThirstLabel
@onready var _thirst_bar: TextureProgressBar = $Inset/Rows/TopRow/ThirstBox/ThirstBar
@onready var _warmth_box: Control = $Inset/Rows/TopRow/WarmthBox
@onready var _warmth_label: Label = $Inset/Rows/TopRow/WarmthBox/WarmthLabel
@onready var _warmth_bar: TextureProgressBar = $Inset/Rows/TopRow/WarmthBox/WarmthBar
@onready var _energy_box: Control = $Inset/Rows/TopRow/EnergyBox
@onready var _energy_label: Label = $Inset/Rows/TopRow/EnergyBox/EnergyLabel
@onready var _energy_bar: TextureProgressBar = $Inset/Rows/TopRow/EnergyBox/EnergyBar
@onready var _season_label: Label = $Inset/Rows/TopRow/SeasonLabel
@onready var _resource_row: HBoxContainer = $Inset/Rows/ResourceRow
@onready var _food_label: Label = $Inset/Rows/ResourceRow/FoodLabel
@onready var _water_label: Label = $Inset/Rows/ResourceRow/WaterLabel
@onready var _wood_label: Label = $Inset/Rows/ResourceRow/WoodLabel
@onready var _materials_label: Label = $Inset/Rows/ResourceRow/MaterialsLabel
@onready var _tools_label: Label = $Inset/Rows/ResourceRow/ToolsLabel


var _preview_badges := {}


func _ready() -> void:
	_resource_row.visible = true
	_resource_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label in [_food_label, _water_label, _wood_label, _materials_label, _tools_label]:
		label.custom_minimum_size = Vector2(108, 0)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_add_stat_icons()


## Optional icons (assets/art/ui/icons/stats/icon_<key>.png): stat icons sit in
## the gap left of each stat box, resource icons become HBox siblings before
## their labels. No file = no node = current text-only HUD.
func _add_stat_icons() -> void:
	var stat_boxes := {
		"health": _health_box, "hunger": _hunger_box, "thirst": _thirst_box,
		"warmth": _warmth_box, "energy": _energy_box,
	}
	for key: String in stat_boxes:
		var texture := StatIcons.texture(key)
		if texture == null:
			continue
		var box: Control = stat_boxes[key]
		var icon := _make_icon(texture)
		box.get_parent().add_child(icon)
		icon.anchor_left = box.anchor_left
		icon.anchor_right = box.anchor_left
		icon.anchor_top = 0.0
		icon.anchor_bottom = 1.0
		icon.offset_left = box.offset_left - 24.0
		icon.offset_right = box.offset_left - 2.0
		icon.offset_top = 4.0
		icon.offset_bottom = -4.0
	var resource_labels := {
		"food": _food_label, "water": _water_label, "wood": _wood_label,
		"stone": _materials_label, "tools": _tools_label,
	}
	for key: String in resource_labels:
		var texture := StatIcons.texture(key)
		if texture == null:
			continue
		var label: Label = resource_labels[key]
		var icon := _make_icon(texture)
		icon.custom_minimum_size = Vector2(22, 0)
		_resource_row.add_child(icon)
		_resource_row.move_child(icon, label.get_index())


func _make_icon(texture: Texture2D) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## Hover preview: "+2 / -1" badges next to the stats/resources a card would
## change. `deltas` keys: health, hunger, thirst, warmth, energy, food, water,
## wood, materials. Cleared with clear_effect_preview().
func show_effect_preview(deltas: Dictionary) -> void:
	clear_effect_preview()
	var anchors := {
		"health": _health_label, "hunger": _hunger_label, "thirst": _thirst_label,
		"warmth": _warmth_label, "energy": _energy_label,
		"food": _food_label, "water": _water_label, "wood": _wood_label,
		"materials": _materials_label,
	}
	# Stat labels are left-aligned in a full-width box (free space inside on the
	# right); resource labels are centered at min-width (badge goes just outside,
	# into the row separation gap).
	var inside_keys := ["health", "hunger", "thirst", "warmth", "energy"]
	for key: String in deltas:
		var value := int(deltas[key])
		if value == 0 or not anchors.has(key):
			continue
		var parent: Label = anchors[key]
		var badge := Label.new()
		badge.text = "%+d" % value
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.z_index = 5
		badge.add_theme_font_size_override("font_size", 13)
		badge.add_theme_color_override("font_color",
			Color(0.55, 1.0, 0.45) if value > 0 else Color(1.0, 0.4, 0.32))
		badge.add_theme_color_override("font_shadow_color", Color(0.03, 0.04, 0.02))
		badge.add_theme_constant_override("shadow_offset_x", 1)
		badge.add_theme_constant_override("shadow_offset_y", 1)
		parent.add_child(badge)
		badge.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		badge.grow_horizontal = Control.GROW_DIRECTION_END
		badge.offset_top = -9.0
		badge.offset_bottom = 9.0
		if key in inside_keys:
			badge.offset_left = -40.0
			badge.offset_right = -2.0
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			badge.offset_left = 2.0
			badge.offset_right = 40.0
		_preview_badges[key] = badge


func clear_effect_preview() -> void:
	for key: String in _preview_badges:
		var badge: Label = _preview_badges[key]
		if is_instance_valid(badge):
			badge.queue_free()
	_preview_badges.clear()


func setup_max_values() -> void:
	_health_bar.max_value = RunState.MAX_HEALTH
	_hunger_bar.max_value = RunState.MAX_HUNGER
	_thirst_bar.max_value = RunState.MAX_THIRST
	_warmth_bar.max_value = RunState.MAX_WARMTH
	_energy_bar.max_value = RunState.MAX_ENERGY


func set_day(day: int, win_day: int, season: int = RunState.Season.SPRING, disaster: DisasterData = null) -> void:
	_day_label.text = tr("Dzień %d/%d  %s") % [day, win_day, RunState.season_name(season)]


	_season_label.text = RunState.season_name(season)
	_day_label.text = _day_label.text.get_slice("  ", 0)
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
	_level_label.text = "Poziom %d  XP %d/%d" % [state.level, state.xp, xp_to_next]
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = state.xp

	_health_label.text = "Zdrowie %d/%d" % [state.health, state.max_health]
	_health_bar.max_value = state.max_health
	_health_bar.value = state.health
	_set_tooltip_many([_health_box, _health_label, _health_bar],
		tr("Zdrowie\nGdy spadnie do 0, run się kończy.\nTracisz je od ran, potworów i pustych potrzeb."))

	_hunger_label.text = tr("Sytość %d/%d") % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger
	_set_tooltip_many([_hunger_box, _hunger_label, _hunger_bar],
		tr("Sytość\nSpada każdej nocy.\nJeśli jest niska, zapasy jedzenia są automatycznie zjadane."))

	_thirst_label.text = "Nawodnienie %d/%d" % [state.thirst, RunState.MAX_THIRST]
	_thirst_bar.value = state.thirst
	_set_tooltip_many([_thirst_box, _thirst_label, _thirst_bar],
		tr("Nawodnienie\nSpada każdej nocy.\nLatem i na suchych biomach spada szybciej."))

	_warmth_label.text = tr("Ciepło %d/%d") % [state.warmth, RunState.MAX_WARMTH]
	_warmth_bar.value = state.warmth
	_set_tooltip_many([_warmth_box, _warmth_label, _warmth_bar],
		tr("Ciepło\nSpada każdej nocy.\nOgnisko, schronienie i część kart pomagają utrzymać temperaturę."))

	_energy_label.text = "Energia %d/%d" % [state.energy, state.max_energy]
	_energy_bar.max_value = state.max_energy
	_energy_bar.value = state.energy
	_set_tooltip_many([_energy_box, _energy_label, _energy_bar],
		tr("Energia\nOdnawia się o świcie do aktualnego maksimum.\nAwans może zwiększać maksimum bez twardego limitu."))

	var food_cap := int(resource_caps.get("food", RunState.MAX_FOOD))
	var water_cap := int(resource_caps.get("water", RunState.MAX_WATER))
	var wood_cap := int(resource_caps.get("wood", RunState.MAX_WOOD))
	var stone_cap := int(resource_caps.get("materials", RunState.MAX_MATERIALS))
	_food_label.text = "Jedzenie %d/%d" % [state.food, food_cap]
	_water_label.text = "Woda %d/%d" % [state.water, water_cap]
	_wood_label.text = "Drewno %d/%d" % [state.wood, wood_cap]
	_materials_label.text = tr("Kamień %d/%d") % [state.materials, stone_cap]
	_tools_label.text = tr("Narzędzia: %s") % ("TAK" if state.has_tools else "nie")
	_set_tooltip(_food_label, tr("Jedzenie\nZapas automatycznie zjadany nocą, gdy sytość jest niska."))
	_set_tooltip(_water_label, tr("Woda\nZapas automatycznie pity nocą, gdy nawodnienie jest niskie."))
	_set_tooltip(_wood_label, tr("Drewno\nBudowa, naprawy, dokładanie do ogniska i część akcji budynków."))
	_set_tooltip(_materials_label, tr("Kamień\nKoszty budynków, zabezpieczanie rejonów i odbudowa po katastrofie."))
	_set_tooltip(_tools_label, tr("Narzędzia\nGdy są gotowe, karty z jedzeniem i drewnem dają większy zysk."))


func set_act2() -> void:
	if ResourceLoader.exists(ACT2_FRAME):
		_frame.texture = load(ACT2_FRAME)


func _set_tooltip(control: Control, text: String) -> void:
	control.tooltip_text = text
	control.mouse_filter = Control.MOUSE_FILTER_STOP


func _set_tooltip_many(controls: Array, text: String) -> void:
	for control in controls:
		if control is Control:
			_set_tooltip(control, text)
