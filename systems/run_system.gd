class_name RunSystem
extends RefCounted
## Core game loop for a single run: day cycle, playing action cards,
## end-of-day events, win/lose conditions.
##
## This class knows NOTHING about scenes or UI — all communication goes
## through signals. UI connects to the signals, then calls start_run().

signal day_started(day: int)
signal stats_changed(state: RunState)
signal hand_changed(hand: Array[ActionCardData])
signal log_message(text: String)
signal run_ended(won: bool, days_survived: int)

const HAND_SIZE := 4
## Starter deck = this many copies of every action card definition.
## Replace with a DeckData resource when deckbuilding lands.
const ACTION_CARD_COPIES := 2
const DAILY_HUNGER_DECAY := 3
const FOOD_HUNGER_VALUE := 2
const STARVATION_DAMAGE := 2
const TOOLS_GAIN_BONUS := 1

var state: RunState
var hand: Array[ActionCardData] = []

var _action_deck: Deck
var _event_deck: Deck
var _rng := RandomNumberGenerator.new()
var _run_over := false


func start_run(action_cards: Array[CardData], event_cards: Array[CardData]) -> void:
	_rng.randomize()
	state = RunState.new()
	_run_over = false

	var deck_cards: Array[CardData] = []
	for card in action_cards:
		for i in ACTION_CARD_COPIES:
			deck_cards.append(card)
	_action_deck = Deck.new(deck_cards, _rng)
	_event_deck = Deck.new(event_cards, _rng)

	log_message.emit("Budzisz się w dziczy. Przetrwaj %d dni." % RunState.TARGET_DAYS)
	_start_day()


## Returns "" when the card can be played, otherwise a player-facing reason.
func can_play(card: ActionCardData) -> String:
	if state.energy < card.energy_cost:
		return "Za mało energii (potrzeba %d)." % card.energy_cost
	if state.food < card.food_cost:
		return "Za mało jedzenia (potrzeba %d)." % card.food_cost
	if state.wood < card.wood_cost:
		return "Za mało drewna (potrzeba %d)." % card.wood_cost
	if state.materials < card.materials_cost:
		return "Za mało materiałów (potrzeba %d)." % card.materials_cost
	if card.special == "build_shelter" and state.shelter_level >= RunState.MAX_SHELTER:
		return "Schronienie jest już w pełni rozbudowane."
	if card.special == "craft_tools" and state.has_tools:
		return "Masz już narzędzia."
	return ""


func play_card(index: int) -> void:
	if _run_over or index < 0 or index >= hand.size():
		return
	var card := hand[index]
	var block_reason := can_play(card)
	if block_reason != "":
		log_message.emit(block_reason)
		return

	hand.remove_at(index)
	_action_deck.discard(card)

	# Pay costs.
	state.energy -= card.energy_cost
	state.food -= card.food_cost
	state.wood -= card.wood_cost
	state.materials -= card.materials_cost

	# Apply effects (tools boost food/wood gains).
	var food_gain := card.food_gain
	var wood_gain := card.wood_gain
	if state.has_tools:
		if food_gain > 0:
			food_gain += TOOLS_GAIN_BONUS
		if wood_gain > 0:
			wood_gain += TOOLS_GAIN_BONUS
	state.food += food_gain
	state.wood += wood_gain
	state.materials += card.materials_gain
	state.health = clampi(state.health + card.health_delta, 0, RunState.MAX_HEALTH)
	state.hunger = clampi(state.hunger + card.hunger_delta, 0, RunState.MAX_HUNGER)
	state.energy = clampi(state.energy + card.energy_delta, 0, RunState.MAX_ENERGY)

	log_message.emit("Zagrywasz: %s." % card.display_name)
	match card.special:
		"build_shelter":
			state.shelter_level += 1
			log_message.emit("Schronienie rozbudowane do poziomu %d." % state.shelter_level)
		"craft_tools":
			state.has_tools = true
			log_message.emit("Masz narzędzia! +%d do zysku jedzenia i drewna." % TOOLS_GAIN_BONUS)
		"explore":
			_resolve_explore()

	stats_changed.emit(state)
	hand_changed.emit(hand)


