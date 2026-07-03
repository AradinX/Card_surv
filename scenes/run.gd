extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")
const BUILDING_POPUP_VIEW_SCENE := preload("res://ui/building_popup_view.tscn")
const CONFIRM_POPUP_SCENE := preload("res://ui/confirm_popup.tscn")
const DECK_POPUP_SCENE := preload("res://ui/deck_popup.tscn")
const SECURE_POPUP_SCENE := preload("res://ui/secure_popup.tscn")
const CARD_DROP_ZONE_SCRIPT := preload("res://ui/card_drop_zone.gd")
const MAX_GATHER_CARD_VIEWS := 3
const LOG_PANEL_ACT2 := "res://assets/art/ui/panels/log_panel_act2.png"
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
## One-shot FX paths used at call sites here; the FX layers themselves live in
## RunFx (scenes/run_fx.gd). All optional — guarded by ResourceLoader.exists.
const EAT_DRINK_FX := "res://assets/art/fx/cards/fx_eat_drink_feedback.png"
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
const DESIGN_VIEWPORT := Vector2(1280, 720)
const OVERLAY_PADDING := Vector2(32, 32)
const LEVEL_PANEL_BASE := Vector2(900, 470)
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
@onready var _night_overlay: NightOverlayView = $NightEventOverlay
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
var _fx: RunFx
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
	_night_overlay.setup(_survival)
	_night_overlay.log_line.connect(_on_log_message)
	_apply_button_skin()
	_fx = RunFx.new(self, _background, _background_art)
	_fx.create_overlays()
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
		AudioManager.play_act2_music(key)
		AudioManager.stop_ambience()
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
	_night_overlay.fit(viewport_size)
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
				"body": "Przycisk w prawym dolnym rogu aktualnego kafla pozwala zabezpieczyć cały rejon na wypadek katastrofy. To kosztowna decyzja: dużo kamienia, energia i drewno za mniejsze szkody oraz wolniejsze zużycie budynków przed kryzysem. Nie musisz robić tego teraz."
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
			return _node_rect(_night_overlay.panel())
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
			_night_overlay.hide_event()
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
	var effect_text := "Efekt:\n-%d%% obrażeń w razie katastrofy\n%d%% szans na zwykłe zużycie HP przed kryzysem\nLimit: %d rejony\nZużywa się podczas katastrofy." % [
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
	_top_status_bar.set_day(day, SurvivalSystem.WIN_DAY, _survival.state.season, _survival.state.disaster if _survival.state.bum_happened else null)
	_fx.update_weather(_survival.state.season)
	_update_forecast()
	if GameManager.tutorial_mode:
		if day == 2 and _tutorial_step <= TUTORIAL_NIGHT_EVENT:
			_tutorial_set_step(TUTORIAL_DISCOVER_TILE)
		elif day >= 3 and _tutorial_step < TUTORIAL_DONE:
			_tutorial_set_step(TUTORIAL_DONE)
		else:
			_update_tutorial_panel()


func _on_stats_changed(state: RunState) -> void:
	_top_status_bar.set_day(state.day, SurvivalSystem.WIN_DAY, state.season, state.disaster if state.bum_happened else null)
	_top_status_bar.set_state(state, _survival.xp_to_next_level(), _resource_caps())
	_refresh_playability()
	_refresh_tiles(state)
	_fx.update_low_hp_vignette(state)
	_fx.update_need_warning_vignettes(state)
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
		var disaster_id := state.disaster.id if state.disaster != null else ""
		var tooltip := ""
		if not tile.is_discovered:
			tooltip = block_reason if block_reason != "" \
				else "Nieznany teren. Wejście odkryje ten kafel."
		elif i == state.current_tile:
			tooltip = tile.biome.corrupted_description_for(disaster_id) if tile.is_corrupted \
				else tile.biome.description
		else:
			tooltip = block_reason if block_reason != "" \
				else "Przejdź (koszt: %d energii)" % _survival.move_energy_cost()
		var building_tooltips: Array[String] = []
		for built in tile.buildings:
			building_tooltips.append(_building_tooltip(built, tile))
		if tile.bum_secured and not state.bum_happened:
			tooltip += "\n\nZabezpieczony rejon: -%d%% obrażeń w razie katastrofy, %d%% szans na zwykłe zużycie HP przed kryzysem. Zabezpieczenie zużyje się podczas katastrofy." % [
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
			secure_tooltip,
			disaster_id
		)
		button.set_accept_card_drops(i == state.current_tile)
	_refresh_building_actions()


func _secure_region_button_tooltip(block_reason: String) -> String:
	var lines: PackedStringArray = [
		"Zabezpiecz rejon",
		"Koszt: %s" % _survival.secure_current_tile_summary(),
		"Efekt: -%d%% obrażeń dla budynków tutaj w razie katastrofy." % SurvivalSystem.BUM_SECURE_DAMAGE_REDUCTION,
		"Przed kryzysem budynki mają tylko %d%% szans na zwykłe zużycie HP." % SurvivalSystem.ACT1_SECURED_WEAR_CHANCE_PERCENT,
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
	var directory := BIOME_CORRUPTED_BG_DIR if tile.is_corrupted else BIOME_NORMAL_BG_DIR
	if tile.is_corrupted:
		var disaster_id := _survival.state.disaster.id if _survival.state.disaster != null else ""
		if disaster_id != "":
			var disaster_path := "%s/biome_%s_%s_bg.png" % [directory, art_id, disaster_id]
			if ResourceLoader.exists(disaster_path):
				return load(disaster_path) as Texture2D
		var plague_path := "%s/biome_%s_plague_bg.png" % [directory, art_id]
		if ResourceLoader.exists(plague_path):
			return load(plague_path) as Texture2D
	else:
		var path := "%s/biome_%s_normal_bg.png" % [directory, art_id]
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

## BUM: the board background flips to its corrupted Act II face and the
## whole screen darkens for the rest of the run.
const BOARD_BG_ACT2 := "res://assets/art/board/backgrounds/bg_biome_board_act2.png"


func _on_bum_struck(disaster: DisasterData) -> void:
	var key := disaster.id if disaster != null else ""
	_act2_look = ACT2_LOOK.get(key, ACT2_LOOK["plague"])
	AudioManager.play_sfx("bum")
	AudioManager.play_act2_music(key)
	AudioManager.stop_ambience()
	_fx.play_bum_fx(_act2_look, _apply_act2_look)


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
	_log.add_theme_color_override("default_color", _act2_look["log_text"])
	_night_overlay.set_act2(_act2_look)
	_background.color = _act2_look["scrim"]
	if _confirm_popup != null:
		_confirm_popup.set_act2()
	if _secure_popup != null:
		_secure_popup.set_act2()
	if _deck_popup != null:
		_deck_popup.set_act2()


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
	_fx.spawn_world_fx(EAT_DRINK_FX, center, Vector2(220, 120))


## A one-shot FX centered on the player's current tile (build/repair/collapse).
func _spawn_tile_fx(path: String, additive: bool) -> void:
	if not ResourceLoader.exists(path):
		return
	var idx: int = _survival.state.current_tile
	if idx < 0 or idx >= _tile_buttons.size():
		return
	var rect := _tile_buttons[idx].get_global_rect()
	_fx.spawn_world_fx(path, rect.get_center(), rect.size * 1.05, additive)


func _apply_button_skin() -> void:
	var buttons := [
		_energy_button,
		_health_button,
		_card_button,
		_build_toggle_button,
		_end_day_button,
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


## Tutorial hook stays here; everything else about the night popup lives in
## NightOverlayView (ui/night_overlay_view.gd).
func _on_night_card_drawn(card: CardData) -> void:
	if GameManager.tutorial_mode and _tutorial_step == TUTORIAL_END_DAY:
		_tutorial_set_step(TUTORIAL_NIGHT_EVENT)
	if card is MonsterCardData:
		AudioManager.play_sfx("monster")
	_night_overlay.show_card(card)


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
				_fx.card_feedback_fx(card, view)
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
	_fx.card_feedback_fx_at(card, feedback_position)
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
	_fx.card_feedback_fx_at(action, feedback_position)
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
