class_name SurvivalSystem
extends RefCounted
## The whole run on the biome board (Dzien 50): Act I (continuous days,
## four survival stats, movement between tiles, buildings as cards in tile
## slots, biome gather actions, end-of-day events), then BUM mid-run (tiles
## flip to corrupted faces, buildings take percent damage) and Act II
## (monsters in the night deck, repairs, ruins, defense buildings).
##
## This class knows NOTHING about scenes or UI — all communication goes
## through signals. UI connects to the signals, then begin() is called.

signal day_started(day: int)
signal stats_changed(state: RunState)
signal hand_changed(hand: Array[CardData])
signal board_changed(state: RunState)
## A previously hidden tile was entered and revealed.
signal tile_discovered(tile_index: int)
signal gather_actions_changed(actions: Array[ActionCardData])
## A level was gained; the player has state.pending_rewards choices waiting.
signal leveled_up(level: int)
## BUM struck this dawn: tiles flipped, buildings damaged, monsters incoming.
signal bum_struck(disaster: DisasterData)
## The card drawn for the night event, shown by UI as a card overlay.
signal night_card_drawn(card: CardData)
signal log_message(text: String)
signal run_ended(won: bool, days_survived: int)

## Full run: Act I (build up) -> BUM mid-run -> Act II (survive the disaster).
const WIN_DAY := 30
## BUM strikes at dawn of a day rolled from this range at run start.
const BUM_DAY_MIN := 13
const BUM_DAY_MAX := 16
## Each building rolls this damage percent range when BUM strikes.
const BUM_DAMAGE_PERCENT_MIN := 60
const BUM_DAMAGE_PERCENT_MAX := 80
## Scripted dawn omens start on this day (foreshadowing), so they always show
## before BUM (which strikes day 13-16) regardless of the rolled BUM day.
const OMEN_START_DAY := 7
const REPAIR_ENERGY_COST := 1
const DEMOLISH_ENERGY_COST := 1
## Building after the cataclysm is allowed but taxed — raw materials are scarce
## in Act II, so every new building costs extra energy/wood/materials. This keeps
## rebuilding possible without trivializing the disaster.
const POST_BUM_BUILD_ENERGY_SURCHARGE := 3
const POST_BUM_BUILD_WOOD_SURCHARGE := 5
const POST_BUM_BUILD_MATERIALS_SURCHARGE := 5
## Tearing down a ruin refunds about half of the build resources.
const DEMOLISH_REFUND_DIVISOR := 2
const HAND_SIZE := 4
const MOVE_ENERGY_COST := 1
const DAILY_HUNGER_DECAY := 3
const DAILY_THIRST_DECAY := 3
const DAILY_WARMTH_DECAY := 3
const SPRING_FOOD_BONUS := 1
const SUMMER_EXTRA_THIRST_DECAY := 1
const AUTUMN_WOOD_BONUS := 1
const WINTER_EXTRA_WARMTH_DECAY := 1
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
## Weighted active pool for night events (weights, cooldowns, per-run caps).
var _night_pool: NightEventPool
## Level-up card reward pool: action cards only (buildings are built from the
## always-available catalog, not drawn).
var _card_pool: Array[CardData] = []
## All buildable buildings — available any day from the build panel, paying
## resources + energy, as long as the current tile has a free slot.
var _building_catalog: Array[BuildingCardData] = []
## Generic events shared by both acts; biome/disaster extras come on top.
var _base_event_cards: Array[CardData] = []
var _day_active := false
var _ended := false
## True when this system was created via resume() rather than start().
var _resumed := false
## "<tile index>:<card id>" entries for gather actions already used today.
var _used_gathers: Dictionary = {}


