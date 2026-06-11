extends Control
## Run scene UI: stat bars, resources, the biome board, gather actions of
## the current tile, event log and the hand of cards. Pure view — reacts to
## SurvivalSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")

@onready var _day_label: Label = $Margin/Layout/TopBar/DayLabel
@onready var _health_label: Label = $Margin/Layout/TopBar/HealthBox/HealthLabel
@onready var _health_bar: ProgressBar = $Margin/Layout/TopBar/HealthBox/HealthBar
@onready var _hunger_label: Label = $Margin/Layout/TopBar/HungerBox/HungerLabel
@onready var _hunger_bar: ProgressBar = $Margin/Layout/TopBar/HungerBox/HungerBar
@onready var _thirst_label: Label = $Margin/Layout/TopBar/ThirstBox/ThirstLabel
@onready var _thirst_bar: ProgressBar = $Margin/Layout/TopBar/ThirstBox/ThirstBar
@onready var _warmth_label: Label = $Margin/Layout/TopBar/WarmthBox/WarmthLabel
@onready var _warmth_bar: ProgressBar = $Margin/Layout/TopBar/WarmthBox/WarmthBar
@onready var _energy_label: Label = $Margin/Layout/TopBar/EnergyBox/EnergyLabel
@onready var _energy_bar: ProgressBar = $Margin/Layout/TopBar/EnergyBox/EnergyBar
@onready var _resources_label: Label = $Margin/Layout/ResourcesLabel
@onready var _board_grid: GridContainer = $Margin/Layout/MidRow/Board
@onready var _log: RichTextLabel = $Margin/Layout/MidRow/Log
@onready var _gather_container: HBoxContainer = $Margin/Layout/GatherBar/GatherCards
@onready var _hand_container: HBoxContainer = $Margin/Layout/BottomBar/Hand
@onready var _end_day_button: Button = $Margin/Layout/BottomBar/EndDayButton

var _survival: SurvivalSystem
var _tile_buttons: Array[Button] = []


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
	_survival.log_message.connect(_on_log_message)
	_end_day_button.pressed.connect(_survival.end_day)

	_survival.begin()


func _create_tile_buttons() -> void:
	for i in BoardGenerator.BOARD_SIZE:
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 110)
		button.pressed.connect(_survival.move_to.bind(i))
		_board_grid.add_child(button)
		_tile_buttons.append(button)


func _on_day_started(day: int) -> void:
	_day_label.text = "Dzień %d/%d" % [day, SurvivalSystem.WIN_DAY]


func _on_stats_changed(state: RunState) -> void:
	_health_label.text = "Zdrowie: %d/%d" % [state.health, RunState.MAX_HEALTH]
	_health_bar.value = state.health
	_hunger_label.text = "Sytość: %d/%d" % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger
	_thirst_label.text = "Nawodnienie: %d/%d" % [state.thirst, RunState.MAX_THIRST]
	_thirst_bar.value = state.thirst
	_warmth_label.text = "Ciepło: %d/%d" % [state.warmth, RunState.MAX_WARMTH]
	_warmth_bar.value = state.warmth
	_energy_label.text = "Energia: %d/%d" % [state.energy, RunState.MAX_ENERGY]
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
		var biome_name := tile.biome.corrupted_display_name if tile.is_corrupted \
			else tile.biome.display_name
		var marker := "▶ " if i == state.current_tile else ""
		var building_names: PackedStringArray = []
		for built in tile.buildings:
			building_names.append(built.data.display_name)
		var buildings_line := ", ".join(building_names) if not building_names.is_empty() \
			else "—"
		button.text = "%s%s\nSloty: %d/%d\n%s" % [
			marker, biome_name,
			tile.buildings.size(), tile.biome.building_slots,
			buildings_line,
		]
		var block_reason := _survival.can_move(i)
		button.disabled = block_reason != ""
		if i == state.current_tile:
			button.tooltip_text = tile.biome.description
		else:
			button.tooltip_text = block_reason if block_reason != "" \
				else "Przejdź (koszt: %d energii)" % SurvivalSystem.MOVE_ENERGY_COST


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
