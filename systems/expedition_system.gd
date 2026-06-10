class_name ExpeditionSystem
extends RefCounted
## Expedition-level flow: map traversal, deckbuilding (card rewards and
## removal), special-event encounters, rest nodes, win/lose conditions.
## Day-level gameplay is delegated to RunSystem instances created per node.
##
## No scene/UI knowledge — communication via signals only.

signal state_changed(state: RunState)
## A non-finale day was survived; the UI should show the map again.
signal return_to_map
signal expedition_ended(won: bool, days_survived: int)

const REWARD_CHOICES := 3
const REST_HEAL := 3

var state: RunState
## The RunSystem of the day being played (valid between prepare_day()
## and that day's day_ended).
var day_system: RunSystem

var _rng := RandomNumberGenerator.new()
var _event_deck: Deck
var _card_pool: Array[ActionCardData] = []
var _encounters: Array[EncounterData] = []
var _used_encounter_ids: Array[String] = []
var _ended := false


func start(
	starter_deck: DeckData,
	card_pool: Array[CardData],
	event_cards: Array[CardData],
	encounters: Array[EncounterData],
) -> void:
	_rng.randomize()
	state = RunState.new()
	for card in starter_deck.cards:
		if card is ActionCardData:
			state.deck.append(card)
	for card in card_pool:
		if card is ActionCardData:
			_card_pool.append(card)
	_event_deck = Deck.new(event_cards, _rng)
	_encounters = encounters
	state.map = MapGenerator.generate(_rng)
	state.current_node_id = -1
	state_changed.emit(state)


func current_node() -> MapNodeData:
	if state.current_node_id < 0:
		return null
	return state.map.get_node_by_id(state.current_node_id)


func get_available_node_ids() -> Array[int]:
	var result: Array[int] = []
	if _ended:
		return result
	var node := current_node()
	if node == null:
		for layer_node in state.map.get_layer_nodes(0):
			result.append(layer_node.id)
	else:
		result = node.next_ids.duplicate()
	return result


## Moves the player onto the node. Returns it, or null if unreachable.
func enter_node(node_id: int) -> MapNodeData:
	if not node_id in get_available_node_ids():
		return null
	state.current_node_id = node_id
	state_changed.emit(state)
	return current_node()


## Creates (but does not start) the RunSystem for the current day node, so
## the UI can connect to its signals before any of them fire.
func prepare_day() -> RunSystem:
	var node := current_node()
	var finale := node != null and node.type == MapNodeData.TYPE_FINALE
	day_system = RunSystem.new(state, _event_deck, _rng, finale)
	day_system.day_ended.connect(_on_day_ended)
	return day_system


func start_prepared_day() -> void:
	day_system.start_day()


# --- Deckbuilding ---


## Up to REWARD_CHOICES distinct random cards from the reward pool.
func roll_card_rewards() -> Array[ActionCardData]:
	var pool := _card_pool.duplicate()
	var result: Array[ActionCardData] = []
	while result.size() < REWARD_CHOICES and not pool.is_empty():
		result.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))
	return result


func add_card_to_deck(card: ActionCardData) -> void:
	state.deck.append(card)
	state_changed.emit(state)


func remove_card_from_deck(index: int) -> void:
	if index < 0 or index >= state.deck.size():
		return
	state.deck.remove_at(index)
	state_changed.emit(state)


# --- Rest nodes ---


func rest_heal() -> void:
	state.health = clampi(state.health + REST_HEAL, 0, RunState.MAX_HEALTH)
	state_changed.emit(state)


# --- Encounters ---


## Random encounter, preferring ones not seen this run.
func roll_encounter() -> EncounterData:
	var fresh: Array[EncounterData] = []
	for encounter in _encounters:
		if not encounter.id in _used_encounter_ids:
			fresh.append(encounter)
	var source := fresh if not fresh.is_empty() else _encounters
	var encounter := source[_rng.randi_range(0, source.size() - 1)]
	_used_encounter_ids.append(encounter.id)
	return encounter


## An option is unavailable if it would drive any resource below zero
## (negative resource deltas are the option's price).
func can_choose_option(option: EncounterOptionData) -> bool:
	return (
		state.food + option.food_delta >= 0
		and state.wood + option.wood_delta >= 0
		and state.materials + option.materials_delta >= 0
	)


func apply_encounter_option(option: EncounterOptionData) -> void:
	if _ended or not can_choose_option(option):
		return
	state.health = clampi(state.health + option.health_delta, 0, RunState.MAX_HEALTH)
	state.hunger = clampi(state.hunger + option.hunger_delta, 0, RunState.MAX_HUNGER)
	state.food += option.food_delta
	state.wood += option.wood_delta
	state.materials += option.materials_delta
	state_changed.emit(state)
	if state.health <= 0:
		_finish(false)


# --- End conditions ---


func _on_day_ended(survived: bool) -> void:
	if not survived:
		_finish(false)
		return
	var node := current_node()
	if node != null and node.type == MapNodeData.TYPE_FINALE:
		_finish(true)
		return
	return_to_map.emit()


func _finish(won: bool) -> void:
	if _ended:
		return
	_ended = true
	# On a win the day counter was already advanced past the survived day.
	var days := state.day - 1 if won else state.day
	expedition_ended.emit(won, days)
