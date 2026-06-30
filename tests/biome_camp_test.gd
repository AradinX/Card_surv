extends SceneTree
## Headless checks for two systems:
##   1. gather_only flag keeps biome gather cards out of the level-up reward pool.
##   2. Biome camp modifiers (warmth/thirst/sickness) are authored on harsh tiles,
##      while safe biomes stay neutral so camping isn't punished everywhere.
##
## Run:
##   godot --headless --path . -s tests/biome_camp_test.gd

const ACTIONS_DIR := "res://data/cards/actions"
const GATHER_ONLY_IDS := ["hunt", "fishing", "snare_trap", "wasteland_scrapwood"]


func _init() -> void:
	var failures := 0
	failures += _check_gather_only_flag()
	failures += _check_reward_pool_excludes_gather()
	failures += _check_camp_modifiers()
	if failures == 0:
		print("Biome camp / gather_only test OK")
	quit(0 if failures == 0 else 1)


## Each tile-pinned gather card must carry gather_only = true.
func _check_gather_only_flag() -> int:
	var failures := 0
	for id in GATHER_ONLY_IDS:
		var card := load("%s/%s.tres" % [ACTIONS_DIR, id]) as ActionCardData
		if card == null:
			push_error("missing gather card: %s" % id)
			failures += 1
			continue
		if not card.gather_only:
			push_error("%s should be flagged gather_only" % id)
			failures += 1
	return failures


## The reward pool must drop every gather_only card but keep normal actions.
func _check_reward_pool_excludes_gather() -> int:
	var failures := 0
	var pool := CardLibrary.load_reward_pool_from_dir(ACTIONS_DIR)
	if pool.is_empty():
		push_error("reward pool is empty")
		return failures + 1
	var pool_ids := {}
	for card in pool:
		pool_ids[card.id] = true
	for id in GATHER_ONLY_IDS:
		if pool_ids.has(id):
			push_error("gather_only card leaked into reward pool: %s" % id)
			failures += 1
	if not pool_ids.has("rest"):
		push_error("expected a normal action (rest) to remain in the reward pool")
		failures += 1
	# The pool must exclude exactly the flagged cards, nothing more, nothing less.
	var full := CardLibrary.load_cards_from_dir(ACTIONS_DIR)
	if full.size() - pool.size() != GATHER_ONLY_IDS.size():
		push_error("reward pool should exclude exactly %d gather_only cards (got %d)" % [
			GATHER_ONLY_IDS.size(), full.size() - pool.size()
		])
		failures += 1
	return failures


## Harsh biomes must carry their camp penalties; a safe biome must stay neutral.
func _check_camp_modifiers() -> int:
	var failures := 0
	var mountains := load("res://data/biomes/mountains.tres") as BiomeData
	var caves := load("res://data/biomes/caves.tres") as BiomeData
	var swamp := load("res://data/biomes/swamp.tres") as BiomeData
	var wasteland := load("res://data/biomes/wasteland.tres") as BiomeData
	var forest := load("res://data/biomes/forest.tres") as BiomeData
	if mountains.camp_warmth_loss <= 0:
		push_error("mountains should drain extra warmth at camp")
		failures += 1
	if caves.camp_warmth_loss <= 0:
		push_error("caves should drain extra warmth at camp")
		failures += 1
	if swamp.camp_sickness_chance <= 0.0 or swamp.camp_sickness_damage <= 0:
		push_error("swamp should risk sickness at camp")
		failures += 1
	if wasteland.camp_thirst_loss <= 0:
		push_error("wasteland should drain extra thirst at camp")
		failures += 1
	if forest.camp_warmth_loss != 0 or forest.camp_thirst_loss != 0 \
			or forest.camp_sickness_chance != 0.0:
		push_error("forest should have no camp penalties (safe tile)")
		failures += 1
	return failures
