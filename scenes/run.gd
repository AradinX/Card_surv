extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const NIGHT_CARD_VIEW_SCENE := preload("res://ui/night_card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")
const BUILDING_POPUP_VIEW_SCENE := preload("res://ui/building_popup_view.tscn")
const CONFIRM_POPUP_SCENE := preload("res://ui/confirm_popup.tscn")
const DECK_POPUP_SCENE := preload("res://ui/deck_popup.tscn")
const SECURE_POPUP_SCENE := preload("res://ui/secure_popup.tscn")
const CARD_DROP_ZONE_SCRIPT := preload("res://ui/card_drop_zone.gd")
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
const LOW_HUNGER_FX := "res://assets/art/fx/ui/fx_low_hunger_vignette.png"
const LOW_THIRST_FX := "res://assets/art/fx/ui/fx_low_thirst_vignette.png"
const BUILD_PLACE_FX := "res://assets/art/fx/buildings/fx_build_place.png"
const REPAIR_FX := "res://assets/art/fx/buildings/fx_repair_sparkle.png"
const COLLAPSE_FX := "res://assets/art/fx/buildings/fx_ruin_collapse.png"
const SECURE_REGION_FX := "res://assets/art/fx/buildings/fx_secure_region.png"
const BIOME_NORMAL_BG_DIR := "res://assets/art/biomes/backgrounds/normal"
const BIOME_CORRUPTED_BG_DIR := "res://assets/art/biomes/backgrounds/corrupted"
const BIOME_PREVIEW_ART_IDS := {
	"forest": "forest",
	"meadows": "meadow",
	"mountains": "mountains",
	"swamp": "swamp",
	"river": "river",
	"wasteland": "wasteland",
	"caves": "caves",
	"coast": "coast",
}
## Low-HP danger vignette shows at or below this fraction of max health.
const LOW_HP_FRACTION := 0.3
const NEED_WARNING_FRACTION := 0.3
const NEED_WARNING_COLORS := {
	"hunger": Color(1.0, 0.55, 0.18, 1.0),
	"thirst": Color(0.22, 0.62, 1.0, 1.0),
	"warmth": Color(0.78, 0.95, 1.0, 1.0),
}
const NEED_WARNING_FX := {
	"hunger": LOW_HUNGER_FX,
	"thirst": LOW_THIRST_FX,
	"warmth": WEATHER_FROST,
}
const DESIGN_VIEWPORT := Vector2(1280, 720)
const OVERLAY_PADDING := Vector2(32, 32)
const LEVEL_PANEL_BASE := Vector2(900, 470)
const NIGHT_PANEL_BASE := Vector2(460, 560)
const NIGHT_NOTE_BASE := Vector2(340, 300)
const NIGHT_LAYOUT_GAP := 28.0
const PAUSE_PANEL_BASE := Vector2(460, 430)
const TUTORIAL_PANEL_BASE := Vector2(430, 190)
const TUTORIAL_HIGHLIGHT_PAD := 8.0
const TUTORIAL_BIOME_CARDS := 0
const TUTORIAL_LOGS := 1
const TUTORIAL_TOP_STATS := 2
const TUTORIAL_HAND_CARDS := 3
const TUTORIAL_BUILD_BUTTON := 4
const TUTORIAL_BUILD_CAMPFIRE := 5
const TUTORIAL_SECURE_REGION := 6
const TUTORIAL_CLICK_BUILDING := 7
const TUTORIAL_USE_BUILDING := 8
const TUTORIAL_END_DAY := 9
const TUTORIAL_NIGHT_EVENT := 10
const TUTORIAL_DISCOVER_TILE := 11
const TUTORIAL_REPAIR_BUILDING := 12
const TUTORIAL_DONE := 13

@onready var _background: ColorRect = $Background
@onready var _background_art: TextureRect = $BackgroundArt
@onready var _main_scroll: ScrollContainer = $Scroll
@onready var _main_margin: MarginContainer = $Scroll/Margin
@onready var _top_status_bar: TopStatusBarView = $Scroll/Margin/Layout/TopStatusBar
@onready var _board_grid: GridContainer = $Scroll/Margin/Layout/MidRow/Board
@onready var _log_panel: Control = $Scroll/Margin/Layout/MidRow/LogPanel
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
var _confirm_popup: ConfirmPopupView
var _secure_popup: SecurePopupView
var _pending_confirm_action := Callable()
var _pending_secure_action := Callable()
var _modal_layer: CanvasLayer
var _building_info_popup
var _deck_button: Button
var _deck_popup: DeckPopupView
var _log_drop_zone
var _tutorial_overlay: Control
var _tutorial_dim: ColorRect
var _tutorial_highlight: Panel
var _tutorial_panel: PanelContainer
var _tutorial_title: Label
var _tutorial_label: Label
var _tutorial_next_button: Button
var _tutorial_step := TUTORIAL_BIOME_CARDS
var _tutorial_hand_played := {}
var _tutorial_delay_token := 0
var _night_fx: Array[Node] = []
var _night_tween: Tween
var _weather_overlay: TextureRect
var _frost_overlay: TextureRect
var _low_hp_overlay: TextureRect
var _low_hp_tween: Tween
var _need_warning_overlays: Dictionary = {}
var _need_warning_tweens: Dictionary = {}
var _dragging_play_card := false
## Active Act II palette (set when BUM strikes; drives _apply_act2_look and the
## per-disaster tint of the corruption FX layers).
var _act2_look := ACT2_LOOK["plague"]


func _ready() -> void:
	_survival = GameManager.survival
	if _survival == null:
		push_error("Run scene started without a survival system; returning to menu.")
		GameManager.return_to_menu()
		return

	_main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_main_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	_forecast_label.visible = false
	_card_choices.custom_minimum_size = Vector2(0, 232)
	_top_status_bar.setup_max_values()
	_setup_overlay_layers()
	_apply_button_skin()
	_create_weather_overlay()
	_create_low_hp_overlay()
	_create_need_warning_overlays()
	# Before the resume act2 look below, so a resumed post-BUM run skins them too.
	_setup_confirm_popups()
	_setup_deck_dialog()
	_setup_tutorial_panel()

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
	_setup_card_drop_targets()
	_building_bar.z_index = 210
	_building_bar.z_as_relative = false
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
	_setup_building_info_popup()
	_apply_responsive_layout()

	_survival.begin()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _setup_overlay_layers() -> void:
	for overlay in [_level_overlay, _night_overlay, _pause_overlay]:
		overlay.z_index = 100
		overlay.z_as_relative = false


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
	_fit_tutorial_panel(viewport_size)


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


func _fit_tutorial_panel(_viewport_size: Vector2) -> void:
	if _tutorial_overlay == null:
		return
	_tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_overlay.offset_left = 0.0
	_tutorial_overlay.offset_top = 0.0
	_tutorial_overlay.offset_right = 0.0
	_tutorial_overlay.offset_bottom = 0.0
	call_deferred("_update_tutorial_visuals")


