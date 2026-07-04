extends SceneTree
## Headless smoke test of the full board-survival loop (no UI). A naive bot
## plays hand cards and biome gather actions greedily, builds from the catalog,
## wanders the board, and the test verifies every run terminates in a win/loss.
##
## Run:
##   godot --headless --path . -s tests/smoke_test.gd

const RUNS := 50
## Smaller sample per non-default class — a balance signal, not a hard gate.
const CLASS_SAMPLE := 90
const MAX_DAYS_GUARD := 200
const BOT_MOVES_PER_DAY := 2
## Fuel level at which the campfire needs feeding soon — shared by the repair
## pass (feed it once standing there) and the movement pass (head back there).
const CAMPFIRE_LOW_FUEL_HP := 3


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
	# Cause-of-death histograms per act (from run_summary) — the tuning signal.
	# Each entry is {count, days} so callers can report an average death day too.
	var act1_causes := {}
	var act2_causes := {}
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
			var cause: String = outcome.cause if outcome.cause != "" else "?"
			if outcome.bum:
				bum_deaths += 1
				_record_cause(act2_causes, cause, outcome.days)
			else:
				act1_deaths += 1
				act1_death_days += outcome.days
				_record_cause(act1_causes, cause, outcome.days)
	var act1_avg_day := (float(act1_death_days) / act1_deaths) if act1_deaths > 0 else 0.0
	print("Smoke test OK: %d/%d runs won (cel: dzień %d), śr. %.1f dni, śr. poziom %.1f" % [
		wins, RUNS, SurvivalSystem.WIN_DAY,
		float(total_days) / RUNS, float(total_levels) / RUNS
	])
	print("  Zgony: Akt I (przed BUM) = %d (śr. dzień %.1f), Akt II (po BUM) = %d" % [
		act1_deaths, act1_avg_day, bum_deaths
	])
	if not act1_causes.is_empty():
		print("  Przyczyny Akt I: %s" % _format_causes(act1_causes))
	if not act2_causes.is_empty():
		print("  Przyczyny Akt II: %s" % _format_causes(act2_causes))

	# Per-class balance signal — the new classes have their own starter decks.
	print("Talie klas (%d runów każda):" % CLASS_SAMPLE)
	# Plain, easy-to-parse rollup for building a summary table from the log.
	print("---CSV---")
	print("class,samples,wins,win_pct,avg_days_all,avg_death_day,top_cause,top_cause_count,top_cause_avg_day")
	for resource in CardLibrary.load_resources_from_dir("res://data/classes"):
		if not (resource is CharacterClassData):
			continue
		var cclass := resource as CharacterClassData
		var class_wins := 0
		var class_days := 0
		var class_deaths := 0
		var class_death_days := 0
		var class_causes := {}
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
			if not outcome.won:
				class_deaths += 1
				class_death_days += outcome.days
				var act := "II" if outcome.bum else "I"
				var cause: String = "%s (Akt %s)" % [outcome.cause if outcome.cause != "" else "?", act]
				_record_cause(class_causes, cause, outcome.days)
		var class_avg_death_day := (float(class_death_days) / class_deaths) if class_deaths > 0 else 0.0
		print("  [%s] %d/%d wygranych, śr. %.1f dni ogółem, śr. dzień śmierci %.1f%s" % [
			cclass.display_name, class_wins, CLASS_SAMPLE, float(class_days) / CLASS_SAMPLE,
			class_avg_death_day,
			("" if class_causes.is_empty() else " — " + _format_causes(class_causes))
		])
		var top := _top_cause(class_causes)
		print("%s,%d,%d,%.1f,%.1f,%.1f,%s,%d,%.1f" % [
			cclass.id, CLASS_SAMPLE, class_wins, 100.0 * class_wins / CLASS_SAMPLE,
			float(class_days) / CLASS_SAMPLE, class_avg_death_day,
			str(top.get("name", "")), int(top.get("count", 0)), float(top.get("avg_day", 0.0)),
		])
	quit(0)


func _record_cause(causes: Dictionary, cause: String, day: int) -> void:
	var entry: Dictionary = causes.get(cause, {"count": 0, "days": 0})
	entry["count"] = int(entry["count"]) + 1
	entry["days"] = int(entry["days"]) + day
	causes[cause] = entry


