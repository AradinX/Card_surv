class_name RunState
extends Resource
## State of a single run (one playthrough). Kept as a Resource with @export
## properties so it can be saved/loaded later without refactoring.
## Global, between-run state belongs in MetaState, NOT here.

const MAX_HEALTH := 10
const MAX_HUNGER := 10
const MAX_THIRST := 10
const MAX_WARMTH := 10
const MAX_ENERGY := 10
## Energy may exceed MAX_ENERGY by one (e.g. the Sunny Morning event).
const ENERGY_CAP := MAX_ENERGY + 1

@export var day: int = 1
@export var health: int = MAX_HEALTH
@export var hunger: int = 8
@export var thirst: int = 8
@export var warmth: int = 8
@export var energy: int = MAX_ENERGY
@export var food: int = 2
@export var water: int = 2
@export var wood: int = 0
@export var materials: int = 0
@export var has_tools: bool = false
## Accumulated energy modifier from events, applied at the next dawn.
@export var next_day_energy_delta: int = 0

## In-run character progression (resets every run; rewards come later).
@export var xp: int = 0
@export var level: int = 1
@export var character_class: CharacterClassData

## Deckbuilding: the player's full deck (action AND building cards); copies
## of a card are duplicate entries pointing at the same resource. Building
## cards leave the deck permanently when built.
@export var deck: Array[CardData] = []

## Biome board: 6 tiles in a 3x2 grid (row-major), player stands on one tile.
@export var board: Array[TileState] = []
@export var current_tile: int = 0

## BUM disaster (rolled when it strikes; null before).
@export var disaster: DisasterData
@export var bum_happened: bool = false
