class_name DisasterData
extends Resource
## Definition of a BUM disaster type (Plaga, Pekniecie, Zacmienie...) —
## Dzien 50 concept, README section 5. Decides which monsters and events
## enter the game in Act II. Corrupted tile faces live on BiomeData.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

## Monsters shuffled into the event deck after BUM.
@export var monsters: Array[MonsterCardData] = []
## Disaster-specific event cards added to the Act II event deck.
@export var extra_event_cards: Array[EventCardData] = []

@export_group("Act II global rules (what this disaster DOES, beyond colour)")
## Extra daily decay added in Act II — gives each disaster a distinct survival
## pressure (Plaga rots food/health; Zaćmienie freezes/darkens).
@export var act2_hunger_decay_delta: int = 0
@export var act2_thirst_decay_delta: int = 0
@export var act2_warmth_decay_delta: int = 0
## Extra food spoiled per day in Act II (Plaga: rot).
@export var act2_food_spoilage_delta: int = 0
## Penalty to daily energy in Act II (Zaćmienie: long dark nights sap rest).
@export var act2_energy_penalty: int = 0
## One-line note shown in the log when BUM strikes, explaining the new rule.
@export_multiline var act2_rule_text: String = ""