func _setup_tutorial_panel() -> void:
	if not GameManager.tutorial_mode:
		return
	_tutorial_overlay = Control.new()
	_tutorial_overlay.name = "TutorialCoachOverlay"
	_tutorial_overlay.z_index = 160
	_tutorial_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_tutorial_overlay)

	_tutorial_dim = ColorRect.new()
	_tutorial_dim.name = "Dim"
	_tutorial_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tutorial_dim.color = Color(0.02, 0.025, 0.02, 0.0)
	_tutorial_overlay.add_child(_tutorial_dim)

	_tutorial_highlight = Panel.new()
	_tutorial_highlight.name = "Highlight"
	_tutorial_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(1.0, 0.86, 0.32, 0.08)
	highlight_style.set_border_width_all(3)
	highlight_style.border_color = Color(1.0, 0.82, 0.22, 1.0)
	highlight_style.set_corner_radius_all(8)
	_tutorial_highlight.add_theme_stylebox_override("panel", highlight_style)
	_tutorial_overlay.add_child(_tutorial_highlight)

	_tutorial_panel = PanelContainer.new()
	_tutorial_panel.name = "TutorialHintPanel"
	_tutorial_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.055, 0.04, 0.96)
	style.set_border_width_all(2)
	style.border_color = Color(0.84, 0.68, 0.28, 0.95)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	_tutorial_panel.add_theme_stylebox_override("panel", style)
	_tutorial_overlay.add_child(_tutorial_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_theme_constant_override("separation", 6)
	_tutorial_panel.add_child(box)

	_tutorial_title = Label.new()
	_tutorial_title.text = "Samouczek"
	_tutorial_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_title.add_theme_font_size_override("font_size", 20)
	_tutorial_title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.36))
	box.add_child(_tutorial_title)

	_tutorial_label = Label.new()
	_tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tutorial_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tutorial_label.add_theme_font_size_override("font_size", 15)
	_tutorial_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.74))
	box.add_child(_tutorial_label)

	_tutorial_next_button = Button.new()
	_tutorial_next_button.custom_minimum_size = Vector2(160, 42)
	_tutorial_next_button.text = "Dalej"
	_tutorial_next_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)
	ButtonSkin.apply_minimal(_tutorial_next_button)
	box.add_child(_tutorial_next_button)
	_update_tutorial_panel()


func _update_tutorial_panel() -> void:
	if _tutorial_overlay == null or _tutorial_panel == null or _survival == null or _survival.state == null:
		return
	var copy := _tutorial_step_copy()
	_tutorial_title.text = str(copy.get("title", "Samouczek"))
	_tutorial_label.text = str(copy.get("body", ""))
	_tutorial_overlay.visible = true
	if _tutorial_next_button != null:
		_tutorial_next_button.visible = _tutorial_step_requires_next()
		_tutorial_next_button.text = "Zako\u0144cz samouczek" if _tutorial_step == TUTORIAL_DONE else "Dalej"
	_update_tutorial_visuals()


func _tutorial_step_copy() -> Dictionary:
	var forecast := _survival.end_of_day_forecast()
	var night_line := "Co noc: syto\u015b\u0107 -%d, nawodnienie -%d, ciep\u0142o -%d. Budynki mog\u0105 to zmieni\u0107." % [
		int(forecast["hunger_decay"]),
		int(forecast["thirst_decay"]),
		int(forecast["warmth_decay"]),
	]
	match _tutorial_step:
		TUTORIAL_BIOME_CARDS:
			return {
				"title": "1/13 Karty biomu",
				"body": "To s\u0105 akcje dost\u0119pne na aktualnym biomie. Na lesie mo\u017cesz pozyska\u0107 drewno. Przeci\u0105gnij kart\u0119 R\u0105b drewno na kartk\u0119 log\u00f3w albo na obecny kafel."
			}
		TUTORIAL_LOGS:
			return {
				"title": "2/13 Logi",
				"body": "Tutaj pojawia si\u0119 zapis przebiegu runu. Log pokazuje faktyczne koszty, zdobyte zasoby, modyfikatory pory roku oraz efekty budynk\u00f3w."
			}
		TUTORIAL_TOP_STATS:
			return {
				"title": "3/13 Pasek stanu",
				"body": "Pasek u g\u00f3ry pokazuje dzie\u0144, poziom, zdrowie, syto\u015b\u0107, nawodnienie, ciep\u0142o, energi\u0119 oraz zapasy. Najed\u017a kursorem na por\u0119 roku, aby zobaczy\u0107 jej bonusy i kary. " + night_line
			}
		TUTORIAL_HAND_CARDS:
			return {
				"title": "4/13 Karty w r\u0119ce",
				"body": "To talia akcji dobrana na bie\u017c\u0105cy dzie\u0144. Zagraj \u0179r\u00f3d\u0142o, aby uzupe\u0142ni\u0107 wod\u0119, oraz Zbieractwo, aby zdoby\u0107 jedzenie i poprawi\u0107 syto\u015b\u0107."
			}
		TUTORIAL_BUILD_BUTTON:
			return {
				"title": "5/13 Budowanie",
				"body": "Przejd\u017a do trybu budowania. Lista poka\u017ce konstrukcje dost\u0119pne na obecnym biomie wraz z kosztem energii, drewna i kamienia."
			}
		TUTORIAL_BUILD_CAMPFIRE:
			return {
				"title": "6/13 Ognisko",
				"body": "Zbuduj Ognisko, przeci\u0105gaj\u0105c jego kart\u0119 na obecny biom albo na kartk\u0119 log\u00f3w. Ognisko dodaje ciep\u0142o podczas nocy, ale stopniowo traci HP."
			}
		TUTORIAL_SECURE_REGION:
			return {
				"title": "7/13 Zabezpieczenie rejonu",
				"body": "Przycisk w prawym dolnym rogu aktualnego kafla pozwala zabezpieczy\u0107 ca\u0142y rejon przed BUM. To kosztowna decyzja: du\u017co kamienia, energia i drewno za mniejsze obra\u017cenia BUM oraz mniej zu\u017cycia budynk\u00f3w w Akcie I. Nie musisz robi\u0107 tego teraz."
			}
		TUTORIAL_CLICK_BUILDING:
			return {
				"title": "8/13 Budynek na kaflu",
				"body": "Budynek jest teraz widoczny na kaflu. Kliknij jego ikon\u0119, aby otworzy\u0107 szczeg\u00f3\u0142y: HP, efekt pasywny, akcj\u0119, napraw\u0119 i rozbi\u00f3rk\u0119."
			}
		TUTORIAL_USE_BUILDING:
			return {
				"title": "9/13 Akcja budynku",
				"body": "Cz\u0119\u015b\u0107 budynk\u00f3w ma aktywne akcje wykonywane za energi\u0119. U\u017cyj akcji Ogrzej si\u0119. Pami\u0119taj: niekt\u00f3re konstrukcje trac\u0105 HP przez u\u017cycie, prac\u0119 lub nocne zu\u017cycie."
			}
		TUTORIAL_END_DAY:
			return {
				"title": "10/13 Koniec dnia",
				"body": "Najed\u017a na Koniec dnia, aby sprawdzi\u0107 prognoz\u0119 nocy: spadki potrzeb, zapasy i wp\u0142yw budynk\u00f3w. Nast\u0119pnie zako\u0144cz dzie\u0144."
			}
		TUTORIAL_NIGHT_EVENT:
			return {
				"title": "11/13 Noc",
				"body": "Karta nocy pokazuje wydarzenie, a notatka obok podsumowuje efekty dodatnie i ujemne. W tym miejscu wida\u0107 r\u00f3wnie\u017c, jak budynki wp\u0142ywaj\u0105 na wynik nocy. Po przeczytaniu kliknij Dalej w panelu nocy."
			}
		TUTORIAL_DISCOVER_TILE:
			return {
				"title": "12/13 Odkrywanie",
				"body": "Drugiego dnia odkryj s\u0105siedni, nieznany kafel. Odkrywanie kosztuje energi\u0119 i mo\u017ce doda\u0107 zagro\u017cenia danego biomu do nocnej puli wydarze\u0144."
			}
		TUTORIAL_REPAIR_BUILDING:
			return {
				"title": "13/13 Naprawa",
				"body": "Po nocy ognisko mo\u017ce mie\u0107 mniej HP. Otw\u00f3rz szczeg\u00f3\u0142y budynku i u\u017cyj naprawy, aby zobaczy\u0107 koszt oraz przywr\u00f3ci\u0107 wytrzyma\u0142o\u015b\u0107."
			}
		TUTORIAL_DONE:
			return {
				"title": "Samouczek zako\u0144czony",
				"body": "Chyba ju\u017c rozumiesz podstawy. Pora wr\u00f3ci\u0107 do menu i rozpocz\u0105\u0107 normaln\u0105 gr\u0119."
			}
		_:
			return {"title": "Samouczek", "body": ""}


