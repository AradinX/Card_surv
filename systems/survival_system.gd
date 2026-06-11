class_name SurvivalSystem
extends RefCounted
## The whole run on the biome board (Dzien 50, Act I core): continuous days,
## four survival stats, movement between tiles (1 energy), buildings as
## cards placed into tile slots, biome gather actions, end-of-day events.
## Replaces the old node-map expedition layer.
##
## This class knows NOTHING about scenes or UI — all communication goes
## through signals. UI connects to the signals, then begin() is called.

signal day_started(day: int)
signal stats_changed(state: RunState)
signal hand_changed(hand: Array[CardData])
signal board_changed(state: RunState)
signal gather_actions_changed(actions: Array[ActionCardData])
## A level was gained; the player has state.pending_rewards choices waiting.
signal leveled_up(level: int)
signal log_message(text: String)
signal run_ended(won: bool, days_survived: int)

## Vertical-slice win condition: survive this many days (BUM extends it later).
const WIN_DAY := 15
const HAND_SIZE := 4
const MOVE_ENERGY_COST := 1
const DAILY_HUNGER_DECAY := 2
const DAILY_THIRST_DECAY := 2
const DAILY_WARMTH_DECAY := 1
const FOOD_HUNGER_VALUE := 2
const WATER_THIRST_VALUE := 2
const STARVATION_DAMAGE := 2
const DEHYDRATION_DAMAGE := 2
const FREEZING_DAMAGE := 2
const TOOLS_GAIN_BONUS := 1
## A standing "night_protection" building reduces protected events' negative
## health/warmth deltas by this many points.
const NIGHT_PROTECTION_VALUE := 2

## In-run progression: XP for actions, level-up = choice of 1 of 3 rewards.
const XP_PER_CARD := 1
const XP_PER_BUILDING := 3
const XP_BASE_COST := 8
const XP_COST_GROWTH := 4
const REWARD_CHOICES := 3
const REWARD_HEAL := 1

var state: RunState
var hand: Array[CardData] = []

var _rng := RandomNumberGenerator.new()
var _day_deck: Deck
var _event_deck: Deck
var _card_pool: Array[ActionCardData] = []
var _day_active := false
var _ended := false
## "<tile index>:<card id>" entries for gather actions already used today.
var _used_gathers: Dictionary = {}


func start(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData] = [],
) -> void:
	_rng.randomize()
	state = RunState.new()
	state.character_class = character_class
	for card in character_class.starter_deck.cards:
		state.deck.append(card)
	for card in card_pool:
		if card is ActionCardData:
			_card_pool.append(card)

	state.board = BoardGenerator.generate(biome_pool, _rng)
	state.current_tile = _rng.randi_range(0, state.board.size() - 1)

	# The board composition shapes the run: biome hazard cards join the
	# shared event deck for the whole run.
	var event_pool: Array[CardData] = event_cards.duplicate()
	for tile in state.board:
		for event in tile.biome.extra_event_cards:
			event_pool.append(event)
	_event_deck = Deck.new(event_pool, _rng)


## Starts day 1. Separate from start() so the UI can connect to signals first.
func begin() -> void:
	log_message.emit("Budzisz się w dziczy. Przetrwaj do dnia %d." % WIN_DAY)
	_start_day()


func current_tile() -> TileState:
	return state.board[state.current_tile]


# --- Movement ---


