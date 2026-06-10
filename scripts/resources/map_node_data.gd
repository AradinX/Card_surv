class_name MapNodeData
extends Resource
## A single node of the expedition map. Pure data, generated at runtime
## by MapGenerator; a Resource so the whole map can be saved later.

const TYPE_TERRAIN := "terrain"
const TYPE_EVENT := "event"
const TYPE_FIND := "find"
const TYPE_REST := "rest"
const TYPE_FINALE := "finale"

@export var id: int = -1
@export var type: String = TYPE_TERRAIN
@export var layer: int = 0
@export var index_in_layer: int = 0
## Ids of nodes in the next layer reachable from this one.
@export var next_ids: Array[int] = []
