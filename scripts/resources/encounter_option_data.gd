class_name EncounterOptionData
extends Resource
## One choice inside a special-event encounter. Negative resource deltas are
## requirements: the option is unavailable if the player can't afford them
## (logic in ExpeditionSystem). Health/hunger deltas always apply (an
## encounter CAN kill you).

@export var label: String = ""
@export_multiline var result_text: String = ""

@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var food_delta: int = 0
@export var wood_delta: int = 0
@export var materials_delta: int = 0

## If true, picking this option is followed by a 1-of-3 card reward choice.
@export var grants_card_choice: bool = false
