class_name RunState
extends Resource
## State of a single run (one playthrough). Kept as a Resource with @export
## properties so it can be saved/loaded later without refactoring.
## Global, between-run state belongs in MetaState, NOT here.

## Starting caps; health/energy caps can grow during a run (level rewards),
## so their current values live in max_health/max_energy below.
const MAX_HEALTH := 10
const MAX_HUNGER := 10
const MAX_THIRST := 10
const MAX_WARMTH := 10
const MAX_ENERGY := 8
## Base storage caps (raised by storage buildings — see SurvivalSystem caps).
const MAX_FOOD := 8
const MAX_WATER := 8
const MAX_WOOD := 12
const MAX_MATERIALS := 12
## Save schema version. Bump on any incompatible to_dict()/from_dict() change;
## from_dict rejects other versions so a post-release patch never half-loads
## an old save into a broken run.
const SAVE_VERSION := 1
enum Season {SPRING, SUMMER, AUTUMN, WINTER}

@export var day: int = 1
@export var season: int = Season.SPRING
@export var max_health: int = MAX_HEALTH
@export var max_energy: int = MAX_ENERGY
@export var health: int = MAX_HEALTH
@export var hunger: int = 8
@export var thirst: int = 8
@export var warmth: int = 8
@export var energy: int = MAX_ENERGY
@export var food: int = 3
@export var water: int = 3
@export var wood: int = 0
@export var materials: int = 0
@export var has_tools: bool = false
## Accumulated energy modifier from events, applied at the next dawn.
@export var next_day_energy_delta: int = 0
## Extra energy cost added to every tile move tomorrow (fog), consumed at dawn.
@export var next_day_move_penalty: int = 0

## In-run character progression (resets every run). Levels grant a choice
## of 1 of 3 rewards; unclaimed level-ups wait in pending_rewards.
@export var xp: int = 0
@export var level: int = 1
@export var pending_rewards: int = 0
@export var character_class: CharacterClassData

## Deckbuilding: the player's full deck (action AND building cards); copies
## of a card are duplicate entries pointing at the same resource. Building
## cards leave the deck permanently when built.
@export var deck: Array[CardData] = []

## Biome board: 6 tiles in a 3x2 grid (row-major), player stands on one tile.
@export var board: Array[TileState] = []
@export var current_tile: int = 0

## BUM disaster: type and strike day are rolled at run start (the player
## never knows the day); bum_happened flips when the board is corrupted.
@export var disaster: DisasterData
@export var bum_day: int = 0
@export var bum_happened: bool = false


## Safe save format: plain JSON-able Dictionary with authored resources
## referenced by id. Never persist RunState with ResourceSaver/ResourceLoader —
## loading a .tres from user:// can execute scripts embedded in a tampered file.
func to_dict() -> Dictionary:
	var board_data: Array = []
	for tile in board:
		var buildings_data: Array = []
		for built in tile.buildings:
			buildings_data.append({
				"id": built.data.id if built.data != null else "",
				"hp": built.hp,
				"is_ruined": built.is_ruined,
			})
		board_data.append({
			"biome_id": tile.biome.id if tile.biome != null else "",
			"is_discovered": tile.is_discovered,
			"is_corrupted": tile.is_corrupted,
			"bum_secured": tile.bum_secured,
			"buildings": buildings_data,
		})
	var deck_ids: Array = []
	for card in deck:
		if card != null:
			deck_ids.append(card.id)
	return {
		"version": SAVE_VERSION,
		"day": day,
		"season": season,
		"max_health": max_health,
		"max_energy": max_energy,
		"health": health,
		"hunger": hunger,
		"thirst": thirst,
		"warmth": warmth,
		"energy": energy,
		"food": food,
		"water": water,
		"wood": wood,
		"materials": materials,
		"has_tools": has_tools,
		"next_day_energy_delta": next_day_energy_delta,
		"next_day_move_penalty": next_day_move_penalty,
		"xp": xp,
		"level": level,
		"pending_rewards": pending_rewards,
		"class_id": character_class.id if character_class != null else "",
		"deck": deck_ids,
		"board": board_data,
		"current_tile": current_tile,
		"disaster_id": disaster.id if disaster != null else "",
		"bum_day": bum_day,
		"bum_happened": bum_happened,
	}