## Returns "" when the move is possible, otherwise a player-facing reason.
func can_move(tile_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if not BoardGenerator.are_adjacent(state.current_tile, tile_index):
		return "Ten kafel nie sąsiaduje z twoją pozycją."
	if state.energy < MOVE_ENERGY_COST:
		return "Za mało energii (potrzeba %d)." % MOVE_ENERGY_COST
	return ""


func move_to(tile_index: int) -> void:
	var block_reason := can_move(tile_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	state.energy -= MOVE_ENERGY_COST
	state.current_tile = tile_index
	log_message.emit("Przechodzisz do biomu: %s." % _tile_name(current_tile()))
	stats_changed.emit(state)
	board_changed.emit(state)
	gather_actions_changed.emit(gather_actions())


# --- Biome gather actions (available only on the current tile) ---


func gather_actions() -> Array[ActionCardData]:
	var biome := current_tile().biome
	if current_tile().is_corrupted:
		return biome.corrupted_gather_cards
	return biome.gather_cards


func can_play_gather(card: ActionCardData) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if _used_gathers.has(_gather_key(card)):
		return "Wykorzystane dzisiaj."
	return _cost_block_reason(
		card.energy_cost, card.food_cost, card.wood_cost, card.materials_cost
	)


func play_gather(card: ActionCardData) -> void:
	var block_reason := can_play_gather(card)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	_used_gathers[_gather_key(card)] = true
	log_message.emit("Korzystasz z okolicy: %s." % card.display_name)
	_resolve_action(card)
	_grant_xp(XP_PER_CARD)
	if _check_death():
		return
	stats_changed.emit(state)
	gather_actions_changed.emit(gather_actions())


# --- Hand cards (actions and buildings) ---


## Returns "" when the card can be played, otherwise a player-facing reason.
func can_play(card: CardData) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if card is ActionCardData:
		var action := card as ActionCardData
		if action.special == "craft_tools" and state.has_tools:
			return "Masz już narzędzia."
		return _cost_block_reason(
			action.energy_cost, action.food_cost, action.wood_cost, action.materials_cost
		)
	if card is BuildingCardData:
		var building := card as BuildingCardData
		if current_tile().buildings.size() >= current_tile().biome.building_slots:
			return "Brak wolnych slotów w tym biomie."
		return _cost_block_reason(
			_building_energy_cost(building),
			building.food_cost,
			_building_wood_cost(building),
			_building_materials_cost(building),
		)
	return "Tej karty nie da się zagrać."


func play_card(index: int) -> void:
	if not _day_active or index < 0 or index >= hand.size():
		return
	var card := hand[index]
	var block_reason := can_play(card)
	if block_reason != "":
		log_message.emit(block_reason)
		return

	hand.remove_at(index)
	if card is ActionCardData:
		_day_deck.discard(card)
		log_message.emit("Zagrywasz: %s." % card.display_name)
		_resolve_action(card as ActionCardData)
		_grant_xp(XP_PER_CARD)
	elif card is BuildingCardData:
		_build(card as BuildingCardData)
		_grant_xp(XP_PER_BUILDING)

	if _check_death():
		return
	stats_changed.emit(state)
	hand_changed.emit(hand)


func end_day() -> void:
	if not _day_active:
		return

	# Unplayed action cards go to the discard pile (buildings cycle too —
	# the deck is rebuilt from state.deck each dawn anyway).
	for card in hand:
		_day_deck.discard(card)
	hand.clear()
	hand_changed.emit(hand)

	_resolve_building_passives()
	_resolve_event(_event_deck.draw() as EventCardData)
	_resolve_needs()
	stats_changed.emit(state)

	if state.health <= 0:
		_finish(false)
		return
	if state.day >= WIN_DAY:
		log_message.emit("Dzień %d. Wciąż żyjesz. To koniec tej próby!" % WIN_DAY)
		_finish(true)
		return

	state.day += 1
	_start_day()


# --- Progression (XP, levels, 1-of-3 rewards) ---


## XP needed to reach the next level (grows with each level).
func xp_to_next_level() -> int:
	return XP_BASE_COST + XP_COST_GROWTH * (state.level - 1)


func has_pending_reward() -> bool:
	return state.pending_rewards > 0 and not _ended


func claim_max_energy() -> void:
	if not has_pending_reward():
		return
	state.pending_rewards -= 1
	state.max_energy += 1
	state.energy = mini(state.energy + 1, state.max_energy + 1)
	log_message.emit("Nagroda: +1 maks. energii (%d)." % state.max_energy)
	stats_changed.emit(state)


func claim_max_health() -> void:
	if not has_pending_reward():
		return
	state.pending_rewards -= 1
	state.max_health += 1
	state.health = mini(state.health + 1 + REWARD_HEAL, state.max_health)
	log_message.emit("Nagroda: +1 maks. zdrowia (%d)." % state.max_health)
	stats_changed.emit(state)


## Up to REWARD_CHOICES distinct random cards from the reward pool.
func roll_card_rewards() -> Array[ActionCardData]:
	var pool := _card_pool.duplicate()
	var result: Array[ActionCardData] = []
	while result.size() < REWARD_CHOICES and not pool.is_empty():
		result.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))
	return result


func claim_card(card: ActionCardData) -> void:
	if not has_pending_reward() or card == null:
		return
	state.pending_rewards -= 1
	state.deck.append(card)
	log_message.emit("Nagroda: %s dołącza do talii (%d kart)." % [
		card.display_name, state.deck.size()
	])
	stats_changed.emit(state)


func _grant_xp(amount: int) -> void:
	state.xp += amount
	while state.xp >= xp_to_next_level():
		state.xp -= xp_to_next_level()
		state.level += 1
		state.pending_rewards += 1
		log_message.emit("AWANS! Poziom %d — wybierz nagrodę." % state.level)
		leveled_up.emit(state.level)


# --- Day flow ---


