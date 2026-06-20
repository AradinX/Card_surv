extends SceneTree
## Headless check for the 50-day season schedule.


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
	survival.start(character_class, biome_pool, event_cards, card_pool, disasters)
	survival.begin()

	_assert_season(survival, 1, RunState.Season.SPRING)
	_advance_to_day(survival, 14)
	_assert_season(survival, 14, RunState.Season.SUMMER)
	_advance_to_day(survival, 26)
	_assert_season(survival, 26, RunState.Season.AUTUMN)
	_advance_to_day(survival, 39)
	_assert_season(survival, 39, RunState.Season.WINTER)

	print("Season test OK: spring/summer/autumn/winter schedule active")
	quit(0)


func _advance_to_day(survival: SurvivalSystem, target_day: int) -> void:
	while survival.state.day < target_day:
		survival.state.health = survival.state.max_health
		survival.state.hunger = RunState.MAX_HUNGER
		survival.state.thirst = RunState.MAX_THIRST
		survival.state.warmth = RunState.MAX_WARMTH
		survival.state.food = 20
		survival.state.water = 20
		survival.end_day()
		survival.resolve_night()


func _assert_season(survival: SurvivalSystem, day: int, season: int) -> void:
	if survival.state.day != day:
		push_error("expected day %d, got %d" % [day, survival.state.day])
		quit(1)
	if survival.state.season != season:
		push_error("day %d: expected season %s, got %s" % [
			day,
			RunState.season_name(season),
			RunState.season_name(survival.state.season),
		])
		quit(1)
