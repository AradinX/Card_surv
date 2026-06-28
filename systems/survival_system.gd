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
## Overnight auto-eating/drinking from stock (counts of portions); UI plays a
## small feedback FX over the stat bars.
signal needs_consumed(food_eaten: int, water_drunk: int)
signal log_message(text: String)
signal run_ended(won: bool, days_survived: int)

## Full run: Act I (build up) -> BUM mid-run -> Act II (survive the disaster).
## Target length per README — Dzień 50.
const WIN_DAY := 50
## BUM strikes at dawn of a day rolled from this range at run start. Playtesters
## had a full board by ~day 10, so the cataclysm hits earlier (Act I ~2 weeks).
const BUM_DAY_MIN := 11
const BUM_DAY_MAX := 14
## Each building rolls this damage percent range when BUM strikes. A building
## survives (stays usable) only if it takes <=50% (ruin threshold), so this range
## leaves roughly a third of buildings standing into Act II instead of wiping all.
const BUM_DAMAGE_PERCENT_MIN := 35
const BUM_DAMAGE_PERCENT_MAX := 80
## Scripted dawn omens start on this day (foreshadowing), so they always show
## before BUM (which strikes day 14-18) regardless of the rolled BUM day.
const OMEN_START_DAY := 8
const REPAIR_ENERGY_COST := 1
const DEMOLISH_ENERGY_COST := 1
## Building after the cataclysm is allowed but taxed — raw materials are scarce
## in Act II, so every new building costs extra energy/wood/materials. This keeps
## rebuilding possible without trivializing the disaster.
const POST_BUM_BUILD_ENERGY_SURCHARGE := 3
const POST_BUM_BUILD_WOOD_SURCHARGE := 5
const POST_BUM_BUILD_MATERIALS_SURCHARGE := 5
## Tearing down a ruin refunds about half of the build resources; standing
## buildings return less, because some materials are lost during careful removal.
const DEMOLISH_REFUND_DIVISOR := 2
const DEMOLISH_STANDING_REFUND_DIVISOR := 4
const DAILY_BUILDING_WEAR := 1
const BUILDING_PASSIVE_WEAR := 1
const BUILDING_ACTION_WEAR := 1
const NIGHTLY_WEAR_BUILDING_IDS := ["building_campfire"]
const EVERY_OTHER_DAY_WEAR_BUILDING_IDS := [
	"building_hut",
	"building_palisade",
	"building_watchtower",
	"building_reinforced_shelter",
	"building_bastion",
]
const PASSIVE_WEAR_EXCLUDED_BUILDING_IDS := [
	"building_campfire",
	"building_hut",
	"building_palisade",
	"building_watchtower",
	"building_reinforced_shelter",
	"building_bastion",
	"building_pantry",
	"building_wood_storage",
]
const HAND_SIZE := 4
const MOVE_ENERGY_COST := 1
const DAILY_HUNGER_DECAY := 3
const DAILY_THIRST_DECAY := 3
const DAILY_WARMTH_DECAY := 3
const SPRING_FOOD_BONUS := 1
const SUMMER_EXTRA_THIRST_DECAY := 1
const AUTUMN_WOOD_BONUS := 1
const WINTER_EXTRA_WARMTH_DECAY := 1
## Winter cuts each gathered resource (food/wood/materials) by this much.
const WINTER_GATHER_PENALTY := 1
const FOOD_HUNGER_VALUE := 2
const WATER_THIRST_VALUE := 2
## Food spoilage: some surplus food spoils each day (slowed by the Kucharz's
## spoilage_multiplier and by Spiżarnia's slow_spoilage). Only bites above this
## stock, so early scarcity isn't punished.
const DAILY_FOOD_SPOILAGE := 1
const SPOILAGE_MIN_FOOD := 4
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
const MAX_ENERGY_CAP := 10

var state: RunState
var hand: Array[CardData] = []

var _rng := RandomNumberGenerator.new()
## Run summary tracking (for the end screen): seed, total HP lost, last damage
## cause, and a per-dawn health snapshot for the sparkline.
var _run_seed := 0
var _damage_taken := 0
var _last_cause := ""
var _health_history: Array[int] = []
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
## After end_day() draws the night card, effects wait here until resolve_night()
## (the player acknowledges the popup; headless callers resolve immediately).
var _night_pending := false
var _pending_night_card: CardData = null
## True once a decision event's choice (and passives) were applied via
## apply_night_choice — resolve_night then only settles needs + advances.
var _night_choice_done := false
var _ended := false
## True when this system was created via resume() rather than start().
var _resumed := false
## "<tile index>:<card id>" entries for gather actions already used today.
var _used_gathers: Dictionary = {}
## "<tile index>:<building index>:<action id>" entries for active buildings used today.
var _used_building_actions: Dictionary = {}


func start(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData] = [],
	disaster_pool: Array[DisasterData] = [],
	catalog: Array[BuildingCardData] = [],
) -> void:
	_rng.randomize()
	_run_seed = int(_rng.seed)
	_damage_taken = 0
	_last_cause = ""
	_health_history = []
	state = RunState.new()
	state.character_class = character_class
	# Class max-stat tweaks (tanky/frail, more/less energy).
	state.max_health = maxi(state.max_health + character_class.health_bonus, 1)
	state.health = state.max_health
	state.max_energy = clampi(state.max_energy + character_class.max_energy_bonus, 1, MAX_ENERGY_CAP)
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
	_resolve_action(card, "Korzystasz z okolicy")
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


