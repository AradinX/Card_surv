class_name ActionCardData
extends CardData
## Definition of a playable action card. Costs are paid up front,
## gains/deltas are applied immediately. "special" effects that need
## logic (random rewards, flags) are resolved by RunSystem.

@export_group("Costs")
@export var energy_cost: int = 0
@export var food_cost: int = 0
@export var wood_cost: int = 0
@export var materials_cost: int = 0

@export_group("Effects")
@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var energy_delta: int = 0
@export var food_gain: int = 0
@export var wood_gain: int = 0
@export var materials_gain: int = 0

## Special effects handled by RunSystem:
## - build_shelter: shelter_level +1 (max RunState.MAX_SHELTER)
## - craft_tools: sets has_tools (one-time; +1 food/wood gain from cards)
## - explore: random reward rolled by RunSystem
@export_enum("none", "build_shelter", "craft_tools", "explore")
var special: String = "none"