func _update_tutorial_visuals() -> void:
	if _tutorial_overlay == null or not _tutorial_overlay.visible:
		return
	var viewport_size := get_viewport_rect().size
	if _tutorial_step == TUTORIAL_DONE:
		_tutorial_highlight.visible = false
		var width := minf(TUTORIAL_PANEL_BASE.x, maxf(viewport_size.x - 32.0, 280.0))
		var height := minf(TUTORIAL_PANEL_BASE.y, maxf(viewport_size.y - 32.0, 140.0))
		_tutorial_panel.custom_minimum_size = Vector2(width, height)
		_tutorial_panel.size = Vector2(width, height)
		_tutorial_panel.position = viewport_size * 0.5 - Vector2(width, height) * 0.5
		return
	var rect := _tutorial_target_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		rect = Rect2(Vector2(24, 112), Vector2(360, 160))
	_tutorial_highlight.visible = not _tutorial_should_hide_highlight()
	var pad := TUTORIAL_HIGHLIGHT_PAD
	var highlight_rect := Rect2(
		rect.position - Vector2(pad, pad),
		rect.size + Vector2(pad * 2.0, pad * 2.0)
	)
	_tutorial_highlight.position = highlight_rect.position
	_tutorial_highlight.size = highlight_rect.size
	_position_tutorial_panel(rect, viewport_size)


func _tutorial_should_hide_highlight() -> bool:
	if _building_info_popup == null or not _building_info_popup.visible:
		return false
	return _tutorial_step in [TUTORIAL_USE_BUILDING, TUTORIAL_REPAIR_BUILDING]


func _position_tutorial_panel(target_rect: Rect2, viewport_size: Vector2) -> void:
	var width := minf(TUTORIAL_PANEL_BASE.x, maxf(viewport_size.x - 32.0, 280.0))
	var height := minf(TUTORIAL_PANEL_BASE.y, maxf(viewport_size.y - 32.0, 140.0))
	_tutorial_panel.custom_minimum_size = Vector2(width, height)
	_tutorial_panel.size = Vector2(width, height)
	var pos := Vector2(target_rect.position.x, target_rect.end.y + 14.0)
	if pos.y + height > viewport_size.y - 16.0:
		pos.y = target_rect.position.y - height - 14.0
	if pos.y < 16.0:
		pos.y = 16.0
	if pos.x + width > viewport_size.x - 16.0:
		pos.x = viewport_size.x - width - 16.0
	if pos.x < 16.0:
		pos.x = 16.0
	_tutorial_panel.position = pos


func _tutorial_target_rect() -> Rect2:
	match _tutorial_step:
		TUTORIAL_BIOME_CARDS:
			return _node_rect(_gather_bar)
		TUTORIAL_LOGS:
			return _node_rect(_log_panel)
		TUTORIAL_TOP_STATS:
			return _node_rect(_top_status_bar)
		TUTORIAL_HAND_CARDS:
			return _node_rect(_hand_container)
		TUTORIAL_BUILD_BUTTON:
			return _node_rect(_build_toggle_button)
		TUTORIAL_BUILD_CAMPFIRE:
			return _node_rect(_build_scroll)
		TUTORIAL_SECURE_REGION:
			var tile_button := _current_tile_button()
			if tile_button is BiomeTileView:
				return (tile_button as BiomeTileView).secure_region_button_rect()
			return _current_tile_rect()
		TUTORIAL_CLICK_BUILDING:
			return _current_tile_rect()
		TUTORIAL_USE_BUILDING:
			return _node_rect(_building_info_popup if _building_info_popup != null and _building_info_popup.visible else _current_tile_button())
		TUTORIAL_END_DAY:
			return _node_rect(_end_day_button)
		TUTORIAL_NIGHT_EVENT:
			return _node_rect(_night_note_panel if _night_note_panel.visible else _night_overlay)
		TUTORIAL_DISCOVER_TILE:
			return _discoverable_tile_rect()
		TUTORIAL_REPAIR_BUILDING:
			return _node_rect(_building_info_popup if _building_info_popup != null and _building_info_popup.visible else _board_grid)
		_:
			return Rect2()


func _node_rect(node: Variant) -> Rect2:
	if node is Control and is_instance_valid(node):
		return (node as Control).get_global_rect()
	return Rect2()


func _current_tile_button() -> Control:
	if _survival == null or _survival.state == null:
		return null
	var idx := _survival.state.current_tile
	if idx >= 0 and idx < _tile_buttons.size():
		return _tile_buttons[idx]
	return null


func _current_tile_rect() -> Rect2:
	return _node_rect(_current_tile_button())


func _discoverable_tile_rect() -> Rect2:
	if _survival == null or _survival.state == null:
		return _node_rect(_board_grid)
	for i in _survival.state.board.size():
		if BoardGenerator.are_adjacent(_survival.state.current_tile, i) \
				and not _survival.state.board[i].is_discovered \
				and i < _tile_buttons.size():
			return _tile_buttons[i].get_global_rect()
	return _node_rect(_board_grid)


func _tutorial_set_step(step: int) -> void:
	if not GameManager.tutorial_mode or _tutorial_step == TUTORIAL_DONE:
		return
	if step <= _tutorial_step and step != TUTORIAL_DONE:
		return
	_tutorial_step = step
	_tutorial_delay_token += 1
	_update_tutorial_panel()
	call_deferred("_update_tutorial_visuals")


func _tutorial_step_requires_next() -> bool:
	return _tutorial_step in [
		TUTORIAL_LOGS,
		TUTORIAL_TOP_STATS,
		TUTORIAL_SECURE_REGION,
		TUTORIAL_DONE,
	]


func _on_tutorial_next_pressed() -> void:
	match _tutorial_step:
		TUTORIAL_LOGS:
			_tutorial_set_step(TUTORIAL_TOP_STATS)
		TUTORIAL_TOP_STATS:
			_tutorial_set_step(TUTORIAL_HAND_CARDS)
		TUTORIAL_SECURE_REGION:
			_tutorial_set_step(TUTORIAL_CLICK_BUILDING)
		TUTORIAL_NIGHT_EVENT:
			_hide_night_event()
			_survival.resolve_night()
		TUTORIAL_DONE:
			GameManager.return_to_menu()
		_:
			pass


func _tutorial_on_card_played(source: String, card_id: String) -> void:
	if not GameManager.tutorial_mode:
		return
	match _tutorial_step:
		TUTORIAL_BIOME_CARDS:
			if source == "gather":
				_tutorial_set_step(TUTORIAL_LOGS)
		TUTORIAL_HAND_CARDS:
			if source == "hand" and card_id in ["find_water", "forage"]:
				_tutorial_hand_played[card_id] = true
				if _tutorial_hand_played.has("find_water") and _tutorial_hand_played.has("forage"):
					_tutorial_set_step(TUTORIAL_BUILD_BUTTON)
		TUTORIAL_BUILD_CAMPFIRE:
			if source == "build" and card_id == "building_campfire":
				_tutorial_set_step(TUTORIAL_SECURE_REGION)
		_:
			pass


## Esc toggles the pause menu. If the settings panel is open (from pause), Esc
## drops back to the pause menu first; other modals (night/level-up) keep Esc.
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _settings_overlay.visible:
		_settings_overlay.visible = false
	elif _confirm_popup != null and _confirm_popup.visible:
		_confirm_popup.close()
		_pending_confirm_action = Callable()
	elif _secure_popup != null and _secure_popup.visible:
		_secure_popup.close()
		_pending_secure_action = Callable()
	elif _deck_popup != null and _deck_popup.visible:
		_deck_popup.close()
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
		button.building_pressed.connect(_on_building_slot_pressed.bind(i))
		button.secure_region_pressed.connect(_on_secure_region_pressed.bind(i))
		button.card_dropped.connect(_on_card_dropped.bind("tile", i))
		_board_grid.add_child(button)
		_tile_buttons.append(button)