func start(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData] = [],
	disaster_pool: Array[DisasterData] = [],
	catalog: Array[BuildingCardData] = [],
) -> void:
	_rng.randomize()
	state = RunState.new()
	state.character_class = character_class
	# Class max-stat tweaks (tanky/frail, more/less energy).
	state.max_health = maxi(state.max_health + character_class.health_bonus, 1)
	state.health = state.max_health
	state.max_energy = maxi(state.max_energy + character_class.max_energy_bonus, 1)
	state.energy = state.max_energy
	# Class starting resource bonuses (clamped to [0, base storage cap]).
	state.food = clampi(state.food + character_class.start_food, 0, RunState.MAX_FOOD)
	state.water = clampi(state.water + character_class.start_water, 0, RunState.MAX_WATER)
	state.wood = clampi(state.wood + character_class.start_wood, 0, RunState.MAX_WOOD)
	state.materials = clampi(state.materials + character_class.start_materials, 0, RunState.MAX_MATERIALS)
	for card in character_class.starter_deck.cards:
		state.deck.append(card)
	for card in card_pool:
		if card is ActionCardData:
			_card_pool.append(card)
	_building_catalog = catalog.duplicate()
	_base_event_cards = event_cards.duplicate()

	state.board = BoardGenerator.generate(biome_pool, _rng)
	state.current_tile = _rng.randi_range(0, state.board.size() - 1)
	current_tile().is_discovered = true

	# BUM is sealed at run start: the player never knows the type or the day.
	if not disaster_pool.is_empty():
		state.disaster = disaster_pool[_rng.randi_range(0, disaster_pool.size() - 1)]
		state.bum_day = _rng.randi_range(BUM_DAY_MIN, BUM_DAY_MAX)

	_rebuild_event_deck()


## Resume a saved run: reuse the loaded RunState and rebuild the non-persisted
## helpers (card reward pool, build catalog, night-event candidates). The board,
## deck, progression and the sealed BUM all live inside `loaded_state`. The day
## restarts from its dawn (within-day progress is not saved).
func resume(
	loaded_state: RunState,
	event_cards: Array[CardData],
	card_pool: Array[CardData] = [],
	catalog: Array[BuildingCardData] = [],
) -> void:
	_rng.randomize()
	_resumed = true
	state = loaded_state
	for card in card_pool:
		if card is ActionCardData:
			_card_pool.append(card)
	_building_catalog = catalog.duplicate()
	_base_event_cards = event_cards.duplicate()
	_rebuild_event_deck()


## Starts the current day. Separate from start()/resume() so the UI can connect
## to signals first.
func begin() -> void:
	if _resumed:
		log_message.emit("Wracasz do gry. Dzień %d z %d." % [state.day, WIN_DAY])
	else:
		log_message.emit("Budzisz się w dziczy. Przetrwaj do dnia %d." % WIN_DAY)
	_start_day()


func current_tile() -> TileState:
	return state.board[state.current_tile]


# --- Movement ---


## Effective move cost — a class trait can make wandering cheaper (min 0).
func move_energy_cost() -> int:
	return maxi(MOVE_ENERGY_COST + state.character_class.move_energy_delta, 0)


