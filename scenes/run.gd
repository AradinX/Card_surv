extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const NIGHT_CARD_VIEW_SCENE := preload("res://ui/night_card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")
const MAX_GATHER_CARD_VIEWS := 3
const LOG_PANEL_ACT2 := "res://assets/art/ui/panels/log_panel_act2.png"
const LOG_TEXT_ACT2 := Color(0.82, 0.78, 0.64, 1.0)
const REPAIR_ICON := "res://assets/art/ui/icons/icon_repair_round.png"
const RUIN_ICON := "res://assets/art/ui/icons/icon_ruin_round.png"

@onready var _background: ColorRect = $Background
@onready var _background_art: TextureRect = $BackgroundArt
@onready var _top_status_bar: TopStatusBarView = $Scroll/Margin/Layout/TopStatusBar
@onready var _board_grid: GridContainer = $Scroll/Margin/Layout/MidRow/Board
@onready var _log_panel_art: TextureRect = $Scroll/Margin/Layout/MidRow/LogPanel/LogPanelArt
@onready var _log: RichTextLabel = $Scroll/Margin/Layout/MidRow/LogPanel/Log
@onready var _gather_container: HBoxContainer = $Scroll/Margin/Layout/CardsRow/GatherBar/GatherCards
@onready var _building_bar: PanelContainer = $BuildingActionPopup
@onready var _building_close_button: Button = $BuildingActionPopup/PopupMargin/VBox/Header/CloseButton
@onready var _building_actions: VBoxContainer = $BuildingActionPopup/PopupMargin/VBox/BuildingActions
@onready var _hand_container: HBoxContainer = $Scroll/Margin/Layout/CardsRow/BottomBar/Hand
@onready var _end_day_button: Button = $Scroll/Margin/Layout/CardsRow/BottomBar/EndDayButton
@onready var _level_overlay: ColorRect = $LevelUpOverlay
@onready var _level_title: Label = $LevelUpOverlay/Panel/PanelMargin/VBox/TitleLabel
@onready var _reward_buttons: HBoxContainer = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons
@onready var _energy_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/EnergyButton
@onready var _health_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/HealthButton
@onready var _card_button: Button = $LevelUpOverlay/Panel/PanelMargin/VBox/RewardButtons/CardButton
@onready var _card_choices: HBoxContainer = $LevelUpOverlay/Panel/PanelMargin/VBox/CardChoices
@onready var _night_overlay: ColorRect = $NightEventOverlay
@onready var _night_card_slot: CenterContainer = $NightEventOverlay/Panel/PanelMargin/VBox/CardSlot
@onready var _night_continue_button: Button = $NightEventOverlay/Panel/PanelMargin/VBox/ContinueButton

var _survival: SurvivalSystem
var _tile_buttons: Array[BiomeTileView] = []
var _button_act := 1
var _building_popup_requested := false


func _ready() -> void:
	_survival = GameManager.survival
	if _survival == null:
		push_error("Run scene started without a survival system; returning to menu.")
		GameManager.return_to_menu()
		return

	_top_status_bar.setup_max_values()
	_apply_button_skin()

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
	_survival.log_message.connect(_on_log_message)
	_end_day_button.pressed.connect(_on_end_day_pressed)
	_building_close_button.pressed.connect(_hide_building_popup)
	_energy_button.pressed.connect(_on_reward_energy)
	_health_button.pressed.connect(_on_reward_health)
	_card_button.pressed.connect(_on_reward_card)
	_night_continue_button.pressed.connect(_hide_night_event)

	_survival.begin()


func _create_tile_buttons() -> void:
	for i in BoardGenerator.BOARD_SIZE:
		var button := BIOME_TILE_VIEW_SCENE.instantiate() as BiomeTileView
		button.pressed.connect(_on_tile_pressed.bind(i))
		button.buildings_pressed.connect(_on_buildings_pressed.bind(i))
		_board_grid.add_child(button)
		_tile_buttons.append(button)


