extends SceneTree
## Property test of MapGenerator: generates many maps and checks structural
## invariants (node count, connectivity, required node types).
##
## Run:
##   godot --headless --path . -s tests/map_test.gd

const MAPS := 200


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var failures := 0
	for i in MAPS:
		failures += _check_map(MapGenerator.generate(rng))
	if failures == 0:
		print("Map test OK: %d maps valid" % MAPS)
	quit(0 if failures == 0 else 1)


func _check_map(map: MapData) -> int:
	var failures := 0
	if map.nodes.size() < 10 or map.nodes.size() > 15:
		push_error("node count out of range: %d" % map.nodes.size())
		failures += 1

	var finale_count := 0
	var has_find := false
	var has_rest := false
	var incoming: Dictionary = {}
	for node in map.nodes:
		match node.type:
			MapNodeData.TYPE_FINALE:
				finale_count += 1
			MapNodeData.TYPE_FIND:
				has_find = true
			MapNodeData.TYPE_REST:
				has_rest = true
		if node.layer == 0 and node.type != MapNodeData.TYPE_TERRAIN:
			push_error("layer 0 node %d is not terrain" % node.id)
			failures += 1
		if node.type != MapNodeData.TYPE_FINALE and node.next_ids.is_empty():
			push_error("node %d has no exits" % node.id)
			failures += 1
		for next_id in node.next_ids:
			var next_node := map.get_node_by_id(next_id)
			if next_node == null or next_node.layer != node.layer + 1:
				push_error("node %d has invalid connection to %d" % [node.id, next_id])
				failures += 1
			incoming[next_id] = true

	for node in map.nodes:
		if node.layer > 0 and not incoming.has(node.id):
			push_error("node %d (layer %d) is unreachable" % [node.id, node.layer])
			failures += 1

	if finale_count != 1:
		push_error("expected exactly 1 finale, got %d" % finale_count)
		failures += 1
	if not has_find:
		push_error("map has no find node")
		failures += 1
	if not has_rest:
		push_error("map has no rest node")
		failures += 1
	return failures
