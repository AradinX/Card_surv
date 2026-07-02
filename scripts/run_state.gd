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


static func season_name(value: int) -> String:
	match value:
		Season.SPRING:
			return "Wiosna"
		Season.SUMMER:
			return "Lato"
		Season.AUTUMN:
			return "Jesień"
		Season.WINTER:
			return "Zima"
		_:
			return "?"
