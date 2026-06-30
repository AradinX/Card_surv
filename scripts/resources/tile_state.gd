class_name TileState
extends Resource
## Runtime state of one board tile, saved as part of RunState.
## The board is a 3x2 grid of tiles; after BUM tiles flip to the corrupted
## face of their biome (is_corrupted = true).

@export var biome: BiomeData
@export var is_discovered: bool = false
@export var is_corrupted: bool = false
## Act I fortification of this tile/base region. It reduces BUM damage for all
## buildings here and gives them a chance to avoid regular wear before BUM.
@export var bum_secured: bool = false
@export var buildings: Array[BuildingState] = []
