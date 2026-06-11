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
