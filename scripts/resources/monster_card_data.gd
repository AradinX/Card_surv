class_name MonsterCardData
extends CardData
## Definition of a monster card (Dzien 50 concept, README section 6).
## After BUM the active disaster shuffles its monsters into the event deck;
## they attack at night, hurting the player and damaging building cards.

## Id of the disaster pool this monster belongs to (e.g. "plague").
@export var disaster_id: String = ""
@export var damage_to_player: int = 0
@export var damage_to_buildings: int = 0
## Copies shuffled into the event deck when the disaster strikes.
@export var copies_in_deck: int = 1
