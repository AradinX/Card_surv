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


func _ready() -> void:
	_resource_row.visible = true
	_resource_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for label in [_food_label, _water_label, _wood_label, _materials_label, _tools_label]:
		label.custom_minimum_size = Vector2(108, 0)
		label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func setup_max_values() -> void:
	_health_bar.max_value = RunState.MAX_HEALTH
	_hunger_bar.max_value = RunState.MAX_HUNGER
	_thirst_bar.max_value = RunState.MAX_THIRST
	_warmth_bar.max_value = RunState.MAX_WARMTH
	_energy_bar.max_value = RunState.MAX_ENERGY


func set_day(day: int, win_day: int, season: int = RunState.Season.SPRING) -> void:
	_day_label.text = "Dzień %d/%d  %s" % [day, win_day, RunState.season_name(season)]


	_season_label.text = RunState.season_name(season)
	_day_label.text = _day_label.text.get_slice("  ", 0)
	_apply_season_style(season)


func _apply_season_style(season: int) -> void:
	var color := Color(0.98, 0.9, 0.76, 1.0)
	var tooltip := ""
	match season:
		RunState.Season.SPRING:
			color = Color(0.62, 0.94, 0.52, 1.0)
			tooltip = "Wiosna\nBuff: akcje zbierające jedzenie dają +1 jedzenia.\nDebuff: brak."
		RunState.Season.SUMMER:
			color = Color(1.0, 0.76, 0.32, 1.0)
			tooltip = "Lato\nBuff: brak.\nDebuff: nocny spadek nawodnienia jest o 1 mocniejszy."
		RunState.Season.AUTUMN:
			color = Color(0.95, 0.58, 0.24, 1.0)
			tooltip = "Jesień\nBuff: akcje z drewnem dają +1 drewna.\nDebuff: brak."
		RunState.Season.WINTER:
			color = Color(0.62, 0.84, 1.0, 1.0)
			tooltip = "Zima\nBuff: brak.\nDebuff: nocny spadek ciepła jest o 1 mocniejszy."
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
		"Zdrowie\nGdy spadnie do 0, run się kończy.\nTracisz je od ran, potworów i pustych potrzeb.")

	_hunger_label.text = "Sytość %d/%d" % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger
	_set_tooltip_many([_hunger_box, _hunger_label, _hunger_bar],
		"Sytość\nSpada każdej nocy.\nJeśli jest niska, zapasy jedzenia są automatycznie zjadane.")

	_thirst_label.text = "Nawodnienie %d/%d" % [state.thirst, RunState.MAX_THIRST]
	_thirst_bar.value = state.thirst
	_set_tooltip_many([_thirst_box, _thirst_label, _thirst_bar],
		"Nawodnienie\nSpada każdej nocy.\nLatem i na suchych biomach spada szybciej.")

	_warmth_label.text = "Ciepło %d/%d" % [state.warmth, RunState.MAX_WARMTH]
	_warmth_bar.value = state.warmth
	_set_tooltip_many([_warmth_box, _warmth_label, _warmth_bar],
		"Ciepło\nSpada każdej nocy.\nOgnisko, schronienie i część kart pomagają utrzymać temperaturę.")

	_energy_label.text = "Energia %d/%d" % [state.energy, state.max_energy]
	_energy_bar.max_value = state.max_energy
	_energy_bar.value = state.energy
	_set_tooltip_many([_energy_box, _energy_label, _energy_bar],
		"Energia\nOdnawia się o świcie do aktualnego maksimum.\nAwans może zwiększać maksimum bez twardego limitu.")

	var food_cap := int(resource_caps.get("food", RunState.MAX_FOOD))
	var water_cap := int(resource_caps.get("water", RunState.MAX_WATER))
	var wood_cap := int(resource_caps.get("wood", RunState.MAX_WOOD))
	var stone_cap := int(resource_caps.get("materials", RunState.MAX_MATERIALS))
	_food_label.text = "Jedzenie %d/%d" % [state.food, food_cap]
	_water_label.text = "Woda %d/%d" % [state.water, water_cap]
	_wood_label.text = "Drewno %d/%d" % [state.wood, wood_cap]
	_materials_label.text = "Kamień %d/%d" % [state.materials, stone_cap]
	_tools_label.text = "Narzędzia: %s" % ("TAK" if state.has_tools else "nie")
	_set_tooltip(_food_label, "Jedzenie\nZapas automatycznie zjadany nocą, gdy sytość jest niska.")
	_set_tooltip(_water_label, "Woda\nZapas automatycznie pity nocą, gdy nawodnienie jest niskie.")
	_set_tooltip(_wood_label, "Drewno\nBudowa, naprawy, dokładanie do ogniska i część akcji budynków.")
	_set_tooltip(_materials_label, "Kamień\nKoszty budynków, zabezpieczanie rejonów i odbudowa po BUM.")
	_set_tooltip(_tools_label, "Narzędzia\nGdy są gotowe, karty z jedzeniem i drewnem dają większy zysk.")


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