func _on_tile_pressed(tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_building_popup_requested = false
		_building_bar.visible = false
		_survival.move_to(tile_index)


func _on_buildings_pressed(tile_index: int) -> void:
	if tile_index != _survival.state.current_tile:
		_building_popup_requested = false
		_building_bar.visible = false
		var move_block := _survival.can_move(tile_index)
		_survival.move_to(tile_index)
		if move_block != "":
			return
	_building_popup_requested = true
	_refresh_building_actions()


func _hide_building_popup() -> void:
	_building_popup_requested = false
	_building_bar.visible = false


func _on_end_day_pressed() -> void:
	_hide_building_popup()
	_survival.end_day()


func _on_day_started(day: int) -> void:
	_top_status_bar.set_day(day, SurvivalSystem.WIN_DAY, _survival.state.season)


func _on_stats_changed(state: RunState) -> void:
	_top_status_bar.set_day(state.day, SurvivalSystem.WIN_DAY, state.season)
	_top_status_bar.set_state(state, _survival.xp_to_next_level())
	_refresh_playability()
	_refresh_tiles(state)


func _on_board_changed(state: RunState) -> void:
	_refresh_tiles(state)


func _on_tile_discovered(tile_index: int) -> void:
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
		button.setup(tile, i == state.current_tile, block_reason, tooltip)
	_refresh_building_actions()

## Repair/demolish controls for buildings on the player's current tile.
func _refresh_building_actions() -> void:
	for child in _building_actions.get_children():
		_building_actions.remove_child(child)
		child.queue_free()

	var buildings := _survival.current_tile().buildings
	if buildings.is_empty():
		_building_popup_requested = false
		_building_bar.visible = false
		return

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
		row.add_child(label)

		if built.is_ruined:
			label.text = "%s\nRUINA" % built.data.display_name
			row.add_child(_make_building_cost_label(
				"Rozbiorka: %d energii" % SurvivalSystem.DEMOLISH_ENERGY_COST
			))
			var demolish_block := _survival.can_demolish(i)
			var demolish_tooltip := demolish_block if demolish_block != "" \
				else "Koszt: %d energii, odzysk ~polowy surowcow" \
					% SurvivalSystem.DEMOLISH_ENERGY_COST
			row.add_child(_make_icon_action_button(
				RUIN_ICON,
				demolish_tooltip,
				demolish_block != "",
				_survival.demolish.bind(i)
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
			row.add_child(_make_icon_action_button(
				REPAIR_ICON,
				repair_tooltip,
				repair_block != "",
				_survival.repair.bind(i)
			))
		else:
			label.text = "%s\nHP %d/%d" % [
				built.data.display_name,
				built.hp,
				_survival.building_max_hp(built.data),
			]
			var status := Label.new()
			status.custom_minimum_size = Vector2(150, 0)
			status.text = "Niezniszczony"
			status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			status.add_theme_font_size_override("font_size", 12)
			status.add_theme_color_override("font_color", Color(0.72, 0.92, 0.58, 1.0))
			row.add_child(status)

	_building_bar.visible = _building_popup_requested


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


func _on_bum_struck(_disaster: DisasterData) -> void:
	if ResourceLoader.exists(BOARD_BG_ACT2):
		_background_art.texture = load(BOARD_BG_ACT2)
	_button_act = 2
	_apply_button_skin()
	_top_status_bar.set_act2()
	if ResourceLoader.exists(LOG_PANEL_ACT2):
		_log_panel_art.texture = load(LOG_PANEL_ACT2)
	_log.add_theme_color_override("default_color", LOG_TEXT_ACT2)
	_background.color = Color(0.04, 0.08, 0.045, 0.58)


func _apply_button_skin() -> void:
	ButtonSkin.apply_many([
		_energy_button,
		_health_button,
		_card_button,
		_end_day_button,
		_night_continue_button,
	], _button_act)
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
	var view: NightCardView = NIGHT_CARD_VIEW_SCENE.instantiate()
	_night_card_slot.add_child(view)
	view.setup(card, "")
	view.focus_mode = Control.FOCUS_NONE
	_night_overlay.visible = true


func _hide_night_event() -> void:
	_night_overlay.visible = false
	_clear_night_card()


func _clear_night_card() -> void:
	for child in _night_card_slot.get_children():
		_night_card_slot.remove_child(child)
		child.queue_free()


func _on_hand_changed(hand: Array[CardData]) -> void:
	_rebuild_cards(_hand_container, hand, func(i: int, _card: CardData) -> void:
		_survival.play_card(i))
	_refresh_playability()


## Used-up gather actions drop out of the list (see available_gather_actions),
## so playing one removes its card rather than just disabling it.
func _on_gather_actions_changed(_actions: Array[ActionCardData]) -> void:
	var cards: Array[CardData] = []
	for action in _survival.available_gather_actions().slice(0, MAX_GATHER_CARD_VIEWS):
		cards.append(action)
	_rebuild_cards(_gather_container, cards, func(_i: int, card: CardData) -> void:
		_survival.play_gather(card as ActionCardData))
	_refresh_playability()


func _rebuild_cards(
	container: HBoxContainer, cards: Array[CardData], on_pressed: Callable
) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for i in cards.size():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		container.add_child(view)
		view.setup(cards[i], "")
		view.pressed.connect(on_pressed.bind(i, cards[i]))


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
	for card in rewards:
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		_card_choices.add_child(view)
		view.setup(card, "")
		view.pressed.connect(_on_reward_card_chosen.bind(card))
	_card_choices.visible = true


func _on_reward_card_chosen(card: CardData) -> void:
	_survival.claim_card(card)
	_show_reward_panel()


func _clear_card_choices() -> void:
	for child in _card_choices.get_children():
		_card_choices.remove_child(child)
		child.queue_free()
	_card_choices.visible = false
