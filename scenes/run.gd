extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const NIGHT_CARD_VIEW_SCENE := preload("res://ui/night_card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")
const MAX_GATHER_CARD_VIEWS := 3
const LOG_PANEL_ACT2 := "res://assets/art/ui/panels/log_panel_act2.png"
const LOG_PANEL_ACT1 := "res://assets/art/ui/panels/log_panel_act1.png"
const LOG_TEXT_ACT2 := Color(0.82, 0.78, 0.64, 1.0)
const REPAIR_ICON := "res://assets/art/ui/icons/icon_repair_round.png"
const RUIN_ICON := "res://assets/art/ui/icons/icon_ruin_round.png"
## BUM transition FX (fullscreen overlays). Additive ones sit on black, the
## rest are chroma-keyed to alpha; see tools/chroma_key_blue.gd.
const BUM_FX := {
	"omen": "res://assets/art/fx/bum/fx_omen_glow.png",
	"flash": "res://assets/art/fx/bum/fx_bum_flash.png",
	"shock": "res://assets/art/fx/bum/fx_shockwave_ring.png",
	"petals": "res://assets/art/fx/bum/fx_blast_petals.png",
	"rift1": "res://assets/art/fx/bum/fx_sky_rift_01.png",
	"rift2": "res://assets/art/fx/bum/fx_sky_rift_02.png",
	"crack": "res://assets/art/fx/bum/fx_screen_crack_overlay.png",
	"wilt": "res://assets/art/fx/bum/fx_wilt_overlay.png",
	"rot": "res://assets/art/fx/corruption/fx_rot_wipe.png",
	"cloud1": "res://assets/art/fx/corruption/fx_plague_cloud_01.png",
	"cloud2": "res://assets/art/fx/corruption/fx_plague_cloud_02.png",
	"vignette": "res://assets/art/fx/corruption/fx_corruption_vignette.png",
	"motes": "res://assets/art/fx/corruption/fx_spore_motes_loop.png",
}
const BUM_FX_ADDITIVE := ["omen", "flash", "motes"]
## Corruption FX layers that get recolored per disaster (the blast itself stays
## natural). Plague keeps them green; Eclipse tints them icy blue.
const ACT2_TINT_LAYERS := ["rot", "cloud1", "cloud2", "wilt", "petals", "vignette", "motes"]
## Per-disaster Act II palette. Keyed by DisasterData.id; "" / unknown falls back
## to plague. fx_tint recolors the corruption overlays, scrim is the screen wash,
## board cools the (plague-themed) Act II board art, log_text recolors the log.
const ACT2_LOOK := {
	"plague": {
		"fx_tint": Color(1.0, 1.0, 1.0),
		"scrim": Color(0.04, 0.08, 0.045, 0.58),
		"board": Color(0.4, 0.42, 0.47),
		"log_text": Color(0.82, 0.78, 0.64, 1.0),
	},
	"eclipse": {
		"fx_tint": Color(0.55, 0.7, 1.05),
		"scrim": Color(0.04, 0.05, 0.11, 0.62),
		"board": Color(0.34, 0.4, 0.52),
		"log_text": Color(0.74, 0.82, 0.95, 1.0),
	},
	"rift": {
		"fx_tint": Color(1.05, 0.66, 0.4),
		"scrim": Color(0.10, 0.05, 0.03, 0.58),
		"board": Color(0.5, 0.4, 0.34),
		"log_text": Color(0.95, 0.78, 0.6, 1.0),
	},
	"flood": {
		"fx_tint": Color(0.5, 0.85, 0.85),
		"scrim": Color(0.03, 0.08, 0.09, 0.6),
		"board": Color(0.36, 0.46, 0.48),
		"log_text": Color(0.72, 0.92, 0.92, 1.0),
	},
}
## Night event card reveal: backs to flip from, fullscreen accent FX.
const CARD_BACK := {
	"event": "res://assets/art/cards/backs/card_back_event.png",
	"monster": "res://assets/art/cards/backs/card_back_monster.png",
}
const NIGHT_FX := {
	"spotlight": "res://assets/art/ui/overlay_night_spotlight.png",
	"glow": "res://assets/art/fx/cards/fx_card_reveal_glow.png",
	"burst": "res://assets/art/fx/cards/fx_card_reveal_burst.png",
	"shine": "res://assets/art/fx/cards/fx_card_shine_sweep.png",
	"dust": "res://assets/art/fx/cards/fx_card_dust_puff.png",
}
const NIGHT_CARD_SIZE := Vector2(170, 255)
## Ambient / feedback FX (all optional — guarded by ResourceLoader.exists, so a
## missing or mid-regeneration asset simply skips the effect).
const WEATHER_RAIN := "res://assets/art/fx/weather/fx_rain_overlay.png"
const WEATHER_SNOW := "res://assets/art/fx/weather/fx_snow_overlay.png"
const WEATHER_FROST := "res://assets/art/fx/weather/fx_frost_edges.png"
const CLAW_FX := "res://assets/art/fx/monster_attack/fx_claw_slash.png"
const HEAL_FX := "res://assets/art/fx/cards/fx_heal_spark.png"
const RESOURCE_FX := "res://assets/art/fx/cards/fx_resource_gain.png"
const EAT_DRINK_FX := "res://assets/art/fx/cards/fx_eat_drink_feedback.png"
## Pre-wired (assets not yet generated — guarded by ResourceLoader.exists).
const LOW_HP_FX := "res://assets/art/fx/ui/fx_low_hp_vignette.png"
const BUILD_PLACE_FX := "res://assets/art/fx/buildings/fx_build_place.png"
const REPAIR_FX := "res://assets/art/fx/buildings/fx_repair_sparkle.png"
const COLLAPSE_FX := "res://assets/art/fx/buildings/fx_ruin_collapse.png"
## Low-HP danger vignette shows at or below this fraction of max health.
const LOW_HP_FRACTION := 0.3
const DESIGN_VIEWPORT := Vector2(1280, 720)
const OVERLAY_PADDING := Vector2(32, 32)
const LEVEL_PANEL_BASE := Vector2(900, 470)
const NIGHT_PANEL_BASE := Vector2(460, 560)
const NIGHT_NOTE_BASE := Vector2(340, 300)
const NIGHT_LAYOUT_GAP := 28.0
const PAUSE_PANEL_BASE := Vector2(460, 430)

@onready var _background: ColorRect = $Background
@onready var _background_art: TextureRect = $BackgroundArt
@onready var _main_scroll: ScrollContainer = $Scroll
@onready var _main_margin: MarginContainer = $Scroll/Margin
@onready var _top_status_bar: TopStatusBarView = $Scroll/Margin/Layout/TopStatusBar
@onready var _board_grid: GridContainer = $Scroll/Margin/Layout/MidRow/Board
@onready var _log_panel_art: TextureRect = $Scroll/Margin/Layout/MidRow/LogPanel/LogPanelArt
@onready var _log: RichTextLabel = $Scroll/Margin/Layout/MidRow/LogPanel/Log
@onready var _gather_bar: HBoxContainer = $Scroll/Margin/Layout/CardsRow/GatherBar
@onready var _gather_container: HBoxContainer = $Scroll/Margin/Layout/CardsRow/GatherBar/GatherCards
@onready var _building_bar: PanelContainer = $BuildingActionPopup
@onready var _building_close_button: Button = $BuildingActionPopup/PopupMargin/VBox/Header/CloseButton
@onready var _building_label: Label = $BuildingActionPopup/PopupMargin/VBox/Header/BuildingLabel
@onready var _building_actions: VBoxContainer = $BuildingActionPopup/PopupMargin/VBox/BuildingActions
@onready var _hand_container: HBoxContainer = $Scroll/Margin/Layout/CardsRow/BottomBar/Hand
@onready var _build_scroll: ScrollContainer = $Scroll/Margin/Layout/CardsRow/BottomBar/BuildScroll
@onready var _build_cards: HBoxContainer = $Scroll/Margin/Layout/CardsRow/BottomBar/BuildScroll/BuildCards
@onready var _button_column: VBoxContainer = $Scroll/Margin/Layout/CardsRow/BottomBar/ButtonColumn
@onready var _build_toggle_button: Button = $Scroll/Margin/Layout/CardsRow/BottomBar/ButtonColumn/BuildToggleButton
@onready var _end_day_button: Button = $Scroll/Margin/Layout/CardsRow/BottomBar/ButtonColumn/EndDayButton
@onready var _level_overlay: ColorRect = $LevelUpOverlay
@onready var _level_panel: PanelContainer = $LevelUpOverlay/Panel
@onready var _level_title: Label = $LevelUpOverlay/Panel/PanelMargin/VBox/TitleLabel
@onready var _reward_buttons: HBoxContainer = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons
@onready var _energy_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/EnergyButton
@onready var _health_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/HealthButton
@onready var _card_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/CardButton
@onready var _card_choices: HBoxContainer = $LevelUpOverlay/Panel/PanelMargin/VBox/CardChoices
@onready var _night_overlay: ColorRect = $NightEventOverlay
@onready var _night_panel: PanelContainer = $NightEventOverlay/Panel
@onready var _night_note_panel: Control = $NightEventOverlay/NotePanel
@onready var _night_note_art: TextureRect = $NightEventOverlay/NotePanel/NoteArt
@onready var _night_card_slot: CenterContainer = $NightEventOverlay/Panel/PanelMargin/VBox/CardSlot
@onready var _night_summary: Label = $NightEventOverlay/NotePanel/NoteMargin/SummaryLabel
@onready var _night_continue_button: Button = $NightEventOverlay/Panel/PanelMargin/VBox/ContinueButton
@onready var _night_choices: VBoxContainer = $NightEventOverlay/Panel/PanelMargin/VBox/ChoiceButtons
@onready var _night_result: Label = $NightEventOverlay/Panel/PanelMargin/VBox/ResultLabel
@onready var _forecast_label: Label = $Scroll/Margin/Layout/MidRow/LogPanel/ForecastLabel
@onready var _pause_overlay: ColorRect = $PauseOverlay
@onready var _pause_panel: PanelContainer = $PauseOverlay/Panel
@onready var _pause_resume_button: Button = $PauseOverlay/Panel/PanelMargin/VBox/ResumeButton
@onready var _pause_settings_button: Button = $PauseOverlay/Panel/PanelMargin/VBox/SettingsButton
@onready var _pause_menu_button: Button = $PauseOverlay/Panel/PanelMargin/VBox/MenuButton
@onready var _settings_overlay: SettingsOverlayView = $SettingsOverlay

