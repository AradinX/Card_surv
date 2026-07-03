extends SceneTree
## One-off balance diagnostic: replays the smoke-test bot until a run dies of
## freezing BEFORE the BUM, then dumps the full day-by-day log of that run.
##
## Run:
##   godot --headless --path . -s tools/balance_trace.gd
##
## ponytail: bot day-loop copied from tests/smoke_test.gd (SceneTree scripts
## don't compose); keep in sync only while this diagnostic is needed.

const MAX_ATTEMPTS := 60
const MAX_DAYS_GUARD := 200
const BOT_MOVES_PER_DAY := 2


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

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for attempt in MAX_ATTEMPTS:
		var survival := SurvivalSystem.new()
		var log_lines: Array[String] = []
		var outcome := {"ended": false, "won": false, "days": 0}
		survival.log_message.connect(func(line: String) -> void:
			log_lines.append("[dz %d] %s" % [survival.state.day, line]))
		survival.run_ended.connect(func(won: bool, days: int) -> void:
			outcome.ended = true
			outcome.won = won
			outcome.days = days)
		survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)
		survival.begin()
		for day_guard in MAX_DAYS_GUARD:
			if outcome.ended:
				break
			_play_day(survival, outcome, rng)
		var summary := survival.run_summary()
		if not outcome.won and not survival.state.bum_happened \
				and str(summary.get("cause", "")) == "Mróz":
			print("=== Run %d: śmierć z MROZU w Akcie I, dzień %d ===" % [attempt, outcome.days])
			print("Seed: %s | Klasa: %s" % [str(summary.get("seed", "?")), str(summary.get("class_name", "?"))])
			for line in log_lines:
				print(line)
			quit(0)
			return
	print("Brak zgonu z mrozu w Akcie I w %d próbach." % MAX_ATTEMPTS)
	quit(0)


func _play_day(
	survival: SurvivalSystem, outcome: Dictionary, rng: RandomNumberGenerator
) -> void:
	var moves_left := BOT_MOVES_PER_DAY
	for step in 200:
		if outcome.ended:
			return
		while survival.has_pending_reward():
			match rng.randi_range(0, 2):
				0:
					survival.claim_max_energy()
				1:
					survival.claim_max_health()
				2:
					var rewards := survival.roll_card_rewards()
					if rewards.is_empty():
						survival.claim_max_energy()
					else:
						survival.claim_card(_pick_reward(survival, rewards, rng))
		if not _has_standing_campfire(survival):
			var campfire := _catalog_building(survival, "building_campfire")
			if campfire != null and survival.can_build(campfire) == "":
				survival.build(campfire)
				continue
		var played := false
		for i in survival.hand.size():
			var hand_card := survival.hand[i]
			if survival.can_play(hand_card) != "":
				continue
			if hand_card is ActionCardData:
				var ac := hand_card as ActionCardData
				if ac.health_delta < 0 and survival.state.health + ac.health_delta <= 3:
					continue
				if ac.hunger_delta < 0 and survival.state.hunger + ac.hunger_delta <= 2:
					continue
				var only_raw_mats := (ac.wood_gain > 0 or ac.materials_gain > 0) \
					and ac.food_gain == 0 and ac.water_gain == 0 \
					and ac.health_delta <= 0 and ac.hunger_delta <= 0 \
					and ac.thirst_delta <= 0 and ac.warmth_delta <= 0 and ac.energy_delta <= 0 \
					and ac.special == "none"
				if only_raw_mats and (survival.state.hunger < 4 or survival.state.thirst < 4):
					continue
			survival.play_card(i)
			played = true
			break
		if played:
			continue
		for card in survival.gather_actions():
			if card.health_delta < 0 and survival.state.food >= 2:
				continue
			if survival.can_play_gather(card) == "":
				survival.play_gather(card)
				played = true
				break
		if played:
			continue
		for building in survival.building_catalog():
			if survival.can_build(building) == "":
				survival.build(building)
				played = true
				break
		if played:
			continue
		var buildings := survival.current_tile().buildings
		for i in buildings.size():
			if survival.is_bum_omen_window() and survival.can_secure_current_tile() == "":
				survival.secure_current_tile()
				played = true
				break
			var built = buildings[i]
			if built.is_ruined:
				if survival.can_demolish(i) == "":
					survival.demolish(i)
					played = true
					break
				continue
			if built.data.id == "building_campfire":
				if built.hp <= 3 and survival.can_repair(i) == "":
					survival.repair(i)
					played = true
					break
				continue
			if survival.can_repair(i) == "":
				survival.repair(i)
				played = true
				break
		if played:
			continue
		if moves_left > 0:
			var reachable: Array[int] = []
			for tile_index in survival.state.board.size():
				if survival.can_move(tile_index) == "":
					reachable.append(tile_index)
			if not reachable.is_empty():
				survival.move_to(reachable[rng.randi_range(0, reachable.size() - 1)])
				moves_left -= 1
				continue
		survival.end_day()
		survival.resolve_night()
		return
	survival.end_day()
	survival.resolve_night()


func _pick_reward(
	survival: SurvivalSystem, rewards: Array[CardData], rng: RandomNumberGenerator
) -> CardData:
	var upgrade_ids := {}
	for upgrade in survival.available_upgrades():
		upgrade_ids[upgrade.id] = true
	for card in rewards:
		if upgrade_ids.has(card.id):
			return card
	for card in rewards:
		if not (card is ActionCardData):
			return card
		var action := card as ActionCardData
		if action.health_delta >= 0 and action.hunger_delta >= 0:
			return card
	return rewards[rng.randi_range(0, rewards.size() - 1)]
