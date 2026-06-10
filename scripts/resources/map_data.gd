class_name MapData
extends Resource
## The whole expedition map: nodes grouped in layers, traversed bottom-up.
## Contains only data and read-only accessors — traversal rules live in
## ExpeditionSystem.

@export var nodes: Array[MapNodeData] = []
@export var layer_count: int = 0


func get_node_by_id(node_id: int) -> MapNodeData:
	for node in nodes:
		if node.id == node_id:
			return node
	return null


func get_layer_nodes(layer: int) -> Array[MapNodeData]:
	var result: Array[MapNodeData] = []
	for node in nodes:
		if node.layer == layer:
			result.append(node)
	return result
