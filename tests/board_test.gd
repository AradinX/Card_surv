extends SceneTree
## Headless invariants test for the biome board generator.
##
## Run:
##   godot --headless --path . -s tests/board_test.gd

const BOARDS := 200


func _init() -> void:
	var pool: Array[BiomeData] = []
	for resource in CardLibrary.load_resources_from_dir("res://data/biomes"):
		if resource is BiomeData:
			pool.append(resource)
	if pool.size() < 3:
		push_error("expected at least 3 biomes in data/biomes")
		quit(1)
		return

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var failures := 0

	for board_index in BOARDS:
		var tiles := BoardGenerator.generate(pool, rng)
		if tiles.size() != BoardGenerator.BOARD_SIZE:
			push_error("board %d: expected %d tiles, got %d" % [
				board_index, BoardGenerator.BOARD_SIZE, tiles.size()
			])
			failures += 1
			continue
		var seen_ids: Array[String] = []
		for tile in tiles:
			if tile.biome == null:
				push_error("board %d: tile without a biome" % board_index)
				failures += 1
				continue
			if not tile.biome in pool:
				push_error("board %d: biome '%s' not from the pool" % [
					board_index, tile.biome.id
				])
				failures += 1
			if tile.biome.building_slots < 2 or tile.biome.building_slots > 4:
				push_error("board %d: biome '%s' slots outside 2-4" % [
					board_index, tile.biome.id
				])
				failures += 1
			if tile.is_corrupted or not tile.buildings.is_empty():
				push_error("board %d: tile not pristine at generation" % board_index)
				failures += 1
			if not tile.biome.id in seen_ids:
				seen_ids.append(tile.biome.id)
		# Pool fits the board, so every pool biome must appear at least once.
		if pool.size() <= BoardGenerator.BOARD_SIZE and seen_ids.size() != pool.size():
			push_error("board %d: only %d of %d pool biomes present" % [
				board_index, seen_ids.size(), pool.size()
			])
			failures += 1

	failures += _check_adjacency()

	if failures == 0:
		print("Board test OK: %d boards valid" % BOARDS)
	quit(0 if failures == 0 else 1)


func _check_adjacency() -> int:
	var failures := 0
	# 3x2 grid, row-major:  0 1 2
	#                       3 4 5
	var expected := {
		0: [1, 3], 1: [0, 2, 4], 2: [1, 5],
		3: [0, 4], 4: [1, 3, 5], 5: [2, 4],
	}
	for a in BoardGenerator.BOARD_SIZE:
		for b in BoardGenerator.BOARD_SIZE:
			var want: bool = b in expected[a]
			if BoardGenerator.are_adjacent(a, b) != want:
				push_error("adjacency mismatch for tiles %d-%d" % [a, b])
				failures += 1
	if BoardGenerator.are_adjacent(0, 0) or BoardGenerator.are_adjacent(-1, 0):
		push_error("adjacency must reject self/out-of-range")
		failures += 1
	return failures
