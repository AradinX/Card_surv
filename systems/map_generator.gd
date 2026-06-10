class_name MapGenerator
extends RefCounted
## Procedural generator of the expedition map: PATH_LAYERS layers of nodes
## plus a single finale node on top. Connections form a non-crossing
## "staircase" between consecutive layers, so every node has at least one
## way in and one way out.

const PATH_LAYERS := 4
## type -> weight, for layers 1..PATH_LAYERS-1 (layer 0 is always terrain).
const TYPE_WEIGHTS := {
	MapNodeData.TYPE_TERRAIN: 5,
	MapNodeData.TYPE_EVENT: 2,
	MapNodeData.TYPE_FIND: 2,
	MapNodeData.TYPE_REST: 2,
}


static func generate(rng: RandomNumberGenerator) -> MapData:
	var map := MapData.new()
	map.layer_count = PATH_LAYERS + 1

	# Layer sizes chosen so the total (with finale) lands in 12..15.
	var sizes: Array[int] = [
		3,
		rng.randi_range(3, 4),
		rng.randi_range(3, 4),
		rng.randi_range(2, 3),
	]

	var next_id := 0
	var layers: Array = []  # Array of Array[MapNodeData]
	for layer in PATH_LAYERS:
		var layer_nodes: Array[MapNodeData] = []
		for index in sizes[layer]:
			var node := MapNodeData.new()
			node.id = next_id
			node.layer = layer
			node.index_in_layer = index
			node.type = (
				MapNodeData.TYPE_TERRAIN if layer == 0 else _roll_type(rng)
			)
			next_id += 1
			layer_nodes.append(node)
			map.nodes.append(node)
		layers.append(layer_nodes)

	_ensure_type_present(layers, MapNodeData.TYPE_FIND, rng)
	_ensure_type_present(layers, MapNodeData.TYPE_REST, rng)

	var finale := MapNodeData.new()
	finale.id = next_id
	finale.layer = PATH_LAYERS
	finale.index_in_layer = 0
	finale.type = MapNodeData.TYPE_FINALE
	map.nodes.append(finale)

	for layer in PATH_LAYERS - 1:
		_connect_layers(layers[layer], layers[layer + 1], rng)
	for node in layers[PATH_LAYERS - 1] as Array[MapNodeData]:
		node.next_ids.append(finale.id)

	return map


static func _roll_type(rng: RandomNumberGenerator) -> String:
	var total := 0
	for weight in TYPE_WEIGHTS.values():
		total += weight as int
	var roll := rng.randi_range(1, total)
	for type: String in TYPE_WEIGHTS:
		roll -= TYPE_WEIGHTS[type] as int
		if roll <= 0:
			return type
	return MapNodeData.TYPE_TERRAIN


## Guarantees at least one node of the given type in layers 1..PATH_LAYERS-1,
## converting a random terrain node if needed (so choices stay interesting).
static func _ensure_type_present(layers: Array, type: String, rng: RandomNumberGenerator) -> void:
	var candidates: Array[MapNodeData] = []
	for layer in range(1, layers.size()):
		for node in layers[layer] as Array[MapNodeData]:
			if node.type == type:
				return
			if node.type == MapNodeData.TYPE_TERRAIN:
				candidates.append(node)
	if not candidates.is_empty():
		candidates[rng.randi_range(0, candidates.size() - 1)].type = type


## Non-crossing staircase connections: walk two pointers across both layers,
## linking the current pair and randomly advancing either side. Guarantees
## every lower node has an exit and every upper node an entrance.
static func _connect_layers(
	lower: Array[MapNodeData], upper: Array[MapNodeData], rng: RandomNumberGenerator
) -> void:
	var j := 0
	var k := 0
	lower[j].next_ids.append(upper[k].id)
	while j < lower.size() - 1 or k < upper.size() - 1:
		var can_advance_lower := j < lower.size() - 1
		var can_advance_upper := k < upper.size() - 1
		if can_advance_lower and (not can_advance_upper or rng.randi_range(0, 1) == 0):
			j += 1
		else:
			k += 1
		lower[j].next_ids.append(upper[k].id)
