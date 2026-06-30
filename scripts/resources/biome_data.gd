class_name BiomeData
extends Resource
## Definition of a biome tile — one of the 6 board tiles drawn at run start
## (Dzien 50 concept, README section 3). Pure data, no logic.
## Each biome has a normal face (Act I) and a corrupted face (after BUM).

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Building slots on this tile (design range 2-4, Laki: 4, Gory: 2).
@export_range(2, 4) var building_slots: int = 3

## Gathering cards available only while the player stands on this tile.
@export var gather_cards: Array[ActionCardData] = []
## Event cards this biome shuffles into the day event deck (biome hazards:
## Gory — harsher winter, Wybrzeze — storms...).
@export var extra_event_cards: Array[EventCardData] = []

@export_group("Camp modifiers (where you sleep tonight)")
## Harsh biomes make "where to camp" a real decision, not just "where to gather".
## These apply at night based on the tile the player ENDS the day on. A shelter
## (night_protection building) on that same tile softens warmth loss and sickness,
## rewarding building where you sleep.
## Extra warmth lost overnight when camped here (cold biomes: Gory, Jaskinie).
@export var camp_warmth_loss: int = 0
## Extra thirst lost overnight when camped here (dry biomes: Pustkowie).
@export var camp_thirst_loss: int = 0
## Chance (0..1) of a sickness flare overnight when camped here (Bagno).
@export_range(0.0, 1.0, 0.05) var camp_sickness_chance: float = 0.0
## Health lost when a camp sickness flare triggers.
@export var camp_sickness_damage: int = 0

@export_group("Corrupted face (after BUM)")
@export var corrupted_display_name: String = ""
@export_multiline var corrupted_description: String = ""
@export var corrupted_gather_cards: Array[ActionCardData] = []
@export var corrupted_extra_event_cards: Array[EventCardData] = []
