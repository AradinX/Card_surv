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
## BUM strikes at dawn of a day rolled from this range at run start. With
## building preparation in place, Act I has room to become a real build-up phase.
const BUM_DAY_MIN := 20
const BUM_DAY_MAX := 26
## Each building rolls this damage percent range when BUM strikes. Ruin only
## hits at 0 HP, so most buildings survive damaged rather than being wiped.
const BUM_DAMAGE_PERCENT_MIN := 35
const BUM_DAMAGE_PERCENT_MAX := 80
const BUM_SECURED_TILE_LIMIT := 2
const BUM_SECURE_BASE_ENERGY_COST := 3
const BUM_SECURE_EXTRA_ENERGY_COST := 1
const BUM_SECURE_BASE_WOOD_COST := 2
const BUM_SECURE_EXTRA_WOOD_COST := 1
const BUM_SECURE_BASE_MATERIALS_COST := 8
const BUM_SECURE_EXTRA_MATERIALS_COST := 5
const BUM_SECURE_DAMAGE_REDUCTION := 30
const BUM_DEFENSE_DAMAGE_REDUCTION_PER_POINT := 4
const BUM_DEFENSE_DAMAGE_REDUCTION_MAX := 20
const BUM_DURABILITY_BASELINE_HP := 8
const BUM_DURABILITY_DAMAGE_REDUCTION_MAX := 8
const BUM_MIN_EFFECTIVE_DAMAGE_PERCENT := 10
const ACT1_SECURED_WEAR_CHANCE_PERCENT := 60
## Scripted dawn omens start this many days before the sealed BUM day.
const BUM_OMEN_LEAD_DAYS := 6
const REPAIR_ENERGY_COST := 1
## HP restored by the "repair_tile" card verb (no wood, no slot interaction).
const REPAIR_TILE_AMOUNT := 3
const DEMOLISH_ENERGY_COST := 1
## Building after the cataclysm is allowed but taxed — raw materials are scarce
## in Act II, so every new building costs a bit extra energy/wood/materials on
## top of its (already rebalanced, see _has_post_bum_surcharge) base cost. This
## keeps rebuilding possible without trivializing the disaster. Campfire/hut are
## exempt entirely: base survival shouldn't get pricier after the cataclysm.
const POST_BUM_BUILD_ENERGY_SURCHARGE := 1
const POST_BUM_BUILD_WOOD_SURCHARGE := 2
const POST_BUM_BUILD_MATERIALS_SURCHARGE := 2
## Tearing down a ruin refunds about half of the build resources; standing
## buildings return less, because some materials are lost during careful removal.
const DEMOLISH_REFUND_DIVISOR := 2
const DEMOLISH_STANDING_REFUND_DIVISOR := 4
const DAILY_BUILDING_WEAR := 1
const BUILDING_PASSIVE_WEAR := 1
const BUILDING_ACTION_WEAR := 1
## The campfire no longer wears like a structure — its "HP" is fuel, burned by
## _resolve_campfire_fuel() once per night instead (see CAMPFIRE_* below).
## Wear cadence by building category (same rule before AND after BUM — no
## separate Act II schedule): buildings with passive income wear every day
## (this list has no day-modulo gate below, so it fires nightly), the hut is
## a deliberate exception at 2 days, and pure-defense static buildings (no
## income, no action) wear every 3 days. Reinforced Shelter (Act II upgrade of
## the hut, but has a passive warmth income) sits with the producers, not the
## hut exception — flag if that should change. Watchtower/Workshop have an
## action but NO passive income, so they're in NEITHER list below: they only
## take wear when their action is actually used (BUILDING_ACTION_WEAR in
## use_building()). Pure cap storages also stay out of scheduled wear.
## A producer that's also used that same day can lose 2 HP in one day
## (schedule + action use); that's intentional, not a bug.
const NIGHTLY_WEAR_BUILDING_IDS := [
	"building_cistern",
	"building_water_filter",
	"building_pantry",
	"building_herbalist",
	"building_field_infirmary",
	"building_farm",
	"building_fishing_dock",
	"building_logging_camp",
	"building_quarry",
	"building_reinforced_shelter",
]
const EVERY_OTHER_DAY_WEAR_BUILDING_IDS := [
	"building_hut",
]
const EVERY_THIRD_DAY_WEAR_BUILDING_IDS := [
	"building_palisade",
	"building_bastion",
]
const EVERY_FOURTH_DAY_WEAR_BUILDING_IDS: Array[String] = []
## Buildings listed here NEVER take the old "wear whenever the nightly passive
## does something" hit — all their wear comes exclusively from the scheduled
## tiers above (or, for the campfire, from burning fuel).
const PASSIVE_WEAR_EXCLUDED_BUILDING_IDS := [
	"building_campfire",
	"building_hut",
	"building_palisade",
	"building_watchtower",
	"building_reinforced_shelter",
	"building_bastion",
	"building_pantry",
	"building_wood_storage",
	"building_well",
	"building_cistern",
	"building_farm",
	"building_fishing_dock",
	"building_herbalist",
	"building_logging_camp",
	"building_quarry",
	"building_traps",
	"building_water_filter",
	"building_field_infirmary",
]
## Campfire fuel economy: hp IS remaining warmth-nights. "Dołóż drewna" adds
## fuel with no cap; "Duży ogień" is a one-night bonus on top of the base
## nightly warmth, costing wood+energy instead of touching the fuel supply.
const CAMPFIRE_FUEL_HP_PER_WOOD := 3
const CAMPFIRE_STOKE_WOOD_COST := 1
const CAMPFIRE_STOKE_ENERGY_COST := 1
const CAMPFIRE_STOKE_BONUS_WARMTH := 3
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
enum HandRole { ECONOMY, SUSTAIN, TEMPO, PAYOFF }
enum RewardNeed {
	FOOD,
	WATER,
	WOOD,
	MATERIALS,
	HEALTH,
	WARMTH,
	ENERGY,
	REPAIR,
	NIGHT,
	CONVERT,
	SYNERGY,
}
const HAND_SYNERGY_SPECIALS := ["momentum", "rhythm", "combo_food"]
const HAND_SURVIVAL_ROLES := [HandRole.ECONOMY, HandRole.SUSTAIN]
const REWARD_SYNERGY_SPECIALS := [
	"momentum", "rhythm", "combo_food",
	"draw_two", "free_move", "repair_tile", "ward_night", "set_trap",
]
const CLASS_REWARD_BIASES := {
	"cook": [RewardNeed.FOOD, RewardNeed.CONVERT, RewardNeed.WARMTH],
	"builder": [RewardNeed.WOOD, RewardNeed.MATERIALS, RewardNeed.REPAIR],
	"herbalist": [RewardNeed.HEALTH, RewardNeed.WARMTH, RewardNeed.CONVERT],
	"hunter": [RewardNeed.ENERGY, RewardNeed.NIGHT, RewardNeed.FOOD],
	"nomad": [RewardNeed.WATER, RewardNeed.FOOD, RewardNeed.ENERGY],
	"planner": [RewardNeed.SYNERGY, RewardNeed.ENERGY, RewardNeed.CONVERT],
	"scout": [RewardNeed.ENERGY, RewardNeed.MATERIALS, RewardNeed.WATER],
	"soldier": [RewardNeed.NIGHT, RewardNeed.HEALTH, RewardNeed.WARMTH],
	"informatyk": [RewardNeed.ENERGY, RewardNeed.SYNERGY, RewardNeed.CONVERT],
}
const LOW_NEED_THRESHOLD := 4
const LOW_STOCK_THRESHOLD := 1
const NIGHT_CRISIS_ENERGY_PENALTY := 1

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
## Per-day card-verb state (reset at dawn in _start_day).
## free moves banked by "free_move" cards; extra night mitigation from "ward_night";
## a one-shot monster-attack negation from "set_trap".
var _free_moves := 0
var _next_move_energy_penalty := 0
## All-day move surcharge set at dawn from last night's event (fog).
var _move_penalty_today := 0
var _extra_night_protection := 0
var _night_trap := false
## Per-turn synergy state (also reset at dawn): how many cards played today, whether
## a food card was played, and the running "momentum" energy refund per later card.
var _turn_cards_played := 0
var _turn_food_played := false
var _energy_refund_per_card := 0
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
var _tutorial_mode := false
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


