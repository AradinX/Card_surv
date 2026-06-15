extends SceneTree
## Headless test for Act I fog of war: only the starting tile is known, and
## moving to an adjacent unknown tile reveals it.


func _init() -> void:
	var character_class: CharacterClassData = load("res://data/classes/cook.tres")
	var biome_pool := CardLibrary.load_biomes_from_dir("res://data/biomes")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var card_pool := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	card_pool.append_array(CardLibrary.load_cards_from_dir("res://data/buildings"))
	var disasters: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir("res://data/disasters"):
		if resource is DisasterData:
			disasters.append(resource)

	var survival := SurvivalSystem.new()
	var signal_state := {"tile_index": -1}
	survival.tile_discovered.connect(func(tile_index: int) -> void:
		signal_state.tile_index = tile_index
	)
	survival.start(character_class, biome_pool, event_cards, card_pool, disasters)
	survival.begin()

	var discovered_at_start := _discovered_count(survival.state)
	if discovered_at_start != 1:
		push_error("expected exactly one discovered tile at start, got %d" % discovered_at_start)
		quit(1)
		return
	if not survival.current_tile().is_discovered:
		push_error("current tile must be discovered at start")
		quit(1)
		return

	var target := -1
	for i in survival.state.board.size():
		if survival.can_move(i) == "":
			target = i
			break
	if target == -1:
		push_error("expected at least one reachable adjacent tile")
		quit(1)
		return
	if survival.state.board[target].is_discovered:
		push_error("first reachable target should still be unknown before movement")
		quit(1)
		return

	survival.move_to(target)
	if signal_state.tile_index != target:
		push_error("tile_discovered should emit moved tile index")
		quit(1)
		return
	if not survival.state.board[target].is_discovered:
		push_error("moving to an unknown tile should discover it")
		quit(1)
		return
	if _discovered_count(survival.state) != 2:
		push_error("expected two discovered tiles after first move")
		quit(1)
		return

	print("Fog of war test OK: start tile plus first moved tile discovered")
	quit(0)


func _discovered_count(state: RunState) -> int:
	var count := 0
	for tile in state.board:
		if tile.is_discovered:
			count += 1
	return count
