extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")

@onready var _day_label: Label = $Scroll/Margin/Layout/TopBar/DayLabel
@onready var _level_label: Label = $Scroll/Margin/Layout/TopBar/LevelLabel
@onready var _health_label: Label = $Scroll/Margin/Layout/TopBar/HealthBox/HealthLabel
@onready var _health_bar: ProgressBar = $Scroll/Margin/Layout/TopBar/HealthBox/HealthBar
@onready var _hunger_label: Label = $Scroll/Margin/Layout/TopBar/HungerBox/HungerLabel
@onready var _hunger_bar: ProgressBar = $Scroll/Margin/Layout/TopBar/HungerBox/HungerBar
@onready var _thirst_label: Label = $Scroll/Margin/Layout/TopBar/ThirstBox/ThirstLabel
@onready var _thirst_bar: ProgressBar = $Scroll/Margin/Layout/TopBar/ThirstBox/ThirstBar
@onready var _warmth_label: Label = $Scroll/Margin/Layout/TopBar/WarmthBox/WarmthLabel
@onready var _warmth_bar: ProgressBar = $Scroll/Margin/Layout/TopBar/WarmthBox/WarmthBar
@onready var _energy_label: Label = $Scroll/Margin/Layout/TopBar/EnergyBox/EnergyLabel
@onready var _energy_bar: ProgressBar = $Scroll/Margin/Layout/TopBar/EnergyBox/EnergyBar
@onready var _background: ColorRect = $Background
@onready var _resources_label: Label = $Scroll/Margin/Layout/ResourcesLabel
@onready var _board_grid: GridContainer = $Scroll/Margin/Layout/MidRow/Board
@onready var _log: RichTextLabel = $Scroll/Margin/Layout/MidRow/Log
@onready var _gather_container: HBoxContainer = $Scroll/Margin/Layout/GatherBar/GatherCards
@onready var _building_bar: HBoxContainer = $Scroll/Margin/Layout/BuildingBar
@onready var _building_actions: HBoxContainer = $Scroll/Margin/Layout/BuildingBar/BuildingActions
@onready var _hand_container: HBoxContainer = $Scroll/Margin/Layout/BottomBar/Hand
@onready var _end_day_button: Button = $Scroll/Margin/Layout/BottomBar/EndDayButton
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


func _ready() -> void:
	_survival = GameManager.survival
	if _survival == null:
		push_error("Run scene started without a survival system; returning to menu.")
		GameManager.return_to_menu()
		return

	_health_bar.max_value = RunState.MAX_HEALTH
	_hunger_bar.max_value = RunState.MAX_HUNGER
	_thirst_bar.max_value = RunState.MAX_THIRST
	_warmth_bar.max_value = RunState.MAX_WARMTH
	_energy_bar.max_value = RunState.MAX_ENERGY

	_create_tile_buttons()

	_survival.day_started.connect(_on_day_started)
	_survival.stats_changed.connect(_on_stats_changed)
	_survival.hand_changed.connect(_on_hand_changed)
	_survival.board_changed.connect(_on_board_changed)
	_survival.gather_actions_changed.connect(_on_gather_actions_changed)
	_survival.leveled_up.connect(_on_leveled_up)
	_survival.bum_struck.connect(_on_bum_struck)
	_survival.night_card_drawn.connect(_on_night_card_drawn)
	_survival.log_message.connect(_on_log_message)
	_end_day_button.pressed.connect(_survival.end_day)
	_energy_button.pressed.connect(_on_reward_energy)
	_health_button.pressed.connect(_on_reward_health)
	_card_button.pressed.connect(_on_reward_card)
	_night_continue_button.pressed.connect(_hide_night_event)

	_survival.begin()


func _create_tile_buttons() -> void:
	for i in BoardGenerator.BOARD_SIZE:
		var button := BIOME_TILE_VIEW_SCENE.instantiate() as BiomeTileView
		button.pressed.connect(_survival.move_to.bind(i))
		_board_grid.add_child(button)
		_tile_buttons.append(button)


func _on_day_started(day: int) -> void:
	_day_label.text = "Dzień %d/%d" % [day, SurvivalSystem.WIN_DAY]


