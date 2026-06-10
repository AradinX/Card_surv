extends Control
## Run scene UI: stat bars, resources, day counter, event log, hand of cards.
## Pure view — reacts to RunSystem signals and forwards player input to it.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")

@onready var _day_label: Label = $Margin/Layout/TopBar/DayLabel
@onready var _health_label: Label = $Margin/Layout/TopBar/HealthBox/HealthLabel
@onready var _health_bar: ProgressBar = $Margin/Layout/TopBar/HealthBox/HealthBar
@onready var _hunger_label: Label = $Margin/Layout/TopBar/HungerBox/HungerLabel
@onready var _hunger_bar: ProgressBar = $Margin/Layout/TopBar/HungerBox/HungerBar
@onready var _energy_label: Label = $Margin/Layout/TopBar/EnergyBox/EnergyLabel
@onready var _energy_bar: ProgressBar = $Margin/Layout/TopBar/EnergyBox/EnergyBar
@onready var _resources_label: Label = $Margin/Layout/ResourcesLabel
@onready var _log: RichTextLabel = $Margin/Layout/Log
@onready var _hand_container: HBoxContainer = $Margin/Layout/BottomBar/Hand
@onready var _end_day_button: Button = $Margin/Layout/BottomBar/EndDayButton

var _run_system: RunSystem


func _ready() -> void:
	_run_system = GameManager.expedition.day_system if GameManager.expedition != null else null
	if _run_system == null:
		push_error("Run scene started without a prepared day; returning to menu.")
		GameManager.return_to_menu()
		return

	_health_bar.max_value = RunState.MAX_HEALTH
	_hunger_bar.max_value = RunState.MAX_HUNGER
	_energy_bar.max_value = RunState.MAX_ENERGY

	_run_system.day_started.connect(_on_day_started)
	_run_system.stats_changed.connect(_on_stats_changed)
	_run_system.hand_changed.connect(_on_hand_changed)
	_run_system.log_message.connect(_on_log_message)
	_end_day_button.pressed.connect(_run_system.end_day)

	GameManager.expedition.start_prepared_day()


func _on_day_started(day: int) -> void:
	var suffix := " — FINAŁ" if _run_system.is_finale else ""
	_day_label.text = "Dzień %d%s" % [day, suffix]


func _on_stats_changed(state: RunState) -> void:
	_health_label.text = "Zdrowie: %d/%d" % [state.health, RunState.MAX_HEALTH]
	_health_bar.value = state.health
	_hunger_label.text = "Sytość: %d/%d" % [state.hunger, RunState.MAX_HUNGER]
	_hunger_bar.value = state.hunger
	_energy_label.text = "Energia: %d/%d" % [state.energy, RunState.MAX_ENERGY]
	_energy_bar.value = state.energy
	_resources_label.text = "Jedzenie: %d   |   Drewno: %d   |   Materiały: %d   |   Schronienie: %d/%d   |   Narzędzia: %s" % [
		state.food, state.wood, state.materials,
		state.shelter_level, RunState.MAX_SHELTER,
		"TAK" if state.has_tools else "nie",
	]
	_refresh_hand_playability()


func _on_hand_changed(hand: Array[ActionCardData]) -> void:
	for child in _hand_container.get_children():
		_hand_container.remove_child(child)
		child.queue_free()
	for i in hand.size():
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		_hand_container.add_child(view)
		view.setup(hand[i], _run_system.can_play(hand[i]))
		view.pressed.connect(_run_system.play_card.bind(i))


func _refresh_hand_playability() -> void:
	# Energy/resources may change without the hand changing (e.g. Rest).
	var hand := _run_system.hand
	var views := _hand_container.get_children()
	for i in mini(views.size(), hand.size()):
		var view := views[i] as CardView
		view.setup(hand[i], _run_system.can_play(hand[i]))


func _on_log_message(text: String) -> void:
	_log.append_text(text + "\n")