func _on_tile_pressed(tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_request_move(tile_index)


func _on_building_slot_pressed(building_index: int, anchor_rect: Rect2, tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_request_move(tile_index, func() -> void:
			_building_popup_requested = false
			_building_bar.visible = false
			_show_building_info(building_index, _tile_buttons[tile_index].get_global_rect())
		)
		return
	_building_popup_requested = false
	_building_bar.visible = false
	_show_building_info(building_index, anchor_rect)


func _on_secure_region_pressed(_anchor_rect: Rect2, tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		return
	var block := _survival.can_secure_current_tile()
	if block != "":
		_on_log_message(block)
		_refresh_tiles(_survival.state)
		return
	var title := "Zabezpieczyć rejon?"
	var cost_text := "Koszt:\n%s" % _survival.secure_current_tile_summary()
	var effect_text := "Efekt:\n-%d%% obrażeń BUM\n%d%% szans na zużycie HP w Akcie I\nLimit: %d rejony\nZużywa się przy BUM." % [
		SurvivalSystem.BUM_SECURE_DAMAGE_REDUCTION,
		SurvivalSystem.ACT1_SECURED_WEAR_CHANCE_PERCENT,
		SurvivalSystem.BUM_SECURED_TILE_LIMIT,
	]
	_confirm_secure(title, cost_text, effect_text, "Zabezpiecz", _secure_region_preview_texture(), func() -> void:
		_survival.secure_current_tile()
		AudioManager.play_sfx("build")
		var fx_path := SECURE_REGION_FX if ResourceLoader.exists(SECURE_REGION_FX) else BUILD_PLACE_FX
		_spawn_tile_fx(fx_path, false)
		_refresh_tiles(_survival.state)
	)


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
		_survival.move_energy_cost(),
	]
	_confirm_action(title, body, ok_text, func() -> void:
		_building_popup_requested = false
		_building_bar.visible = false
		_hide_building_info_popup()
		_survival.move_to(tile_index)
		if after_move.is_valid():
			after_move.call()
	)


func _hide_building_popup() -> void:
	_building_popup_requested = false
	_building_bar.visible = false
	_hide_building_info_popup()


func _on_end_day_pressed() -> void:
	_hide_building_popup()
	if _build_mode:
		_set_build_mode(false)
	_survival.end_day()
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_END_DAY:
		call_deferred("_update_tutorial_visuals")


func _on_day_started(day: int) -> void:
	_top_status_bar.set_day(day, SurvivalSystem.WIN_DAY, _survival.state.season)
	_update_weather()
	_update_forecast()
	if GameManager.tutorial_mode:
		if day == 2 and _tutorial_step <= TUTORIAL_NIGHT_EVENT:
			_tutorial_set_step(TUTORIAL_DISCOVER_TILE)
		elif day >= 3 and _tutorial_step < TUTORIAL_DONE:
			_tutorial_set_step(TUTORIAL_DONE)
		else:
			_update_tutorial_panel()


func _on_stats_changed(state: RunState) -> void:
	_top_status_bar.set_day(state.day, SurvivalSystem.WIN_DAY, state.season)
	_top_status_bar.set_state(state, _survival.xp_to_next_level(), _resource_caps())
	_refresh_playability()
	_refresh_tiles(state)
	_update_low_hp_vignette(state)
	_update_need_warning_vignettes(state)
	_update_forecast()
	if _build_mode:
		_refresh_build_playability()
	if _building_info_popup != null and _building_info_popup.visible:
		_refresh_building_info_popup()


## End-of-day forecast: tonight's stat drops + supplies, so the player doesn't
## have to do the math (warmth shown as net of building heat vs decay).
func _update_forecast() -> void:
	var f := _survival.end_of_day_forecast()
	var warmth_net: int = f["warmth_net"]
	var warmth_txt := ("%+d" % warmth_net) if warmth_net != 0 else "0"
	_forecast_label.text = ""
	var sickness_line := ""
	var sickness_chance: float = f.get("camp_sickness_chance", 0.0)
	if sickness_chance > 0.0:
		sickness_line = "\nRyzyko choroby w tym biomie: %d%% (-%d zdrowia)" % [
			int(round(sickness_chance * 100.0)),
			int(f.get("camp_sickness_damage", 0)),
		]
	_end_day_button.tooltip_text = "Po nocy:\nSytość -%d\nNawodnienie -%d\nCiepło %s (noc -%d, budynki +%d)\nZapasy: %d jedzenia, %d wody%s" % [
		f["hunger_decay"],
		f["thirst_decay"],
		warmth_txt,
		f["warmth_decay"],
		f["passive_warmth"],
		f["food"],
		f["water"],
		sickness_line,
	]


func _on_board_changed(state: RunState) -> void:
	_refresh_tiles(state)
	if _build_mode:
		_refresh_build_cards()
	if _building_info_popup != null and _building_info_popup.visible:
		_refresh_building_info_popup()


func _on_tile_discovered(tile_index: int) -> void:
	AudioManager.play_sfx("discover")
	if tile_index >= 0 and tile_index < _tile_buttons.size():
		_tile_buttons[tile_index].play_discovery_fx()
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_DISCOVER_TILE:
		_tutorial_set_step(TUTORIAL_REPAIR_BUILDING)


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
				else "Przejdź (koszt: %d energii)" % _survival.move_energy_cost()
		var building_tooltips: Array[String] = []
		for built in tile.buildings:
			building_tooltips.append(_building_tooltip(built, tile))
		if tile.bum_secured and not state.bum_happened:
			tooltip += "\n\nZabezpieczony rejon: -%d%% obrażeń BUM, %d%% szans na zużycie HP w Akcie I. Zabezpieczenie zużyje się przy BUM." % [
				SurvivalSystem.BUM_SECURE_DAMAGE_REDUCTION,
				SurvivalSystem.ACT1_SECURED_WEAR_CHANCE_PERCENT,
			]
		var secure_visible := i == state.current_tile \
			and tile.is_discovered \
			and not state.bum_happened \
			and not tile.bum_secured \
			and not tile.buildings.is_empty()
		var secure_block := _survival.can_secure_current_tile() if secure_visible else ""
		var secure_tooltip := _secure_region_button_tooltip(secure_block) if secure_visible else ""
		button.setup(
			tile,
			i == state.current_tile,
			block_reason,
			tooltip,
			building_tooltips,
			secure_visible,
			secure_block != "",
			secure_tooltip
		)
		button.set_accept_card_drops(i == state.current_tile)
	_refresh_building_actions()


func _secure_region_button_tooltip(block_reason: String) -> String:
	var lines: PackedStringArray = [
		"Zabezpiecz rejon",
		"Koszt: %s" % _survival.secure_current_tile_summary(),
		"Efekt: -%d%% obrażeń BUM dla budynków tutaj." % SurvivalSystem.BUM_SECURE_DAMAGE_REDUCTION,
		"W Akcie I budynki mają tylko %d%% szans na zużycie HP." % SurvivalSystem.ACT1_SECURED_WEAR_CHANCE_PERCENT,
		"Limit: %d zabezpieczone rejony." % SurvivalSystem.BUM_SECURED_TILE_LIMIT,
	]
	if block_reason != "":
		lines.append(block_reason)
	return "\n".join(lines)


func _resource_caps() -> Dictionary:
	return {
		"food": _survival.food_cap(),
		"water": _survival.water_cap(),
		"wood": _survival.wood_cap(),
		"materials": _survival.materials_cap(),
	}

## Current-tile building list. Details and actions live in BuildingInfoPopup.
func _refresh_building_actions() -> void:
	for child in _building_actions.get_children():
		_building_actions.remove_child(child)
		child.queue_free()
	_building_popup_requested = false
	_building_bar.visible = false
	if _building_info_popup != null and _building_info_popup.visible:
		_refresh_building_info_popup()


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
		_hide_building_info_popup()
	)


func _show_building_info(building_index: int, anchor: Rect2 = Rect2()) -> void:
	var popup_data := _building_info_data(building_index)
	if popup_data.is_empty():
		return
	_building_info_popup.popup_for(popup_data, anchor, get_viewport_rect().size)
	if GameManager.tutorial_mode:
		if _tutorial_step == TUTORIAL_CLICK_BUILDING:
			_tutorial_set_step(TUTORIAL_USE_BUILDING)
		elif _tutorial_step == TUTORIAL_REPAIR_BUILDING:
			call_deferred("_update_tutorial_visuals")


func _refresh_building_info_popup() -> void:
	if _building_info_popup == null or not _building_info_popup.visible:
		return
	var popup_data := _building_info_data(_building_info_popup.selected_building_index())
	if popup_data.is_empty():
		_hide_building_info_popup()
		return
	_building_info_popup.set_content(popup_data)


func _building_info_data(building_index: int) -> Dictionary:
	var buildings := _survival.current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return {}
	var built = buildings[building_index]
	var data: BuildingCardData = built.data
	var max_hp := _survival.building_max_hp(data)
	var effect_parts := _building_passive_effect_parts(data)
	var action := _survival.building_action(building_index)
	var block := str(action.get("block", "")) if not action.is_empty() else ""
	var action_used := block.contains("użyta dzisiaj")
	var summary := str(action.get("summary", "")) if not action.is_empty() else ""
	var action_text := ""
	if not built.is_ruined and not action.is_empty():
		action_text = "%s%s" % [
			str(action.get("title", "Użyj")),
			"\n%s" % summary if summary != "" else "",
		]

	var is_campfire := data.id == "building_campfire"
	var repair_text := ""
	var repair_disabled := false
	var repair_tooltip := ""
	var repair_button_text := "Napraw"
	if is_campfire:
		repair_button_text = "Dołóż drewna"
		var fuel_block := _survival.can_repair(building_index)
		repair_text = "Dołóż: %d drewno -> +%d noce" % [
			SurvivalSystem.CAMPFIRE_STOKE_WOOD_COST,
			SurvivalSystem.CAMPFIRE_FUEL_HP_PER_WOOD,
		]
		repair_disabled = fuel_block != ""
		repair_tooltip = fuel_block if fuel_block != "" else "Można dokładać bez ograniczeń."
	elif built.is_ruined:
		repair_text = "Naprawa: niedostępna."
		repair_disabled = true
		repair_tooltip = "Ruiny można tylko rozebrać."
	elif built.hp >= max_hp:
		repair_text = "Naprawa: pełne HP."
		repair_disabled = true
		repair_tooltip = "Budynek ma pełne HP."
	else:
		var repair_block := _survival.can_repair(building_index)
		var wood_cost := _survival.repair_wood_cost(built)
		repair_text = "Naprawa: %d energii, %d drewna" % [
			SurvivalSystem.REPAIR_ENERGY_COST,
			wood_cost,
		]
		repair_disabled = repair_block != ""
		repair_tooltip = repair_block if repair_block != "" else "Naprawa do pełnego HP."

	var refund := _demolish_refund_summary(built)
	var demolish_block := _survival.can_demolish(building_index)
	var demolish_text := "Rozbiórka: %d energii\nZwrot: %s%s" % [
		SurvivalSystem.DEMOLISH_ENERGY_COST,
		refund,
		"" if built.is_ruined else " (mniej)",
	]
	var hp_text := ""
	if is_campfire:
		hp_text = ("Pali się jeszcze %d nocy" % built.hp) if built.hp > 0 else "Wygasłe"
	else:
		hp_text = "HP %d/%d%s" % [built.hp, max_hp, "  |  RUINA" if built.is_ruined else ""]
	return {
		"index": building_index,
		"building_data": data,
		"act2": _survival.state.bum_happened,
		"hp_text": hp_text,
		"hp_low": not is_campfire and not built.is_ruined and built.hp * 2 < max_hp,
		"status_text": _building_wear_text(data, building_index) if not is_campfire else "",
		"effects_text": ("Pasywnie: %s" % ", ".join(effect_parts)) if not effect_parts.is_empty() else "",
		"action_text": action_text,
		"use_visible": not built.is_ruined and not action.is_empty(),
		"use_disabled": block != "" or action.is_empty(),
		"use_text": "Użyto" if action_used else (str(action.get("title", "Użyj")) if not action.is_empty() else "Użyj"),
		"use_tooltip": block if block != "" else summary,
		"repair_text": repair_text,
		"repair_button_text": repair_button_text,
		"repair_disabled": repair_disabled,
		"repair_tooltip": repair_tooltip,
		"demolish_text": demolish_text,
		"demolish_disabled": demolish_block != "",
		"demolish_tooltip": demolish_block if demolish_block != "" else demolish_text,
	}


## Short "-1 HP co N dni" disclosure so the player knows what to expect instead
## of discovering wear rates by trial and error (feedback item: too opaque).
func _building_wear_text(data: BuildingCardData, building_index: int) -> String:
	if data.id == "building_campfire":
		return ""
	if SurvivalSystem.NIGHTLY_WEAR_BUILDING_IDS.has(data.id):
		return "Zużycie: -1 HP co dzień."
	if SurvivalSystem.EVERY_OTHER_DAY_WEAR_BUILDING_IDS.has(data.id):
		return "Zużycie: -1 HP co 2 dni."
	if SurvivalSystem.EVERY_THIRD_DAY_WEAR_BUILDING_IDS.has(data.id):
		return "Zużycie: -1 HP co 3 dni."
	if SurvivalSystem.EVERY_FOURTH_DAY_WEAR_BUILDING_IDS.has(data.id):
		return "Zużycie: -1 HP co 4 dni."
	if not _survival.building_action(building_index).is_empty():
		return "Zużycie: -1 HP przy użyciu akcji."
	return "Zużycie: brak stałego zużycia."


func _hide_building_info_popup() -> void:
	if _building_info_popup != null:
		_building_info_popup.hide()


func _on_building_info_use_pressed(building_index: int) -> void:
	if building_index < 0:
		return
	var buildings := _survival.current_tile().buildings
	if building_index >= buildings.size():
		return
	var action := _survival.building_action(building_index)
	if action.is_empty():
		return
	var block := str(action.get("block", ""))
	if block != "":
		_on_log_message(block)
		return
	var title := "Użyć akcji budynku?"
	var action_title := str(action.get("title", "Użyj"))
	var summary := str(action.get("summary", ""))
	var text := "%s\nAkcja: %s%s" % [
		buildings[building_index].data.display_name,
		action_title,
		"\nEfekt: %s" % summary if summary != "" else "",
	]
	_confirm_action(title, text, action_title, func() -> void:
		_use_building_confirmed(building_index)
	)


func _use_building_confirmed(building_index: int) -> void:
	_survival.use_building(building_index)
	AudioManager.play_sfx("card_play")
	_refresh_building_actions()
	_refresh_building_info_popup()
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_USE_BUILDING:
		_tutorial_set_step(TUTORIAL_END_DAY)


func _on_building_info_repair_pressed(building_index: int) -> void:
	if building_index < 0:
		return
	var buildings := _survival.current_tile().buildings
	if building_index >= buildings.size():
		return
	var built = buildings[building_index]
	var repair_block := _survival.can_repair(building_index)
	if repair_block != "":
		_on_log_message(repair_block)
		return
	if built.data.id == "building_campfire":
		var fuel_text := "%s\nPali się jeszcze: %d nocy\nKoszt: %d drewno -> +%d nocy paliwa" % [
			built.data.display_name,
			built.hp,
			SurvivalSystem.CAMPFIRE_STOKE_WOOD_COST,
			SurvivalSystem.CAMPFIRE_FUEL_HP_PER_WOOD,
		]
		_confirm_action("Dołożyć drewna do ogniska?", fuel_text, "Dołóż drewna", func() -> void:
			_repair_building_confirmed(building_index)
		)
		return
	var max_hp := _survival.building_max_hp(built.data)
	var text := "%s\nHP: %d/%d\nKoszt: %d energii, %d drewna" % [
		built.data.display_name,
		built.hp,
		max_hp,
		SurvivalSystem.REPAIR_ENERGY_COST,
		_survival.repair_wood_cost(built),
	]
	_confirm_action("Naprawić budynek?", text, "Napraw", func() -> void:
		_repair_building_confirmed(building_index)
	)


func _repair_building_confirmed(building_index: int) -> void:
	_survival.repair(building_index)
	AudioManager.play_sfx("repair")
	_spawn_tile_fx(REPAIR_FX, true)
	_refresh_building_actions()
	_refresh_building_info_popup()
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_REPAIR_BUILDING:
		_tutorial_set_step(TUTORIAL_DONE)


func _on_building_info_demolish_pressed(building_index: int) -> void:
	if building_index < 0:
		return
	_confirm_demolish(building_index)


func _add_building_interaction(row: HBoxContainer, building_index: int) -> void:
	var action := _survival.building_action(building_index)
	if action.is_empty():
		return
	var block := str(action.get("block", ""))
	var title := str(action.get("title", "Akcja"))
	var summary := str(action.get("summary", ""))
	var tooltip := block if block != "" else "%s\n%s" % [title, summary]
	var action_idx := building_index
	row.add_child(_make_text_action_button(
		"Użyj",
		tooltip,
		block != "",
		func() -> void:
			_survival.use_building(action_idx)
			AudioManager.play_sfx("card_play")
			_refresh_building_actions()
	))


func _demolish_refund_summary(built) -> String:
	var divisor := SurvivalSystem.DEMOLISH_REFUND_DIVISOR if built.is_ruined \
		else SurvivalSystem.DEMOLISH_STANDING_REFUND_DIVISOR
	var wood_refund := floori(built.data.wood_cost / float(divisor))
	var stone_refund := floori(built.data.materials_cost / float(divisor))
	var parts: PackedStringArray = []
	if wood_refund > 0:
		parts.append("+%d drewna" % wood_refund)
	if stone_refund > 0:
		parts.append("+%d kamienia" % stone_refund)
	return ", ".join(parts) if not parts.is_empty() else "brak"


func _building_tooltip(built, tile: TileState = null) -> String:
	if tile == null:
		tile = _survival.current_tile()
	var data: BuildingCardData = built.data
	var hp_line := "HP %d/%d" % [built.hp, _survival.building_max_hp(data)]
	if data.id == "building_campfire":
		hp_line = "Pali się jeszcze %d nocy" % built.hp if built.hp > 0 else "Wygasłe"
	var parts: PackedStringArray = [
		data.display_name,
		hp_line,
	]
	if tile.bum_secured and not _survival.state.bum_happened:
		parts.append("Rejon zabezpieczony")
	var production := _building_effect_parts(data)
	if not production.is_empty():
		parts.append("Efekty: %s" % ", ".join(production))
	if data.special != "":
		parts.append("Specjalne: %s" % _building_special_description(data.special))
	var action := _building_action_for_tooltip(built, tile)
	if action != "":
		parts.append("Akcja: %s" % action)
	return "\n".join(parts)


func _building_action_for_tooltip(built, tile: TileState = null) -> String:
	if built.is_ruined:
		return ""
	if tile == null:
		tile = _survival.current_tile()
	if tile != _survival.current_tile():
		return ""
	var buildings := tile.buildings
	var idx := buildings.find(built)
	if idx < 0:
		return ""
	var action := _survival.building_action(idx)
	if action.is_empty():
		return ""
	var text := "%s (%s)" % [str(action.get("title", "Akcja")), str(action.get("summary", ""))]
	var block := str(action.get("block", ""))
	if block != "":
		text += "\n%s" % block
	return text


func _building_effect_parts(data: BuildingCardData) -> PackedStringArray:
	var parts: PackedStringArray = []
	if data.id == "building_campfire":
		parts.append("%+d ciepła/noc, dopóki się pali" % data.warmth_delta)
		parts.append("Duży ogień: +%d ciepła dodatkowo tej nocy (1 drewno + 1 energia)" %
			SurvivalSystem.CAMPFIRE_STOKE_BONUS_WARMTH)
		return parts
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


func _building_passive_effect_parts(data: BuildingCardData) -> PackedStringArray:
	var parts := _building_effect_parts(data)
	if data.id == "building_campfire" and parts.size() > 1:
		parts.resize(1)
	match data.special:
		"night_protection", "slow_spoilage":
			parts.append(_building_special_description(data.special))
	return parts


func _building_special_description(special: String) -> String:
	match special:
		"night_protection":
			return "chroni przed częścią nocnych strat zdrowia/ciepła"
		"slow_spoilage":
			return "spowalnia psucie jedzenia"
		"unlock_crafting":
			return "daje narzędzia po zbudowaniu"
		_:
			return special


## --- Build mode ---
## The "Budowanie" button swaps the gather/hand card rows for a scrollable
## catalog of buildings; clicking a card asks for confirmation before placing it
## on the current tile.


## Confirm (move/discover/demolish) and secure-region modals painted on the
## hand-made wooden panels. Both are full-screen overlays added on top.
func _setup_confirm_popups() -> void:
	_modal_layer = CanvasLayer.new()
	_modal_layer.name = "ModalLayer"
	_modal_layer.layer = 50
	add_child(_modal_layer)

	_confirm_popup = CONFIRM_POPUP_SCENE.instantiate()
	_confirm_popup.z_index = 300
	_confirm_popup.z_as_relative = false
	_modal_layer.add_child(_confirm_popup)
	_confirm_popup.confirmed.connect(_on_action_confirmed)

	_secure_popup = SECURE_POPUP_SCENE.instantiate()
	_secure_popup.z_index = 300
	_secure_popup.z_as_relative = false
	_modal_layer.add_child(_secure_popup)
	_secure_popup.confirmed.connect(_on_secure_confirmed)


func _setup_building_info_popup() -> void:
	_building_info_popup = BUILDING_POPUP_VIEW_SCENE.instantiate()
	_building_info_popup.z_index = 220
	_building_info_popup.z_as_relative = false
	_building_info_popup.hide()
	add_child(_building_info_popup)
	_building_info_popup.use_pressed.connect(_on_building_info_use_pressed)
	_building_info_popup.repair_pressed.connect(_on_building_info_repair_pressed)
	_building_info_popup.demolish_pressed.connect(_on_building_info_demolish_pressed)


func _setup_card_drop_targets() -> void:
	_log_drop_zone = Control.new()
	_log_drop_zone.set_script(CARD_DROP_ZONE_SCRIPT)
	_log_drop_zone.name = "CardDropZone"
	_log_drop_zone.anchor_right = 1.0
	_log_drop_zone.anchor_bottom = 1.0
	_log_drop_zone.offset_right = 0.0
	_log_drop_zone.offset_bottom = 0.0
	_log_drop_zone.card_dropped.connect(_on_card_dropped.bind("log", -1))
	_log_panel.add_child(_log_drop_zone)


func _setup_deck_dialog() -> void:
	_deck_button = Button.new()
	_deck_button.custom_minimum_size = Vector2(220, 44)
	_deck_button.text = "Talia"
	_deck_button.clip_text = true
	_button_column.add_child(_deck_button)
	_button_column.move_child(_deck_button, 0)
	ButtonSkin.apply_primary(_deck_button, _button_act)
	_deck_button.pressed.connect(_show_deck_dialog)

	_deck_popup = DECK_POPUP_SCENE.instantiate()
	_deck_popup.z_index = 300
	_deck_popup.z_as_relative = false
	_modal_layer.add_child(_deck_popup)


func _confirm_action(title: String, text: String, ok_text: String, action: Callable) -> void:
	_pending_confirm_action = action
	_confirm_popup.open(title, text, ok_text)


func _on_action_confirmed() -> void:
	var action := _pending_confirm_action
	_pending_confirm_action = Callable()
	if action.is_valid():
		action.call()


func _secure_region_preview_texture() -> Texture2D:
	var tile := _survival.current_tile()
	var art_id := str(BIOME_PREVIEW_ART_IDS.get(tile.biome.id, tile.biome.id))
	var state_suffix := "plague" if tile.is_corrupted else "normal"
	var directory := BIOME_CORRUPTED_BG_DIR if tile.is_corrupted else BIOME_NORMAL_BG_DIR
	var path := "%s/biome_%s_%s_bg.png" % [directory, art_id, state_suffix]
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	var fallback := "%s/biome_forest_normal_bg.png" % BIOME_NORMAL_BG_DIR
	if ResourceLoader.exists(fallback):
		return load(fallback) as Texture2D
	return null


## Secure-region prompt uses its own panel (with a preview slot) instead of the
## plain confirm popup.
func _confirm_secure(
		title: String,
		cost_text: String,
		effect_text: String,
		ok_text: String,
		preview: Texture2D,
		action: Callable) -> void:
	_pending_secure_action = action
	_secure_popup.open(title, cost_text, effect_text, ok_text, preview)


func _on_secure_confirmed() -> void:
	var action := _pending_secure_action
	_pending_secure_action = Callable()
	if action.is_valid():
		action.call()


func _show_deck_dialog() -> void:
	_deck_popup.open(_survival.state.deck)


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
		if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_BUILD_BUTTON:
			_tutorial_set_step(TUTORIAL_BUILD_CAMPFIRE)
	if GameManager.tutorial_mode:
		call_deferred("_update_tutorial_visuals")


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
		_setup_draggable_card(view, building, "build", -1, "Przeciągnij budowlę na aktualny biom albo kartkę logów.")


## Update greying of existing build cards without rebuilding the row (cheaper on
## frequent stats changes, avoids flicker).
func _refresh_build_playability() -> void:
	var catalog := _survival.available_buildings()
	var views := _build_cards.get_children()
	for i in mini(views.size(), catalog.size()):
		var view := views[i] as CardView
		view.setup(catalog[i], _survival.can_build(catalog[i]), _build_cost_summary(catalog[i]))
		view.set_drag_payload({
			"type": "play_card",
			"source": "build",
			"index": -1,
			"card": catalog[i],
			"card_id": catalog[i].id,
		})
		if not view.is_play_blocked():
			view.tooltip_text = "Przeciągnij budowlę na aktualny biom albo kartkę logów."


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
	var biome_label: String = _survival.required_biome_label(b)
	if biome_label != "":
		parts.append(biome_label)
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


func _make_text_action_button(
	text: String,
	button_tooltip: String,
	is_disabled: bool,
	on_pressed: Callable
) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(74, 42)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.text = text
	button.clip_text = true
	button.disabled = is_disabled
	button.tooltip_text = button_tooltip
	button.pressed.connect(on_pressed)
	ButtonSkin.apply_minimal(button)
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.68, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.78, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.46, 0.34, 0.85))
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
	_night_summary.add_theme_color_override("font_color", _act2_look["log_text"])
	_background.color = _act2_look["scrim"]
	if _confirm_popup != null:
		_confirm_popup.set_act2()
	if _secure_popup != null:
		_secure_popup.set_act2()
	if _deck_popup != null:
		_deck_popup.set_act2()


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
	_card_feedback_fx_at(card, view.global_position + view.size * 0.5)


