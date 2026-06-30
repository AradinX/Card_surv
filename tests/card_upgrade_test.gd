extends SceneTree
## Card upgrade rewards: picking an upgrade SWAPS the owned base card in place
## (deck evolves, size unchanged), while a normal card reward APPENDS.
##
## Run:
##   godot --headless --path . -s tests/card_upgrade_test.gd


func _init() -> void:
	var failures := 0

	var character_class: CharacterClassData = load("res://data/classes/cook.tres")
	var biome_pool := CardLibrary.load_biomes_from_dir("res://data/biomes")
	var event_cards := CardLibrary.load_cards_from_dir("res://data/cards/events")
	var card_pool := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	var catalog: Array[BuildingCardData] = []
	for res in CardLibrary.load_cards_from_dir("res://data/buildings"):
		if res is BuildingCardData:
			catalog.append(res)
	var disaster_pool: Array[DisasterData] = []
	for res in CardLibrary.load_resources_from_dir("res://data/disasters"):
		if res is DisasterData:
			disaster_pool.append(res)

	var survival := SurvivalSystem.new()
	survival.start(character_class, biome_pool, event_cards, card_pool, disaster_pool, catalog)
	survival.begin()

	# Guarantee an upgradeable card is owned (forage carries an upgrade path).
	if survival.available_upgrades().is_empty():
		survival.state.deck.append(load("res://data/cards/actions/forage.tres"))

	var upgrades := survival.available_upgrades()
	if upgrades.is_empty():
		push_error("expected at least one available upgrade")
		quit(1)
		return
	var upgrade: CardData = upgrades[0]

	_set_stable_survival_state(survival)
	var rolled := survival.roll_card_rewards()
	if rolled.size() != SurvivalSystem.REWARD_CHOICES:
		push_error("expected %d reward choices, got %d" % [
			SurvivalSystem.REWARD_CHOICES, rolled.size()
		])
		failures += 1
	var rolled_ids := {}
	var synergy_seen := false
	for card in rolled:
		if rolled_ids.has(card.id):
			push_error("duplicate reward option '%s'" % card.id)
			failures += 1
		rolled_ids[card.id] = true
		if card is ActionCardData and survival._is_reward_synergy(card as ActionCardData):
			synergy_seen = true
	if not synergy_seen:
		push_error("expected at least one synergy/tempo reward lane")
		failures += 1

	survival.state.thirst = 2
	survival.state.water = 0
	var crisis_rewards := survival.roll_card_rewards()
	var water_seen := false
	for card in crisis_rewards:
		if survival._card_matches_reward_need(card, SurvivalSystem.RewardNeed.WATER):
			water_seen = true
	if not water_seen:
		push_error("expected water reward while thirst/water crisis is active")
		failures += 1

	var cook_rewards := _stable_rewards_for_class(
		"res://data/classes/cook.tres", biome_pool, event_cards, card_pool, disaster_pool, catalog
	)
	if not _rewards_match_any_need(
		cook_rewards,
		[SurvivalSystem.RewardNeed.FOOD, SurvivalSystem.RewardNeed.CONVERT, SurvivalSystem.RewardNeed.WARMTH]
	):
		push_error("cook rewards should show a cook-flavored lane")
		failures += 1
	var hunter_rewards := _stable_rewards_for_class(
		"res://data/classes/hunter.tres", biome_pool, event_cards, card_pool, disaster_pool, catalog
	)
	if not _rewards_match_any_need(
		hunter_rewards,
		[SurvivalSystem.RewardNeed.ENERGY, SurvivalSystem.RewardNeed.NIGHT, SurvivalSystem.RewardNeed.FOOD]
	):
		push_error("hunter rewards should show a hunter-flavored lane")
		failures += 1

	# The upgrade target must NOT already be owned (it's a fresh variant).
	for owned in survival.state.deck:
		if owned.id == upgrade.id:
			push_error("upgrade target should not be owned before claiming")
			failures += 1

	var deck_before := survival.state.deck.size()
	survival.state.pending_rewards += 1
	survival.claim_card(upgrade)

	if survival.state.deck.size() != deck_before:
		push_error("upgrade should swap in place, not change deck size: %d -> %d" % [
			deck_before, survival.state.deck.size()
		])
		failures += 1
	var has_upgrade := false
	for owned in survival.state.deck:
		if owned.id == upgrade.id:
			has_upgrade = true
	if not has_upgrade:
		push_error("upgraded card missing from deck after claim")
		failures += 1
	# The same upgrade is no longer offered (its base was consumed/owned).
	for again in survival.available_upgrades():
		if again.id == upgrade.id:
			push_error("upgrade still offered after it was claimed")
			failures += 1

	# A normal (non-upgrade) reward still appends.
	var size_before_append := survival.state.deck.size()
	survival.state.pending_rewards += 1
	survival.claim_card(load("res://data/cards/actions/stoke_fire.tres"))
	if survival.state.deck.size() != size_before_append + 1:
		push_error("normal card reward should append (%d -> %d)" % [
			size_before_append, survival.state.deck.size()
		])
		failures += 1

	if failures == 0:
		print("Card upgrade test OK: swap in place + normal append verified")
	quit(0 if failures == 0 else 1)


func _stable_rewards_for_class(
	class_path: String,
	biome_pool: Array[BiomeData],
	event_cards: Array[CardData],
	card_pool: Array[CardData],
	disaster_pool: Array[DisasterData],
	catalog: Array[BuildingCardData],
) -> Array[CardData]:
	var survival := SurvivalSystem.new()
	survival.start(load(class_path), biome_pool, event_cards, card_pool, disaster_pool, catalog)
	survival._rng.seed = 9001
	_set_stable_survival_state(survival)
	return survival.roll_card_rewards()


func _set_stable_survival_state(survival: SurvivalSystem) -> void:
	survival.state.food = 4
	survival.state.water = 4
	survival.state.wood = 4
	survival.state.materials = 4
	survival.state.hunger = 8
	survival.state.thirst = 8
	survival.state.warmth = 8
	survival.state.health = survival.state.max_health


func _rewards_match_any_need(rewards: Array[CardData], needs: Array) -> bool:
	var probe := SurvivalSystem.new()
	for card in rewards:
		for need in needs:
			if probe._card_matches_reward_need(card, int(need)):
				return true
	return false