var _survival: SurvivalSystem
var _tile_buttons: Array[BiomeTileView] = []
var _button_act := 1
var _building_popup_requested := false
var _build_mode := false
var _build_confirm: ConfirmationDialog
var _pending_build: BuildingCardData
var _action_confirm: ConfirmationDialog
var _pending_confirm_action := Callable()
var _deck_button: Button
var _deck_dialog: AcceptDialog
var _night_fx: Array[Node] = []
var _night_tween: Tween
var _weather_overlay: TextureRect
var _frost_overlay: TextureRect
var _low_hp_overlay: TextureRect
var _low_hp_tween: Tween
## Active Act II palette (set when BUM strikes; drives _apply_act2_look and the
## per-disaster tint of the corruption FX layers).
var _act2_look := ACT2_LOOK["plague"]


func _ready() -> void:
	_survival = GameManager.survival
	if _survival == null:
		push_error("Run scene started without a survival system; returning to menu.")
		GameManager.return_to_menu()
		return

	_main_scroll.horizontal_scroll_mode = 0
	_main_scroll.vertical_scroll_mode = 0
	_build_scroll.horizontal_scroll_mode = 2
	_forecast_label.visible = false
	_card_choices.custom_minimum_size = Vector2(0, 232)
	_top_status_bar.setup_max_values()
	_apply_button_skin()
	_create_weather_overlay()
	_create_low_hp_overlay()
	_setup_deck_dialog()

	# Current-tile marker = the played character's medallion (fallback inside).
	if _survival.state != null and _survival.state.character_class != null:
		BiomeTileView.set_marker_for_class(_survival.state.character_class)

	# Background music + nature ambience for the current act (resumed runs may
	# already be post-BUM).
	if _survival.state != null and _survival.state.bum_happened and _survival.state.disaster != null:
		var key := _survival.state.disaster.id
		_act2_look = ACT2_LOOK.get(key, ACT2_LOOK["plague"])
		AudioManager.play_act2_music(_survival.state.disaster.id)
		AudioManager.play_act2_ambience(_survival.state.disaster.id)
		_apply_act2_look()
	else:
		AudioManager.play_music("act1")
		AudioManager.play_ambience("forest")

	_create_tile_buttons()

	_survival.day_started.connect(_on_day_started)
	_survival.stats_changed.connect(_on_stats_changed)
	_survival.hand_changed.connect(_on_hand_changed)
	_survival.board_changed.connect(_on_board_changed)
	_survival.tile_discovered.connect(_on_tile_discovered)
	_survival.gather_actions_changed.connect(_on_gather_actions_changed)
	_survival.leveled_up.connect(_on_leveled_up)
	_survival.bum_struck.connect(_on_bum_struck)
	_survival.night_card_drawn.connect(_on_night_card_drawn)
	_survival.needs_consumed.connect(_on_needs_consumed)
	_survival.log_message.connect(_on_log_message)
	_end_day_button.pressed.connect(_on_end_day_pressed)
	_build_toggle_button.pressed.connect(_on_build_toggle_pressed)
	_setup_build_confirm()
	_setup_action_confirm()
	_building_close_button.pressed.connect(_hide_building_popup)
	_building_label.text = "Naprawa / rozbiórka"
	_energy_button.pressed.connect(_on_reward_energy)
	_health_button.pressed.connect(_on_reward_health)
	_card_button.pressed.connect(_on_reward_card)
	_night_continue_button.pressed.connect(_on_night_continue)
	ButtonSkin.apply_minimal_many([
		_pause_resume_button, _pause_settings_button, _pause_menu_button
	])
	_pause_resume_button.pressed.connect(_hide_pause)
	_pause_settings_button.pressed.connect(_settings_overlay.open)
	_pause_menu_button.pressed.connect(GameManager.return_to_menu)
	_apply_responsive_layout()

	_survival.begin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var main_scale := minf(1.0, minf(
		viewport_size.x / DESIGN_VIEWPORT.x,
		viewport_size.y / DESIGN_VIEWPORT.y
	))
	_main_margin.scale = Vector2(main_scale, main_scale)
	_main_scroll.scroll_horizontal = 0
	_main_scroll.scroll_vertical = 0

	_fit_centered_panel(_level_panel, LEVEL_PANEL_BASE, viewport_size)
	_fit_night_layout(viewport_size)
	_fit_centered_panel(_pause_panel, PAUSE_PANEL_BASE, viewport_size)
	_fit_building_popup(viewport_size)


func _fit_centered_panel(panel: Control, base_size: Vector2, viewport_size: Vector2) -> void:
	var available := Vector2(
		maxf(viewport_size.x - OVERLAY_PADDING.x * 2.0, 1.0),
		maxf(viewport_size.y - OVERLAY_PADDING.y * 2.0, 1.0)
	)
	var panel_scale := minf(1.0, minf(available.x / base_size.x, available.y / base_size.y))
	panel.scale = Vector2(panel_scale, panel_scale)
	panel.pivot_offset = panel.size * 0.5


func _fit_night_layout(viewport_size: Vector2) -> void:
	var available := Vector2(
		maxf(viewport_size.x - OVERLAY_PADDING.x * 2.0, 1.0),
		maxf(viewport_size.y - OVERLAY_PADDING.y * 2.0, 1.0)
	)
	var total_width := NIGHT_NOTE_BASE.x + NIGHT_LAYOUT_GAP + NIGHT_PANEL_BASE.x
	var max_height := maxf(NIGHT_NOTE_BASE.y, NIGHT_PANEL_BASE.y)
	var panel_scale := minf(1.0, minf(available.x / total_width, available.y / max_height))
	var scaled_total := total_width * panel_scale
	var left := (viewport_size.x - scaled_total) * 0.5
	var top := (viewport_size.y - max_height * panel_scale) * 0.5

	_place_overlay_panel(_night_note_panel, NIGHT_NOTE_BASE, panel_scale, Vector2(
		left,
		top + (max_height - NIGHT_NOTE_BASE.y) * panel_scale * 0.5
	))
	_place_overlay_panel(_night_panel, NIGHT_PANEL_BASE, panel_scale, Vector2(
		left + (NIGHT_NOTE_BASE.x + NIGHT_LAYOUT_GAP) * panel_scale,
		top
	))


func _place_overlay_panel(panel: Control, base_size: Vector2, panel_scale: float, pos: Vector2) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.custom_minimum_size = base_size
	panel.size = base_size
	panel.position = pos
	panel.scale = Vector2(panel_scale, panel_scale)
	panel.pivot_offset = Vector2.ZERO


func _fit_building_popup(viewport_size: Vector2) -> void:
	var width := minf(692.0, maxf(viewport_size.x - 32.0, 320.0))
	var height := minf(344.0, maxf(viewport_size.y - 96.0, 220.0))
	_building_bar.anchor_left = 1.0
	_building_bar.anchor_top = 1.0
	_building_bar.anchor_right = 1.0
	_building_bar.anchor_bottom = 1.0
	_building_bar.offset_left = -width - 28.0
	_building_bar.offset_top = -height - 104.0
	_building_bar.offset_right = -28.0
	_building_bar.offset_bottom = -104.0