func _card_feedback_fx_at(card: CardData, center: Vector2) -> void:
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
	_spawn_world_fx(path, center, Vector2(150, 150))


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


func _create_need_warning_overlays() -> void:
	for id in NEED_WARNING_COLORS.keys():
		var texture_path := str(NEED_WARNING_FX.get(id, ""))
		if not ResourceLoader.exists(texture_path):
			texture_path = LOW_HP_FX
		if not ResourceLoader.exists(texture_path):
			continue
		var overlay := TextureRect.new()
		overlay.texture = load(texture_path)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var color: Color = NEED_WARNING_COLORS[id]
		color.a = 0.0
		overlay.modulate = color
		overlay.visible = false
		add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_need_warning_overlays[id] = overlay


func _update_need_warning_vignettes(state: RunState) -> void:
	_update_need_warning_vignette("hunger", state.hunger, RunState.MAX_HUNGER, 0.42, 0.16)
	_update_need_warning_vignette("thirst", state.thirst, RunState.MAX_THIRST, 0.46, 0.18)
	_update_need_warning_vignette("warmth", state.warmth, RunState.MAX_WARMTH, 0.44, 0.16)


func _update_need_warning_vignette(
	id: String, current: int, maximum: int, high_alpha: float, low_alpha: float
) -> void:
	var overlay := _need_warning_overlays.get(id) as TextureRect
	if overlay == null:
		return
	var critical := current <= int(ceil(maximum * NEED_WARNING_FRACTION))
	if critical and not overlay.visible:
		overlay.visible = true
		var color: Color = NEED_WARNING_COLORS[id]
		color.a = low_alpha
		overlay.modulate = color
		var peak_alpha := high_alpha + 0.12 if current <= 0 else high_alpha
		var base_alpha := low_alpha + 0.06 if current <= 0 else low_alpha
		var tween := create_tween().set_loops()
		tween.tween_property(overlay, "modulate:a", peak_alpha, 0.65) \
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay, "modulate:a", base_alpha, 0.65) \
			.set_trans(Tween.TRANS_SINE)
		_need_warning_tweens[id] = tween
	elif not critical and overlay.visible:
		var tween := _need_warning_tweens.get(id) as Tween
		if tween != null:
			tween.kill()
			_need_warning_tweens[id] = null
		overlay.visible = false
		overlay.modulate.a = 0.0


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
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_END_DAY:
		_tutorial_set_step(TUTORIAL_NIGHT_EVENT)
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
		var block_reason := _survival.night_choice_block_reason(i) if _survival != null else ""
		button.disabled = true
		button.text = _choice_button_text(choice, block_reason)
		button.set_meta("choice_block_reason", block_reason)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 12)
		ButtonSkin.apply_minimal(button)
		button.pressed.connect(_on_night_choice.bind(i))
		_night_choices.add_child(button)