## Most frequent cause in a `_record_cause`-built histogram, with its average
## death day — empty dict if there were no deaths.
func _top_cause(causes: Dictionary) -> Dictionary:
	var best_key := ""
	var best: Dictionary = {}
	for key in causes:
		var entry: Dictionary = causes[key]
		if best.is_empty() or int(entry["count"]) > int(best["count"]):
			best = entry
			best_key = key
	if best.is_empty():
		return {}
	return {
		"name": best_key,
		"count": best["count"],
		"avg_day": float(best["days"]) / int(best["count"]),
	}


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
	var outcome := {"ended": false, "won": false, "days": 0, "level": 1, "bum": false, "cause": ""}
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
	outcome.cause = str(survival.run_summary().get("cause", ""))
	return outcome


func _format_causes(causes: Dictionary) -> String:
	var parts: PackedStringArray = []
	var keys := causes.keys()
	keys.sort_custom(func(a, b): return int(causes[a]["count"]) > int(causes[b]["count"]))
	for key in keys:
		var entry: Dictionary = causes[key]
		var avg_day := float(entry["days"]) / int(entry["count"])
		parts.append("%s ×%d (śr. dzień %.1f)" % [key, entry["count"], avg_day])
	return ", ".join(parts)


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

		# A reasonable player secures a heat source before anything else: with no
		# campfire standing anywhere, build one the moment it's affordable —
		# otherwise the greedy card loop drains energy first and the bot freezes.
		if not _has_standing_campfire(survival):
			var campfire := _catalog_building(survival, "building_campfire")
			if campfire != null and survival.can_build(campfire) == "":
				survival.build(campfire)
				continue

		# Same reasoning for a passive water source: cistern/deszczówka refill
		# water every night for free, so a reasonable player raises one early
		# instead of only reacting to thirst hand-to-mouth via gather actions.
		if not _has_standing_water_building(survival):
			var played_water_building := false
			for building_id in ["building_cistern", "building_water_filter"]:
				var water_building := _catalog_building(survival, building_id)
				if water_building != null and survival.can_build(water_building) == "":
					survival.build(water_building)
					played_water_building = true
					break
			if played_water_building:
				continue

		# Whichever need is closer to crisis gets served first — a reasonable
		# player drinks or eats the moment a stat is running dry instead of
		# dawdling on an unrelated hand card while thirst or hunger craters
		# (the old greedy "first playable card" order didn't distinguish).
		var thirst_critical := survival.state.thirst <= SurvivalSystem.LOW_NEED_THRESHOLD \
			or survival.state.water <= SurvivalSystem.LOW_STOCK_THRESHOLD
		var hunger_critical := survival.state.hunger <= SurvivalSystem.LOW_NEED_THRESHOLD \
			or survival.state.food <= SurvivalSystem.LOW_STOCK_THRESHOLD
		if thirst_critical or hunger_critical:
			var thirst_first := not hunger_critical or survival.state.thirst <= survival.state.hunger
			if thirst_first:
				if thirst_critical and _try_relieve_thirst(survival):
					continue
				if hunger_critical and _try_relieve_hunger(survival):
					continue
			else:
				if hunger_critical and _try_relieve_hunger(survival):
					continue
				if thirst_critical and _try_relieve_thirst(survival):
					continue

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
				if ac.thirst_delta < 0 and survival.state.thirst + ac.thirst_delta <= 2:
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

		# ...then patch up the local settlement. Demolish only ever targets
		# ruins (can_demolish has no HP gate of its own, so without this check
		# a "healthy building, nothing to repair" tile would get its buildings
		# torn down for no reason). The campfire has no repair ceiling (uncapped
		# fuel stockpiling), so only feed it once it's actually running low —
		# a reasonable player doesn't dump every spare log onto a roaring fire.
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
				if built.hp <= CAMPFIRE_LOW_FUEL_HP and survival.can_repair(i) == "":
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

		# ...then wander — but if the campfire is running low on fuel and we're
		# not standing on it, head straight back instead of drifting randomly.
		# A reasonable player doesn't let the only heat source go dark by
		# accident (feedback: bot let it burn out and froze).
		if moves_left > 0:
			var reachable: Array[int] = []
			for tile_index in survival.state.board.size():
				if survival.can_move(tile_index) == "":
					reachable.append(tile_index)
			if not reachable.is_empty():
				var target := reachable[rng.randi_range(0, reachable.size() - 1)]
				# Only detour home with wood actually in hand — heading back
				# empty-handed just burns a move on a fire it can't feed yet.
				if survival.state.wood >= SurvivalSystem.CAMPFIRE_STOKE_WOOD_COST:
					var campfire_tile := _low_fuel_campfire_tile(survival)
					if campfire_tile >= 0:
						target = _step_toward(reachable, campfire_tile)
				survival.move_to(target)
				moves_left -= 1
				continue

		survival.end_day()
		survival.resolve_night()
		return

	# Step guard tripped — end the day to keep the run moving.
	survival.end_day()
	survival.resolve_night()