## Esc toggles the pause menu. If the settings panel is open (from pause), Esc
## drops back to the pause menu first; other modals (night/level-up) keep Esc.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_overlay.visible:
		_settings_overlay.visible = false
	elif _night_overlay.visible or _level_overlay.visible:
		return
	else:
		_pause_overlay.visible = not _pause_overlay.visible
	get_viewport().set_input_as_handled()


func _hide_pause() -> void:
	_pause_overlay.visible = false


func _create_tile_buttons() -> void:
	for i in BoardGenerator.BOARD_SIZE:
		var button := BIOME_TILE_VIEW_SCENE.instantiate() as BiomeTileView
		button.pressed.connect(_on_tile_pressed.bind(i))
		button.buildings_pressed.connect(_on_buildings_pressed.bind(i))
		_board_grid.add_child(button)
		_tile_buttons.append(button)


func _on_tile_pressed(tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_request_move(tile_index)


func _on_buildings_pressed(tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_request_move(tile_index, func() -> void:
			_building_popup_requested = true
			_refresh_building_actions()
		)
		return
	_building_popup_requested = true
	_refresh_building_actions()


func _request_move(tile_index: int, after_move: Callable = Callable()) -> void:
	var block := _survival.can_move(tile_index)
	if block != "":
		_on_log_message(block)
		return
	var tile := _survival.state.board[tile_index]
	var is_discovery := not tile.is_discovered
	var title := "Odkryć kafel?" if is_discovery else "Przejść na kafel?"
	var ok_text := "Odkryj" if is_discovery else "Przejdź"
	var body := "%s\nKoszt: %d energii" % [
		"Nieznany teren. Odkrycie aktywuje jego nocne zagrożenia." if is_discovery
			else tile.biome.display_name,
		SurvivalSystem.MOVE_ENERGY_COST,
	]
	_confirm_action(title, body, ok_text, func() -> void:
		_building_popup_requested = false
		_building_bar.visible = false
		_survival.move_to(tile_index)
		if after_move.is_valid():
			after_move.call()
	)


func _hide_building_popup() -> void:
	_building_popup_requested = false
	_building_bar.visible = false


func _on_end_day_pressed() -> void:
	_hide_building_popup()
	if _build_mode:
		_set_build_mode(false)
	_survival.end_day()


func _on_day_started(day: int) -> void:
	_top_status_bar.set_day(day, SurvivalSystem.WIN_DAY, _survival.state.season)
	_update_weather()
	_update_forecast()


func _on_stats_changed(state: RunState) -> void:
	_top_status_bar.set_day(state.day, SurvivalSystem.WIN_DAY, state.season)
	_top_status_bar.set_state(state, _survival.xp_to_next_level(), _resource_caps())
	_refresh_playability()
	_refresh_tiles(state)
	_update_low_hp_vignette(state)
	_update_forecast()
	if _build_mode:
		_refresh_build_playability()


## End-of-day forecast: tonight's stat drops + supplies, so the player doesn't
## have to do the math (warmth shown as net of building heat vs decay).
func _update_forecast() -> void:
	var f := _survival.end_of_day_forecast()
	var warmth_net: int = f["warmth_net"]
	var warmth_txt := ("%+d" % warmth_net) if warmth_net != 0 else "0"
	_forecast_label.text = ""
	_end_day_button.tooltip_text = "Po nocy:\nSytość -%d\nNawodnienie -%d\nCiepło %s (noc -%d, budynki +%d)\nZapasy: %d jedzenia, %d wody" % [
		f["hunger_decay"],
		f["thirst_decay"],
		warmth_txt,
		f["warmth_decay"],
		f["passive_warmth"],
		f["food"],
		f["water"],
	]


func _on_board_changed(state: RunState) -> void:
	_refresh_tiles(state)
	if _build_mode:
		_refresh_build_cards()


func _on_tile_discovered(tile_index: int) -> void:
	AudioManager.play_sfx("discover")
	if tile_index >= 0 and tile_index < _tile_buttons.size():
		_tile_buttons[tile_index].play_discovery_fx()


func _refresh_tiles(state: RunState) -> void:
	for i in _tile_buttons.size():
		var tile := state.board[i]
		var button := _tile_buttons[i]
		var block_reason := "" if i == state.current_tile else _survival.can_move(i)
		var tooltip := ""
		if not tile.is_discovered:
			tooltip = block_reason if block_reason != "" \
				else "Nieznany teren. Wejście odkryje ten kafel."
		elif i == state.current_tile:
			tooltip = tile.biome.corrupted_description if tile.is_corrupted \
				else tile.biome.description
		else:
			tooltip = block_reason if block_reason != "" \
				else "Przejdź (koszt: %d energii)" % SurvivalSystem.MOVE_ENERGY_COST
		var building_tooltips: Array[String] = []
		for built in tile.buildings:
			building_tooltips.append(_building_tooltip(built))
		button.setup(tile, i == state.current_tile, block_reason, tooltip, building_tooltips)
	_refresh_building_actions()


func _resource_caps() -> Dictionary:
	return {
		"food": _survival.food_cap(),
		"water": _survival.water_cap(),
		"wood": _survival.wood_cap(),
		"materials": _survival.materials_cap(),
	}

## Repair/demolish controls for buildings on the player's current tile.
func _refresh_building_actions() -> void:
	for child in _building_actions.get_children():
		_building_actions.remove_child(child)
		child.queue_free()

	var buildings := _survival.current_tile().buildings
	if buildings.is_empty():
		var empty := Label.new()
		empty.text = "Brak budowli na tym kaflu."
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", Color(0.82, 0.76, 0.58, 1.0))
		_building_actions.add_child(empty)
	for i in buildings.size():
		var built := buildings[i]
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 60)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)
		_building_actions.add_child(row)

		var label := Label.new()
		label.custom_minimum_size = Vector2(260, 60)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.size_flags_vertical = Control.SIZE_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.clip_text = true
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 1.0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		label.tooltip_text = _building_tooltip(built)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_child(label)

		if built.is_ruined:
			label.text = "%s\nRUINA" % built.data.display_name
			var refund := _demolish_refund_summary(built)
			row.add_child(_make_building_cost_label(
				"Rozbiórka: %d energii\nZwrot: %s" % [
					SurvivalSystem.DEMOLISH_ENERGY_COST,
					refund,
				]
			))
			var demolish_block := _survival.can_demolish(i)
			var demolish_tooltip := demolish_block if demolish_block != "" \
				else "Koszt: %d energii\nZwrot: %s" % [
					SurvivalSystem.DEMOLISH_ENERGY_COST,
					refund,
				]
			var demolish_idx := i
			row.add_child(_make_icon_action_button(
				RUIN_ICON,
				demolish_tooltip,
				demolish_block != "",
				func() -> void:
					_confirm_demolish(demolish_idx)
			))
		elif built.hp < _survival.building_max_hp(built.data):
			label.text = "%s\nHP %d/%d" % [
				built.data.display_name,
				built.hp,
				_survival.building_max_hp(built.data),
			]
			row.add_child(_make_building_cost_label(
				"Koszt: %d energii, %d drewna" % [
					SurvivalSystem.REPAIR_ENERGY_COST,
					_survival.repair_wood_cost(built),
				]
			))
			var repair_block := _survival.can_repair(i)
			var repair_tooltip := repair_block if repair_block != "" \
				else "Koszt: %d energii i %d drewna, naprawa do pelna" % [
					SurvivalSystem.REPAIR_ENERGY_COST,
					_survival.repair_wood_cost(built),
				]
			var repair_idx := i
			row.add_child(_make_icon_action_button(
				REPAIR_ICON,
				repair_tooltip,
				repair_block != "",
				func() -> void:
					_survival.repair(repair_idx)
					AudioManager.play_sfx("repair")
					_spawn_tile_fx(REPAIR_FX, true)
			))
		else:
			label.text = "%s\nHP %d/%d" % [
				built.data.display_name,
				built.hp,
				_survival.building_max_hp(built.data),
			]
			var refund := _demolish_refund_summary(built)
			row.add_child(_make_building_cost_label(
				"Rozbiórka: %d energii\nZwrot: %s" % [
					SurvivalSystem.DEMOLISH_ENERGY_COST,
					refund,
				]
			))
			var demolish_block := _survival.can_demolish(i)
			var demolish_tooltip := demolish_block if demolish_block != "" \
				else "Koszt: %d energii\nZwrot: %s\nMniejszy zwrot niż z ruin" % [
					SurvivalSystem.DEMOLISH_ENERGY_COST,
					refund,
				]
			var demolish_idx := i
			row.add_child(_make_icon_action_button(
				RUIN_ICON,
				demolish_tooltip,
				demolish_block != "",
				func() -> void:
					_confirm_demolish(demolish_idx)
			))

	_building_bar.visible = _building_popup_requested