## Full choice copy: clear risk odds plus explicit success/failure outcomes.
func _choice_button_text(choice, block_reason: String = "") -> String:
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
	if block_reason != "":
		lines.append(block_reason)
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
	var parts: PackedStringArray = []
	if choice.risk_health > 0: parts.append("-%d zdrowia" % choice.risk_health)
	if choice.risk_hunger_delta != 0: parts.append("%+d sytości" % choice.risk_hunger_delta)
	if choice.risk_thirst_delta != 0: parts.append("%+d nawodnienia" % choice.risk_thirst_delta)
	if choice.risk_warmth_delta != 0: parts.append("%+d ciepła" % choice.risk_warmth_delta)
	if choice.risk_food_gain != 0: parts.append("%+d jedzenia" % choice.risk_food_gain)
	if choice.risk_water_gain != 0: parts.append("%+d wody" % choice.risk_water_gain)
	if choice.risk_wood_gain != 0: parts.append("%+d drewna" % choice.risk_wood_gain)
	if choice.risk_materials_gain != 0: parts.append("%+d kamienia" % choice.risk_materials_gain)
	if choice.risk_next_day_energy_delta != 0: parts.append("%+d energii jutro" % choice.risk_next_day_energy_delta)
	return ", ".join(parts) if not parts.is_empty() else "brak efektu"


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
		var monster_parts: PackedStringArray = []
		if monster.damage_to_player > 0:
			monster_parts.append("-%d zdrowia" % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			monster_parts.append("-%d HP budynku" % monster.damage_to_buildings)
		return ", ".join(monster_parts) if not monster_parts.is_empty() else "atak bez obrażeń"
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
	var event_parts := _stat_delta_parts(
		health_delta, event.hunger_delta, event.thirst_delta, warmth_delta,
		event.food_delta, event.water_delta, event.wood_delta, event.materials_delta,
		event.next_day_energy_delta
	)
	return ", ".join(event_parts) if not event_parts.is_empty() else "brak zmian"


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
	if state.bum_happened and state.disaster != null:
		hunger_decay += int(state.disaster.get("act2_hunger_decay_delta"))
		thirst_decay += int(state.disaster.get("act2_thirst_decay_delta"))
		warmth_decay += int(state.disaster.get("act2_warmth_decay_delta"))
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
			var choice_button := button as Button
			choice_button.disabled = str(choice_button.get_meta("choice_block_reason", "")) != ""
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
	, "hand")
	_refresh_playability()