## Returns "" when the building on the current tile can be torn down.
func can_demolish(building_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return "Nie ma takiego budynku."
	if state.energy < DEMOLISH_ENERGY_COST:
		return "Za mało energii (potrzeba %d)." % DEMOLISH_ENERGY_COST
	return ""


## Tearing down a building frees the slot and refunds part of build resources.
func demolish(building_index: int) -> void:
	var block_reason := can_demolish(building_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	var built := current_tile().buildings[building_index]
	var refund_divisor := DEMOLISH_REFUND_DIVISOR if built.is_ruined else DEMOLISH_STANDING_REFUND_DIVISOR
	var wood_refund := floori(built.data.wood_cost / float(refund_divisor))
	var materials_refund := floori(built.data.materials_cost / float(refund_divisor))
	state.energy -= DEMOLISH_ENERGY_COST
	_add_wood(wood_refund)
	_add_materials(materials_refund)
	current_tile().buildings.remove_at(building_index)
	log_message.emit("Rozbierasz %s: %s (+%d drewna, +%d kamienia)." % [
		"ruinę" if built.is_ruined else "budynek",
		built.data.display_name,
		wood_refund,
		materials_refund,
	])
	stats_changed.emit(state)
	board_changed.emit(state)


## Active, once-per-day interactions on selected standing buildings. Buildings
## without an action are still passive: their effects resolve at night.
func building_action(building_index: int) -> Dictionary:
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return {}
	var built := buildings[building_index]
	if built.is_ruined:
		return {}
	var action := _building_action_definition(built.data)
	if action.is_empty():
		return {}
	action["block"] = can_use_building(building_index)
	action["summary"] = _building_action_summary(action)
	return action


func can_use_building(building_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return "Nie ma takiego budynku."
	var built := buildings[building_index]
	if built.is_ruined:
		return "Ruina nie ma aktywnej akcji."
	var action := _building_action_definition(built.data)
	if action.is_empty():
		return "Ten budynek działa pasywnie."
	var key := _building_action_key(building_index, action)
	if _used_building_actions.has(key):
		return "Ta akcja budynku była już użyta dzisiaj."
	var cost_block := _cost_block_reason(
		int(action.get("cost_energy", 0)),
		int(action.get("cost_food", 0)),
		int(action.get("cost_wood", 0)),
		int(action.get("cost_materials", 0))
	)
	if cost_block != "":
		return cost_block
	if bool(action.get("tools", false)) and state.has_tools:
		return "Masz już narzędzia."
	return _building_action_capacity_block(action)


func use_building(building_index: int) -> void:
	var block_reason := can_use_building(building_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	var built := current_tile().buildings[building_index]
	var action := _building_action_definition(built.data)
	var snapshot := _action_state_snapshot()
	state.energy -= int(action.get("cost_energy", 0))
	state.food -= int(action.get("cost_food", 0))
	state.wood -= int(action.get("cost_wood", 0))
	state.materials -= int(action.get("cost_materials", 0))
	_apply_stat_deltas(
		int(action.get("health", 0)),
		int(action.get("hunger", 0)),
		int(action.get("thirst", 0)),
		int(action.get("warmth", 0))
	)
	_add_food(int(action.get("food", 0)))
	_add_water(int(action.get("water", 0)))
	_add_wood(int(action.get("wood", 0)))
	_add_materials(int(action.get("materials", 0)))
	var drawn := 0
	if int(action.get("draw_cards", 0)) > 0:
		var before_hand := hand.size()
		_draw_cards(int(action.get("draw_cards", 0)))
		drawn = hand.size() - before_hand
	if bool(action.get("tools", false)):
		state.has_tools = true
	_used_building_actions[_building_action_key(building_index, action)] = true
	var summary := _action_delta_summary(snapshot)
	if drawn > 0:
		summary += (", " if summary != "" else "") + "+%d karta do ręki" % drawn
	log_message.emit("Budynek: %s - %s%s" % [
		built.data.display_name,
		str(action.get("title", "Akcja")),
		": %s." % summary if summary != "" else ".",
	])
	_apply_building_wear(built, BUILDING_ACTION_WEAR, "Użycie zużywa %s (-%d HP)." % [
		built.data.display_name,
		BUILDING_ACTION_WEAR,
	])
	stats_changed.emit(state)
	board_changed.emit(state)
	if drawn > 0:
		hand_changed.emit(hand)


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
		var lock_reason := _biome_lock_reason(building)
		if lock_reason != "":
			return lock_reason
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
		_resolve_action(card as ActionCardData, "Zagrywasz")
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


## True if the building should SHOW in the build panel now: generic buildings
## show everywhere, biome buildings only on their matching current biome.
func is_building_available(building: BuildingCardData) -> bool:
	if building.act2_only and not state.bum_happened:
		return false
	return _biome_lock_reason(building) == ""


## Catalog filtered to what can be built on the current biome. Affordability
## still greys via can_build, but wrong-biome buildings are hidden.
func available_buildings() -> Array[BuildingCardData]:
	var out: Array[BuildingCardData] = []
	for building in _building_catalog:
		if is_building_available(building):
			out.append(building)
	return out


## Tonight's predicted needs so the UI can show it instead of the player doing
## the math: decay per stat (class + season + disaster), passive warmth from
## buildings, current supplies and how much each portion restores.
func end_of_day_forecast() -> Dictionary:
	var hunger_decay := DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta \
		+ _act2_rule("act2_hunger_decay_delta")
	var thirst_decay := DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta \
		+ _act2_rule("act2_thirst_decay_delta")
	if state.season == RunState.Season.SUMMER:
		thirst_decay += SUMMER_EXTRA_THIRST_DECAY
	var warmth_decay := DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta \
		+ _act2_rule("act2_warmth_decay_delta")
	if state.season == RunState.Season.WINTER:
		warmth_decay += WINTER_EXTRA_WARMTH_DECAY
	var passive_warmth := 0
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined:
				passive_warmth += built.data.warmth_delta
	return {
		"hunger_decay": hunger_decay,
		"thirst_decay": thirst_decay,
		"warmth_decay": warmth_decay,
		"passive_warmth": passive_warmth,
		"warmth_net": passive_warmth - warmth_decay,
		"food": state.food,
		"water": state.water,
		"food_value": int(round(FOOD_HUNGER_VALUE * state.character_class.food_hunger_multiplier)),
		"water_value": WATER_THIRST_VALUE,
	}


func can_build(building: BuildingCardData) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if building.act2_only and not state.bum_happened:
		return "Dostępne dopiero po katastrofie."
	var lock_reason := _biome_lock_reason(building)
	if lock_reason != "":
		return lock_reason
	if current_tile().buildings.size() >= current_tile().biome.building_slots:
		return "Brak wolnych slotów w tym biomie."
	return _cost_block_reason(
		_building_energy_cost(building),
		building.food_cost,
		_building_wood_cost(building),
		_building_materials_cost(building),
	)


## Biome ids -> Polish names, used only for the "needs discovery" build message.
const BIOME_DISPLAY_NAMES := {
	"forest": "Las", "meadows": "Łąki", "mountains": "Góry",
	"swamp": "Bagno", "river": "Rzeka", "wasteland": "Pustkowie",
	"caves": "Jaskinie", "coast": "Wybrzeże",
}


## "" if the building has no biome requirement or the current biome matches.
## Otherwise returns a player-facing reason naming the allowed biomes.
func _biome_lock_reason(building: BuildingCardData) -> String:
	if building.required_biome_ids.is_empty():
		return ""
	if current_tile().biome.id in building.required_biome_ids:
		return ""
	var names: PackedStringArray = []
	for biome_id in building.required_biome_ids:
		names.append(BIOME_DISPLAY_NAMES.get(biome_id, biome_id))
	return "Można budować tylko na: " + " / ".join(names)


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


## Player ends the day: discard the hand and DRAW the night event, announcing it
## via night_card_drawn — but apply nothing yet. The UI shows the card and calls
## resolve_night() once the player acknowledges it. Headless callers (bot/tests)
## call resolve_night() straight after.
func end_day() -> void:
	if not _day_active or _night_pending:
		return

	# Unplayed action cards go to the discard pile (buildings cycle too —
	# the deck is rebuilt from state.deck each dawn anyway).
	for card in hand:
		_day_deck.discard(card)
	hand.clear()
	hand_changed.emit(hand)

	_night_pending = true
	_pending_night_card = _night_pool.draw(state.day, _night_phase())
	if _pending_night_card != null:
		night_card_drawn.emit(_pending_night_card)


## Resolve the drawn night event and the day's needs, then advance (or finish).
## Called when the player acknowledges the night popup; effects land here so the
## player sees the card BEFORE the stats move. Idempotent per end_day().
## Apply ONLY a chosen option of a decision event (passives + the choice), then
## pause so the UI can show the outcome before the player confirms. Returns a
## short summary of what happened (incl. risk backfire). Call resolve_night()
## afterwards to settle needs and advance the day.
func apply_night_choice(choice_index: int) -> String:
	if not _night_pending or _night_choice_done:
		return ""
	if not (_pending_night_card is EventCardData):
		return ""
	var event := _pending_night_card as EventCardData
	if event.choices.is_empty():
		return ""
	_night_choice_done = true
	_resolve_building_passives(false)
	return _resolve_event_choice(event, choice_index)


func resolve_night(choice_index: int = 0) -> void:
	if not _night_pending:
		return
	_night_pending = false
	var night_card := _pending_night_card
	_pending_night_card = null

	# Skip card resolution if a choice (and passives) were already applied via
	# apply_night_choice — just settle needs and advance.
	if not _night_choice_done:
		_resolve_building_passives(false)
		if night_card is MonsterCardData:
			_resolve_monster_attack(night_card as MonsterCardData)
		elif night_card is EventCardData:
			var event := night_card as EventCardData
			if not event.choices.is_empty():
				_resolve_event_choice(event, choice_index)
			else:
				_resolve_event(event)
	_night_choice_done = false
	_resolve_needs()
	_resolve_scheduled_building_wear()
	stats_changed.emit(state)
	board_changed.emit(state)

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
	if state.max_energy >= MAX_ENERGY_CAP:
		log_message.emit("Maksymalna energia ma limit %d. Wybierz inną nagrodę." % MAX_ENERGY_CAP)
		return
	state.pending_rewards -= 1
	state.max_energy = mini(state.max_energy + 1, MAX_ENERGY_CAP)
	state.energy = mini(state.energy + 1, state.max_energy)
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
	_used_building_actions.clear()
	_health_history.append(state.health)
	_update_season_for_day()

	if not state.bum_happened and state.disaster != null:
		if state.day >= state.bum_day:
			_trigger_bum()
		elif state.day >= OMEN_START_DAY:
			_log_omen()
	# Hard cap at max energy (no overflow). The active disaster can sap a flat
	# amount in Act II (Zaćmienie: dark, restless nights).
	state.energy = clampi(
		state.max_energy + state.next_day_energy_delta - _act2_rule("act2_energy_penalty"),
		1, state.max_energy
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
	if day <= 13:
		return RunState.Season.SPRING
	if day <= 25:
		return RunState.Season.SUMMER
	if day <= 38:
		return RunState.Season.AUTUMN
	return RunState.Season.WINTER


func _season_description(season: int) -> String:
	match season:
		RunState.Season.SPRING:
			return "Dzicz budzi się do życia: zbieranie jedzenia daje +1."
		RunState.Season.SUMMER:
			return "Upał wysusza gardło: nocne pragnienie spada o 1 mocniej."
		RunState.Season.AUTUMN:
			return "Las zrzuca gałęzie: akcje z drewnem dają +1 drewna."
		RunState.Season.WINTER:
			return "Mróz wgryza się w kości: ciepło spada o 1 mocniej."
		_:
			return ""


# --- Card resolution ---


func _resolve_action(card: ActionCardData, log_prefix: String = "Zagrywasz") -> void:
	var snapshot: Dictionary = _action_state_snapshot()
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
		log_message.emit("Jesień daje suche gałęzie. +%d drewna." % AUTUMN_WOOD_BONUS)
	# Winter: nature gives less — every gathered resource yields one fewer.
	var materials_gain := card.materials_gain
	if state.season == RunState.Season.WINTER:
		var winter_before := food_gain + wood_gain + materials_gain
		if food_gain > 0:
			food_gain = maxi(food_gain - WINTER_GATHER_PENALTY, 0)
		if wood_gain > 0:
			wood_gain = maxi(wood_gain - WINTER_GATHER_PENALTY, 0)
		if materials_gain > 0:
			materials_gain = maxi(materials_gain - WINTER_GATHER_PENALTY, 0)
		if winter_before > food_gain + wood_gain + materials_gain:
			log_message.emit("Zima skąpi plonów — mniejszy zbiór.")
	_add_food(food_gain)
	_add_water(card.water_gain)
	_add_wood(wood_gain)
	_add_materials(materials_gain)
	_apply_stat_deltas(
		card.health_delta, card.hunger_delta, card.thirst_delta, card.warmth_delta
	)
	state.energy = clampi(state.energy + card.energy_delta, 0, state.max_energy)

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
		"scout_reveal":
			_scout_reveal()
	var summary: String = _action_delta_summary(snapshot)
	var suffix: String = "."
	if summary != "":
		suffix = ": %s." % summary
	log_message.emit("%s: %s%s" % [log_prefix, card.display_name, suffix])


func _action_state_snapshot() -> Dictionary:
	return {
		"health": state.health,
		"hunger": state.hunger,
		"thirst": state.thirst,
		"warmth": state.warmth,
		"energy": state.energy,
		"food": state.food,
		"water": state.water,
		"wood": state.wood,
		"materials": state.materials,
		"has_tools": state.has_tools,
	}


func _action_delta_summary(before: Dictionary) -> String:
	var parts: PackedStringArray = []
	_append_delta_part(parts, state.health - int(before["health"]), "zdrowia")
	_append_delta_part(parts, state.hunger - int(before["hunger"]), "sytości")
	_append_delta_part(parts, state.thirst - int(before["thirst"]), "nawodnienia")
	_append_delta_part(parts, state.warmth - int(before["warmth"]), "ciepła")
	_append_delta_part(parts, state.energy - int(before["energy"]), "energii")
	_append_delta_part(parts, state.food - int(before["food"]), "jedzenia")
	_append_delta_part(parts, state.water - int(before["water"]), "wody")
	_append_delta_part(parts, state.wood - int(before["wood"]), "drewna")
	_append_delta_part(parts, state.materials - int(before["materials"]), "kamienia")
	if not bool(before["has_tools"]) and state.has_tools:
		parts.append("narzędzia: tak")
	return ", ".join(parts)


func _append_delta_part(parts: PackedStringArray, delta: int, label: String) -> void:
	if delta != 0:
		parts.append("%+d %s" % [delta, label])


## Scout an adjacent UNDISCOVERED tile without moving there: reveals its biome
## (and arms its hazards in the night pool — info vs risk). Picks one at random.
func _building_action_definition(building: BuildingCardData) -> Dictionary:
	match building.id:
		"building_campfire":
			return {"id": "warm_up", "title": "Ogrzej się", "cost_energy": 1, "warmth": 3}
		"building_well":
			return {"id": "draw_water", "title": "Nabierz wody", "cost_energy": 1, "water": 2}
		"building_cistern":
			return {"id": "draw_water", "title": "Nabierz wody", "cost_energy": 1, "water": 3}
		"building_water_filter":
			return {"id": "filter_water", "title": "Przefiltruj wodę", "cost_energy": 1, "water": 2}
		"building_pantry":
			return {"id": "eat_ration", "title": "Zjedz zapas", "cost_energy": 1, "cost_food": 1, "hunger": 3}
		"building_workshop":
			return {"id": "craft_tools", "title": "Wykonaj narzędzia", "cost_energy": 1, "cost_wood": 1, "cost_materials": 1, "tools": true}
		"building_herbalist":
			return {"id": "brew_medicine", "title": "Użyj ziół", "cost_energy": 1, "health": 2}
		"building_field_infirmary":
			return {"id": "field_treatment", "title": "Opatrz rany", "cost_energy": 1, "health": 3}
		"building_watchtower":
			return {"id": "lookout", "title": "Wypatruj zagrożeń", "cost_energy": 1, "draw_cards": 1}
		"building_farm":
			return {"id": "harvest", "title": "Zbierz plon", "cost_energy": 1, "food": 1}
		"building_traps":
			return {"id": "check_traps", "title": "Sprawdź sidła", "cost_energy": 1, "food": 1}
		"building_fishing_dock":
			return {"id": "fish", "title": "Zarzuć sieci", "cost_energy": 1, "food": 1}
		"building_logging_camp":
			return {"id": "chop_wood", "title": "Rąb drewno", "cost_energy": 1, "wood": 1}
		"building_wood_storage":
			return {"id": "take_dry_wood", "title": "Weź suche drewno", "cost_energy": 1, "wood": 1}
		"building_quarry":
			return {"id": "mine_stone", "title": "Wydobądź kamień", "cost_energy": 1, "materials": 1}
		_:
			return {}


func _building_action_summary(action: Dictionary) -> String:
	var parts: PackedStringArray = []
	_append_cost_part(parts, int(action.get("cost_energy", 0)), "energii")
	_append_cost_part(parts, int(action.get("cost_food", 0)), "jedzenia")
	_append_cost_part(parts, int(action.get("cost_wood", 0)), "drewna")
	_append_cost_part(parts, int(action.get("cost_materials", 0)), "kamienia")
	_append_delta_part(parts, int(action.get("health", 0)), "zdrowia")
	_append_delta_part(parts, int(action.get("hunger", 0)), "sytości")
	_append_delta_part(parts, int(action.get("thirst", 0)), "nawodnienia")
	_append_delta_part(parts, int(action.get("warmth", 0)), "ciepła")
	_append_delta_part(parts, int(action.get("food", 0)), "jedzenia")
	_append_delta_part(parts, int(action.get("water", 0)), "wody")
	_append_delta_part(parts, int(action.get("wood", 0)), "drewna")
	_append_delta_part(parts, int(action.get("materials", 0)), "kamienia")
	if bool(action.get("tools", false)):
		parts.append("narzędzia: tak")
	if int(action.get("draw_cards", 0)) > 0:
		parts.append("+%d karta do ręki" % int(action.get("draw_cards", 0)))
	return ", ".join(parts)


func _append_cost_part(parts: PackedStringArray, amount: int, label: String) -> void:
	if amount > 0:
		parts.append("-%d %s" % [amount, label])


func _building_action_capacity_block(action: Dictionary) -> String:
	if int(action.get("health", 0)) > 0 and state.health >= state.max_health:
		return "Zdrowie jest już pełne."
	if int(action.get("hunger", 0)) > 0 and state.hunger >= RunState.MAX_HUNGER:
		return "Sytość jest już pełna."
	if int(action.get("thirst", 0)) > 0 and state.thirst >= RunState.MAX_THIRST:
		return "Nawodnienie jest już pełne."
	if int(action.get("warmth", 0)) > 0 and state.warmth >= RunState.MAX_WARMTH:
		return "Ciepło jest już pełne."
	if int(action.get("food", 0)) > 0 and state.food >= food_cap():
		return "Limit jedzenia jest pełny."
	if int(action.get("water", 0)) > 0 and state.water >= water_cap():
		return "Limit wody jest pełny."
	if int(action.get("wood", 0)) > 0 and state.wood >= wood_cap():
		return "Limit drewna jest pełny."
	if int(action.get("materials", 0)) > 0 and state.materials >= materials_cap():
		return "Limit kamienia jest pełny."
	if int(action.get("draw_cards", 0)) > 0 and hand.size() >= HAND_SIZE:
		return "Masz pełną rękę."
	return ""


func _building_action_key(building_index: int, action: Dictionary) -> String:
	return "%d:%d:%s" % [state.current_tile, building_index, str(action.get("id", ""))]


func _scout_reveal() -> void:
	var hidden: Array[int] = []
	for i in state.board.size():
		if BoardGenerator.are_adjacent(state.current_tile, i) and not state.board[i].is_discovered:
			hidden.append(i)
	if hidden.is_empty():
		log_message.emit("Zwiad: brak nieodkrytych sąsiednich kafli.")
		return
	var idx := hidden[_rng.randi_range(0, hidden.size() - 1)]
	state.board[idx].is_discovered = true
	_rebuild_event_deck()
	log_message.emit("Zwiad odsłania sąsiedni teren: %s." % _tile_name(state.board[idx]))
	board_changed.emit(state)
	tile_discovered.emit(idx)


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


## Post-BUM rebuild surcharge applies to NORMAL buildings only; dedicated Act II
## buildings (act2_only) are the intended rebuild path, so they skip it.
func _has_post_bum_surcharge(building: BuildingCardData) -> bool:
	return state.bum_happened and not building.act2_only


func _building_energy_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_ENERGY_SURCHARGE if _has_post_bum_surcharge(building) else 0
	return maxi(building.energy_cost + state.character_class.build_energy_cost_delta + surcharge, 0)


## The class resource discount takes points off wood first, then materials.
func _building_wood_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_WOOD_SURCHARGE if _has_post_bum_surcharge(building) else 0
	return maxi(building.wood_cost + surcharge - state.character_class.build_resource_discount, 0)


func _building_materials_cost(building: BuildingCardData) -> int:
	var surcharge := POST_BUM_BUILD_MATERIALS_SURCHARGE if _has_post_bum_surcharge(building) else 0
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
			log_message.emit("Odkrywasz stary obóz. +2 kamienia.")
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
	if state.disaster != null and state.disaster.act2_rule_text != "":
		log_message.emit(state.disaster.act2_rule_text)
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
	var tile := current_tile()
	if tile.is_discovered:
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


## Per-disaster foreshadowing lines (keyed by DisasterData.id). Plague reads as
## rot/sickness, Eclipse as cold/dark; unknown disasters fall back to plague.
const BUM_OMENS := {
	"plague": [
		"Martwe ptaki leżą pod drzewami. Żadne zwierzę ich nie tyka.",
		"Ziemia zadrżała. Na horyzoncie stoi zielonkawa łuna.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Zwierzyna ucichła. Las wstrzymuje oddech.",
	],
	"eclipse": [
		"Słońce wschodzi blade i zimne. Cień trwa dłużej niż powinien.",
		"Woda w naczyniach pokryła się rano cienkim lodem.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Ptaki odleciały na południe za wcześnie. Robi się cicho i mroźno.",
	],
	"rift": [
		"Ziemia drży coraz częściej. W skałach pojawiają się rysy.",
		"Ze szczelin w gruncie unosi się gorący, siarkowy pył.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Nocą słychać głuchy huk gdzieś w głębi ziemi.",
	],
	"flood": [
		"Rzeki wezbrały, a deszcz nie ustaje od dni.",
		"Woda podchodzi pod obóz. Grunt zamienia się w błoto.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Powietrze jest ciężkie od wilgoci. Wszystko pleśnieje.",
	],
}


## Foreshadowing in the last days before BUM (the player senses SOMETHING).
func _log_omen() -> void:
	var key := state.disaster.id if state.disaster != null else ""
	var omens: Array = BUM_OMENS.get(key, BUM_OMENS["plague"])
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
		_record_damage(player_damage, "Atak: %s" % monster.display_name)
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


func _apply_building_wear(built: BuildingState, amount: int, message: String = "") -> void:
	if built == null or built.is_ruined or amount <= 0:
		return
	built.hp = maxi(built.hp - amount, 0)
	if message != "":
		log_message.emit(message)
	_check_ruin(built)


func _resolve_scheduled_building_wear() -> void:
	var wear_logs: PackedStringArray = []
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var building_id := built.data.id
			if NIGHTLY_WEAR_BUILDING_IDS.has(building_id):
				_apply_building_wear(built, DAILY_BUILDING_WEAR)
				wear_logs.append("%s -%d HP" % [built.data.display_name, DAILY_BUILDING_WEAR])
			elif state.day % 2 == 0 and EVERY_OTHER_DAY_WEAR_BUILDING_IDS.has(building_id):
				_apply_building_wear(built, DAILY_BUILDING_WEAR)
				wear_logs.append("%s -%d HP" % [built.data.display_name, DAILY_BUILDING_WEAR])
	if not wear_logs.is_empty():
		log_message.emit("Zużycie budynków: %s." % "; ".join(wear_logs))


func _should_passive_wear(data: BuildingCardData, apply_stat_passives: bool) -> bool:
	if data == null or PASSIVE_WEAR_EXCLUDED_BUILDING_IDS.has(data.id):
		return false
	if data.food_gain != 0 or data.water_gain != 0 or data.wood_gain != 0 or data.materials_gain != 0:
		return true
	if apply_stat_passives and (
		data.health_delta != 0 or data.hunger_delta != 0
		or data.thirst_delta != 0 or data.warmth_delta != 0
	):
		return true
	return false


func _resolve_stat_passive_building_wear(stat_key: String) -> void:
	var wear_logs: PackedStringArray = []
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined or not _should_passive_wear(built.data, true):
				continue
			var value := 0
			match stat_key:
				"health":
					value = built.data.health_delta
				"hunger":
					value = built.data.hunger_delta
				"thirst":
					value = built.data.thirst_delta
				"warmth":
					value = built.data.warmth_delta
			if value == 0:
				continue
			_apply_building_wear(built, BUILDING_PASSIVE_WEAR)
			wear_logs.append("%s -%d HP" % [built.data.display_name, BUILDING_PASSIVE_WEAR])
	if not wear_logs.is_empty():
		log_message.emit("Praca budynków zużywa: %s." % "; ".join(wear_logs))


func _resolve_workshop_maintenance() -> String:
	if state.wood <= 0:
		return ""
	var target: BuildingState = null
	var target_missing_hp := 0
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var max_hp := building_max_hp(built.data)
			var missing_hp := max_hp - built.hp
			if missing_hp > target_missing_hp:
				target = built
				target_missing_hp = missing_hp
	if target == null:
		return ""
	state.wood -= 1
	target.hp = mini(target.hp + 1, building_max_hp(target.data))
	return "konserwuje %s (-1 drewna, +1 HP; %d/%d HP)" % [
		target.data.display_name,
		target.hp,
		building_max_hp(target.data),
	]


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


func _resolve_building_passives(apply_stat_passives: bool = true) -> void:
	var building_logs: PackedStringArray = []
	var wear_logs: PackedStringArray = []
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var data := built.data
			var snapshot := _action_state_snapshot()
			_add_food(data.food_gain)
			_add_water(data.water_gain)
			_add_wood(data.wood_gain)
			_add_materials(data.materials_gain)
			if apply_stat_passives:
				_apply_stat_deltas(
					data.health_delta, data.hunger_delta, data.thirst_delta, data.warmth_delta
				)
			var summary := _action_delta_summary(snapshot)
			if summary != "":
				building_logs.append("%s %s" % [data.display_name, summary])
				if _should_passive_wear(data, apply_stat_passives):
					_apply_building_wear(built, BUILDING_PASSIVE_WEAR)
					wear_logs.append("%s -%d HP" % [data.display_name, BUILDING_PASSIVE_WEAR])
			if data.special == "unlock_crafting":
				var maintenance_log := _resolve_workshop_maintenance()
				if maintenance_log != "":
					building_logs.append("%s %s" % [data.display_name, maintenance_log])
	if not building_logs.is_empty():
		log_message.emit("Budynki nocą: %s." % "; ".join(building_logs))


	if not wear_logs.is_empty():
		log_message.emit("Praca budynków zużywa: %s." % "; ".join(wear_logs))


func _standing_building_stat_passives() -> Dictionary:
	var totals := {
		"health": 0,
		"hunger": 0,
		"thirst": 0,
		"warmth": 0,
	}
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			totals["health"] += built.data.health_delta
			totals["hunger"] += built.data.hunger_delta
			totals["thirst"] += built.data.thirst_delta
			totals["warmth"] += built.data.warmth_delta
	return totals


func _stat_passive_summary(passives: Dictionary) -> String:
	var parts: PackedStringArray = []
	_append_delta_part(parts, int(passives.get("health", 0)), "zdrowia")
	_append_delta_part(parts, int(passives.get("hunger", 0)), "sytości")
	_append_delta_part(parts, int(passives.get("thirst", 0)), "nawodnienia")
	_append_delta_part(parts, int(passives.get("warmth", 0)), "ciepła")
	return ", ".join(parts)


## Counts standing (non-ruined) buildings with a given special.
func _count_special(special: String) -> int:
	var count := 0
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.data.special == special:
				count += 1
	return count


## Some surplus food spoils each day; the Kucharz and Spiżarnia (slow_spoilage)
## reduce it.
## Active disaster's Act II rule value (0 before BUM or when unset).
func _act2_rule(field: String) -> int:
	if not state.bum_happened or state.disaster == null:
		return 0
	return int(state.disaster.get(field))


func _resolve_spoilage() -> void:
	if state.food < SPOILAGE_MIN_FOOD:
		return
	var base := int(round(DAILY_FOOD_SPOILAGE * state.character_class.spoilage_multiplier))
	base += _act2_rule("act2_food_spoilage_delta")
	var spoiled := maxi(base - _count_special("slow_spoilage"), 0)
	if spoiled > 0:
		state.food = maxi(state.food - spoiled, 0)
		log_message.emit("Część zapasów się psuje. -%d jedzenia." % spoiled)


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


## Apply the player's chosen option on a decision event. A risky choice may
## backfire (gains skipped, you take risk_health damage instead). Returns a
## short PL summary of the outcome for the UI confirmation popup.
func _resolve_event_choice(event: EventCardData, choice_index: int) -> String:
	log_message.emit("Zdarzenie: %s — %s" % [event.display_name, event.description])
	var idx := clampi(choice_index, 0, event.choices.size() - 1)
	var choice := event.choices[idx]
	var backfired := choice.risk_chance > 0 and _rng.randi_range(0, 99) < choice.risk_chance
	if backfired:
		_apply_stat_deltas(-choice.risk_health, 0, 0, 0)
		if choice.risk_health > 0:
			_record_damage(choice.risk_health, "Zdarzenie: %s" % event.display_name)
		log_message.emit("Nie udało się! -%d zdrowia." % choice.risk_health)
		return "Nie udało się! −%d zdrowia." % choice.risk_health
	_apply_stat_deltas(
		choice.health_delta, choice.hunger_delta, choice.thirst_delta, choice.warmth_delta
	)
	_add_food(choice.food_gain)
	_add_water(choice.water_gain)
	_add_wood(choice.wood_gain)
	_add_materials(choice.materials_gain)
	state.next_day_energy_delta += choice.next_day_energy_delta
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
	if choice.grant_random_card and not _card_pool.is_empty():
		var card: CardData = _card_pool[_rng.randi_range(0, _card_pool.size() - 1)]
		state.deck.append(card)
		log_message.emit("Zyskujesz kartę do talii: %s." % card.display_name)
		parts.append("nowa karta: %s" % card.display_name)
	if choice.result_text != "":
		log_message.emit(choice.result_text)
	var summary := choice.result_text
	if not parts.is_empty():
		summary += "\n(" + ", ".join(parts) + ")" if summary != "" else "(" + ", ".join(parts) + ")"
	return summary if summary != "" else "Gotowe."


func _has_night_protection() -> bool:
	# Building passives are global, so any standing (non-ruined) Szalas counts.
	for tile in state.board:
		for built in tile.buildings:
			if built.data.special == "night_protection" and not built.is_ruined:
				return true
	return false


func _resolve_needs() -> void:
	# Spoilage first, so spoiled food can't be eaten tonight.
	_resolve_spoilage()
	var needs_snapshot := _action_state_snapshot()
	var stat_passives := _standing_building_stat_passives()
	var passive_summary := _stat_passive_summary(stat_passives)
	if passive_summary != "":
		log_message.emit("Budynki wspierają potrzeby nocą: %s." % passive_summary)

	var health_passive := int(stat_passives.get("health", 0))
	if health_passive != 0:
		var health_before_passive := state.health
		state.health = clampi(state.health + health_passive, 0, state.max_health)
		if state.health > health_before_passive:
			_resolve_stat_passive_building_wear("health")

	# Hunger: building passives and decay resolve as one nightly balance, then
	# food is eaten from stock (class can change food efficiency).
	var hunger_decay := DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta \
		+ _act2_rule("act2_hunger_decay_delta")
	var food_value := int(round(FOOD_HUNGER_VALUE * state.character_class.food_hunger_multiplier))
	state.hunger = clampi(
		state.hunger + int(stat_passives.get("hunger", 0)) - hunger_decay,
		0,
		RunState.MAX_HUNGER
	)
	var food_eaten := 0
	while state.food > 0 and state.hunger <= RunState.MAX_HUNGER - food_value:
		state.food -= 1
		state.hunger += food_value
		food_eaten += 1
		log_message.emit("Zjadasz porcję jedzenia (+%d sytości)." % food_value)
	if state.hunger <= 0:
		var hunger_dmg := _deprivation_damage(STARVATION_DAMAGE)
		state.health = maxi(state.health - hunger_dmg, 0)
		_record_damage(hunger_dmg, "Głód")
		log_message.emit("Sytość spadła do 0: tracisz zdrowie z głodu (-%d zdrowia)." % hunger_dmg)

	# Thirst: building passives and decay resolve together, then drink from
	# stock. Summer makes water pressure harsher.
	var thirst_decay := DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta \
		+ _act2_rule("act2_thirst_decay_delta")
	if state.season == RunState.Season.SUMMER:
		thirst_decay += SUMMER_EXTRA_THIRST_DECAY
		log_message.emit("Letni upał wysusza cię szybciej. -%d nawodnienia." %
			SUMMER_EXTRA_THIRST_DECAY)
	state.thirst = clampi(
		state.thirst + int(stat_passives.get("thirst", 0)) - thirst_decay,
		0,
		RunState.MAX_THIRST
	)
	var water_drunk := 0
	while state.water > 0 and state.thirst <= RunState.MAX_THIRST - WATER_THIRST_VALUE:
		state.water -= 1
		state.thirst += WATER_THIRST_VALUE
		water_drunk += 1
		log_message.emit("Pijesz wodę (+%d nawodnienia)." % WATER_THIRST_VALUE)
	if state.thirst <= 0:
		var thirst_dmg := _deprivation_damage(DEHYDRATION_DAMAGE)
		state.health = maxi(state.health - thirst_dmg, 0)
		_record_damage(thirst_dmg, "Odwodnienie")
		log_message.emit("Nawodnienie spadło do 0: tracisz zdrowie z odwodnienia (-%d zdrowia)." % thirst_dmg)

	# Warmth: nights are cold; campfires and other passives offset decay before
	# the max cap is applied, so +10 warmth and -3 night becomes a real +7.
	var warmth_decay := DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta \
		+ _act2_rule("act2_warmth_decay_delta")
	if state.season == RunState.Season.WINTER:
		warmth_decay += WINTER_EXTRA_WARMTH_DECAY
		log_message.emit("Zimowa noc odbiera dodatkowe ciepło. -%d ciepła." %
			WINTER_EXTRA_WARMTH_DECAY)
	state.warmth = clampi(
		state.warmth + int(stat_passives.get("warmth", 0)) - warmth_decay,
		0,
		RunState.MAX_WARMTH
	)
	if state.warmth <= 0:
		var warmth_dmg := _deprivation_damage(FREEZING_DAMAGE)
		state.health = maxi(state.health - warmth_dmg, 0)
		_record_damage(warmth_dmg, "Mróz")
		log_message.emit("Ciepło spadło do 0: tracisz zdrowie z zimna (-%d zdrowia)." % warmth_dmg)

	if food_eaten > 0 or water_drunk > 0:
		needs_consumed.emit(food_eaten, water_drunk)
	var needs_summary := _action_delta_summary(needs_snapshot)
	if needs_summary != "":
		log_message.emit("Bilans potrzeb po nocy: %s." % needs_summary)


## Hunger/thirst/cold must be a visible threat: before BUM each empty need deals
## its full damage, and after BUM it bites harder.
func _deprivation_damage(full_damage: int) -> int:
	return full_damage + 1 if state.bum_happened else full_damage


## Accumulate HP loss + remember the most recent cause (for the end screen).
func _record_damage(amount: int, cause: String) -> void:
	if amount <= 0:
		return
	_damage_taken += amount
	_last_cause = cause


## Snapshot for the end-screen summary (cause of death, totals, seed, HP graph).
func run_summary() -> Dictionary:
	var standing := 0
	var ruined := 0
	for tile in state.board:
		for built in tile.buildings:
			if built.is_ruined:
				ruined += 1
			else:
				standing += 1
	return {
		"cause": _last_cause,
		"damage_taken": _damage_taken,
		"seed": _run_seed,
		"health_history": _health_history.duplicate(),
		"buildings_standing": standing,
		"buildings_ruined": ruined,
		"level": state.level,
		"bum_day": state.bum_day if state.bum_happened else 0,
		"disaster": state.disaster.display_name if state.disaster != null else "",
	}


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
		return "Za mało kamienia (potrzeba %d)." % materials_cost
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
