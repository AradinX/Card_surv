class_name BuildingState
extends Resource
## Runtime state of one constructed building, saved as part of RunState.
## Damage rules (README, BUM): below 50% damage = repairable for resources
## proportional to damage; 50%+ = ruin, only tear-down for ~50% refund.

@export var data: BuildingCardData
@export var hp: int = 0