func _confirm_demolish(building_index: int) -> void:
	var buildings := _survival.current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return
	var built = buildings[building_index]
	var title := "Rozebrać ruinę?" if built.is_ruined else "Rozebrać budynek?"
	var text := "%s\nKoszt: %d energii\nZwrot: %s" % [
		built.data.display_name,
		SurvivalSystem.DEMOLISH_ENERGY_COST,
		_demolish_refund_summary(built),
	]
	_confirm_action(title, text, "Rozbierz", func() -> void:
		_survival.demolish(building_index)
		_spawn_tile_fx(COLLAPSE_FX, false)
	)


func _demolish_refund_summary(built) -> String:
	var divisor := SurvivalSystem.DEMOLISH_REFUND_DIVISOR if built.is_ruined \
		else SurvivalSystem.DEMOLISH_STANDING_REFUND_DIVISOR
	var wood_refund := floori(built.data.wood_cost / float(divisor))
	var stone_refund := floori(built.data.materials_cost / float(divisor))
	return "+%d drewna, +%d kamienia" % [wood_refund, stone_refund]


func _building_tooltip(built) -> String:
	var data: BuildingCardData = built.data
	var parts: PackedStringArray = [
		data.display_name,
		"HP %d/%d" % [built.hp, _survival.building_max_hp(data)],
	]
	var production := _building_effect_parts(data)
	if not production.is_empty():
		parts.append("Efekty: %s" % ", ".join(production))
	if data.special != "":
		parts.append("Specjalne: %s" % _building_special_description(data.special))
	return "\n".join(parts)


func _building_effect_parts(data: BuildingCardData) -> PackedStringArray:
	var parts: PackedStringArray = []
	if data.food_gain != 0: parts.append("%+d jedzenia nocą" % data.food_gain)
	if data.water_gain != 0: parts.append("%+d wody nocą" % data.water_gain)
	if data.wood_gain != 0: parts.append("%+d drewna nocą" % data.wood_gain)
	if data.materials_gain != 0: parts.append("%+d kamienia nocą" % data.materials_gain)
	if data.health_delta != 0: parts.append("%+d zdrowia nocą" % data.health_delta)
	if data.warmth_delta != 0: parts.append("%+d ciepła nocą" % data.warmth_delta)
	if data.defense > 0: parts.append("obrona %d" % data.defense)
	if data.food_cap_bonus > 0: parts.append("+%d limitu jedzenia" % data.food_cap_bonus)
	if data.water_cap_bonus > 0: parts.append("+%d limitu wody" % data.water_cap_bonus)
	if data.wood_cap_bonus > 0: parts.append("+%d limitu drewna" % data.wood_cap_bonus)
	if data.materials_cap_bonus > 0: parts.append("+%d limitu kamienia" % data.materials_cap_bonus)
	return parts


func _building_special_description(special: String) -> String:
	match special:
		"night_protection":
			return "chroni przed częścią nocnych strat zdrowia/ciepła"
		"slow_spoilage":
			return "spowalnia psucie jedzenia"
		"unlock_crafting":
			return "przerabia drewno na kamień nocą"
		_:
			return special


## --- Build mode ---
## The "Budowanie" button swaps the gather/hand card rows for a scrollable
## catalog of buildings; clicking a card asks for confirmation before placing it
## on the current tile.


func _setup_build_confirm() -> void:
	_build_confirm = ConfirmationDialog.new()
	_build_confirm.title = "Postawić budowlę?"
	_build_confirm.ok_button_text = "Buduj"
	_build_confirm.cancel_button_text = "Anuluj"
	_build_confirm.confirmed.connect(_on_build_confirmed)
	add_child(_build_confirm)


func _setup_action_confirm() -> void:
	_action_confirm = ConfirmationDialog.new()
	_action_confirm.cancel_button_text = "Anuluj"
	_action_confirm.confirmed.connect(_on_action_confirmed)
	add_child(_action_confirm)


func _setup_deck_dialog() -> void:
	_deck_button = Button.new()
	_deck_button.custom_minimum_size = Vector2(220, 44)
	_deck_button.text = "Talia"
	_deck_button.clip_text = true
	_button_column.add_child(_deck_button)
	_button_column.move_child(_deck_button, 0)
	ButtonSkin.apply_primary(_deck_button, _button_act)
	_deck_button.pressed.connect(_show_deck_dialog)

	_deck_dialog = AcceptDialog.new()
	_deck_dialog.title = "Talia"
	_deck_dialog.ok_button_text = "OK"
	add_child(_deck_dialog)


func _confirm_action(title: String, text: String, ok_text: String, action: Callable) -> void:
	_pending_confirm_action = action
	_action_confirm.title = title
	_action_confirm.dialog_text = text
	_action_confirm.ok_button_text = ok_text
	_action_confirm.popup_centered(Vector2i(420, 220))


func _on_action_confirmed() -> void:
	var action := _pending_confirm_action
	_pending_confirm_action = Callable()
	if action.is_valid():
		action.call()


func _show_deck_dialog() -> void:
	_deck_dialog.dialog_text = _deck_summary()
	_deck_dialog.popup_centered(Vector2i(560, 520))


func _deck_summary() -> String:
	var counts := _deck_counts()
	if counts.is_empty():
		return "Talia jest pusta."
	var lines: PackedStringArray = ["Karty w talii: %d" % _survival.state.deck.size(), ""]
	var names: Array[String] = []
	for id in counts.keys():
		names.append(str(id))
	names.sort()
	for id in names:
		var item: Dictionary = counts[id]
		var card: CardData = item["card"]
		lines.append("%s x%d" % [card.display_name, int(item["count"])])
	return "\n".join(lines)


func _deck_counts() -> Dictionary:
	var counts := {}
	for card in _survival.state.deck:
		if card == null:
			continue
		var key := card.id
		if not counts.has(key):
			counts[key] = {"card": card, "count": 0}
		counts[key]["count"] = int(counts[key]["count"]) + 1
	return counts


func _deck_count_for(card: CardData) -> int:
	if card == null:
		return 0
	var counts := _deck_counts()
	return int(counts.get(card.id, {"count": 0})["count"])


func _on_build_toggle_pressed() -> void:
	_set_build_mode(not _build_mode)


func _set_build_mode(enabled: bool) -> void:
	_build_mode = enabled
	_gather_bar.visible = not enabled
	_hand_container.visible = not enabled
	_build_scroll.visible = enabled
	_build_toggle_button.text = "Akcje" if enabled else "Budowanie"
	if enabled:
		_hide_building_popup()
		_refresh_build_cards()


## Catalog of buildings as cards, greyed out when they can't be placed on the
## current tile (no slot / can't afford). Costs reflect class + post-BUM surcharge.
func _refresh_build_cards() -> void:
	for child in _build_cards.get_children():
		_build_cards.remove_child(child)
		child.queue_free()
	for building in _survival.available_buildings():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		_build_cards.add_child(view)
		view.setup(building, _survival.can_build(building), _build_cost_summary(building))
		view.pressed.connect(_on_build_card_pressed.bind(building))


## Update greying of existing build cards without rebuilding the row (cheaper on
## frequent stats changes, avoids flicker).
func _refresh_build_playability() -> void:
	var catalog := _survival.available_buildings()
	var views := _build_cards.get_children()
	for i in mini(views.size(), catalog.size()):
		(views[i] as CardView).setup(
			catalog[i], _survival.can_build(catalog[i]), _build_cost_summary(catalog[i])
		)


func _on_build_card_pressed(building: BuildingCardData) -> void:
	var block: String = _survival.can_build(building)
	if block != "":
		_on_log_message(block)
		return
	_pending_build = building
	_build_confirm.dialog_text = "%s\nKoszt: %s\n\nPostawić na tym kaflu?" % [
		building.display_name,
		_build_cost_summary(building),
	]
	_build_confirm.popup_centered()


func _on_build_confirmed() -> void:
	if _pending_build == null:
		return
	_survival.build(_pending_build)
	AudioManager.play_sfx("build")
	_spawn_tile_fx(BUILD_PLACE_FX, false)
	_pending_build = null
	if _build_mode:
		_refresh_build_cards()


## Effective build cost (class discount + post-BUM surcharge) as a player string.
func _build_cost_summary(b: BuildingCardData) -> String:
	var cost: Dictionary = _survival.effective_build_cost(b)
	var parts: Array[String] = ["%d energii" % int(cost["energy"])]
	if int(cost["wood"]) > 0:
		parts.append("%d drewna" % int(cost["wood"]))
	if int(cost["materials"]) > 0:
		parts.append("%d kamienia" % int(cost["materials"]))
	if int(cost["food"]) > 0:
		parts.append("%d jedz." % int(cost["food"]))
	return ", ".join(parts)


