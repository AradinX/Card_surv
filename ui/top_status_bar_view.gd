class_name TopStatusBarView
extends Control
## Self-contained top HUD. Keeps day, level, stats and resources inside fixed
## text/bar windows over the act-specific wreath frame.

const ACT2_FRAME := "res://assets/art/ui/panels/top_status_bar_panel_act2_withered_candidate.png"

@onready var _frame: TextureRect = $Frame
@onready var _day_label: Label = $Inset/Rows/TopRow/DayLabel
@onready var _level_label: Label = $Inset/Rows/TopRow/LevelLabel
@onready var _xp_bar: TextureProgressBar = $Inset/Rows/TopRow/XPBar
@onready var _health_label: Label = $Inset/Rows/TopRow/HealthBox/HealthLabel
@onready var _health_bar: TextureProgressBar = $Inset/Rows/TopRow/HealthBox/HealthBar
@onready var _hunger_label: Label = $Inset/Rows/TopRow/HungerBox/HungerLabel
@onready var _hunger_bar: TextureProgressBar = $Inset/Rows/TopRow/HungerBox/HungerBar
@onready var _thirst_label: Label = $Inset/Rows/TopRow/ThirstBox/ThirstLabel
@onready var _thirst_bar: TextureProgressBar = $Inset/Rows/TopRow/ThirstBox/ThirstBar
@onready var _warmth_label: Label = $Inset/Rows/TopRow/WarmthBox/WarmthLabel
@onready var _warmth_bar: TextureProgressBar = $Inset/Rows/TopRow/WarmthBox/WarmthBar
@onready var _energy_label: Label = $Inset/Rows/TopRow/EnergyBox/EnergyLabel
@onready var _energy_bar: TextureProgressBar = $Inset/Rows/TopRow/EnergyBox/EnergyBar
@onready var _season_label: Label = $Inset/Rows/TopRow/SeasonLabel
@onready var _resources_label: Label = $Inset/Rows/ResourcesLabel


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
			tooltip = "Wiosna\nBuff: akcje zbierajace jedzenie daja +1 jedzenia.\nDebuff: brak."
		RunState.Season.SUMMER:
			color = Color(1.0, 0.76, 0.32, 1.0)
			tooltip = "Lato\nBuff: brak.\nDebuff: nocny spadek nawodnienia jest o 1 mocniejszy."
		RunState.Season.AUTUMN:
			color = Color(0.95, 0.58, 0.24, 1.0)
			tooltip = "Jesien\nBuff: akcje z drewnem daja +1 drewna.\nDebuff: brak."
		RunState.Season.WINTER:
			color = Color(0.62, 0.84, 1.0, 1.0)
			tooltip = "Zima\nBuff: brak.\nDebuff: nocny spadek ciepla jest o 1 mocniejszy."
	_season_label.add_theme_color_override("font_color", color)
	_season_label.tooltip_text = tooltip
	_season_label.mouse_filter = Control.MOUSE_FILTER_STOP


func set_state(state: RunState, xp_to_next: int) -> void:
	_level_label.text = "Poziom %d  XP %d/%d" % [state.level, state.xp, xp_to_next]
	_xp_bar.max_value = xp_to_next
	_xp_bar.value = state.xp

	_health_label.text = "Zdrowie %d/%d" % [state.health, state.max_health]
	_health_bar.max_value = state.max_health
	_health_bar.value = state.health

	_hunger_label.text = "Sytość %d/%d" % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger

	_thirst_label.text = "Woda %d/%d" % [state.thirst, RunState.MAX_THIRST]
	_thirst_bar.value = state.thirst

	_warmth_label.text = "Ciepło %d/%d" % [state.warmth, RunState.MAX_WARMTH]
	_warmth_bar.value = state.warmth

	_energy_label.text = "Energia %d/%d" % [state.energy, state.max_energy]
	_energy_bar.max_value = state.max_energy
	_energy_bar.value = state.energy

	_resources_label.text = "Jedzenie %d   |   Woda %d   |   Drewno %d   |   Materiały %d   |   Narzędzia: %s" % [
		state.food, state.water, state.wood, state.materials,
		"TAK" if state.has_tools else "nie",
	]


func set_act2() -> void:
	if ResourceLoader.exists(ACT2_FRAME):
		_frame.texture = load(ACT2_FRAME)
