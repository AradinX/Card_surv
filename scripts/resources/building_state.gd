class_name BuildingState
extends Resource
## Runtime state of one constructed building, saved as part of RunState.
## Damage rules (README, BUM): a building is repairable while hp > 0;
## once hp hits 0 it becomes a ruin, only tear-down-able for a partial refund.

@export var data: BuildingCardData
## For "building_campfire" this doubles as remaining fuel (nights of warmth
## left), not structural integrity — it is intentionally allowed to exceed
## data.max_hp when the player stokes it with extra wood.
@export var hp: int = 0
## A building whose hp hits 0 becomes a ruin: passives, defense and specials
## stop working and it can only be torn down. The campfire never ruins this
## way (see _check_ruin) — running out of fuel just means it's unlit.
@export var is_ruined: bool = false
## Day-transient: set when "Duży ogień" is used, consumed by the following
## night's warmth resolution, cleared every dawn. Not meant to be relied on
## across a save/reload mid-day.
var campfire_boost_active: bool = false