## Marks this as a guided onboarding run. GameManager calls this after start()
## has loaded the same cards, buildings and biomes used by normal runs.
func configure_tutorial_run() -> void:
	_tutorial_mode = true
	state.day = 1
	state.health = state.max_health
	state.hunger = 8
	state.thirst = 8
	state.warmth = 8
	state.energy = state.max_energy
	state.food = 3
	state.water = 3
	state.wood = 4
	state.materials = 2
	state.has_tools = false
	state.next_day_energy_delta = 0
	state.bum_day = maxi(state.bum_day, BUM_DAY_MAX)
	state.bum_happened = false

	for i in state.board.size():
		state.board[i].is_discovered = false
		if state.board[i].biome != null and state.board[i].biome.id == "forest":
			state.current_tile = i
	current_tile().is_discovered = true

	var tutorial_deck := _cards_by_ids([
		"find_water", "forage", "deadfall_wood", "rest",
		"survey", "craft_tools", "bandage", "dried_meat",
	])
	if not tutorial_deck.is_empty():
		state.deck = tutorial_deck
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
	return maxi(
		MOVE_ENERGY_COST + state.character_class.move_energy_delta
		+ _next_move_energy_penalty + _move_penalty_today,
		0
	)


## Returns "" when the move is possible, otherwise a player-facing reason.
func can_move(tile_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	if not BoardGenerator.are_adjacent(state.current_tile, tile_index):
		return "Ten kafel nie sąsiaduje z twoją pozycją."
	if _free_moves <= 0 and state.energy < move_energy_cost():
		return "Za mało energii (potrzeba %d)." % move_energy_cost()
	if _free_moves > 0 and _next_move_energy_penalty > 0 and state.energy < _next_move_energy_penalty:
		return "Za mało energii (potrzeba %d)." % _next_move_energy_penalty
	return ""


func move_to(tile_index: int) -> void:
	var block_reason := can_move(tile_index)
	if block_reason != "":
		log_message.emit(block_reason)
		return
	if _free_moves > 0:
		_free_moves -= 1
		if _next_move_energy_penalty > 0:
			state.energy -= _next_move_energy_penalty
			log_message.emit("Bieg skraca trasę, ale objazd kosztuje +%d energii." % _next_move_energy_penalty)
			_next_move_energy_penalty = 0
		else:
			log_message.emit("Bieg: ten ruch jest darmowy.")
	else:
		state.energy -= move_energy_cost()
		_next_move_energy_penalty = 0
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


## Returns "" when the building on the current tile can be repaired (or, for
## the campfire, refuelled — see add_campfire_fuel below, reached through the
## same "Napraw"/"Dołóż drewna" UI button).
func can_repair(building_index: int) -> String:
	if not _day_active:
		return "Dzień dobiegł końca."
	var buildings := current_tile().buildings
	if building_index < 0 or building_index >= buildings.size():
		return "Nie ma takiego budynku."
	var built := buildings[building_index]
	if built.data.id == "building_campfire":
		if state.wood < CAMPFIRE_STOKE_WOOD_COST:
			return "Za mało drewna (potrzeba %d)." % CAMPFIRE_STOKE_WOOD_COST
		return ""
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
	if built.data.id == "building_campfire":
		state.wood -= CAMPFIRE_STOKE_WOOD_COST
		built.hp += CAMPFIRE_FUEL_HP_PER_WOOD
		log_message.emit("Dokładasz drewno do ogniska: pali się jeszcze %d nocy." % built.hp)
		stats_changed.emit(state)
		board_changed.emit(state)
		return
	state.energy -= REPAIR_ENERGY_COST
	state.wood -= repair_wood_cost(built)
	built.hp = building_max_hp(built.data)
	log_message.emit("Naprawiasz: %s (HP %d/%d)." % [
		built.data.display_name, built.hp, building_max_hp(built.data)
	])
	stats_changed.emit(state)
	board_changed.emit(state)


# Region securing lives in BumResolver; these stay as the stable public API.
func secured_tile_count() -> int:
	return BumResolver.secured_tile_count(self)


func secure_current_tile_cost() -> Dictionary:
	return BumResolver.secure_current_tile_cost(self)


func secure_current_tile_summary() -> String:
	return BumResolver.secure_current_tile_summary(self)


## Returns "" when the current tile/base region can be prepared for BUM.
func can_secure_current_tile() -> String:
	return BumResolver.can_secure_current_tile(self)


func secure_current_tile() -> void:
	BumResolver.secure_current_tile(self)


## Card verb "repair_tile": patch the most-damaged standing (non-ruined) building
## on the current tile by `amount` HP — no wood, no energy beyond the card itself.
func _repair_current_tile(amount: int) -> void:
	var best: BuildingState = null
	for built in current_tile().buildings:
		if not built.is_ruined and built.hp < building_max_hp(built.data):
			if best == null or built.hp < best.hp:
				best = built
	if best == null:
		log_message.emit("Brak budynku do doraźnej naprawy na tym kaflu.")
		return
	best.hp = mini(best.hp + amount, building_max_hp(best.data))
	log_message.emit("Doraźna naprawa: %s (HP %d/%d)." % [
		best.data.display_name, best.hp, building_max_hp(best.data)
	])
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
	var repaired_buildings := 0
	if int(action.get("repair_tile_buildings", 0)) > 0:
		repaired_buildings = _repair_current_tile_buildings(int(action.get("repair_tile_buildings", 0)))
	if bool(action.get("tools", false)):
		state.has_tools = true
	if bool(action.get("campfire_boost", false)):
		built.campfire_boost_active = true
	_used_building_actions[_building_action_key(building_index, action)] = true
	var summary := _action_delta_summary(snapshot)
	if bool(action.get("campfire_boost", false)):
		summary += (", " if summary != "" else "") + "+%d ciepła tej nocy" % CAMPFIRE_STOKE_BONUS_WARMTH
	if drawn > 0:
		summary += (", " if summary != "" else "") + "+%d karta do ręki" % drawn
	if repaired_buildings > 0:
		summary += (", " if summary != "" else "") + "naprawiono %d bud. (+%d HP)" % [
			repaired_buildings,
			int(action.get("repair_tile_buildings", 0)),
		]
	log_message.emit("Budynek: %s - %s%s" % [
		built.data.display_name,
		str(action.get("title", "Akcja")),
		": %s." % summary if summary != "" else ".",
	])
	if bool(action.get("no_wear", false)):
		stats_changed.emit(state)
		board_changed.emit(state)
		if drawn > 0:
			hand_changed.emit(hand)
		return
	_apply_building_wear(built, BUILDING_ACTION_WEAR, "Użycie zużywa %s (-%d HP)." % [
		built.data.display_name,
		BUILDING_ACTION_WEAR,
	], current_tile())
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
	# Honest forecast: include the penalties of the tile the player is camped on.
	var camp := NightResolver.camp_modifiers(self)
	thirst_decay += int(camp["thirst_loss"])
	warmth_decay += int(camp["warmth_loss"])
	var passive_warmth := 0
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined:
				passive_warmth += NightResolver.building_warmth_value(self, built)
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
		"camp_sickness_chance": float(camp["sickness_chance"]),
		"camp_sickness_damage": int(camp["sickness_damage"]),
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


## Short "Tylko: X / Y" label for the build-mode card, shown regardless of the
## current tile so the restriction is visible before the player even tries.
func required_biome_label(building: BuildingCardData) -> String:
	if building.required_biome_ids.is_empty():
		return ""
	var names: PackedStringArray = []
	for biome_id in building.required_biome_ids:
		names.append(BIOME_DISPLAY_NAMES.get(biome_id, biome_id))
	return "Tylko: " + " / ".join(names)


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
	_pending_night_card = _night_pool.draw(state.day, NightResolver.phase(self))
	if _pending_night_card != null:
		night_card_drawn.emit(_pending_night_card)


# Night resolution lives in NightResolver; these stay as the stable public API.


## Apply ONLY a chosen option of a decision event (passives + the choice), then
## pause so the UI can show the outcome before the player confirms. Returns a
## short summary of what happened (incl. risk backfire). Call resolve_night()
## afterwards to settle needs and advance the day.
func apply_night_choice(choice_index: int) -> String:
	return NightResolver.apply_choice(self, choice_index)


func night_choice_block_reason(choice_index: int) -> String:
	return NightResolver.choice_block_reason(self, choice_index)


## Resolve the drawn night event and the day's needs, then advance (or finish).
## Called when the player acknowledges the night popup; effects land here so the
## player sees the card BEFORE the stats move. Idempotent per end_day().
func resolve_night(choice_index: int = 0) -> void:
	NightResolver.resolve(self, choice_index)


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


## Upgrade variants available right now: for each owned action card that names an
## upgrade path, the upgraded card — deduped and only if not already owned. Choosing
## one swaps the base card in the deck (deck evolves instead of bloating).
func available_upgrades() -> Array[CardData]:
	var out: Array[CardData] = []
	var owned_ids := {}
	for owned in state.deck:
		owned_ids[owned.id] = true
	var seen_paths := {}
	for owned in state.deck:
		if owned is ActionCardData:
			var path: String = (owned as ActionCardData).upgrade_id
			if path != "" and not seen_paths.has(path) and ResourceLoader.exists(path):
				var upgraded := load(path) as CardData
				if upgraded != null and not owned_ids.has(upgraded.id):
					seen_paths[path] = true
					out.append(upgraded)
	return out


## Up to REWARD_CHOICES cards for the level-up choice: at most one is an upgrade,
## then the draft steers toward current crisis first. Calm moments lean into
## class flavor plus tempo/synergy, so broad rewards do not flatten archetypes.
func roll_card_rewards() -> Array[CardData]:
	var result: Array[CardData] = []
	var upgrades := available_upgrades()
	if not upgrades.is_empty():
		result.append(upgrades[_rng.randi_range(0, upgrades.size() - 1)])
	var pool := _card_pool.duplicate()
	_remove_reward_ids(pool, result)
	var has_crisis := _has_current_reward_crisis()
	if has_crisis:
		_append_reward_by_need(result, pool, _current_reward_need())
	_append_reward_by_need(result, pool, _class_reward_need(result))
	if state.bum_happened:
		_append_reward_by_need(result, pool, _disaster_reward_need())
	if not has_crisis:
		_append_synergy_reward(result, pool)
		_append_reward_by_need(result, pool, _deck_gap_reward_need())
	_append_synergy_reward(result, pool)
	_append_random_reward(result, pool)
	while result.size() < REWARD_CHOICES and not pool.is_empty():
		_append_random_reward(result, pool)
	return result


func _remove_reward_ids(pool: Array[CardData], result: Array[CardData]) -> void:
	for reward in result:
		for i in range(pool.size() - 1, -1, -1):
			if pool[i].id == reward.id:
				pool.remove_at(i)


func _append_reward_by_need(result: Array[CardData], pool: Array[CardData], need: int) -> void:
	if result.size() >= REWARD_CHOICES:
		return
	if _result_has_reward_need(result, need):
		return
	var matching: Array[int] = []
	for i in pool.size():
		if _card_matches_reward_need(pool[i], need):
			matching.append(i)
	if matching.is_empty():
		return
	var pool_idx: int = matching[_rng.randi_range(0, matching.size() - 1)]
	result.append(pool.pop_at(pool_idx))


func _append_synergy_reward(result: Array[CardData], pool: Array[CardData]) -> void:
	if result.size() >= REWARD_CHOICES:
		return
	if _result_has_reward_need(result, RewardNeed.SYNERGY):
		return
	var matching: Array[int] = []
	for i in pool.size():
		if pool[i] is ActionCardData and _is_reward_synergy(pool[i] as ActionCardData):
			matching.append(i)
	if matching.is_empty():
		return
	var pool_idx: int = matching[_rng.randi_range(0, matching.size() - 1)]
	result.append(pool.pop_at(pool_idx))


func _result_has_reward_need(result: Array[CardData], need: int) -> bool:
	for card in result:
		if _card_matches_reward_need(card, need):
			return true
	return false


func _append_random_reward(result: Array[CardData], pool: Array[CardData]) -> void:
	if result.size() >= REWARD_CHOICES or pool.is_empty():
		return
	result.append(pool.pop_at(_rng.randi_range(0, pool.size() - 1)))


func _has_current_reward_crisis() -> bool:
	return state.thirst <= LOW_NEED_THRESHOLD \
		or state.water <= LOW_STOCK_THRESHOLD \
		or state.hunger <= LOW_NEED_THRESHOLD \
		or state.food <= LOW_STOCK_THRESHOLD \
		or state.warmth <= LOW_NEED_THRESHOLD \
		or state.health <= LOW_NEED_THRESHOLD \
		or _has_damaged_building() \
		or state.wood <= LOW_STOCK_THRESHOLD \
		or state.materials <= LOW_STOCK_THRESHOLD


func _current_reward_need() -> int:
	if state.thirst <= LOW_NEED_THRESHOLD or state.water <= LOW_STOCK_THRESHOLD:
		return RewardNeed.WATER
	if state.hunger <= LOW_NEED_THRESHOLD or state.food <= LOW_STOCK_THRESHOLD:
		return RewardNeed.FOOD
	if state.warmth <= LOW_NEED_THRESHOLD:
		return RewardNeed.WARMTH
	if state.health <= LOW_NEED_THRESHOLD:
		return RewardNeed.HEALTH
	if _has_damaged_building():
		return RewardNeed.REPAIR
	if state.wood <= LOW_STOCK_THRESHOLD:
		return RewardNeed.WOOD
	if state.materials <= LOW_STOCK_THRESHOLD:
		return RewardNeed.MATERIALS
	return _deck_gap_reward_need()


func _deck_gap_reward_need() -> int:
	var needs := [
		RewardNeed.FOOD,
		RewardNeed.WATER,
		RewardNeed.WOOD,
		RewardNeed.MATERIALS,
		RewardNeed.HEALTH,
		RewardNeed.WARMTH,
		RewardNeed.CONVERT,
	]
	var best_need: int = needs[0]
	var best_count := 9999
	for need in needs:
		var count := _deck_need_count(need)
		if count < best_count:
			best_count = count
			best_need = need
	return best_need


func _disaster_reward_need() -> int:
	if state.bum_happened and state.disaster != null:
		match state.disaster.id:
			"plague":
				return RewardNeed.FOOD if _deck_need_count(RewardNeed.FOOD) <= _deck_need_count(RewardNeed.HEALTH) else RewardNeed.HEALTH
			"flood":
				return RewardNeed.WARMTH if _deck_need_count(RewardNeed.WARMTH) <= _deck_need_count(RewardNeed.WATER) else RewardNeed.WATER
			"eclipse":
				return RewardNeed.WARMTH if _deck_need_count(RewardNeed.WARMTH) <= _deck_need_count(RewardNeed.ENERGY) else RewardNeed.ENERGY
			"rift":
				return RewardNeed.REPAIR if _deck_need_count(RewardNeed.REPAIR) <= _deck_need_count(RewardNeed.MATERIALS) else RewardNeed.MATERIALS
	return RewardNeed.SYNERGY


func _class_reward_need(result: Array[CardData] = []) -> int:
	if state.character_class == null:
		return RewardNeed.SYNERGY
	var biases: Array = CLASS_REWARD_BIASES.get(state.character_class.id, [])
	for need in biases:
		if not _result_has_reward_need(result, int(need)):
			return int(need)
	return int(biases[0]) if not biases.is_empty() else RewardNeed.SYNERGY


func _deck_need_count(need: int) -> int:
	var count := 0
	for card in state.deck:
		if _card_matches_reward_need(card, need):
			count += 1
	return count


func _card_matches_reward_need(card: CardData, need: int) -> bool:
	if not (card is ActionCardData):
		return false
	var action := card as ActionCardData
	match need:
		RewardNeed.FOOD:
			return action.food_gain > 0 or action.hunger_delta > 0
		RewardNeed.WATER:
			return action.water_gain > 0 or action.thirst_delta > 0
		RewardNeed.WOOD:
			return action.wood_gain > 0
		RewardNeed.MATERIALS:
			return action.materials_gain > 0
		RewardNeed.HEALTH:
			return action.health_delta > 0
		RewardNeed.WARMTH:
			return action.warmth_delta > 0
		RewardNeed.ENERGY:
			return action.energy_delta > 0 or action.special in ["momentum", "rhythm", "free_move", "draw_two"]
		RewardNeed.REPAIR:
			return action.special == "repair_tile" or action.wood_gain > 0 or action.materials_gain > 0
		RewardNeed.NIGHT:
			return action.special in ["ward_night", "set_trap"] or action.warmth_delta > 0
		RewardNeed.CONVERT:
			return action.food_cost > 0 or action.wood_cost > 0 or action.materials_cost > 0 \
				or action.health_delta < 0 or action.hunger_delta < 0 or action.thirst_delta < 0
		RewardNeed.SYNERGY:
			return _is_reward_synergy(action)
	return false


func _has_damaged_building() -> bool:
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.hp < building_max_hp(built.data):
				return true
	return false


func _is_reward_synergy(card: ActionCardData) -> bool:
	if _card_role(card) == HandRole.PAYOFF:
		return true
	if REWARD_SYNERGY_SPECIALS.has(card.special):
		return true
	return card.energy_delta > 0


func claim_card(card: CardData) -> void:
	if not has_pending_reward() or card == null:
		return
	state.pending_rewards -= 1
	# If this card upgrades a card already in the deck, swap it in place.
	for i in state.deck.size():
		var base := state.deck[i]
		if base is ActionCardData:
			var path: String = (base as ActionCardData).upgrade_id
			if path != "" and ResourceLoader.exists(path):
				var upgraded := load(path)
				if upgraded != null and upgraded.id == card.id:
					state.deck[i] = card
					log_message.emit("Ulepszenie: %s → %s." % [base.display_name, card.display_name])
					stats_changed.emit(state)
					return
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
	for tile in state.board:
		for built in tile.buildings:
			built.campfire_boost_active = false
	# Card-verb and synergy state are fresh each day (night flags were already
	# spent during the previous night's resolution).
	_free_moves = 0
	_next_move_energy_penalty = 0
	_extra_night_protection = 0
	_night_trap = false
	_turn_cards_played = 0
	_turn_food_played = false
	_energy_refund_per_card = 0
	_health_history.append(state.health)
	_update_season_for_day()

	if not state.bum_happened and state.disaster != null:
		if state.day >= state.bum_day:
			BumResolver.trigger(self)
		elif is_bum_omen_window():
			BumResolver.log_omen(self)
	# Hard cap at max energy (no overflow). The active disaster can sap a flat
	# amount in Act II (Zaćmienie: dark, restless nights).
	state.energy = clampi(
		state.max_energy + state.next_day_energy_delta - _act2_rule("act2_energy_penalty"),
		1, state.max_energy
	)
	state.next_day_energy_delta = 0
	# Fog-like conditions: last night's event can tax every tile move today.
	_move_penalty_today = state.next_day_move_penalty
	state.next_day_move_penalty = 0
	if _move_penalty_today > 0:
		log_message.emit("Trudne warunki: każdy ruch kosztuje dziś +%d energii." % _move_penalty_today)

	# Passive dawn healing (a medic/hardy class trait).
	if state.character_class.daily_health_regen > 0 and state.health < state.max_health:
		var healed := mini(state.character_class.daily_health_regen, state.max_health - state.health)
		state.health += healed
		log_message.emit("Budzisz się wypoczęty. +%d zdrowia." % healed)

	# Each day starts with a fresh shuffle of the player's full deck.
	var deck_cards: Array[CardData] = []
	for card in state.deck:
		deck_cards.append(card)
	var opening_ids := _tutorial_opening_hand_ids()
	hand.clear()
	if opening_ids.is_empty():
		_deal_bucketed_hand(deck_cards)
	else:
		var remaining := deck_cards.duplicate()
		for card_id in opening_ids:
			var idx := _find_card_index_by_id(remaining, card_id)
			if idx >= 0 and hand.size() < HAND_SIZE:
				hand.append(remaining.pop_at(idx))
		_day_deck = Deck.new(remaining, _rng)
		_draw_cards(HAND_SIZE - hand.size())

	log_message.emit("--- Dzień %d ---" % state.day)
	if _tutorial_mode:
		var hint := _tutorial_day_hint()
		if hint != "":
			log_message.emit(hint)
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


func _hand_limit() -> int:
	return HAND_SIZE + maxi(state.character_class.bonus_hand_cards, 0)


func _draw_cards(count: int) -> void:
	for i in count:
		if hand.size() >= _hand_limit():
			return
		var card := _day_deck.draw()
		if card != null:
			hand.append(card)


## --- Role-bucketed opening hand (variant A) ---
##
func _card_role(card: CardData) -> int:
	if not (card is ActionCardData):
		return HandRole.TEMPO
	var a := card as ActionCardData
	if a.special in HAND_SYNERGY_SPECIALS:
		return HandRole.PAYOFF
	if a.food_gain > 0 or a.water_gain > 0 or a.wood_gain > 0 or a.materials_gain > 0:
		return HandRole.ECONOMY
	if a.health_delta > 0 or a.hunger_delta > 0 or a.thirst_delta > 0 or a.warmth_delta > 0:
		return HandRole.SUSTAIN
	return HandRole.TEMPO


## Deterministic in-place shuffle using the system RNG (so seeded runs/tests stay
## reproducible — Array.shuffle() would use the global RNG).
func _rng_shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp: Variant = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp


## Build the opening hand from owned cards only. First deal a normal shuffled hand,
## then make a small survival correction only if the hand has no economy/sustain
## at all. This avoids dead openings without making every dawn feel solved.
func _deal_bucketed_hand(deck_cards: Array[CardData]) -> void:
	var limit := _hand_limit()
	var draw_pool := deck_cards.duplicate()
	_rng_shuffle(draw_pool)
	var picked: Array[CardData] = []
	while picked.size() < limit and not draw_pool.is_empty():
		picked.append(draw_pool.pop_back())

	_ensure_survival_hand(picked, draw_pool)
	_reduce_hand_triples(picked, draw_pool)
	hand = picked
	_day_deck = Deck.new(draw_pool, _rng)


func _ensure_survival_hand(picked: Array[CardData], draw_pool: Array[CardData]) -> void:
	if _hand_has_any_role(picked, HAND_SURVIVAL_ROLES):
		return
	var candidate_idx := _find_any_role_index(draw_pool, HAND_SURVIVAL_ROLES)
	if candidate_idx < 0:
		return
	var replace_idx := _find_survival_replacement_index(picked)
	if replace_idx < 0:
		return
	var replaced := picked[replace_idx]
	picked[replace_idx] = draw_pool.pop_at(candidate_idx)
	draw_pool.append(replaced)


func _hand_has_any_role(cards: Array[CardData], roles: Array) -> bool:
	for card in cards:
		if roles.has(_card_role(card)):
			return true
	return false


func _find_any_role_index(cards: Array[CardData], roles: Array) -> int:
	for i in cards.size():
		if roles.has(_card_role(cards[i])):
			return i
	return -1


func _find_survival_replacement_index(cards: Array[CardData]) -> int:
	for i in cards.size():
		if not HAND_SURVIVAL_ROLES.has(_card_role(cards[i])):
			return i
	return cards.size() - 1 if not cards.is_empty() else -1


func _reduce_hand_triples(picked: Array[CardData], draw_pool: Array[CardData]) -> void:
	var counts := _card_id_counts(picked)
	for id in counts.keys():
		while int(counts[id]) >= 3:
			var duplicate_idx := _find_duplicate_index(picked, str(id))
			var replacement_idx := _find_non_duplicate_pool_index(draw_pool, counts)
			if duplicate_idx < 0 or replacement_idx < 0:
				return
			var replaced := picked[duplicate_idx]
			picked[duplicate_idx] = draw_pool.pop_at(replacement_idx)
			draw_pool.append(replaced)
			counts = _card_id_counts(picked)


func _card_id_counts(cards: Array[CardData]) -> Dictionary:
	var counts := {}
	for card in cards:
		counts[card.id] = int(counts.get(card.id, 0)) + 1
	return counts


func _find_duplicate_index(cards: Array[CardData], id: String) -> int:
	for i in range(cards.size() - 1, -1, -1):
		if cards[i].id == id:
			return i
	return -1


func _find_non_duplicate_pool_index(cards: Array[CardData], current_counts: Dictionary) -> int:
	for i in cards.size():
		if int(current_counts.get(cards[i].id, 0)) < 2:
			return i
	return -1


func _cards_by_ids(ids: Array[String]) -> Array[CardData]:
	var result: Array[CardData] = []
	for card_id in ids:
		var card := _card_by_id(card_id)
		if card != null:
			result.append(card)
	return result


func _card_by_id(card_id: String) -> CardData:
	for card in _card_pool:
		if card != null and card.id == card_id:
			return card
	for card in state.deck:
		if card != null and card.id == card_id:
			return card
	return null


func _tutorial_opening_hand_ids() -> Array[String]:
	if not _tutorial_mode:
		return []
	match state.day:
		1:
			return ["find_water", "forage", "deadfall_wood", "rest"]
		2:
			return ["survey", "craft_tools", "bandage", "dried_meat"]
		_:
			return []


func _find_card_index_by_id(cards: Array[CardData], card_id: String) -> int:
	for i in cards.size():
		if cards[i] != null and cards[i].id == card_id:
			return i
	return -1


func _tutorial_day_hint() -> String:
	match state.day:
		1:
			return "SAMOUCZEK: przeci\u0105gnij kart\u0119 akcji na kartk\u0119 log\u00f3w albo obecny biom. Zdob\u0105d\u017a wod\u0119, jedzenie i drewno, potem otw\u00f3rz Budowanie i postaw pierwszy budynek."
		2:
			return "SAMOUCZEK: kliknij zbudowany budynek na biomie, sprawd\u017a jego akcj\u0119 i opis. U\u017cyj budynku, zagraj kart\u0119 rozpoznania albo odkryj s\u0105siedni kafel."
		3:
			return "SAMOUCZEK: cz\u0119\u015b\u0107 prowadzona zako\u0144czona. Dalej grasz normalnie: rozwijaj tali\u0119, osad\u0119 i przygotuj si\u0119 na BUM."
		_:
			return ""


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
	var card_summary := _action_card_base_summary(card)
	var bonus_parts: PackedStringArray = []
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
			bonus_parts.append("narzędzia +%d jedzenia" % TOOLS_GAIN_BONUS)
		if wood_gain > 0:
			wood_gain += TOOLS_GAIN_BONUS
			bonus_parts.append("narzędzia +%d drewna" % TOOLS_GAIN_BONUS)
	if state.season == RunState.Season.SPRING and card.food_gain > 0:
		food_gain += SPRING_FOOD_BONUS
		bonus_parts.append("wiosna +%d jedzenia" % SPRING_FOOD_BONUS)
	if state.season == RunState.Season.AUTUMN and card.wood_gain > 0:
		wood_gain += AUTUMN_WOOD_BONUS
		bonus_parts.append("jesień +%d drewna" % AUTUMN_WOOD_BONUS)
	# Winter: nature gives less — every gathered resource yields one fewer.
	var materials_gain := card.materials_gain
	if state.season == RunState.Season.WINTER:
		if food_gain > 0:
			var food_penalty := mini(WINTER_GATHER_PENALTY, food_gain)
			food_gain = maxi(food_gain - WINTER_GATHER_PENALTY, 0)
			if food_penalty > 0:
				bonus_parts.append("zima -%d jedzenia" % food_penalty)
		if wood_gain > 0:
			var wood_penalty := mini(WINTER_GATHER_PENALTY, wood_gain)
			wood_gain = maxi(wood_gain - WINTER_GATHER_PENALTY, 0)
			if wood_penalty > 0:
				bonus_parts.append("zima -%d drewna" % wood_penalty)
		if materials_gain > 0:
			var materials_penalty := mini(WINTER_GATHER_PENALTY, materials_gain)
			materials_gain = maxi(materials_gain - WINTER_GATHER_PENALTY, 0)
			if materials_penalty > 0:
				bonus_parts.append("zima -%d kamienia" % materials_penalty)
	_add_food(food_gain)
	_add_water(card.water_gain)
	_add_wood(wood_gain)
	_add_materials(materials_gain)
	_apply_stat_deltas(
		card.health_delta, card.hunger_delta, card.thirst_delta, card.warmth_delta
	)
	state.energy = clampi(
		state.energy + card.energy_delta + _energy_refund_per_card, 0, state.max_energy
	)
	state.next_day_energy_delta += card.next_day_energy_delta

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
		"free_move":
			_free_moves += 1
			log_message.emit("Następny ruch dziś jest darmowy.")
		"repair_tile":
			_repair_current_tile(REPAIR_TILE_AMOUNT)
		"ward_night":
			_extra_night_protection += NIGHT_PROTECTION_VALUE
			log_message.emit("Warta: tej nocy mniej oberwiesz od zdarzeń i potworów.")
		"set_trap":
			_night_trap = true
			log_message.emit("Zastawiasz wnyki — pierwszy nocny napastnik wpadnie w pułapkę.")
		"momentum":
			_energy_refund_per_card += 1
			log_message.emit("Zapał: każda kolejna karta dziś zwraca +1 energii.")
		"rhythm":
			var recovered_energy := mini(_turn_cards_played, state.max_energy - state.energy)
			if recovered_energy > 0:
				state.energy += recovered_energy
		"combo_food":
			if _turn_food_played:
				_add_food(2)
				log_message.emit("Combo jedzenia: +2 jedzenia za wcześniejszą kartę jedzenia.")
		"next_move_cost":
			_next_move_energy_penalty += 1
			log_message.emit("Następny ruch dziś kosztuje +1 energii.")
	# Per-turn synergy bookkeeping: count this card so later plays this turn can
	# react (rhythm/momentum/combo_food). Gather actions resolve here too, so they
	# also feed the combo counters.
	_turn_cards_played += 1
	if card.food_gain > 0 or card.hunger_delta > 0:
		_turn_food_played = true
	var summary: String = _action_delta_summary(snapshot)
	var lines: PackedStringArray = ["%s: %s." % [log_prefix, card.display_name]]
	if card_summary != "":
		lines.append("Karta: %s." % card_summary)
	lines.append("Bonusy/modyfikatory: %s." % (
		", ".join(bonus_parts) if not bonus_parts.is_empty() else "brak"
	))
	if summary != "":
		lines.append("Razem: %s." % summary)
	log_message.emit("\n".join(lines))


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


func _action_card_base_summary(card: ActionCardData) -> String:
	var parts: PackedStringArray = []
	_append_delta_part(parts, -card.energy_cost, "energii")
	_append_delta_part(parts, -card.food_cost, "jedzenia")
	_append_delta_part(parts, -card.wood_cost, "drewna")
	_append_delta_part(parts, -card.materials_cost, "kamienia")
	_append_delta_part(parts, card.health_delta, "zdrowia")
	_append_delta_part(parts, card.hunger_delta, "sytości")
	_append_delta_part(parts, card.thirst_delta, "nawodnienia")
	_append_delta_part(parts, card.warmth_delta, "ciepła")
	_append_delta_part(parts, card.energy_delta, "energii")
	_append_delta_part(parts, card.food_gain, "jedzenia")
	_append_delta_part(parts, card.water_gain, "wody")
	_append_delta_part(parts, card.wood_gain, "drewna")
	_append_delta_part(parts, card.materials_gain, "kamienia")
	_append_delta_part(parts, card.next_day_energy_delta, "energii jutro")
	var special := _action_special_log_text(card.special, card)
	if special != "":
		parts.append(special)
	return ", ".join(parts)


func action_card_effect_summary(card: ActionCardData) -> String:
	var parts: PackedStringArray = []
	_append_delta_part(parts, card.health_delta, "zdrowia")
	_append_delta_part(parts, card.hunger_delta, "sytości")
	_append_delta_part(parts, card.thirst_delta, "nawodnienia")
	_append_delta_part(parts, card.warmth_delta, "ciepła")
	_append_delta_part(parts, card.energy_delta, "energii")
	_append_delta_part(parts, card.food_gain, "jedzenia")
	_append_delta_part(parts, card.water_gain, "wody")
	_append_delta_part(parts, card.wood_gain, "drewna")
	_append_delta_part(parts, card.materials_gain, "kamienia")
	_append_delta_part(parts, card.next_day_energy_delta, "energii jutro")
	var special := _action_special_log_text(card.special, card)
	if special != "":
		parts.append(special)
	return "  ·  ".join(parts)


func _rhythm_recovered_energy(card: ActionCardData) -> int:
	if card == null or card.special != "rhythm" or _turn_cards_played <= 0:
		return 0
	var energy_after_base := clampi(
		state.energy - card.energy_cost + card.energy_delta + _energy_refund_per_card,
		0,
		state.max_energy
	)
	return mini(_turn_cards_played, state.max_energy - energy_after_base)


func _action_special_log_text(special: String, card: ActionCardData = null) -> String:
	match special:
		"craft_tools":
			return "tworzy narzędzia"
		"explore":
			return "losowe znalezisko"
		"double_explore":
			return "2 losowe znaleziska"
		"draw_two":
			return "+2 karty do ręki"
		"scout_reveal":
			return "odsłania sąsiedni kafel"
		"free_move":
			return "następny ruch dziś za darmo"
		"repair_tile":
			return "doraźna naprawa budynku"
		"ward_night":
			return "warta: łagodzi noc"
		"set_trap":
			return "wnyki: blokują atak potwora"
		"momentum":
			return "zapał: kolejne karty zwracają energię"
		"rhythm":
			var recovered := _rhythm_recovered_energy(card)
			return "+%d energii" % recovered if recovered > 0 else ""
		"combo_food":
			return "combo jedzenia"
		"next_move_cost":
			return "następny ruch dziś kosztuje +1 energii"
		_:
			return ""


func _append_delta_part(parts: PackedStringArray, delta: int, label: String) -> void:
	if delta != 0:
		parts.append("%+d %s" % [delta, label])


## Scout an adjacent UNDISCOVERED tile without moving there: reveals its biome
## (and arms its hazards in the night pool — info vs risk). Picks one at random.
func _building_action_definition(building: BuildingCardData) -> Dictionary:
	match building.id:
		"building_campfire":
			return {
				"id": "stoke_big_fire",
				"title": "Duży ogień",
				"cost_wood": CAMPFIRE_STOKE_WOOD_COST,
				"cost_energy": CAMPFIRE_STOKE_ENERGY_COST,
				"campfire_boost": true,
				"no_wear": true,
			}
		"building_well":
			return {"id": "draw_water", "title": "Nabierz wody", "cost_energy": 1, "water": 3}
		"building_cistern":
			return {"id": "draw_water", "title": "Nabierz wody", "cost_energy": 1, "water": 3}
		"building_water_filter":
			return {"id": "collect_rainwater", "title": "Zbierz deszczówkę", "cost_energy": 1, "water": 2}
		"building_pantry":
			return {"id": "eat_ration", "title": "Zjedz zapas", "cost_energy": 1, "cost_food": 1, "hunger": 3}
		"building_workshop":
			return {
				"id": "workshop_repair",
				"title": "Podreperuj konstrukcje",
				"cost_energy": 1,
				"cost_wood": 1,
				"cost_materials": 1,
				"repair_tile_buildings": 1,
				"no_wear": true,
			}
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
	if int(action.get("repair_tile_buildings", 0)) > 0:
		parts.append("+%d HP budynkom na kaflu" % int(action.get("repair_tile_buildings", 0)))
	if int(action.get("draw_cards", 0)) > 0:
		parts.append("+%d karta do ręki" % int(action.get("draw_cards", 0)))
	if bool(action.get("campfire_boost", false)):
		parts.append("+%d ciepła tej nocy" % CAMPFIRE_STOKE_BONUS_WARMTH)
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
	if int(action.get("repair_tile_buildings", 0)) > 0 and not _has_damaged_current_tile_building():
		return "Brak uszkodzonych budynków na tym kaflu."
	return ""


func _has_damaged_current_tile_building() -> bool:
	for built in current_tile().buildings:
		if built.is_ruined:
			continue
		if built.hp < building_max_hp(built.data):
			return true
	return false


func _repair_current_tile_buildings(amount: int) -> int:
	var repaired := 0
	for built in current_tile().buildings:
		if built.is_ruined:
			continue
		var max_hp := building_max_hp(built.data)
		if built.hp >= max_hp:
			continue
		built.hp = mini(built.hp + amount, max_hp)
		repaired += 1
	return repaired


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
	if building.special == "unlock_crafting" and not state.has_tools:
		state.has_tools = true

	log_message.emit("Budujesz: %s (%s, slot %d/%d)." % [
		building.display_name,
		_tile_name(current_tile()),
		current_tile().buildings.size(),
		current_tile().biome.building_slots,
	])
	if building.special == "unlock_crafting":
		log_message.emit("%s daje narzędzia." % building.display_name)
	board_changed.emit(state)


## Post-BUM rebuild surcharge applies to NORMAL buildings only; dedicated Act II
## buildings (act2_only) are the intended rebuild path, so they skip it. Campfire
## and hut are core survival — they cost exactly the same before and after BUM.
func _has_post_bum_surcharge(building: BuildingCardData) -> bool:
	if building.id == "building_campfire" or building.id == "building_hut":
		return false
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
# The strike itself, region securing and omens live in systems/bum_resolver.gd;
# the night pool wiring and resolution live in systems/night_resolver.gd.


func _rebuild_event_deck() -> void:
	NightResolver.rebuild_pool(self)


func is_bum_omen_window() -> bool:
	return BumResolver.is_omen_window(self)


func building_max_hp(building: BuildingCardData) -> int:
	return building.max_hp + state.character_class.building_hp_bonus


func _apply_building_wear(
	built: BuildingState, amount: int, message: String = "", tile: TileState = null
) -> bool:
	if built == null or built.is_ruined or amount <= 0:
		return false
	if BumResolver.secured_tile_absorbs_wear(self, tile, built):
		return false
	built.hp = maxi(built.hp - amount, 0)
	if message != "":
		log_message.emit(message)
	_check_ruin(built)
	return true


func _tile_for_building(built: BuildingState) -> TileState:
	for tile in state.board:
		if built in tile.buildings:
			return tile
	return null


## At 0 HP a building collapses into a ruin: passives, defense and specials
## stop working; it can only be torn down. The campfire is exempt — it never
## ruins from running out of fuel, it just goes unlit (fuel burn lives in
## NightResolver._resolve_campfire_fuel).
func _check_ruin(built: BuildingState) -> void:
	if built.is_ruined or built.data.id == "building_campfire":
		return
	if built.hp <= 0:
		built.is_ruined = true
		log_message.emit("%s zamienia się w RUINĘ. Możesz ją tylko rozebrać." %
			built.data.display_name)


# --- Shared helpers used by both day actions and the night resolvers ---


## Counts standing (non-ruined) buildings with a given special.
func _count_special(special: String) -> int:
	var count := 0
	for tile in state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.data.special == special:
				count += 1
	return count


## Active disaster's Act II rule value (0 before BUM or when unset).
func _act2_rule(field: String) -> int:
	if not state.bum_happened or state.disaster == null:
		return 0
	return int(state.disaster.get(field))


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
	var discovered := 0
	var slots_total := 0
	for tile in state.board:
		if tile.is_discovered:
			discovered += 1
		slots_total += tile.biome.building_slots
		for built in tile.buildings:
			if built.is_ruined:
				ruined += 1
			else:
				standing += 1
	var total_buildings := standing + ruined
	var day_deck_count := _day_deck.cards_left() if _day_deck != null else 0
	return {
		"cause": _last_cause,
		"damage_taken": _damage_taken,
		"seed": _run_seed,
		"health_history": _health_history.duplicate(),
		"day": state.day,
		"class_name": state.character_class.display_name if state.character_class != null else "",
		"season": RunState.season_name(state.season),
		"current_biome": _tile_name(current_tile()),
		"bum_happened": state.bum_happened,
		"days_after_bum": maxi(state.day - state.bum_day, 0) if state.bum_happened else 0,
		"buildings_standing": standing,
		"buildings_ruined": ruined,
		"buildings_total": total_buildings,
		"building_slots_total": slots_total,
		"building_slots_free": maxi(slots_total - total_buildings, 0),
		"discovered_tiles": discovered,
		"board_tiles": state.board.size(),
		"level": state.level,
		"xp": state.xp,
		"deck_size": state.deck.size(),
		"hand_size": hand.size(),
		"day_deck_count": day_deck_count,
		"health": state.health,
		"max_health": state.max_health,
		"hunger": state.hunger,
		"thirst": state.thirst,
		"warmth": state.warmth,
		"energy": state.energy,
		"max_energy": state.max_energy,
		"food": state.food,
		"food_cap": food_cap(),
		"water": state.water,
		"water_cap": water_cap(),
		"wood": state.wood,
		"wood_cap": wood_cap(),
		"materials": state.materials,
		"materials_cap": materials_cap(),
		"has_tools": state.has_tools,
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
