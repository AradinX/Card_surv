class_name CharacterClassData
extends Resource
## Definition of a playable class (Kucharz, Budowlaniec, Wojskowy) —
## Dzien 50 concept, README section 7. Modifiers are read by systems;
## 1.0 / 0 means "no change from the base rules".

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

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
## Extra daily hunger decay (Wojskowy +1).
@export var hunger_rate_delta: int = 0