func _make_building_cost_label(text: String) -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(210, 60)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_FILL
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.clip_text = true
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.88, 0.78, 0.55, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _make_icon_action_button(
	icon_path: String,
	button_tooltip: String,
	is_disabled: bool,
	on_pressed: Callable
) -> Button:
	var button := Button.new()
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty_style)
	button.custom_minimum_size = Vector2(60, 60)
	button.icon = load(icon_path)
	button.expand_icon = true
	button.disabled = is_disabled
	button.tooltip_text = button_tooltip
	button.pressed.connect(on_pressed)
	return button

## BUM: the board background flips to its corrupted Act II face and the
## whole screen darkens for the rest of the run.
const BOARD_BG_ACT2 := "res://assets/art/board/backgrounds/bg_biome_board_act2.png"


func _on_bum_struck(disaster: DisasterData) -> void:
	var key := disaster.id if disaster != null else ""
	_act2_look = ACT2_LOOK.get(key, ACT2_LOOK["plague"])
	AudioManager.play_sfx("bum")
	AudioManager.play_act2_music(key)
	AudioManager.play_act2_ambience(key)
	_play_bum_fx()


## Swap the whole screen to its Act II look. Triggered at the flash peak of the
## BUM animation so the player never sees the UI flip "raw".
func _apply_act2_look() -> void:
	if ResourceLoader.exists(BOARD_BG_ACT2):
		_background_art.texture = load(BOARD_BG_ACT2)
	_background_art.self_modulate = _act2_look["board"]
	_button_act = 2
	_apply_button_skin()
	_top_status_bar.set_act2()
	if ResourceLoader.exists(LOG_PANEL_ACT2):
		_log_panel_art.texture = load(LOG_PANEL_ACT2)
		_night_note_art.texture = load(LOG_PANEL_ACT2)
	_log.add_theme_color_override("default_color", _act2_look["log_text"])
	_background.color = _act2_look["scrim"]


