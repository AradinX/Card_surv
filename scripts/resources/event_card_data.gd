class_name EventCardData
extends CardData
## Definition of an end-of-day event card. Deltas are applied to the run
## state when the event resolves. Energy effects apply to the NEXT day
## (energy is reset at dawn).

@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var thirst_delta: int = 0
@export var warmth_delta: int = 0
@export var next_day_energy_delta: int = 0
@export var food_delta: int = 0
@export var water_delta: int = 0
@export var wood_delta: int = 0
@export var materials_delta: int = 0

## If true, a standing building with special "night_protection" (Szalas)
## reduces this event's negative health/warmth deltas.
@export var shelter_protects: bool = false