func _on_stats_changed(state: RunState) -> void:
	_level_label.text = "Poziom %d\nXP %d/%d" % [
		state.level, state.xp, _survival.xp_to_next_level()
	]
	_health_label.text = "Zdrowie: %d/%d" % [state.health, state.max_health]
	_health_bar.max_value = state.max_health
	_health_bar.value = state.health
	_hunger_label.text = "Sytość: %d/%d" % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger
	_thirst_label.text = "Nawodnienie: %d/%d" % [state.thirst, RunState.MAX_THIRST]
	_thirst_bar.value = state.thirst
	_warmth_label.text = "Ciepło: %d/%d" % [state.warmth, RunState.MAX_WARMTH]
	_warmth_bar.value = state.warmth
	_energy_label.text = "Energia: %d/%d" % [state.energy, state.max_energy]
	_energy_bar.max_value = state.max_energy
	_energy_bar.value = state.energy
	_resources_label.text = "Jedzenie: %d   |   Woda: %d   |   Drewno: %d   |   Materiały: %d   |   Narzędzia: %s" % [
		state.food, state.water, state.wood, state.materials,
		"TAK" if state.has_tools else "nie",
	]
	_refresh_playability()
	_refresh_tiles(state)


func _on_board_changed(state: RunState) -> void:
	_refresh_tiles(state)


func _refresh_tiles(state: RunState) -> void:
	for i in _tile_buttons.size():
		var tile := state.board[i]
		var button := _tile_buttons[i]
		var block_reason := _survival.can_move(i)
		var tooltip := ""
		if i == state.current_tile:
			tooltip = tile.biome.corrupted_description if tile.is_corrupted \
				else tile.biome.description
		else:
			tooltip = block_reason if block_reason != "" \
				else "Przejdź (koszt: %d energii)" % SurvivalSystem.MOVE_ENERGY_COST
		button.setup(tile, i == state.current_tile, block_reason, tooltip)
	_refresh_building_actions()

## Repair/demolish buttons for buildings on the player's current tile.
func _refresh_building_actions() -> void:
	for child in _building_actions.get_children():
		_building_actions.remove_child(child)
		child.queue_free()

	var buildings := _survival.current_tile().buildings
	var any_action := false
	for i in buildings.size():
		var built := buildings[i]
		if built.is_ruined:
			var demolish_button := Button.new()
			demolish_button.text = "Rozbierz ruinę: %s" % built.data.display_name
			var demolish_block := _survival.can_demolish(i)
			demolish_button.disabled = demolish_block != ""
			demolish_button.tooltip_text = demolish_block if demolish_block != "" \
				else "Koszt: %d energii, odzysk ~połowy surowców" \
					% SurvivalSystem.DEMOLISH_ENERGY_COST
			demolish_button.pressed.connect(_survival.demolish.bind(i))
			_building_actions.add_child(demolish_button)
			any_action = true
		elif built.hp < _survival.building_max_hp(built.data):
			var repair_button := Button.new()
			repair_button.text = "Napraw: %s (%d drewna)" % [
				built.data.display_name, _survival.repair_wood_cost(built)
			]
			var repair_block := _survival.can_repair(i)
			repair_button.disabled = repair_block != ""
			repair_button.tooltip_text = repair_block if repair_block != "" \
				else "Koszt: %d energii, naprawa do pełna" \
					% SurvivalSystem.REPAIR_ENERGY_COST
			repair_button.pressed.connect(_survival.repair.bind(i))
			_building_actions.add_child(repair_button)
			any_action = true
	_building_bar.visible = any_action


## BUM: the world darkens for the rest of the run.
func _on_bum_struck(_disaster: DisasterData) -> void:
	_background.color = Color(0.04, 0.08, 0.045, 0.58)


func _on_night_card_drawn(card: CardData) -> void:
	_clear_night_card()
	var view: CardView = CARD_VIEW_SCENE.instantiate()
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


func _on_gather_actions_changed(actions: Array[ActionCardData]) -> void:
	var cards: Array[CardData] = []
	for action in actions:
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
	var gathers := _survival.gather_actions()
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