func _start_day() -> void:
	_day_active = true
	_used_gathers.clear()
	# Energy may exceed the cap by one (e.g. the Sunny Morning event).
	state.energy = clampi(
		state.max_energy + state.next_day_energy_delta, 1, state.max_energy + 1
	)
	state.next_day_energy_delta = 0

	# Each day starts with a fresh shuffle of the player's full deck.
	var deck_cards: Array[CardData] = []
	for card in state.deck:
		deck_cards.append(card)
	_day_deck = Deck.new(deck_cards, _rng)
	hand.clear()
	_draw_cards(HAND_SIZE)

	log_message.emit("--- Dzień %d ---" % state.day)
	day_started.emit(state.day)
	stats_changed.emit(state)
	hand_changed.emit(hand)
	board_changed.emit(state)
	gather_actions_changed.emit(gather_actions())


func _finish(won: bool) -> void:
	if _ended:
		return
	_ended = true
	_day_active = false
	if not won:
		log_message.emit("Twoje zdrowie spadło do zera. Koniec.")
	run_ended.emit(won, state.day)


func _check_death() -> bool:
	# A card can kill you (e.g. Adrenalina at 1 HP).
	if state.health > 0:
		return false
	stats_changed.emit(state)
	_finish(false)
	return true


func _draw_cards(count: int) -> void:
	for i in count:
		var card := _day_deck.draw()
		if card != null:
			hand.append(card)


# --- Card resolution ---


func _resolve_action(card: ActionCardData) -> void:
	state.energy -= card.energy_cost
	state.food -= card.food_cost
	state.wood -= card.wood_cost
	state.materials -= card.materials_cost

	# Tools boost food/wood gains.
	var food_gain := card.food_gain
	var wood_gain := card.wood_gain
	if state.has_tools:
		if food_gain > 0:
			food_gain += TOOLS_GAIN_BONUS
		if wood_gain > 0:
			wood_gain += TOOLS_GAIN_BONUS
	state.food += food_gain
	state.water += card.water_gain
	state.wood += wood_gain
	state.materials += card.materials_gain
	_apply_stat_deltas(
		card.health_delta, card.hunger_delta, card.thirst_delta, card.warmth_delta
	)
	state.energy = clampi(state.energy + card.energy_delta, 0, state.max_energy + 1)

	match card.special:
		"craft_tools":
			state.has_tools = true
			log_message.emit("Masz narzędzia! +%d do zysku jedzenia i drewna." % TOOLS_GAIN_BONUS)
		"explore":
			_resolve_explore()
		"double_explore":
			_resolve_explore()
			_resolve_explore()
		"draw_two":
			_draw_cards(2)
			log_message.emit("Dobierasz 2 karty.")


func _build(building: BuildingCardData) -> void:
	state.energy -= _building_energy_cost(building)
	state.food -= building.food_cost
	state.wood -= _building_wood_cost(building)
	state.materials -= _building_materials_cost(building)

	var built := BuildingState.new()
	built.data = building
	built.hp = building.max_hp + state.character_class.building_hp_bonus
	current_tile().buildings.append(built)

	# A built building leaves the player's deck permanently — it lives on
	# the table from now on.
	state.deck.erase(building)

	log_message.emit("Budujesz: %s (%s, slot %d/%d)." % [
		building.display_name,
		_tile_name(current_tile()),
		current_tile().buildings.size(),
		current_tile().biome.building_slots,
	])
	board_changed.emit(state)


func _building_energy_cost(building: BuildingCardData) -> int:
	return maxi(building.energy_cost + state.character_class.build_energy_cost_delta, 0)


## The class resource discount takes points off wood first, then materials.
func _building_wood_cost(building: BuildingCardData) -> int:
	return maxi(building.wood_cost - state.character_class.build_resource_discount, 0)


func _building_materials_cost(building: BuildingCardData) -> int:
	var discount_left := maxi(
		state.character_class.build_resource_discount - building.wood_cost, 0
	)
	return maxi(building.materials_cost - discount_left, 0)


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
			state.water += 1
			state.food += 1
			log_message.emit("Znajdujesz deszczówkę i jagody. +1 wody, +1 jedzenia.")


# --- End of day ---


func _resolve_building_passives() -> void:
	for tile in state.board:
		for built in tile.buildings:
			var data := built.data
			state.food += data.food_gain
			state.water += data.water_gain
			state.wood += data.wood_gain
			state.materials += data.materials_gain
			_apply_stat_deltas(
				data.health_delta, data.hunger_delta, data.thirst_delta, data.warmth_delta
			)