## Used-up gather actions drop out of the list (see available_gather_actions),
## so playing one removes its card rather than just disabling it.
func _on_gather_actions_changed(_actions: Array[ActionCardData]) -> void:
	var cards: Array[CardData] = []
	for action in _survival.available_gather_actions().slice(0, MAX_GATHER_CARD_VIEWS):
		cards.append(action)
	_rebuild_cards(_gather_container, cards, func(_i: int, card: CardData) -> void:
		_survival.play_gather(card as ActionCardData)
	, "gather")
	_refresh_playability()


func _rebuild_cards(
	container: HBoxContainer, cards: Array[CardData], on_pressed: Callable, source: String = ""
) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for i in cards.size():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		container.add_child(view)
		view.setup(cards[i], "", "", _card_effect_override(cards[i]))
		var card := cards[i]
		var index := i
		if source != "":
			_setup_draggable_card(
				view, card, source, index,
				"Przeciągnij kartę na aktualny biom albo kartkę logów."
			)
		else:
			view.pressed.connect(func() -> void:
				_card_feedback_fx(card, view)
				on_pressed.call(index, card))


func _setup_draggable_card(
	view: CardView, card: CardData, source: String, index: int, hint: String
) -> void:
	view.set_drag_payload({
		"type": "play_card",
		"source": source,
		"index": index,
		"card": card,
		"card_id": card.id,
	})
	view.card_drag_started.connect(_on_card_drag_started)
	view.card_drag_finished.connect(_on_card_drag_finished)
	view.pressed.connect(func() -> void:
		if view.is_play_blocked():
			view.play_blocked_feedback()
			_on_log_message(view.block_reason())
	)
	if not view.is_play_blocked():
		view.tooltip_text = hint