## Returns "" when the move is possible, otherwise a player-facing reason.
func can_move(tile_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if not BoardGenerator.are_adjacent(state.current_tile, tile_index):
		return "Ten kafel nie sąsiaduje z twoją pozycją."
	if state.energy < move_energy_cost():
		return "Za mało energii (potrzeba %d)." % move_energy_cost()
	return ""


func move_to(tile_index: int) -> void:
	var block_reason := can_move(tile_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	state.energy -= move_energy_cost()
	state.current_tile = tile_index
	var discovered_now := false
	if not current_tile().is_discovered:
		current_tile().is_discovered = true
		discovered_now = true
	log_message.emit("Przechodzisz do biomu: %s." % _tile_name(current_tile()))
	if discovered_now:
		log_message.emit("Odkrywasz nowy teren: %s." % _tile_name(current_tile()))
		_rebuild_event_deck()
	stats_changed.emit(state)
	board_changed.emit(state)
	if discovered_now:
		tile_discovered.emit(tile_index)
	gather_actions_changed.emit(gather_actions())


# --- Biome gather actions (available only on the current tile) ---


func gather_actions() -> Array[ActionCardData]:
	var biome := current_tile().biome
	if current_tile().is_corrupted:
		return biome.corrupted_gather_cards
	return biome.gather_cards


## Gather actions still available today (used-up ones drop out of the list so
## the UI can remove them rather than just greying them out).
func available_gather_actions() -> Array[ActionCardData]:
	var available: Array[ActionCardData] = []
	for card in gather_actions():
		if not _used_gathers.has(_gather_key(card)):
			available.append(card)
	return available


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


# --- Building maintenance (repairs and ruins, README BUM section) ---


## Wood needed to fully repair a damaged building (1 per 2 missing HP).
func repair_wood_cost(built: BuildingState) -> int:
	return ceili((building_max_hp(built.data) - built.hp) / 2.0)


## Returns "" when the building on the current tile can be repaired.
func can_repair(building_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return "Nie ma takiego budynku."
	var built := buildings[building_index]
	if built.is_ruined:
		return "To ruina — można ją tylko rozebrać."
	if built.hp >= building_max_hp(built.data):
		return "Budynek jest cały."
	if state.energy < REPAIR_ENERGY_COST:
		return "Za mało energii (potrzeba %d)." % REPAIR_ENERGY_COST
	if state.wood < repair_wood_cost(built):
		return "Za mało drewna (potrzeba %d)." % repair_wood_cost(built)
	return ""


func repair(building_index: int) -> void:
	var block_reason := can_repair(building_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	var built := current_tile().buildings[building_index]
	state.energy -= REPAIR_ENERGY_COST
	state.wood -= repair_wood_cost(built)
	built.hp = building_max_hp(built.data)
	log_message.emit("Naprawiasz: %s (HP %d/%d)." % [
		built.data.display_name, built.hp, building_max_hp(built.data)
	])
	stats_changed.emit(state)
	board_changed.emit(state)


## Returns "" when the ruin on the current tile can be torn down.
func can_demolish(building_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return "Nie ma takiego budynku."
	if not buildings[building_index].is_ruined:
		return "Budynek stoi — rozbiórka tylko dla ruin."
	if state.energy < DEMOLISH_ENERGY_COST:
		return "Za mało energii (potrzeba %d)." % DEMOLISH_ENERGY_COST
	return ""


## Tearing down a ruin frees the slot and refunds ~half the build resources.
func demolish(building_index: int) -> void:
	var block_reason := can_demolish(building_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	var built := current_tile().buildings[building_index]
	var wood_refund := floori(built.data.wood_cost / float(DEMOLISH_REFUND_DIVISOR))
	var materials_refund := floori(built.data.materials_cost / float(DEMOLISH_REFUND_DIVISOR))
	state.energy -= DEMOLISH_ENERGY_COST
	_add_wood(wood_refund)
	_add_materials(materials_refund)
	current_tile().buildings.remove_at(building_index)
	log_message.emit("Rozbierasz ruinę: %s (+%d drewna, +%d materiałów)." % [
		built.data.display_name, wood_refund, materials_refund
	])
	stats_changed.emit(state)
	board_changed.emit(state)


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


## All buildable buildings (always available — not drawn from the deck).
func building_catalog() -> Array[BuildingCardData]:
	return _building_catalog


func can_build(building: BuildingCardData) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if current_tile().buildings.size() >= current_tile().biome.building_slots:
		return "Brak wolnych slotów w tym biomie."
	return _cost_block_reason(
		_building_energy_cost(building),
		building.food_cost,
		_building_wood_cost(building),
		_building_materials_cost(building),
	)


## Effective build cost on the current tile (class discount + post-BUM surcharge),
## so the UI shows the player exactly what they will pay.
func effective_build_cost(building: BuildingCardData) -> Dictionary:
	return {
		"energy": _building_energy_cost(building),
		"food": building.food_cost,
		"wood": _building_wood_cost(building),
		"materials": _building_materials_cost(building),
	}


## Build a catalog building on the current tile (pays cost, occupies a slot).
func build(building: BuildingCardData) -> void:
	var block_reason := can_build(building)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	_build(building)
	_grant_xp(XP_PER_BUILDING)
	if _check_death():
		return
	stats_changed.emit(state)


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
	var night_card := _night_pool.draw(state.day, _night_phase())
	if night_card != null:
		night_card_drawn.emit(night_card)
	if night_card is MonsterCardData:
		_resolve_monster_attack(night_card as MonsterCardData)
	elif night_card is EventCardData:
		_resolve_event(night_card as EventCardData)
	_resolve_needs()
	stats_changed.emit(state)

	if state.health <= 0:
		_finish(false)
		return
	if state.day >= WIN_DAY:
		log_message.emit("Dzień %d. Budzisz się we własnym łóżku. To był sen?" % WIN_DAY)
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


## Up to REWARD_CHOICES distinct random cards from the reward pool
## (actions and buildings alike — a building reward is a new card to build).
func roll_card_rewards() -> Array[CardData]:
	var pool := _card_pool.duplicate()
	var result: Array[CardData] = []
	while result.size() < REWARD_CHOICES and not pool.is_empty():
		result.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))
	return result


func claim_card(card: CardData) -> void:
	if not has_pending_reward() or card == null:
		return
	state.pending_rewards -= 1
	state.deck.append(card)
	log_message.emit("Nagroda: %s dołącza do talii (%d kart)." % [
		card.display_name, state.deck.size()
	])
	stats_changed.emit(state)


func _grant_xp(amount: int) -> void:
	state.xp += maxi(int(round(amount * state.character_class.xp_multiplier)), 0)
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
	_update_season_for_day()

	if not state.bum_happened and state.disaster != null:
		if state.day >= state.bum_day:
			_trigger_bum()
		elif state.day >= OMEN_START_DAY:
			_log_omen()
	# Energy may exceed the cap by one (e.g. the Sunny Morning event).
	state.energy = clampi(
		state.max_energy + state.next_day_energy_delta, 1, state.max_energy + 1
	)
	state.next_day_energy_delta = 0

	# Passive dawn healing (a medic/hardy class trait).
	if state.character_class.daily_health_regen > 0 and state.health < state.max_health:
		var healed := mini(state.character_class.daily_health_regen, state.max_health - state.health)
		state.health += healed
		log_message.emit("Budzisz się wypoczęty. +%d zdrowia." % healed)

	# Each day starts with a fresh shuffle of the player's full deck.
	var deck_cards: Array[CardData] = []
	for card in state.deck:
		deck_cards.append(card)
	_day_deck = Deck.new(deck_cards, _rng)
	hand.clear()
	_draw_cards(HAND_SIZE + maxi(state.character_class.bonus_hand_cards, 0))

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
		if hand.size() >= HAND_SIZE:
			return
		var card := _day_deck.draw()
		if card != null:
			hand.append(card)


func _update_season_for_day() -> void:
	var next_season := _season_for_day(state.day)
	if state.day == 1 or next_season != state.season:
		state.season = next_season
		log_message.emit("Pora roku: %s. %s" % [
			RunState.season_name(state.season),
			_season_description(state.season),
		])
	else:
		state.season = next_season


func _season_for_day(day: int) -> int:
	if day <= 7:
		return RunState.Season.SPRING
	if day <= 14:
		return RunState.Season.SUMMER
	if day <= 22:
		return RunState.Season.AUTUMN
	return RunState.Season.WINTER


func _season_description(season: int) -> String:
	match season:
		RunState.Season.SPRING:
			return "Dzicz budzi sie do zycia: zbieranie jedzenia daje +1."
		RunState.Season.SUMMER:
			return "Upal wysusza gardlo: nocne pragnienie spada o 1 mocniej."
		RunState.Season.AUTUMN:
			return "Las zrzuca galezie: akcje z drewnem daja +1 drewna."
		RunState.Season.WINTER:
			return "Mroz wgryza sie w kosci: cieplo spada o 1 mocniej."
		_:
			return ""


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
	if state.season == RunState.Season.SPRING and card.food_gain > 0:
		food_gain += SPRING_FOOD_BONUS
		log_message.emit("Wiosna sprzyja zbieraniu. +%d jedzenia." % SPRING_FOOD_BONUS)
	if state.season == RunState.Season.AUTUMN and card.wood_gain > 0:
		wood_gain += AUTUMN_WOOD_BONUS
		log_message.emit("Jesien daje suche galezie. +%d drewna." % AUTUMN_WOOD_BONUS)
	_add_food(food_gain)
	_add_water(card.water_gain)
	_add_wood(wood_gain)
	_add_materials(card.materials_gain)
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
	built.hp = building_max_hp(building)
	current_tile().buildings.append(built)

	log_message.emit("Budujesz: %s (%s, slot %d/%d)." % [
		building.display_name,
		_tile_name(current_tile()),
		current_tile().buildings.size(),
		current_tile().biome.building_slots,
	])
	board_changed.emit(state)


func _building_energy_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_ENERGY_SURCHARGE if state.bum_happened else 0
	return maxi(building.energy_cost + state.character_class.build_energy_cost_delta + surcharge, 0)


## The class resource discount takes points off wood first, then materials.
func _building_wood_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_WOOD_SURCHARGE if state.bum_happened else 0
	return maxi(building.wood_cost + surcharge - state.character_class.build_resource_discount, 0)


func _building_materials_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_MATERIALS_SURCHARGE if state.bum_happened else 0
	var discount_left := maxi(
		state.character_class.build_resource_discount - building.wood_cost, 0
	)
	return maxi(building.materials_cost + surcharge - discount_left, 0)


func _resolve_explore() -> void:
	match _rng.randi_range(0, 3):
		0:
			_add_food(2)
			log_message.emit("Znajdujesz gniazdo pełne jaj. +2 jedzenia.")
		1:
			_add_wood(2)
			log_message.emit("Trafiasz na powalone drzewo. +2 drewna.")
		2:
			_add_materials(2)
			log_message.emit("Odkrywasz stary obóz. +2 materiałów.")
		3:
			_add_water(1)
			_add_food(1)
			log_message.emit("Znajdujesz deszczówkę i jagody. +1 wody, +1 jedzenia.")


# --- BUM and Act II (README sections 5-6) ---


## The catastrophe: tiles flip to their corrupted faces, every building
## rolls a damage percent (>= 50% = ruin), and the event deck is rebuilt
## with corrupted biome hazards, disaster events and monster cards.
func _trigger_bum() -> void:
	state.bum_happened = true
	log_message.emit("=== BUM ===")
	log_message.emit("Niebo pęka. %s" % state.disaster.description)

	for tile in state.board:
		tile.is_corrupted = true
		for built in tile.buildings:
			var max_hp := building_max_hp(built.data)
			var percent := _rng.randi_range(
				BUM_DAMAGE_PERCENT_MIN, BUM_DAMAGE_PERCENT_MAX
			)
			built.hp = maxi(built.hp - roundi(max_hp * percent / 100.0), 0)
			_check_ruin(built)
			if not built.is_ruined:
				log_message.emit("%s: uszkodzenia %d%% (HP %d/%d)." % [
					built.data.display_name, percent, built.hp, max_hp
				])

	_rebuild_event_deck()

	log_message.emit("Świat już nie jest ten sam. Przetrwaj do dnia %d." % WIN_DAY)
	bum_struck.emit(state.disaster)
	board_changed.emit(state)


func _rebuild_event_deck() -> void:
	if _night_pool == null:
		_night_pool = NightEventPool.new(_rng)
	# Rebuild keeps the cooldown/limit history; only the candidate set changes
	# (discovery reveals biome hazards, BUM adds disaster events + monsters).
	_night_pool.set_candidates(_event_pool())


func _event_pool() -> Array[CardData]:
	var event_pool: Array[CardData] = _base_event_cards.duplicate()
	for tile in state.board:
		if not tile.is_discovered:
			continue
		var biome_events := tile.biome.corrupted_extra_event_cards \
			if tile.is_corrupted else tile.biome.extra_event_cards
		for event in biome_events:
			event_pool.append(event)

	if state.bum_happened and state.disaster != null:
		for event in state.disaster.extra_event_cards:
			event_pool.append(event)
		# Each monster appears once; the pool weights it by copies_in_deck.
		for monster in state.disaster.monsters:
			event_pool.append(monster)
	return event_pool


## Run phase for the night pool's category weighting.
func _night_phase() -> int:
	if state.bum_happened:
		return NightEventPool.Phase.ACT2
	if state.day >= OMEN_START_DAY:
		return NightEventPool.Phase.OMEN
	return NightEventPool.Phase.ACT1


## Foreshadowing in the last days before BUM (the player senses SOMETHING).
func _log_omen() -> void:
	var omens: Array[String] = [
		"Martwe ptaki leżą pod drzewami. Żadne zwierzę ich nie tyka.",
		"Ziemia zadrżała. Na horyzoncie stoi zielonkawa łuna.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Zwierzyna ucichła. Las wstrzymuje oddech.",
	]
	log_message.emit("Omen: %s" % omens[state.day % omens.size()])


## A monster card drawn at night: it claws the player and one building,
## then shuffles back into the event deck (monsters don't go away).
func _resolve_monster_attack(monster: MonsterCardData) -> void:
	log_message.emit("Potwór: %s — %s" % [monster.display_name, monster.description])

	var player_damage := maxi(
		monster.damage_to_player - state.character_class.monster_damage_reduction, 0
	)
	# A standing Szalas shields the player from night attacks too — until
	# monsters or BUM turn it into a ruin.
	if player_damage > 0 and _has_night_protection():
		player_damage = maxi(player_damage - NIGHT_PROTECTION_VALUE, 0)
		log_message.emit("Szałas osłania cię przed atakiem.")
	if player_damage > 0:
		state.health = maxi(state.health - player_damage, 0)
		log_message.emit("%s rani cię. -%d zdrowia." % [monster.display_name, player_damage])

	if monster.damage_to_buildings > 0:
		_monster_attack_building(monster)

	# The pool handles recurrence via weight; nothing to discard.
	board_changed.emit(state)


## The monster picks a random standing building; the summed defense of
## standing buildings on that tile (Palisada...) soaks part of the damage.
func _monster_attack_building(monster: MonsterCardData) -> void:
	var standing: Array = []
	var tiles: Array[TileState] = []
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined:
				standing.append(built)
				tiles.append(tile)
	if standing.is_empty():
		return

	var pick := _rng.randi_range(0, standing.size() - 1)
	var target: BuildingState = standing[pick]
	var damage := maxi(monster.damage_to_buildings - _tile_defense(tiles[pick]), 0)
	if damage <= 0:
		log_message.emit("Palisada odpiera atak na %s." % target.data.display_name)
		return
	target.hp = maxi(target.hp - damage, 0)
	log_message.emit("%s niszczy %s (-%d HP, zostało %d/%d)." % [
		monster.display_name, target.data.display_name, damage,
		target.hp, building_max_hp(target.data),
	])
	_check_ruin(target)


func _tile_defense(tile: TileState) -> int:
	var defense := 0
	for built in tile.buildings:
		if not built.is_ruined:
			defense += built.data.defense
	return defense


func building_max_hp(building: BuildingCardData) -> int:
	return building.max_hp + state.character_class.building_hp_bonus


## Below 50% HP a building collapses into a ruin: passives, defense and
## specials stop working; it can only be torn down (README BUM threshold).
func _check_ruin(built: BuildingState) -> void:
	if built.is_ruined:
		return
	if built.hp * 2 < building_max_hp(built.data):
		built.is_ruined = true
		log_message.emit("%s zamienia się w RUINĘ. Możesz ją tylko rozebrać." %
			built.data.display_name)


# --- End of day ---


func _resolve_building_passives() -> void:
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var data := built.data
			_add_food(data.food_gain)
			_add_water(data.water_gain)
			_add_wood(data.wood_gain)
			_add_materials(data.materials_gain)
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
	_add_food(event.food_delta)
	_add_water(event.water_delta)
	_add_wood(event.wood_delta)
	_add_materials(event.materials_delta)
	state.next_day_energy_delta += event.next_day_energy_delta


func _has_night_protection() -> bool:
	# Building passives are global, so any standing (non-ruined) Szalas counts.
	for tile in state.board:
		for built in tile.buildings:
			if built.data.special == "night_protection" and not built.is_ruined:
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
		var hunger_dmg := _deprivation_damage(STARVATION_DAMAGE)
		state.health = maxi(state.health - hunger_dmg, 0)
		log_message.emit("Głodujesz! -%d zdrowia." % hunger_dmg)

	# Thirst: decay, then drink from stock. Summer makes water pressure harsher.
	var thirst_decay := DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta
	if state.season == RunState.Season.SUMMER:
		thirst_decay += SUMMER_EXTRA_THIRST_DECAY
		log_message.emit("Letni upal wysusza cie szybciej. -%d nawodnienia." %
			SUMMER_EXTRA_THIRST_DECAY)
	state.thirst = clampi(state.thirst - thirst_decay, 0, RunState.MAX_THIRST)
	while state.water > 0 and state.thirst <= RunState.MAX_THIRST - WATER_THIRST_VALUE:
		state.water -= 1
		state.thirst += WATER_THIRST_VALUE
		log_message.emit("Pijesz wodę (+%d nawodnienia)." % WATER_THIRST_VALUE)
	if state.thirst <= 0:
		var thirst_dmg := _deprivation_damage(DEHYDRATION_DAMAGE)
		state.health = maxi(state.health - thirst_dmg, 0)
		log_message.emit("Odwodnienie! -%d zdrowia." % thirst_dmg)

	# Warmth: nights are cold; campfires (passives, applied above) offset it.
	var warmth_decay := DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta
	if state.season == RunState.Season.WINTER:
		warmth_decay += WINTER_EXTRA_WARMTH_DECAY
		log_message.emit("Zimowa noc odbiera dodatkowe cieplo. -%d ciepla." %
			WINTER_EXTRA_WARMTH_DECAY)
	state.warmth = clampi(state.warmth - warmth_decay, 0, RunState.MAX_WARMTH)
	if state.warmth <= 0:
		var warmth_dmg := _deprivation_damage(FREEZING_DAMAGE)
		state.health = maxi(state.health - warmth_dmg, 0)
		log_message.emit("Zamarzasz! -%d zdrowia." % warmth_dmg)


## Hunger/thirst/cold bite harder after the cataclysm. In Act I (before BUM)
## deprivation deals one less point of damage, easing the early game.
func _deprivation_damage(full_damage: int) -> int:
	return full_damage if state.bum_happened else maxi(full_damage - 1, 0)


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


## Storage caps: base + bonuses from standing (non-ruined) storage buildings.
func food_cap() -> int:
	return RunState.MAX_FOOD + _cap_bonus("food")


func water_cap() -> int:
	return RunState.MAX_WATER + _cap_bonus("water")


func wood_cap() -> int:
	return RunState.MAX_WOOD + _cap_bonus("wood")


func materials_cap() -> int:
	return RunState.MAX_MATERIALS + _cap_bonus("materials")


func _cap_bonus(kind: String) -> int:
	var total := 0
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			match kind:
				"food":
					total += built.data.food_cap_bonus
				"water":
					total += built.data.water_cap_bonus
				"wood":
					total += built.data.wood_cap_bonus
				"materials":
					total += built.data.materials_cap_bonus
	return total


## Resource gains are clamped to the (building-boosted) storage cap, so the
## player can no longer hoard 100 food — surplus is wasted without storage.
func _add_food(amount: int) -> void:
	state.food = clampi(state.food + amount, 0, food_cap())


func _add_water(amount: int) -> void:
	state.water = clampi(state.water + amount, 0, water_cap())


func _add_wood(amount: int) -> void:
	state.wood = clampi(state.wood + amount, 0, wood_cap())


func _add_materials(amount: int) -> void:
	state.materials = clampi(state.materials + amount, 0, materials_cap())


func _gather_key(card: ActionCardData) -> String:
	return "%d:%s" % [state.current_tile, card.id]


func _tile_name(tile: TileState) -> String:
	if tile.is_corrupted:
		return tile.biome.corrupted_display_name
	return tile.biome.display_name
