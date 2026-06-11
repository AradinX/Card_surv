class_name RunState
extends Resource
## State of a single run (one playthrough). Kept as a Resource with @export
## properties so it can be saved/loaded later without refactoring.
## Global, between-run state belongs in MetaState, NOT here.

const MAX_HEALTH := 10
const MAX_HUNGER := 10
const MAX_ENERGY := 6
## Energy may exceed MAX_ENERGY by one (e.g. the Sunny Morning event).
const ENERGY_CAP := MAX_ENERGY + 1
const MAX_SHELTER := 2

@export var day: int = 1
@export var health: int = MAX_HEALTH
@export var hunger: int = 8
@export var energy: int = MAX_ENERGY
@export var food: int = 2
@export var wood: int = 0
@export var materials: int = 0
@export var shelter_level: int = 0
@export var has_tools: bool = false
## Accumulated energy modifier from events, applied at the next dawn.
@export var next_day_energy_delta: int = 0

## Deckbuilding: the player's full deck; copies of a card are duplicate
## entries pointing at the same ActionCardData resource.
@export var deck: Array[ActionCardData] = []

## Expedition map and the player's position on it (-1 = before first node).
## NOTE: node-map fields are legacy (etap 2 prototype) — they get removed
## once the Dzien 50 biome board replaces the expedition map.
@export var map: MapData
@export var current_node_id: int = -1

## --- Dzien 50 (concept: README.md) — skeleton, not wired into gameplay ---

## Concept defaults pending vertical-slice balance.
const MAX_THIRST := 10
const MAX_WARMTH := 10

@export_group("Dzien 50 skeleton")
@export var thirst: int = MAX_THIRST
@export var warmth: int = MAX_WARMTH
@export var water: int = 0
## In-run character progression (resets every run, README section 4).
@export var xp: int = 0
@export var level: int = 1
@export var character_class: CharacterClassData
## Disaster type rolled for this run; null until BUM strikes.
@export var disaster: DisasterData
@export var bum_happened: bool = false
## Biome board: 6 tiles in a 3x2 grid, row-major; player stands on one tile.
@export var board: Array[TileState] = []
@export var current_tile: int = 0
