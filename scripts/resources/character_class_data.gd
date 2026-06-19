class_name CharacterClassData
extends Resource
## Definition of a playable class (Kucharz, Budowlaniec, Wojskowy) —
## Dzien 50 concept, README section 7. Modifiers are read by systems;
## 1.0 / 0 means "no change from the base rules".

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Roulette progression / difficulty order: lower unlocks first. 0 = the
## starting class (Kucharz). The roulette always unlocks the lowest-order class
## still locked, so players climb from easiest to hardest.
@export var unlock_order: int = 0

## Class starter deck (~10 cards incl. 1-2 unique ones).
@export var starter_deck: DeckData

@export_group("Modifiers")
## Multiplier on hunger restored by food (Kucharz 1.5, Budowlaniec < 1).
@export var food_hunger_multiplier: float = 1.0
## Multiplier on food spoilage speed (Kucharz < 1).
@export var spoilage_multiplier: float = 1.0
## Extra energy cost of building cards (Kucharz/Wojskowy +1).
@export var build_energy_cost_delta: int = 0
## Flat discount on building resource costs (Budowlaniec).
@export var build_resource_discount: int = 0
## Bonus HP for constructed buildings (Budowlaniec).
@export var building_hp_bonus: int = 0
## Flat reduction of monster damage dealt to the player (Wojskowy).
@export var monster_damage_reduction: int = 0
## Extra daily hunger decay (Wojskowy +1, negative = hardier appetite).
@export var hunger_rate_delta: int = 0

@export_group("Modifiers — extended")
## Extra daily thirst decay (negative = drinks less).
@export var thirst_rate_delta: int = 0
## Extra daily warmth decay (negative = resists cold).
@export var warmth_rate_delta: int = 0
## Adjusts the energy cost of moving between tiles (negative = cheaper, min 0).
@export var move_energy_delta: int = 0
## Extra cards drawn into the opening hand each dawn.
@export var bonus_hand_cards: int = 0
## Health restored automatically at every dawn (a passive medic/hardy trait).
@export var daily_health_regen: int = 0
## Multiplier on all XP gained (a fast-learner trait).
@export var xp_multiplier: float = 1.0

## Adjusts starting (and maximum) health — a tanky class is +, a frail one −.
@export var health_bonus: int = 0
## Adjusts maximum energy per day (Informatyk −2, etc.).
@export var max_energy_bonus: int = 0

@export_group("Starting resources")
@export var start_food: int = 0
@export var start_water: int = 0
@export var start_wood: int = 0
@export var start_materials: int = 0
