extends SceneTree
## Headless check for BUM preparation: secured buildings plus base defense
## should turn Act I investment into reliable Act II carry-over.
##
## Run:
##   godot --headless --path . -s tests/bum_preparation_test.gd


func _init() -> void:
	var character_class: CharacterClassData = load("res://data/classes/cook.tres")
	var biome_pool := CardLibrary.load_biomes_from_dir("res://data/biomes")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var card_pool := CardLibrary.load_reward_pool_from_dir("res://data/cards/actions")
	var building_catalog: Array[BuildingCardData] = []
	for res in CardLibrary.load_cards_from_dir("res://data/buildings"):
		if res is BuildingCardData:
			building_catalog.append(res)
	var disaster_pool: Array[DisasterData] = []
	for resource in CardLibrary.load_resources_from_dir("res://data/disasters"):
		if resource is DisasterData:
			disaster_pool.append(resource)

	var palisade := _building_by_id(building_catalog, "building_palisade")
	var campfire := _building_by_id(building_catalog, "building_campfire")
	if character_class == null or palisade == null or campfire == null or disaster_pool.is_empty():
		push_error("BUM preparation test setup failed.")
		quit(1)
		return

	var survival := SurvivalSystem.new()
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)
	survival.begin()
	if survival.state.bum_day < SurvivalSystem.BUM_DAY_MIN \
			or survival.state.bum_day > SurvivalSystem.BUM_DAY_MAX:
		push_error("BUM day %d outside configured range %d-%d." % [
			survival.state.bum_day,
			SurvivalSystem.BUM_DAY_MIN,
			SurvivalSystem.BUM_DAY_MAX,
		])
		quit(1)
		return
	survival.state.day = survival.state.bum_day - SurvivalSystem.BUM_OMEN_LEAD_DAYS - 1
	if survival.is_bum_omen_window():
		push_error("BUM omen window should not start too early.")
		quit(1)
		return
	survival.state.day = survival.state.bum_day - SurvivalSystem.BUM_OMEN_LEAD_DAYS
	if not survival.is_bum_omen_window():
		push_error("BUM omen window should start %d days before BUM." %
			SurvivalSystem.BUM_OMEN_LEAD_DAYS)
		quit(1)
		return
	survival.state.max_energy = 20
	survival.state.energy = 20
	survival.state.hunger = 10
	survival.state.thirst = 10
	survival.state.wood = 20
	survival.state.materials = 20

	survival.build(palisade)
	survival.build(campfire)
	if survival.current_tile().buildings.size() < 2:
		push_error("Expected palisade and campfire to be built on the current tile.")
		quit(1)
		return

	var secured_for_limit := 0
	for tile_index in survival.state.board.size():
		if tile_index == survival.state.current_tile:
			continue
		survival.state.board[tile_index].bum_secured = true
		secured_for_limit += 1
		if secured_for_limit >= SurvivalSystem.BUM_SECURED_TILE_LIMIT:
			break
	if survival.can_secure_current_tile() == "":
		push_error("Expected secured tile limit to block further fortification.")
		quit(1)
		return
	for tile in survival.state.board:
		tile.bum_secured = false

	var block := survival.can_secure_current_tile()
	if block != "":
		push_error("Expected current tile to be securable, got: %s" % block)
		quit(1)
		return
	survival.secure_current_tile()

	survival.call("_trigger_bum")

	var failures := 0
	for built in survival.current_tile().buildings:
		if built.is_ruined:
			push_error("%s should survive secured BUM with palisade defense." % built.data.display_name)
			failures += 1
	if survival.current_tile().bum_secured:
		push_error("BUM should consume the tile security flag.")
		failures += 1

	if failures == 0:
		print("BUM preparation test OK")
	quit(0 if failures == 0 else 1)


func _building_by_id(catalog: Array[BuildingCardData], id: String) -> BuildingCardData:
	for building in catalog:
		if building.id == id:
			return building
	return null
