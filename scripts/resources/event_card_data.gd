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

## --- Active night pool tuning (see NightEventPool) ---
## Relative draw weight within the active pool (higher = more frequent).
@export var weight: int = 10
## Minimum days between two appearances of this card (0 = no cooldown).
@export var cooldown_days: int = 0
## Hard cap of appearances per run (0 = unlimited).
@export var max_per_run: int = 0
## Free-form tags (e.g. "disease", "flood") for future filtering.
@export var tags: PackedStringArray = PackedStringArray()
## What KIND of event this is. Drives phase weighting + UI tint.
## One of: "neutral" | "weather" | "biome" | "omen" | "monster" | "disaster".
@export var category: String = "neutral"
## How HARSH it is. Drives pacing (no two "major" nights in a row) + UI.
## One of: "minor" | "medium" | "major".
@export var severity: String = "minor"
