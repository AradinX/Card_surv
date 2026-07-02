class_name EventChoiceData
extends Resource
## One option on a choice-based night event (EventCardData.choices). Applying it
## adds the deltas/gains; a risky option can backfire and apply the Risk fields
## instead. Pure data - resolved by SurvivalSystem.

@export var label: String = ""
@export_multiline var result_text: String = ""

@export_group("Effects")
@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var thirst_delta: int = 0
@export var warmth_delta: int = 0
@export var food_gain: int = 0
@export var water_gain: int = 0
@export var wood_gain: int = 0
@export var materials_gain: int = 0
@export var next_day_energy_delta: int = 0
## Adds one random reward card to the player's deck (e.g. "nakarm -> +karta").
@export var grant_random_card: bool = false
## Optional requirement, e.g. "building_campfire" means the option needs a
## standing active building. For campfire, "active" also means fuel > 0.
@export var required_active_building_id: String = ""

@export_group("Risk")
## % chance this choice BACKFIRES: Effects are skipped and these fields apply.
@export_range(0, 100) var risk_chance: int = 0
@export var risk_health: int = 0
@export var risk_hunger_delta: int = 0
@export var risk_thirst_delta: int = 0
@export var risk_warmth_delta: int = 0
@export var risk_food_gain: int = 0
@export var risk_water_gain: int = 0
@export var risk_wood_gain: int = 0
@export var risk_materials_gain: int = 0
@export var risk_next_day_energy_delta: int = 0