## Cataclysm: a layered fullscreen sequence — dread glow, blast (flash +
## shockwave + torn petals), the sky tearing, then creeping rot/plague that
## wipes the lush board over to its corrupted Act II face. A dark vignette and
## drifting spores stay for the rest of the run.
func _play_bum_fx() -> void:
	for id in BUM_FX:
		if not ResourceLoader.exists(BUM_FX[id]):
			_apply_act2_look()
			return

	var fx := Control.new()
	add_child(fx)
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center := size * 0.5
	var omen := _make_fx_layer("omen", fx)
	var flash := _make_fx_layer("flash", fx)
	var shock := _make_fx_layer("shock", fx)
	shock.pivot_offset = center
	shock.scale = Vector2(0.15, 0.15)
	var petals := _make_fx_layer("petals", fx)
	petals.pivot_offset = center
	petals.scale = Vector2(0.6, 0.6)
	var rift1 := _make_fx_layer("rift1", fx)
	var rift2 := _make_fx_layer("rift2", fx)
	var crack := _make_fx_layer("crack", fx)
	var wilt := _make_fx_layer("wilt", fx)
	var rot := _make_fx_layer("rot", fx)
	var cloud1 := _make_fx_layer("cloud1", fx)
	var cloud2 := _make_fx_layer("cloud2", fx)
	# Persistent Act II atmosphere — parented to the scene, then moved to sit
	# just above the board background and BELOW the gameplay UI, so it blends
	# into the backdrop instead of covering the HUD and cards. The transient fx
	# container stays on top (added later) for the blast.
	var vignette := _make_fx_layer("vignette", self)
	var motes := _make_fx_layer("motes", self)
	var bg_index := _background_art.get_index()
	move_child(vignette, bg_index + 1)
	move_child(motes, bg_index + 2)

	var t := create_tween().set_parallel(true)
	# 1) Dread glow swells and fades.
	t.tween_property(omen, "modulate:a", 0.7, 0.25)
	t.tween_property(omen, "modulate:a", 0.0, 0.6).set_delay(0.55)
	# 2) Blast: flash, expanding shockwave ring and torn petals. The Act II look
	# is swapped in under the flash peak.
	t.tween_property(flash, "modulate:a", 1.0, 0.08).set_delay(0.25)
	t.tween_property(flash, "modulate:a", 0.0, 0.5).set_delay(0.42)
	t.tween_callback(_apply_act2_look).set_delay(0.34)
	t.tween_property(shock, "modulate:a", 0.9, 0.1).set_delay(0.26)
	t.tween_property(shock, "scale", Vector2(1.55, 1.55), 0.6) \
		.set_delay(0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(shock, "modulate:a", 0.0, 0.35).set_delay(0.55)
	t.tween_property(petals, "modulate:a", 1.0, 0.12).set_delay(0.28)
	t.tween_property(petals, "scale", Vector2(1.3, 1.3), 0.75) \
		.set_delay(0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(petals, "modulate:a", 0.0, 0.5).set_delay(0.62)
	# 3) The sky tears (rift_01 -> rift_02) and the screen cracks.
	t.tween_property(rift1, "modulate:a", 0.95, 0.2).set_delay(0.5)
	t.tween_property(rift1, "modulate:a", 0.0, 0.3).set_delay(0.82)
	t.tween_property(rift2, "modulate:a", 0.95, 0.3).set_delay(0.8)
	t.tween_property(crack, "modulate:a", 0.8, 0.25).set_delay(0.6)
	# 4) Rot and plague creep in and wipe the board to Act II; the pretty Act I
	# flowers wilt and brown along the ground.
	t.tween_property(rot, "modulate:a", 1.0, 0.65).set_delay(0.85)
	t.tween_property(wilt, "modulate:a", 1.0, 0.7).set_delay(0.8)
	t.tween_property(cloud1, "modulate:a", 0.9, 0.7).set_delay(0.9)
	t.tween_property(cloud2, "modulate:a", 0.85, 0.7).set_delay(1.05)
	# 5) Persistent atmosphere settles in.
	t.tween_property(vignette, "modulate:a", 1.0, 0.8).set_delay(1.45)
	t.tween_property(motes, "modulate:a", 0.5, 1.0).set_delay(1.6)
	# 6) Transient corruption fades out, revealing the settled Act II board.
	t.tween_property(rift2, "modulate:a", 0.0, 0.6).set_delay(1.7)
	t.tween_property(crack, "modulate:a", 0.0, 0.7).set_delay(1.7)
	t.tween_property(rot, "modulate:a", 0.0, 0.9).set_delay(2.0)
	t.tween_property(wilt, "modulate:a", 0.0, 0.9).set_delay(2.05)
	t.tween_property(cloud1, "modulate:a", 0.0, 0.8).set_delay(2.1)
	t.tween_property(cloud2, "modulate:a", 0.0, 0.8).set_delay(2.2)

	t.finished.connect(func() -> void:
		if is_instance_valid(fx):
			fx.queue_free()
		_loop_spore_motes(motes)
	)


func _make_fx_layer(id: String, parent: Control) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(BUM_FX[id])
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.modulate.a = 0.0
	if id in ACT2_TINT_LAYERS:
		# self_modulate tints RGB while the alpha fade rides on modulate.a.
		layer.self_modulate = _act2_look["fx_tint"]
	parent.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if id in BUM_FX_ADDITIVE:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		layer.material = mat
	return layer


## Gentle breathing loop for the lingering spore haze.
func _loop_spore_motes(motes: TextureRect) -> void:
	if not is_instance_valid(motes):
		return
	var loop := create_tween().set_loops()
	loop.tween_property(motes, "modulate:a", 0.28, 3.5).set_trans(Tween.TRANS_SINE)
	loop.tween_property(motes, "modulate:a", 0.5, 3.5).set_trans(Tween.TRANS_SINE)


# --- Ambient & feedback FX ---


## A subtle weather layer behind the gameplay UI (above the scrim, below the
## board), swapped by season. Never covers popups since it sits under the UI.
func _create_weather_overlay() -> void:
	_weather_overlay = _make_ambient_overlay(0.5)
	_frost_overlay = _make_ambient_overlay(0.45)


## A full-screen ambient layer above the scrim but below the gameplay UI, so it
## never covers popups.
func _make_ambient_overlay(alpha: float) -> TextureRect:
	var overlay := TextureRect.new()
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = alpha
	overlay.visible = false
	add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	move_child(overlay, _background.get_index() + 1)
	return overlay


## Rain in spring/autumn, snow + frost vignette in winter, clear in summer.
func _update_weather() -> void:
	if _weather_overlay == null:
		return
	var path := ""
	match _survival.state.season:
		RunState.Season.WINTER:
			path = WEATHER_SNOW
		RunState.Season.SPRING, RunState.Season.AUTUMN:
			path = WEATHER_RAIN
		_:
			path = ""
	if path != "" and ResourceLoader.exists(path):
		_weather_overlay.texture = load(path)
		_weather_overlay.visible = true
	else:
		_weather_overlay.visible = false

	var is_winter := _survival.state.season == RunState.Season.WINTER
	if is_winter and ResourceLoader.exists(WEATHER_FROST):
		_frost_overlay.texture = load(WEATHER_FROST)
		_frost_overlay.visible = true
	else:
		_frost_overlay.visible = false


## A quick claw-slash flash over the night card when a monster attacks.
func _spawn_claw_flash() -> void:
	if not ResourceLoader.exists(CLAW_FX):
		return
	var sz := Vector2(380, 380)
	var claw := TextureRect.new()
	claw.texture = load(CLAW_FX)
	claw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	claw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	claw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claw.size = sz
	claw.position = get_viewport_rect().size * 0.5 - sz * 0.5
	claw.pivot_offset = sz * 0.5
	claw.modulate = Color(1, 1, 1, 0)
	claw.scale = Vector2(0.7, 0.7)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	claw.material = mat
	_night_overlay.add_child(claw)
	_night_fx.append(claw)
	# Strike just after the card has flipped to its monster face.
	var t := create_tween()
	t.tween_interval(1.25)
	t.tween_property(claw, "modulate:a", 1.0, 0.07)
	t.parallel().tween_property(claw, "scale", Vector2(1.15, 1.15), 0.18)
	t.tween_property(claw, "modulate:a", 0.0, 0.28)


## Pops a heal/resource sparkle over a just-played card.
func _card_feedback_fx(card: CardData, view: Control) -> void:
	if not (card is ActionCardData):
		return
	var action := card as ActionCardData
	var path := ""
	if action.health_delta > 0:
		path = HEAL_FX
	elif action.food_gain > 0 or action.water_gain > 0 \
			or action.wood_gain > 0 or action.materials_gain > 0:
		path = RESOURCE_FX
	if path == "" or not ResourceLoader.exists(path):
		return
	_spawn_world_fx(path, view.global_position + view.size * 0.5, Vector2(150, 150))


## Overnight the survivor auto-ate/drank from stock — a small feedback glow over
## the top stat bars (where hunger/thirst live). Additive (asset sits on black).
func _on_needs_consumed(food_eaten: int, water_drunk: int) -> void:
	if food_eaten > 0:
		AudioManager.play_sfx("eat")
	if water_drunk > 0:
		AudioManager.play_sfx("drink")
	if not ResourceLoader.exists(EAT_DRINK_FX):
		return
	var rect := _top_status_bar.get_global_rect()
	# Left third of the HUD holds the stat bars; nudge the glow over them.
	var center := Vector2(rect.position.x + rect.size.x * 0.28, rect.get_center().y)
	_spawn_world_fx(EAT_DRINK_FX, center, Vector2(220, 120))


## A one-shot FX at a screen point, auto-freed when it finishes. Additive glows
## (sparks) on black; cut-out FX (dust, rubble) keep normal blending.
func _spawn_world_fx(path: String, center: Vector2, fx_size: Vector2, additive := true) -> void:
	var fx := TextureRect.new()
	fx.texture = load(path)
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.size = fx_size
	fx.position = center - fx_size * 0.5
	fx.pivot_offset = fx_size * 0.5
	fx.modulate.a = 0.0
	fx.scale = Vector2(0.7, 0.7)
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = mat
	add_child(fx)
	var t := create_tween()
	t.tween_property(fx, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(fx, "scale", Vector2(1.2, 1.2), 0.32)
	t.tween_property(fx, "modulate:a", 0.0, 0.3)
	t.tween_callback(fx.queue_free)


## A one-shot FX centered on the player's current tile (build/repair/collapse).
func _spawn_tile_fx(path: String, additive: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var idx: int = _survival.state.current_tile
	if idx < 0 or idx >= _tile_buttons.size():
		return
	var rect := _tile_buttons[idx].get_global_rect()
	_spawn_world_fx(path, rect.get_center(), rect.size * 1.05, additive)


# --- Critical-HP danger vignette ---


func _create_low_hp_overlay() -> void:
	_low_hp_overlay = TextureRect.new()
	_low_hp_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_low_hp_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_low_hp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_hp_overlay.modulate.a = 0.0
	_low_hp_overlay.visible = false
	if ResourceLoader.exists(LOW_HP_FX):
		_low_hp_overlay.texture = load(LOW_HP_FX)
	add_child(_low_hp_overlay)
	_low_hp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Pulsing red vignette when health is critically low (skipped if asset absent).
func _update_low_hp_vignette(state: RunState) -> void:
	if _low_hp_overlay == null or _low_hp_overlay.texture == null:
		return
	var critical := state.health > 0 \
		and state.health <= int(ceil(state.max_health * LOW_HP_FRACTION))
	if critical and not _low_hp_overlay.visible:
		_low_hp_overlay.visible = true
		_low_hp_tween = create_tween().set_loops()
		_low_hp_tween.tween_property(_low_hp_overlay, "modulate:a", 0.7, 0.6) \
			.set_trans(Tween.TRANS_SINE)
		_low_hp_tween.tween_property(_low_hp_overlay, "modulate:a", 0.28, 0.6) \
			.set_trans(Tween.TRANS_SINE)
	elif not critical and _low_hp_overlay.visible:
		if _low_hp_tween != null:
			_low_hp_tween.kill()
			_low_hp_tween = null
		_low_hp_overlay.visible = false
		_low_hp_overlay.modulate.a = 0.0


func _apply_button_skin() -> void:
	var buttons := [
		_energy_button,
		_health_button,
		_card_button,
		_end_day_button,
		_night_continue_button,
	]
	if _deck_button != null:
		buttons.append(_deck_button)
	ButtonSkin.apply_many(buttons, _button_act)
	_apply_close_button_skin()


func _apply_close_button_skin() -> void:
	var empty_style := StyleBoxEmpty.new()
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		_building_close_button.add_theme_stylebox_override(state, empty_style)
	_building_close_button.add_theme_color_override("font_color", Color(1.0, 0.28, 0.22, 1.0))
	_building_close_button.add_theme_color_override("font_hover_color", Color(1.0, 0.42, 0.34, 1.0))
	_building_close_button.add_theme_color_override("font_pressed_color", Color(0.78, 0.08, 0.07, 1.0))
	_building_close_button.add_theme_color_override("font_shadow_color", Color(0.08, 0.01, 0.01, 1.0))
	_building_close_button.add_theme_constant_override("shadow_offset_x", 1)
	_building_close_button.add_theme_constant_override("shadow_offset_y", 1)


func _on_night_card_drawn(card: CardData) -> void:
	_clear_night_card()
	_night_overlay.visible = true
	# Locked until the reveal animation finishes, so the card is always read
	# before its effects resolve (re-enabled on the reveal tween's `finished`).
	_night_continue_button.disabled = true

	# Front and back are both direct children of the slot's CenterContainer, so
	# they land on the exact same centred rect. The card flips from back to front.
	var view: NightCardView = NIGHT_CARD_VIEW_SCENE.instantiate()
	_night_card_slot.add_child(view)
	view.custom_minimum_size = NIGHT_CARD_SIZE
	view.setup(card, "")
	view.focus_mode = Control.FOCUS_NONE
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.pivot_offset = NIGHT_CARD_SIZE * 0.5
	view.scale = Vector2(0.0, 1.0)
	view.visible = false

	var is_monster := card is MonsterCardData
	var back := TextureRect.new()
	back.texture = load(CARD_BACK["monster" if is_monster else "event"])
	back.custom_minimum_size = NIGHT_CARD_SIZE
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.pivot_offset = NIGHT_CARD_SIZE * 0.5
	_night_card_slot.add_child(back)

	_night_summary.text = _night_summary_text(card)
	_night_summary.visible = true
	_night_note_panel.visible = true
	_build_night_choices(card)
	_play_night_reveal(view, back, _night_tint(card))
	if is_monster:
		AudioManager.play_sfx("monster")
		_spawn_claw_flash()


## Decision events show one button per choice (with its effect summary) instead
## of a single "Dalej". Buttons start disabled and unlock when the reveal ends.
func _build_night_choices(card: CardData) -> void:
	for child in _night_choices.get_children():
		child.queue_free()
	var choices: Array = card.get("choices") if card is EventCardData else []
	if choices == null or choices.is_empty():
		_night_choices.visible = false
		_night_continue_button.visible = true
		return
	_night_choices.visible = true
	_night_result.visible = false
	_night_continue_button.visible = false
	for i in choices.size():
		var choice = choices[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 86)
		button.disabled = true
		button.text = _choice_button_text(choice)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 12)
		ButtonSkin.apply_minimal(button)
		button.pressed.connect(_on_night_choice.bind(i))
		_night_choices.add_child(button)


## Full choice copy: clear risk odds plus explicit success/failure outcomes.
func _choice_button_text(choice) -> String:
	var label := _choice_label_without_risk(choice.label)
	var title := label
	if choice.risk_chance > 0:
		title = "%s (%d%% na sukces)" % [label, 100 - choice.risk_chance]

	var lines: PackedStringArray = [title]
	var success := _choice_success_summary(choice)
	if success != "":
		lines.append("%s: %s" % ["Sukces" if choice.risk_chance > 0 else "Efekt", success])
	if choice.risk_chance > 0:
		lines.append("Porażka: %s" % _choice_failure_summary(choice))
	return "\n".join(lines)


func _choice_label_without_risk(label: String) -> String:
	return label.replace(" (ryzyko)", "").replace("(ryzyko)", "").strip_edges()


func _choice_success_summary(choice) -> String:
	var parts: PackedStringArray = []
	if choice.health_delta != 0: parts.append("%+d zdrowia" % choice.health_delta)
	if choice.hunger_delta != 0: parts.append("%+d sytości" % choice.hunger_delta)
	if choice.thirst_delta != 0: parts.append("%+d nawodnienia" % choice.thirst_delta)
	if choice.warmth_delta != 0: parts.append("%+d ciepła" % choice.warmth_delta)
	if choice.food_gain != 0: parts.append("%+d jedzenia" % choice.food_gain)
	if choice.water_gain != 0: parts.append("%+d wody" % choice.water_gain)
	if choice.wood_gain != 0: parts.append("%+d drewna" % choice.wood_gain)
	if choice.materials_gain != 0: parts.append("%+d kamienia" % choice.materials_gain)
	if choice.next_day_energy_delta != 0: parts.append("%+d energii jutro" % choice.next_day_energy_delta)
	if choice.grant_random_card: parts.append("+1 karta do talii")
	return ", ".join(parts)


func _choice_failure_summary(choice) -> String:
	if choice.risk_health > 0:
		return "-%d zdrowia" % choice.risk_health
	return "brak efektu"


func _night_summary_text(card: CardData) -> String:
	var lines: PackedStringArray = []
	var card_effect := _night_card_effect_summary(card)
	if card_effect != "":
		lines.append("Karta: %s" % card_effect)
	var passives := _night_building_passive_summary()
	if passives != "":
		lines.append("Budynki: %s" % passives)
	lines.append("Noc: %s" % _night_needs_summary())
	return "\n".join(lines)


func _night_card_effect_summary(card: CardData) -> String:
	if card is MonsterCardData:
		var monster := card as MonsterCardData
		var parts: PackedStringArray = []
		if monster.damage_to_player > 0:
			parts.append("-%d zdrowia" % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			parts.append("-%d HP budynku" % monster.damage_to_buildings)
		return ", ".join(parts) if not parts.is_empty() else "atak bez obrażeń"
	if not (card is EventCardData):
		return ""
	var event := card as EventCardData
	if not event.choices.is_empty():
		return "wybierz opcję poniżej"
	var health_delta := event.health_delta
	var warmth_delta := event.warmth_delta
	if event.shelter_protects and _has_standing_special("night_protection"):
		health_delta = maxi(health_delta, mini(health_delta + SurvivalSystem.NIGHT_PROTECTION_VALUE, 0))
		warmth_delta = maxi(warmth_delta, mini(warmth_delta + SurvivalSystem.NIGHT_PROTECTION_VALUE, 0))
	var parts := _stat_delta_parts(
		health_delta, event.hunger_delta, event.thirst_delta, warmth_delta,
		event.food_delta, event.water_delta, event.wood_delta, event.materials_delta,
		event.next_day_energy_delta
	)
	return ", ".join(parts) if not parts.is_empty() else "brak zmian"


func _night_building_passive_summary() -> String:
	if _survival == null or _survival.state == null:
		return ""
	var health := 0
	var hunger := 0
	var thirst := 0
	var warmth := 0
	var food := 0
	var water := 0
	var wood := 0
	var stone := 0
	var workshop_crafts := false
	for tile in _survival.state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var data: BuildingCardData = built.data
			health += data.health_delta
			hunger += data.hunger_delta
			thirst += data.thirst_delta
			warmth += data.warmth_delta
			food += data.food_gain
			water += data.water_gain
			wood += data.wood_gain
			stone += data.materials_gain
			if data.special == "unlock_crafting" and _survival.state.wood > 0:
				workshop_crafts = true
	var parts := _stat_delta_parts(health, hunger, thirst, warmth, food, water, wood, stone, 0)
	if workshop_crafts:
		parts.append("-1 drewna, +1 kamienia")
	return ", ".join(parts)


func _night_needs_summary() -> String:
	if _survival == null or _survival.state == null:
		return "-3 sytości, -3 nawodnienia, -3 ciepła"
	var state := _survival.state
	var hunger_decay := SurvivalSystem.DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta
	var thirst_decay := SurvivalSystem.DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta
	var warmth_decay := SurvivalSystem.DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta
	if state.season == RunState.Season.SUMMER:
		thirst_decay += SurvivalSystem.SUMMER_EXTRA_THIRST_DECAY
	if state.season == RunState.Season.WINTER:
		warmth_decay += SurvivalSystem.WINTER_EXTRA_WARMTH_DECAY
	return "-%d sytości, -%d nawodnienia, -%d ciepła" % [
		hunger_decay, thirst_decay, warmth_decay
	]


func _stat_delta_parts(
	health: int, hunger: int, thirst: int, warmth: int,
	food: int, water: int, wood: int, stone: int, next_energy: int
) -> PackedStringArray:
	var parts: PackedStringArray = []
	if health != 0: parts.append("%+d zdrowia" % health)
	if hunger != 0: parts.append("%+d sytości" % hunger)
	if thirst != 0: parts.append("%+d nawodnienia" % thirst)
	if warmth != 0: parts.append("%+d ciepła" % warmth)
	if food != 0: parts.append("%+d jedzenia" % food)
	if water != 0: parts.append("%+d wody" % water)
	if wood != 0: parts.append("%+d drewna" % wood)
	if stone != 0: parts.append("%+d kamienia" % stone)
	if next_energy != 0: parts.append("%+d energii jutro" % next_energy)
	return parts


func _has_standing_special(special: String) -> bool:
	if _survival == null or _survival.state == null:
		return false
	for tile in _survival.state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.data.special == special:
				return true
	return false


## Picking a choice applies it immediately but PAUSES on a result summary — the
## player reads what happened and clicks „Dalej" to settle the night.
func _on_night_choice(index: int) -> void:
	var summary := _survival.apply_night_choice(index)
	for button in _night_choices.get_children():
		(button as Button).queue_free()
	_night_choices.visible = false
	_night_result.text = summary
	_night_result.visible = true
	_night_summary.text = "Wybór: %s\nNoc: %s" % [
		summary.replace("\n", " "),
		_night_needs_summary()
	]
	_night_note_panel.visible = true
	_night_continue_button.visible = true
	_night_continue_button.disabled = false


## Reveal FX tint by event category (monsters red, weather blue, biome green,
## disaster sickly purple, omen amber, neutral warm gold).
func _night_tint(card: CardData) -> Color:
	if card is MonsterCardData:
		return Color(1.0, 0.46, 0.4)
	var category := str(card.get("category")) if card is EventCardData else ""
	match category:
		"weather":
			return Color(0.62, 0.82, 1.0)
		"biome":
			return Color(0.72, 1.0, 0.62)
		"disaster":
			return Color(0.82, 0.52, 1.0)
		"omen":
			return Color(1.0, 0.72, 0.32)
		"monster":
			return Color(1.0, 0.46, 0.4)
		_:
			return Color(1.0, 0.92, 0.72)


## The card flips from its back to its front while a spotlight, glow, sparks,
## a shine sweep and a dust puff sell the reveal. Spotlight + glow linger behind
## the panel; the rest are one-shot. `tint` colours the glow/burst per category.
func _play_night_reveal(view: Control, back: Control, tint: Color) -> void:

	# Backdrop glow behind the panel (does not wash the card face).
	var spotlight := _spawn_night_fx("spotlight", get_viewport_rect().size, true, Color.WHITE, 0)
	var glow := _spawn_night_fx("glow", Vector2(560, 560), true, tint, 1)
	# One-shot accents on top.
	var burst := _spawn_night_fx("burst", Vector2(620, 620), true, tint, -1)
	burst.scale = Vector2(0.6, 0.6)
	var shine := _spawn_night_fx("shine", Vector2(220, 320), true, Color.WHITE, -1)
	var dust := _spawn_night_fx("dust", Vector2(360, 180), true, tint, -1)
	dust.position.y += 120.0

	# Hold on the card back so the player reads it before it flips.
	const HOLD := 0.95

	if _night_tween != null:
		_night_tween.kill()
	_night_tween = create_tween().set_parallel(true)
	# Dust puff as the card lands (at the very start).
	_night_tween.tween_property(dust, "modulate:a", 0.7, 0.15)
	_night_tween.tween_property(dust, "modulate:a", 0.0, 0.4).set_delay(0.2)
	# Spotlight settles in immediately and frames the held back.
	_night_tween.tween_property(spotlight, "modulate:a", 0.55, 0.45)
	# Glow blooms as the flip begins.
	_night_tween.tween_property(glow, "modulate:a", 0.7, 0.45).set_delay(HOLD)
	# The flip: back turns to edge, swap back->front, front turns out. Both are
	# pivoted at their centre, so the card stays centred throughout.
	_night_tween.tween_property(back, "scale", Vector2(0.0, 1.0), 0.22) \
		.set_delay(HOLD).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_night_tween.tween_callback(func() -> void:
		back.visible = false
		view.visible = true
	).set_delay(HOLD + 0.22)
	_night_tween.tween_property(view, "scale", Vector2(1.0, 1.0), 0.24) \
		.set_delay(HOLD + 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	# Shine sweeps across during the flip.
	var sx := shine.position.x
	_night_tween.tween_property(shine, "modulate:a", 0.85, 0.15).set_delay(HOLD + 0.15)
	_night_tween.tween_property(shine, "position:x", sx + 90.0, 0.4) \
		.set_delay(HOLD + 0.15).set_trans(Tween.TRANS_SINE)
	_night_tween.tween_property(shine, "modulate:a", 0.0, 0.2).set_delay(HOLD + 0.45)
	# Burst pops at the reveal moment.
	_night_tween.tween_property(burst, "modulate:a", 0.9, 0.1).set_delay(HOLD + 0.3)
	_night_tween.tween_property(burst, "scale", Vector2(1.35, 1.35), 0.55) \
		.set_delay(HOLD + 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_night_tween.tween_property(burst, "modulate:a", 0.0, 0.4).set_delay(HOLD + 0.55)
	# Card has been revealed and read — let the player acknowledge / choose.
	_night_tween.finished.connect(func() -> void:
		if is_instance_valid(_night_continue_button):
			_night_continue_button.disabled = false
		for button in _night_choices.get_children():
			(button as Button).disabled = false
	)


func _spawn_night_fx(id: String, fx_size: Vector2, additive: bool, tint: Color, behind: int) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(NIGHT_FX[id])
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.size = fx_size
	layer.position = get_viewport_rect().size * 0.5 - fx_size * 0.5
	layer.pivot_offset = fx_size * 0.5
	layer.modulate = Color(tint.r, tint.g, tint.b, 0.0)
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		layer.material = mat
	_night_overlay.add_child(layer)
	# behind >= 0: move under the panel (backdrop); -1: stay on top (accent).
	if behind >= 0:
		_night_overlay.move_child(layer, behind)
	_night_fx.append(layer)
	return layer


## OK pressed: hide the popup, THEN resolve the night so the player sees the
## card before the stats move. The button is disabled until the reveal finishes
## (see _on_night_card_drawn / _play_night_reveal), so the card is always read.
func _on_night_continue() -> void:
	_hide_night_event()
	_survival.resolve_night()


func _hide_night_event() -> void:
	_night_overlay.visible = false
	_clear_night_card()


func _clear_night_card() -> void:
	if _night_tween != null:
		_night_tween.kill()
		_night_tween = null
	for node in _night_fx:
		if is_instance_valid(node):
			node.queue_free()
	_night_fx.clear()
	for child in _night_card_slot.get_children():
		_night_card_slot.remove_child(child)
		child.queue_free()
	for child in _night_choices.get_children():
		child.queue_free()
	_night_result.visible = false
	_night_result.text = ""
	_night_note_panel.visible = false
	_night_summary.visible = false
	_night_summary.text = ""


func _on_hand_changed(hand: Array[CardData]) -> void:
	_rebuild_cards(_hand_container, hand, func(i: int, _card: CardData) -> void:
		_survival.play_card(i)
	, true)
	_refresh_playability()


## Used-up gather actions drop out of the list (see available_gather_actions),
## so playing one removes its card rather than just disabling it.
func _on_gather_actions_changed(_actions: Array[ActionCardData]) -> void:
	var cards: Array[CardData] = []
	for action in _survival.available_gather_actions().slice(0, MAX_GATHER_CARD_VIEWS):
		cards.append(action)
	_rebuild_cards(_gather_container, cards, func(_i: int, card: CardData) -> void:
		_survival.play_gather(card as ActionCardData)
	, true)
	_refresh_playability()


func _rebuild_cards(
	container: HBoxContainer, cards: Array[CardData], on_pressed: Callable, confirm_cards := false
) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for i in cards.size():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		container.add_child(view)
		view.setup(cards[i], "")
		var card := cards[i]
		var index := i
		view.pressed.connect(func() -> void:
			if confirm_cards:
				_confirm_action(
					"Zagrać kartę?",
					"%s\n%s\nKoszt: %s" % [
						card.display_name,
						card.description,
						_card_cost_summary(card),
					],
					"Zagraj",
					func() -> void:
						if is_instance_valid(view):
							_card_feedback_fx(card, view)
						on_pressed.call(index, card)
				)
			else:
				_card_feedback_fx(card, view)
				on_pressed.call(index, card))


func _card_cost_summary(card: CardData) -> String:
	if card is ActionCardData:
		var action := card as ActionCardData
		var parts: PackedStringArray = ["%d energii" % action.energy_cost]
		if action.food_cost > 0: parts.append("%d jedzenia" % action.food_cost)
		if action.wood_cost > 0: parts.append("%d drewna" % action.wood_cost)
		if action.materials_cost > 0: parts.append("%d kamienia" % action.materials_cost)
		return ", ".join(parts)
	return "brak"


## Energy/resources may change without the hand changing (e.g. Rest), so
## availability is re-evaluated on every stats change.
func _refresh_playability() -> void:
	var hand := _survival.hand
	var hand_views := _hand_container.get_children()
	for i in mini(hand_views.size(), hand.size()):
		(hand_views[i] as CardView).setup(hand[i], _survival.can_play(hand[i]))
	var gathers := _survival.available_gather_actions().slice(0, MAX_GATHER_CARD_VIEWS)
	var gather_views := _gather_container.get_children()
	for i in mini(gather_views.size(), gathers.size()):
		(gather_views[i] as CardView).setup(gathers[i], _survival.can_play_gather(gathers[i]))


func _on_log_message(text: String) -> void:
	_log.append_text(text + "\n")


# --- Level-up rewards ---


func _on_leveled_up(_level: int) -> void:
	AudioManager.play_sfx("level_up")
	_show_reward_panel()


func _show_reward_panel() -> void:
	if not _survival.has_pending_reward():
		_level_overlay.visible = false
		return
	var state := _survival.state
	var suffix := "" if state.pending_rewards == 1 \
		else " (w kolejce: %d)" % state.pending_rewards
	_level_title.text = "Awans! Poziom %d — wybierz nagrodę%s" % [state.level, suffix]
	_reward_buttons.visible = true
	_clear_card_choices()
	_energy_button.disabled = state.max_energy >= SurvivalSystem.MAX_ENERGY_CAP
	if _energy_button.disabled:
		_energy_button.tooltip_text = "Limit maksymalnej energii: %d" % SurvivalSystem.MAX_ENERGY_CAP
	else:
		_energy_button.tooltip_text = ""
	_level_overlay.visible = true


func _on_reward_energy() -> void:
	_survival.claim_max_energy()
	_show_reward_panel()


func _on_reward_health() -> void:
	_survival.claim_max_health()
	_show_reward_panel()


## Rolling the 3 cards commits to this reward (no going back — that would
## allow re-roll scumming).
func _on_reward_card() -> void:
	var rewards := _survival.roll_card_rewards()
	if rewards.is_empty():
		if _survival.state.max_energy >= SurvivalSystem.MAX_ENERGY_CAP:
			_survival.claim_max_health()
		else:
			_survival.claim_max_energy()
		_show_reward_panel()
		return
	_reward_buttons.visible = false
	_clear_card_choices()
	_level_title.text = "Wybierz kartę do talii (obecnie: %d kart)" % _survival.state.deck.size()
	for card in rewards:
		var wrap := VBoxContainer.new()
		wrap.custom_minimum_size = Vector2(132, 228)
		wrap.add_theme_constant_override("separation", 4)
		_card_choices.add_child(wrap)

		var view: CardView = CARD_VIEW_SCENE.instantiate()
		wrap.add_child(view)
		view.setup(card, "")
		view.tooltip_text = "Masz w talii: %d" % _deck_count_for(card)
		view.pressed.connect(_on_reward_card_chosen.bind(card))

		var count_label := Label.new()
		count_label.text = "Masz w talii: %d" % _deck_count_for(card)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.66, 1.0))
		wrap.add_child(count_label)
	_card_choices.visible = true


func _on_reward_card_chosen(card: CardData) -> void:
	_survival.claim_card(card)
	_show_reward_panel()


func _clear_card_choices() -> void:
	for child in _card_choices.get_children():
		_card_choices.remove_child(child)
		child.queue_free()
	_card_choices.visible = false
