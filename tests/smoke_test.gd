extends SceneTree
## Headless smoke test of the full board-survival loop (no UI). A naive bot
## plays hand cards and biome gather actions greedily, builds from the catalog,
## wanders the board, and the test verifies every run terminates in a win/loss.
##
## Run:
##   godot --headless --path . -s tests/smoke_test.gd

const RUNS := 50
## Smaller sample per non-default class — a balance signal, not a hard gate.
const CLASS_SAMPLE := 30
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
	assert(character_class != null and character_class.starter_deck != null,
		"cook class with a starter deck is required")
	assert(biome_pool.size() >= 3, "expected at least 3 biomes")
	assert(event_cards.size() >= 10, "expected at least 10 event cards")
	assert(card_pool.size() >= 20, "expected at least 20 action cards in the reward pool")
	assert(building_catalog.size() >= 4, "expected at least 4 buildings in the catalog")
	assert(disaster_pool.size() >= 1, "expected at least 1 disaster type")
	print("Pool: %d biomes, %d events, %d reward cards, %d buildings, %d disasters, starter deck %d cards" % [
		biome_pool.size(), event_cards.size(), card_pool.size(), building_catalog.size(),
		disaster_pool.size(), character_class.starter_deck.cards.size()
	])

	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var wins := 0
	var total_days := 0
	var total_levels := 0
	var bum_deaths := 0
	# Act I (early game) deaths = losses BEFORE the cataclysm (bum never struck).
	var act1_deaths := 0
	var act1_death_days := 0
	for run_index in RUNS:
		var outcome := _play_run(
			character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog, rng
		)
		if not outcome.ended:
			push_error("Run %d did not terminate!" % run_index)
			quit(1)
			return
		wins += 1 if outcome.won else 0
		total_days += outcome.days
		total_levels += outcome.level
		if not outcome.won:
			if outcome.bum:
				bum_deaths += 1
			else:
				act1_deaths += 1
				act1_death_days += outcome.days
	var act1_avg_day := (float(act1_death_days) / act1_deaths) if act1_deaths > 0 else 0.0
	print("Smoke test OK: %d/%d runs won (cel: dzień %d), śr. %.1f dni, śr. poziom %.1f" % [
		wins, RUNS, SurvivalSystem.WIN_DAY,
		float(total_days) / RUNS, float(total_levels) / RUNS
	])
	print("  Zgony: Akt I (przed BUM) = %d (śr. dzień %.1f), Akt II (po BUM) = %d" % [
		act1_deaths, act1_avg_day, bum_deaths
	])

	# Per-class balance signal — the new classes have their own starter decks.
	print("Talie klas (%d runów każda):" % CLASS_SAMPLE)
	for resource in CardLibrary.load_resources_from_dir("res://data/classes"):
		if not (resource is CharacterClassData):
			continue
		var cclass := resource as CharacterClassData
		var class_wins := 0
		var class_days := 0
		for i in CLASS_SAMPLE:
			var outcome := _play_run(
				cclass, biome_pool, event_cards, card_pool, disaster_pool, building_catalog, rng
			)
			if not outcome.ended:
				push_error("Class %s run did not terminate!" % cclass.id)
				quit(1)
				return
			class_wins += 1 if outcome.won else 0
			class_days += outcome.days
		print("  [%s] %d/%d wygranych, śr. %.1f dni" % [
			cclass.display_name, class_wins, CLASS_SAMPLE, float(class_days) / CLASS_SAMPLE
		])
	quit(0)


func _play_run(
	character_class: CharacterClassData,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData],
	disaster_pool: Array[DisasterData],
	building_catalog: Array[BuildingCardData],
	rng: RandomNumberGenerator,
) -> Dictionary:
	var survival := SurvivalSystem.new()
	var outcome := {"ended": false, "won": false, "days": 0, "level": 1, "bum": false}
	survival.run_ended.connect(func(won: bool, days: int) -> void:
		outcome.ended = true
		outcome.won = won
		outcome.days = days
	)
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, building_catalog)
	survival.begin()

	for day_guard in MAX_DAYS_GUARD:
		if outcome.ended:
			break
		_play_day(survival, outcome, rng)
	outcome.level = survival.state.level
	outcome.bum = survival.state.bum_happened
	return outcome


func _play_day(
	survival: SurvivalSystem, outcome: Dictionary, rng: RandomNumberGenerator
) -> void:
	var moves_left := BOT_MOVES_PER_DAY
	for step in 200:
		if outcome.ended:
			return

		# Claim pending level rewards with a random pick.
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

		# Greedy: first playable hand card — but a reasonable player won't burn
		# health or satiety they can't spare (trade/tempo cards are opt-in).
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
				# Don't spend energy mining raw wood/stone while a survival need is
				# pressing — a reasonable player handles food/water first.
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

		# ...then the local biome's gather actions (skip self-harming cards
		# like Skazona zwierzyna unless food is actually running out)...
		for card in survival.gather_actions():
			if card.health_delta < 0 and survival.state.food >= 2:
				continue
			if survival.can_play_gather(card) == "":
				survival.play_gather(card)
				played = true
				break
		if played:
			continue

		# ...then build the first affordable building with a free local slot...
		for building in survival.building_catalog():
			if survival.can_build(building) == "":
				survival.build(building)
				played = true
				break
		if played:
			continue

		# ...then patch up the local settlement (repairs, ruin tear-downs)...
		for i in survival.current_tile().buildings.size():
			if survival.can_repair(i) == "":
				survival.repair(i)
				played = true
				break
			if survival.can_demolish(i) == "":
				survival.demolish(i)
				played = true
				break
		if played:
			continue

		# ...then wander to a random adjacent tile.
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

	# Step guard tripped — end the day to keep the run moving.
	survival.end_day()
	survival.resolve_night()


## A reasonable player's reward pick: take an upgrade of an owned card if offered
## (strict improvement), else any card with no self-harm, else random.
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
