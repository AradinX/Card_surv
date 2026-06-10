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
@export var map: MapData
@export var current_node_id: int = -1