func _resolve_event(event: EventCardData) -> void:
	if event == null:
		return
	log_message.emit("Zdarzenie: %s — %s" % [event.display_name, event.description])

	var health_delta := event.health_delta
	var warmth_delta := event.warmth_delta
	if event.shelter_protects and _has_night_protection():
		var mitigated_health := mini(health_delta + NIGHT_PROTECTION_VALUE, 0)
		var mitigated_warmth := mini(warmth_delta + NIGHT_PROTECTION_VALUE, 0)
		if mitigated_health != health_delta or mitigated_warmth != warmth_delta:
			log_message.emit("Szałas osłania cię przed nocą.")
		health_delta = maxi(health_delta, mitigated_health)
		warmth_delta = maxi(warmth_delta, mitigated_warmth)

	_apply_stat_deltas(health_delta, event.hunger_delta, event.thirst_delta, warmth_delta)
	state.food = maxi(state.food + event.food_delta, 0)
	state.water = maxi(state.water + event.water_delta, 0)
	state.wood = maxi(state.wood + event.wood_delta, 0)
	state.materials = maxi(state.materials + event.materials_delta, 0)
	state.next_day_energy_delta += event.next_day_energy_delta
	_event_deck.discard(event)


func _has_night_protection() -> bool:
	# Building passives are global, so any standing Szalas counts.
	for tile in state.board:
		for built in tile.buildings:
			if built.data.special == "night_protection" and built.hp > 0:
				return true
	return false


func _resolve_needs() -> void:
	# Hunger: decay, then eat from stock (class can change food efficiency).
	var hunger_decay := DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta
	var food_value := int(round(FOOD_HUNGER_VALUE * state.character_class.food_hunger_multiplier))
	state.hunger = clampi(state.hunger - hunger_decay, 0, RunState.MAX_HUNGER)
	while state.food > 0 and state.hunger <= RunState.MAX_HUNGER - food_value:
		state.food -= 1
		state.hunger += food_value
		log_message.emit("Zjadasz porcję jedzenia (+%d sytości)." % food_value)
	if state.hunger <= 0:
		state.health = maxi(state.health - STARVATION_DAMAGE, 0)
		log_message.emit("Głodujesz! -%d zdrowia." % STARVATION_DAMAGE)

	# Thirst: decay, then drink from stock.
	state.thirst = clampi(state.thirst - DAILY_THIRST_DECAY, 0, RunState.MAX_THIRST)
	while state.water > 0 and state.thirst <= RunState.MAX_THIRST - WATER_THIRST_VALUE:
		state.water -= 1
		state.thirst += WATER_THIRST_VALUE
		log_message.emit("Pijesz wodę (+%d nawodnienia)." % WATER_THIRST_VALUE)
	if state.thirst <= 0:
		state.health = maxi(state.health - DEHYDRATION_DAMAGE, 0)
		log_message.emit("Odwodnienie! -%d zdrowia." % DEHYDRATION_DAMAGE)

	# Warmth: nights are cold; campfires (passives, applied above) offset it.
	state.warmth = clampi(state.warmth - DAILY_WARMTH_DECAY, 0, RunState.MAX_WARMTH)
	if state.warmth <= 0:
		state.health = maxi(state.health - FREEZING_DAMAGE, 0)
		log_message.emit("Zamarzasz! -%d zdrowia." % FREEZING_DAMAGE)


# --- Helpers ---


func _cost_block_reason(
	energy_cost: int, food_cost: int, wood_cost: int, materials_cost: int
) -> String:
	if state.energy < energy_cost:
		return "Za mało energii (potrzeba %d)." % energy_cost
	if state.food < food_cost:
		return "Za mało jedzenia (potrzeba %d)." % food_cost
	if state.wood < wood_cost:
		return "Za mało drewna (potrzeba %d)." % wood_cost
	if state.materials < materials_cost:
		return "Za mało materiałów (potrzeba %d)." % materials_cost
	return ""


func _apply_stat_deltas(
	health_delta: int, hunger_delta: int, thirst_delta: int, warmth_delta: int
) -> void:
	state.health = clampi(state.health + health_delta, 0, state.max_health)
	state.hunger = clampi(state.hunger + hunger_delta, 0, RunState.MAX_HUNGER)
	state.thirst = clampi(state.thirst + thirst_delta, 0, RunState.MAX_THIRST)
	state.warmth = clampi(state.warmth + warmth_delta, 0, RunState.MAX_WARMTH)


func _gather_key(card: ActionCardData) -> String:
	return "%d:%s" % [state.current_tile, card.id]


func _tile_name(tile: TileState) -> String:
	if tile.is_corrupted:
		return tile.biome.corrupted_display_name
	return tile.biome.display_name