## Rebuilds a RunState from to_dict() output (parsed JSON, so untrusted).
## `catalog` maps ids back to the authored res:// resources:
## {"classes": {id: CharacterClassData}, "cards": {id: CardData (actions AND
## buildings)}, "biomes": {...}, "buildings": {...}, "disasters": {...}}.
## Returns null when the data is not a usable save (caller deletes it).
static func from_dict(data: Variant, catalog: Dictionary) -> RunState:
	if not (data is Dictionary):
		return null
	if _read_int(data, "version", 0) != SAVE_VERSION:
		return null
	var classes: Dictionary = catalog.get("classes", {})
	var character: CharacterClassData = classes.get(str(data.get("class_id", "")))
	if character == null:
		return null

	var state := RunState.new()
	state.character_class = character
	state.day = maxi(_read_int(data, "day", 1), 1)
	state.season = clampi(_read_int(data, "season", Season.SPRING), Season.SPRING, Season.WINTER)
	state.max_health = maxi(_read_int(data, "max_health", MAX_HEALTH), 1)
	state.max_energy = maxi(_read_int(data, "max_energy", MAX_ENERGY), 1)
	state.health = clampi(_read_int(data, "health", state.max_health), 0, state.max_health)
	state.hunger = clampi(_read_int(data, "hunger", 8), 0, MAX_HUNGER)
	state.thirst = clampi(_read_int(data, "thirst", 8), 0, MAX_THIRST)
	state.warmth = clampi(_read_int(data, "warmth", 8), 0, MAX_WARMTH)
	state.energy = clampi(_read_int(data, "energy", state.max_energy), 0, state.max_energy)
	# Storage caps can legitimately exceed the base MAX_* (storage buildings),
	# so resources are only floored at 0 — SurvivalSystem enforces live caps.
	state.food = maxi(_read_int(data, "food", 0), 0)
	state.water = maxi(_read_int(data, "water", 0), 0)
	state.wood = maxi(_read_int(data, "wood", 0), 0)
	state.materials = maxi(_read_int(data, "materials", 0), 0)
	state.has_tools = _read_bool(data, "has_tools")
	state.next_day_energy_delta = _read_int(data, "next_day_energy_delta", 0)
	state.next_day_move_penalty = maxi(_read_int(data, "next_day_move_penalty", 0), 0)
	state.xp = maxi(_read_int(data, "xp", 0), 0)
	state.level = maxi(_read_int(data, "level", 1), 1)
	state.pending_rewards = maxi(_read_int(data, "pending_rewards", 0), 0)

	var cards: Dictionary = catalog.get("cards", {})
	var deck_value: Variant = data.get("deck")
	if deck_value is Array:
		for card_id in deck_value:
			var card: CardData = cards.get(str(card_id))
			if card != null:
				state.deck.append(card)
			else:
				push_warning("RunState: unknown card id '%s' in save, skipped" % str(card_id))

	var biomes: Dictionary = catalog.get("biomes", {})
	var buildings: Dictionary = catalog.get("buildings", {})
	var board_value: Variant = data.get("board")
	if not (board_value is Array) or (board_value as Array).is_empty():
		return null
	for tile_value in board_value:
		if not (tile_value is Dictionary):
			return null
		var biome: BiomeData = biomes.get(str(tile_value.get("biome_id", "")))
		if biome == null:
			return null
		var tile := TileState.new()
		tile.biome = biome
		tile.is_discovered = _read_bool(tile_value, "is_discovered")
		tile.is_corrupted = _read_bool(tile_value, "is_corrupted")
		tile.bum_secured = _read_bool(tile_value, "bum_secured")
		var buildings_value: Variant = tile_value.get("buildings")
		if buildings_value is Array:
			for built_value in buildings_value:
				if not (built_value is Dictionary):
					continue
				var building_data: BuildingCardData = buildings.get(str(built_value.get("id", "")))
				if building_data == null:
					push_warning("RunState: unknown building id in save, skipped")
					continue
				var built := BuildingState.new()
				built.data = building_data
				built.hp = maxi(_read_int(built_value, "hp", 0), 0)
				built.is_ruined = _read_bool(built_value, "is_ruined")
				tile.buildings.append(built)
		state.board.append(tile)
	state.current_tile = clampi(_read_int(data, "current_tile", 0), 0, state.board.size() - 1)

	var disasters: Dictionary = catalog.get("disasters", {})
	state.disaster = disasters.get(str(data.get("disaster_id", "")))
	state.bum_day = maxi(_read_int(data, "bum_day", 0), 0)
	state.bum_happened = _read_bool(data, "bum_happened")
	return state


## JSON numbers arrive as floats and a tampered file can hold any type, so
## coerce defensively instead of casting.
static func _read_int(data: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = data.get(key)
	if value is int or value is float:
		return int(value)
	return fallback


static func _read_bool(data: Dictionary, key: String) -> bool:
	var value: Variant = data.get(key)
	return value is bool and value


## Static context has no Object.tr() — translate through TranslationServer.
static func _tr(text: String) -> String:
	return TranslationServer.translate(text)


static func season_name(value: int) -> String:
	match value:
		Season.SPRING:
			return _tr("Wiosna")
		Season.SUMMER:
			return _tr("Lato")
		Season.AUTUMN:
			return _tr("Jesień")
		Season.WINTER:
			return _tr("Zima")
		_:
			return "?"