func _on_card_drag_started(_payload: Dictionary) -> void:
	_dragging_play_card = true
	_set_card_drop_targets_active(true)


func _on_card_drag_finished() -> void:
	_dragging_play_card = false
	_set_card_drop_targets_active(false)


func _set_card_drop_targets_active(active: bool) -> void:
	if _log_drop_zone != null:
		_log_drop_zone.drop_enabled = active
	_log_panel_art.modulate = Color(1.12, 1.18, 0.92, 1.0) if active else Color.WHITE
	if _survival == null or _survival.state == null:
		return
	for i in _tile_buttons.size():
		_tile_buttons[i].set_drop_highlight(active and i == _survival.state.current_tile)
	if not active:
		_refresh_tiles(_survival.state)


func _on_card_dropped(payload: Dictionary, target: String, tile_index: int) -> void:
	_dragging_play_card = false
	_set_card_drop_targets_active(false)
	if target == "tile" and tile_index != _survival.state.current_tile:
		_on_log_message("Kartę możesz zagrać na aktualnym biomie.")
		return
	var drop_position := _drop_feedback_position(target, tile_index)
	_play_dragged_card(payload, drop_position)


func _drop_feedback_position(target: String, tile_index: int) -> Vector2:
	if target == "tile" and tile_index >= 0 and tile_index < _tile_buttons.size():
		return _tile_buttons[tile_index].get_global_rect().get_center()
	return _log_panel.get_global_rect().get_center()


func _play_dragged_card(payload: Dictionary, feedback_position: Vector2) -> void:
	var source := str(payload.get("source", ""))
	if _build_mode and source != "build":
		_on_log_message("Najpierw zamknij tryb budowania, żeby zagrać kartę.")
		return
	match source:
		"hand":
			_play_dragged_hand_card(payload, feedback_position)
		"gather":
			_play_dragged_gather_card(payload, feedback_position)
		"build":
			_play_dragged_building_card(payload, feedback_position)
		_:
			_on_log_message("Nie rozpoznano przeciągniętej karty.")


func _play_dragged_hand_card(payload: Dictionary, feedback_position: Vector2) -> void:
	var index := _resolve_hand_card_index(payload)
	if index < 0:
		_on_log_message("Tej karty nie ma już w ręce.")
		return
	var card := _survival.hand[index]
	var block := _survival.can_play(card)
	if block != "":
		_on_log_message(block)
		return
	_card_feedback_fx_at(card, feedback_position)
	_survival.play_card(index)
	_tutorial_on_card_played("hand", card.id)


func _play_dragged_gather_card(payload: Dictionary, feedback_position: Vector2) -> void:
	var action := _resolve_gather_card(payload)
	if action == null:
		_on_log_message("Ta akcja biomu nie jest już dostępna.")
		return
	var block := _survival.can_play_gather(action)
	if block != "":
		_on_log_message(block)
		return
	_card_feedback_fx_at(action, feedback_position)
	_survival.play_gather(action)
	_tutorial_on_card_played("gather", action.id)


func _play_dragged_building_card(payload: Dictionary, _feedback_position: Vector2) -> void:
	var building := _resolve_building_card(payload)
	if building == null:
		_on_log_message("Ta budowla nie jest już dostępna.")
		return
	var block := _survival.can_build(building)
	if block != "":
		_on_log_message(block)
		return
	_survival.build(building)
	AudioManager.play_sfx("build")
	_spawn_tile_fx(BUILD_PLACE_FX, false)
	if _build_mode:
		_refresh_build_cards()
	_tutorial_on_card_played("build", building.id)


func _resolve_hand_card_index(payload: Dictionary) -> int:
	var index := int(payload.get("index", -1))
	var card_id := str(payload.get("card_id", ""))
	if index >= 0 and index < _survival.hand.size():
		var indexed_card := _survival.hand[index]
		if indexed_card != null and indexed_card.id == card_id:
			return index
	for i in _survival.hand.size():
		var card := _survival.hand[i]
		if card != null and card.id == card_id:
			return i
	return -1


func _resolve_gather_card(payload: Dictionary) -> ActionCardData:
	var card_id := str(payload.get("card_id", ""))
	for action in _survival.available_gather_actions():
		if action != null and action.id == card_id:
			return action
	return null


func _resolve_building_card(payload: Dictionary) -> BuildingCardData:
	var card_id := str(payload.get("card_id", ""))
	for building in _survival.available_buildings():
		if building != null and building.id == card_id:
			return building
	return null


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
		(hand_views[i] as CardView).setup(
			hand[i], _survival.can_play(hand[i]), "", _card_effect_override(hand[i])
		)
	var gathers := _survival.available_gather_actions().slice(0, MAX_GATHER_CARD_VIEWS)
	var gather_views := _gather_container.get_children()
	for i in mini(gather_views.size(), gathers.size()):
		(gather_views[i] as CardView).setup(
			gathers[i], _survival.can_play_gather(gathers[i]), "", _card_effect_override(gathers[i])
		)


func _card_effect_override(card: CardData) -> Variant:
	if card is ActionCardData:
		return _survival.action_card_effect_summary(card as ActionCardData)
	return null


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
	_energy_button.disabled = false
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
		_survival.claim_max_energy()
		_show_reward_panel()
		return
	_reward_buttons.visible = false
	_clear_card_choices()
	_level_title.text = "Wybierz kartę do talii (obecnie: %d kart)" % _survival.state.deck.size()
	for card in rewards:
		var choice_wrap := VBoxContainer.new()
		choice_wrap.custom_minimum_size = Vector2(132, 228)
		choice_wrap.add_theme_constant_override("separation", 4)
		_card_choices.add_child(choice_wrap)

		var view: CardView = CARD_VIEW_SCENE.instantiate()
		choice_wrap.add_child(view)
		view.setup(card, "", "", _card_effect_override(card))
		view.tooltip_text = "Masz w talii: %d" % _deck_count_for(card)
		view.pressed.connect(_on_reward_card_chosen.bind(card))

		var count_label := Label.new()
		count_label.text = "Masz w talii: %d" % _deck_count_for(card)
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 12)
		count_label.add_theme_color_override("font_color", Color(0.93, 0.87, 0.66, 1.0))
		choice_wrap.add_child(count_label)
	_card_choices.visible = true


func _on_reward_card_chosen(card: CardData) -> void:
	_survival.claim_card(card)
	_show_reward_panel()


func _clear_card_choices() -> void:
	for child in _card_choices.get_children():
		_card_choices.remove_child(child)
		child.queue_free()
	_card_choices.visible = false
