class_name BoardGenerator
extends RefCounted
## Generates the run board: BOARD_SIZE biome tiles laid out in a
## GRID_COLS x GRID_ROWS grid (row-major). Every biome from the pool appears
## at least once (as long as the pool fits the board); remaining tiles are
## random repeats. Uses an injected RNG so runs can be seeded later.

const GRID_COLS := 3
const GRID_ROWS := 2
const BOARD_SIZE := GRID_COLS * GRID_ROWS
## Biomes that MUST appear on every board so their resources are always reachable
## (Las = drewno, Góry = kamień). Missing ids are simply skipped.
const GUARANTEED_BIOME_IDS := ["forest", "mountains"]


static func generate(pool: Array[BiomeData], rng: RandomNumberGenerator) -> Array[TileState]:
	assert(not pool.is_empty(), "biome pool must not be empty")

	# Force the guaranteed biomes in first, then fill the rest at random.
	var guaranteed: Array[BiomeData] = []
	var rest: Array[BiomeData] = []
	for biome in pool:
		if biome.id in GUARANTEED_BIOME_IDS:
			guaranteed.append(biome)
		else:
			rest.append(biome)
	_shuffle(rest, rng)
	var picked: Array[BiomeData] = guaranteed.duplicate()
	for biome in rest:
		if picked.size() >= BOARD_SIZE:
			break
		picked.append(biome)
	picked = picked.slice(0, BOARD_SIZE)
	while picked.size() < BOARD_SIZE:
		picked.append(pool[rng.randi_range(0, pool.size() - 1)])
	# Shuffle so the guaranteed biomes don't always land on the same tiles.
	_shuffle(picked, rng)

	var tiles: Array[TileState] = []
	for biome in picked:
		var tile := TileState.new()
		tile.biome = biome
		tiles.append(tile)
	return tiles


## Orthogonal adjacency of two row-major tile indices on the grid.
static func are_adjacent(a: int, b: int) -> bool:
	if a == b or a < 0 or b < 0 or a >= BOARD_SIZE or b >= BOARD_SIZE:
		return false
	@warning_ignore("integer_division")
	var row_a := a / GRID_COLS
	@warning_ignore("integer_division")
	var row_b := b / GRID_COLS
	var col_a := a % GRID_COLS
	var col_b := b % GRID_COLS
	return absi(row_a - row_b) + absi(col_a - col_b) == 1


static func _shuffle(biomes: Array[BiomeData], rng: RandomNumberGenerator) -> void:
	# Fisher-Yates using the injected RNG (Array.shuffle() uses the global one).
	for i in range(biomes.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := biomes[i]
		biomes[i] = biomes[j]
		biomes[j] = tmp