func _has_standing_campfire(survival: SurvivalSystem) -> bool:
	for tile in survival.state.board:
		for built in tile.buildings:
			if built.data.id == "building_campfire" and not built.is_ruined:
				return true
	return false


## Fuel burns every night board-wide regardless of where the player stands, but
## feeding it requires being on that tile — so a campfire the bot wandered away
## from just goes dark with nobody noticing. Returns the tile index of a
## campfire that needs feeding soon (and isn't the tile we're already on), or
## -1 if none does.
func _low_fuel_campfire_tile(survival: SurvivalSystem) -> int:
	for tile_index in survival.state.board.size():
		if tile_index == survival.state.current_tile:
			continue
		for built in survival.state.board[tile_index].buildings:
			if built.data.id == "building_campfire" and built.hp <= CAMPFIRE_LOW_FUEL_HP:
				return tile_index
	return -1


## Grid is small (BoardGenerator.GRID_COLS x GRID_ROWS) so a greedy step that
## shrinks Manhattan distance to the target each move reaches it in at most a
## few days — no real pathfinding needed.
func _step_toward(reachable: Array[int], target: int) -> int:
	var cols := BoardGenerator.GRID_COLS
	var target_row := target / cols
	var target_col := target % cols
	var best := reachable[0]
	var best_dist := 9999
	for candidate in reachable:
		var dist := absi(candidate / cols - target_row) + absi(candidate % cols - target_col)
		if dist < best_dist:
			best_dist = dist
			best = candidate
	return best


func _has_standing_water_building(survival: SurvivalSystem) -> bool:
	for tile in survival.state.board:
		for built in tile.buildings:
			if built.data.water_gain > 0 and not built.is_ruined:
				return true
	return false


## Plays the first playable hand card, then the first playable gather action,
## that actually relieves thirst (water_gain or thirst_delta > 0).
func _try_relieve_thirst(survival: SurvivalSystem) -> bool:
	for i in survival.hand.size():
		var card := survival.hand[i]
		if card is ActionCardData and survival.can_play(card) == "":
			var ac := card as ActionCardData
			if ac.water_gain > 0 or ac.thirst_delta > 0:
				survival.play_card(i)
				return true
	for card in survival.gather_actions():
		if (card.water_gain > 0 or card.thirst_delta > 0) and survival.can_play_gather(card) == "":
			survival.play_gather(card)
			return true
	return false


## Same as _try_relieve_thirst but for hunger (food_gain or hunger_delta > 0).
func _try_relieve_hunger(survival: SurvivalSystem) -> bool:
	for i in survival.hand.size():
		var card := survival.hand[i]
		if card is ActionCardData and survival.can_play(card) == "":
			var ac := card as ActionCardData
			if ac.food_gain > 0 or ac.hunger_delta > 0:
				survival.play_card(i)
				return true
	for card in survival.gather_actions():
		if (card.food_gain > 0 or card.hunger_delta > 0) and survival.can_play_gather(card) == "":
			survival.play_gather(card)
			return true
	return false


func _catalog_building(survival: SurvivalSystem, id: String) -> BuildingCardData:
	for building in survival.building_catalog():
		if building.id == id:
			return building
	return null


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
