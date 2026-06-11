class_name BuildingCardData
extends CardData
## Definition of a building card (Dzien 50 concept, README section 4).
## When played, the building occupies a slot on the player's current tile
## and stays on the table as a card with HP. Passive effects are global —
## they apply regardless of where the player stands.

@export_group("Build costs")
@export var energy_cost: int = 0
@export var wood_cost: int = 0
@export var materials_cost: int = 0
@export var food_cost: int = 0

@export_group("Durability")
## Damage below 50% of max_hp = repairable; 50% or more = ruin that can
## only be torn down for ~50% of resources (README, BUM section).
@export var max_hp: int = 10
## Reduces monster damage dealt to buildings (Act II defense).
@export var defense: int = 0

@export_group("Passive per-day effects")
@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var thirst_delta: int = 0
@export var warmth_delta: int = 0
@export var food_gain: int = 0
@export var water_gain: int = 0
@export var wood_gain: int = 0
@export var materials_gain: int = 0

## Special behaviours resolved by systems (extend as buildings get built):
## - slow_spoilage: food spoils slower (Spizarnia)
## - night_protection: shields the player from night events (Szalas)
## - unlock_crafting: better cards appear in reward pools (Warsztat)
@export_enum("none", "slow_spoilage", "night_protection", "unlock_crafting")
var special: String = "none"
