class_name TileState
extends Resource
## Runtime state of one board tile, saved as part of RunState.
## The board is a 3x2 grid of tiles; after BUM tiles flip to the corrupted
## face of their biome (is_corrupted = true).

@export var biome: BiomeData
@export var is_corrupted: bool = false
@export var buildings: Array[BuildingState] = []
