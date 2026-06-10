class_name RunState
extends Resource
## State of a single run (one playthrough). Kept as a Resource with @export
## properties so it can be saved/loaded later without refactoring.
## Global, between-run state belongs in MetaState, NOT here.

const MAX_HEALTH := 10
const MAX_HUNGER := 10
const MAX_ENERGY := 6
const MAX_SHELTER := 2
const TARGET_DAYS := 20

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