func end_day() -> void:
	if _run_over:
		return

	# Unplayed cards go to the discard pile.
	for card in hand:
		_action_deck.discard(card)
	hand.clear()

	_resolve_event(_event_deck.draw() as EventCardData)
	_resolve_hunger()
	stats_changed.emit(state)

	if state.health <= 0:
		_finish_run(false)
		return
	if state.day >= RunState.TARGET_DAYS:
		_finish_run(true)
		return

	state.day += 1
	state.energy = clampi(
		RunState.MAX_ENERGY + state.next_day_energy_delta, 1, RunState.MAX_ENERGY + 1
	)
	state.next_day_energy_delta = 0
	_start_day()


func _start_day() -> void:
	_draw_hand()
	log_message.emit("--- Dzień %d ---" % state.day)
	day_started.emit(state.day)
	stats_changed.emit(state)
	hand_changed.emit(hand)


func _draw_hand() -> void:
	hand.clear()
	for i in HAND_SIZE:
		var card := _action_deck.draw() as ActionCardData
		if card != null:
			hand.append(card)


func _resolve_event(event: EventCardData) -> void:
	if event == null:
		return
	log_message.emit("Zdarzenie: %s — %s" % [event.display_name, event.description])

	var health_delta := event.health_delta
	if event.shelter_protects and health_delta < 0 and state.shelter_level > 0:
		var mitigated := mini(health_delta + state.shelter_level, 0)
		if mitigated != health_delta:
			log_message.emit("Schronienie łagodzi skutki (%d -> %d obrażeń)." % [
				-health_delta, -mitigated
			])
		health_delta = mitigated

	state.health = clampi(state.health + health_delta, 0, RunState.MAX_HEALTH)
	state.hunger = clampi(state.hunger + event.hunger_delta, 0, RunState.MAX_HUNGER)
	state.food = maxi(state.food + event.food_delta, 0)
	state.wood = maxi(state.wood + event.wood_delta, 0)
	state.materials = maxi(state.materials + event.materials_delta, 0)
	state.next_day_energy_delta += event.next_day_energy_delta
	_event_deck.discard(event)


func _resolve_hunger() -> void:
	state.hunger = clampi(state.hunger - DAILY_HUNGER_DECAY, 0, RunState.MAX_HUNGER)
	while state.food > 0 and state.hunger <= RunState.MAX_HUNGER - FOOD_HUNGER_VALUE:
		state.food -= 1
		state.hunger += FOOD_HUNGER_VALUE
		log_message.emit("Zjadasz porcję jedzenia (+%d sytości)." % FOOD_HUNGER_VALUE)
	if state.hunger <= 0:
		state.health = maxi(state.health - STARVATION_DAMAGE, 0)
		log_message.emit("Głodujesz! -%d zdrowia." % STARVATION_DAMAGE)


func _resolve_explore() -> void:
	match _rng.randi_range(0, 3):
		0:
			state.food += 2
			log_message.emit("Znajdujesz gniazdo pełne jaj. +2 jedzenia.")
		1:
			state.wood += 2
			log_message.emit("Trafiasz na powalone drzewo. +2 drewna.")
		2:
			state.materials += 2
			log_message.emit("Odkrywasz stary obóz. +2 materiałów.")
		3:
			state.food += 1
			state.materials += 1
			log_message.emit("Znajdujesz ukryty schowek. +1 jedzenia, +1 materiałów.")


func _finish_run(won: bool) -> void:
	_run_over = true
	if won:
		log_message.emit("Przetrwałeś %d dni. Wygrana!" % RunState.TARGET_DAYS)
	else:
		log_message.emit("Twoje zdrowie spadło do zera. Koniec runu.")
	run_ended.emit(won, state.day)
