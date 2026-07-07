class_name NightResolver
extends RefCounted
## Night resolution extracted from SurvivalSystem: the active event pool
## wiring, the drawn card's effects (event / decision / monster attack),
## building passives and wear, campfire fuel and the overnight needs balance.
## Stateless — every function takes the owning SurvivalSystem; run state,
## constants and signals stay there and its public API is unchanged
## (end_day/resolve_night/apply_night_choice delegate here).


## Static funcs have no Object.tr(); route player-facing text through the
## TranslationServer directly (same catalog, PL source text as the key).
static func _tr(text: String) -> String:
	return TranslationServer.translate(text)


# --- Active night pool ---


static func rebuild_pool(sys: SurvivalSystem) -> void:
	if sys._night_pool == null:
		sys._night_pool = NightEventPool.new(sys._rng)
	# Rebuild keeps the cooldown/limit history; only the candidate set changes
	# (discovery reveals biome hazards, BUM adds disaster events + monsters).
	sys._night_pool.set_candidates(_event_pool(sys))


static func _event_pool(sys: SurvivalSystem) -> Array[CardData]:
	var event_pool: Array[CardData] = []
	for event in sys._base_event_cards:
		if _event_matches_disaster(sys, event):
			event_pool.append(event)
	var tile: TileState = sys.current_tile()
	if tile.is_discovered:
		var biome_events := tile.biome.corrupted_extra_event_cards \
			if tile.is_corrupted else tile.biome.extra_event_cards
		for event in biome_events:
			if _event_matches_disaster(sys, event):
				event_pool.append(event)

	if sys.state.bum_happened and sys.state.disaster != null:
		for event in sys.state.disaster.extra_event_cards:
			event_pool.append(event)
		# Each monster appears once; the pool weights it by copies_in_deck.
		for monster in sys.state.disaster.monsters:
			event_pool.append(monster)
	return event_pool


## Disaster-gated events (EventCardData.disaster_id) join the pool only after
## BUM and only under the matching disaster; "" means always eligible.
static func _event_matches_disaster(sys: SurvivalSystem, event: CardData) -> bool:
	var data := event as EventCardData
	if data == null or data.disaster_id == "":
		return true
	return sys.state.bum_happened and sys.state.disaster != null \
		and sys.state.disaster.id == data.disaster_id


## Run phase for the night pool's category weighting.
static func phase(sys: SurvivalSystem) -> int:
	if sys.state.bum_happened:
		return NightEventPool.Phase.ACT2
	if BumResolver.is_omen_window(sys):
		return NightEventPool.Phase.OMEN
	return NightEventPool.Phase.ACT1


# --- Night flow (choice + resolution) ---


## Apply ONLY a chosen option of a decision event (passives + the choice), then
## pause so the UI can show the outcome before the player confirms. Returns a
## short summary of what happened (incl. risk backfire). Call resolve()
## afterwards to settle needs and advance the day.
static func apply_choice(sys: SurvivalSystem, choice_index: int) -> String:
	if not sys._night_pending or sys._night_choice_done:
		return ""
	if not (sys._pending_night_card is EventCardData):
		return ""
	var event := sys._pending_night_card as EventCardData
	if event.choices.is_empty():
		return ""
	var block_reason := _choice_block_reason_for_event(sys, event, choice_index)
	if block_reason != "":
		sys.log_message.emit(block_reason)
		return block_reason
	sys._night_choice_done = true
	resolve_building_passives(sys, false)
	return _resolve_event_choice(sys, event, choice_index)


static func choice_block_reason(sys: SurvivalSystem, choice_index: int) -> String:
	if not sys._night_pending or not (sys._pending_night_card is EventCardData):
		return ""
	return _choice_block_reason_for_event(sys, sys._pending_night_card as EventCardData, choice_index)


static func _choice_block_reason_for_event(
	sys: SurvivalSystem, event: EventCardData, choice_index: int
) -> String:
	if event == null or event.choices.is_empty():
		return ""
	var idx := clampi(choice_index, 0, event.choices.size() - 1)
	var choice := event.choices[idx]
	if choice.required_active_building_id != "" and not _has_active_building(sys, choice.required_active_building_id):
		return _active_building_requirement_text(choice.required_active_building_id)
	return ""


static func _active_building_requirement_text(building_id: String) -> String:
	match building_id:
		"building_campfire":
			return _tr("Wymaga aktywnego ogniska.")
		_:
			return _tr("Wymaga aktywnego budynku.")


static func _has_active_building(sys: SurvivalSystem, building_id: String) -> bool:
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.data == null or built.data.id != building_id or built.is_ruined:
				continue
			if building_id == "building_campfire" and built.hp <= 0:
				continue
			return true
	return false


## Resolve the drawn night event and the day's needs, then advance (or finish).
## Called when the player acknowledges the night popup; effects land here so the
## player sees the card BEFORE the stats move. Idempotent per end_day().
static func resolve(sys: SurvivalSystem, choice_index: int = 0) -> void:
	if not sys._night_pending:
		return
	sys._night_pending = false
	var night_card: CardData = sys._pending_night_card
	sys._pending_night_card = null

	# Skip card resolution if a choice (and passives) were already applied via
	# apply_choice — just settle needs and advance.
	if not sys._night_choice_done:
		resolve_building_passives(sys, false)
		if night_card is MonsterCardData:
			_resolve_monster_attack(sys, night_card as MonsterCardData)
		elif night_card is EventCardData:
			var event := night_card as EventCardData
			if not event.choices.is_empty():
				_resolve_event_choice(sys, event, choice_index)
			else:
				_resolve_event(sys, event)
	sys._night_choice_done = false
	_resolve_needs(sys)
	_resolve_campfire_fuel(sys)
	_resolve_scheduled_building_wear(sys)
	sys.stats_changed.emit(sys.state)
	sys.board_changed.emit(sys.state)

	if sys.state.health <= 0:
		sys._finish(false)
		return
	if sys.state.day >= sys.WIN_DAY:
		sys.log_message.emit(_tr("Dzień %d. Budzisz się we własnym łóżku. To był sen?") % sys.WIN_DAY)
		sys._finish(true)
		return

	sys.state.day += 1
	sys._start_day()


# --- Monster attacks (Act II) ---


## A monster card drawn at night: it claws the player and one building,
## then shuffles back into the event deck (monsters don't go away).
static func _resolve_monster_attack(sys: SurvivalSystem, monster: MonsterCardData) -> void:
	sys.log_message.emit(_tr("Potwór: %s — %s") % [_tr(monster.display_name), _tr(monster.description)])

	var player_damage := maxi(
		monster.damage_to_player - sys.state.character_class.monster_damage_reduction, 0
	)
	# A standing Szalas shields the player from night attacks too — until
	# monsters or BUM turn it into a ruin.
	if player_damage > 0 and _has_night_protection(sys):
		player_damage = maxi(player_damage - sys.NIGHT_PROTECTION_VALUE, 0)
		sys.log_message.emit(_tr("Szałas osłania cię przed atakiem."))
	if player_damage > 0 and sys._night_trap:
		sys._night_trap = false
		player_damage = 0
		sys.log_message.emit(_tr("Wnyki przyjmują cios — unikasz ataku potwora."))
	if player_damage > 0 and sys._extra_night_protection > 0:
		player_damage = maxi(player_damage - sys._extra_night_protection, 0)
		sys.log_message.emit(_tr("Warta osłania cię przed atakiem."))
	if player_damage > 0:
		sys.state.health = maxi(sys.state.health - player_damage, 0)
		sys._record_damage(player_damage, _tr("Atak: %s") % _tr(monster.display_name))
		sys.log_message.emit(_tr("%s rani cię. -%d zdrowia.") % [_tr(monster.display_name), player_damage])

	if monster.damage_to_buildings > 0:
		_monster_attack_building(sys, monster)

	# The pool handles recurrence via weight; nothing to discard.
	sys.board_changed.emit(sys.state)


## The monster picks a random standing building; the settlement's summed
## defense (Palisada...) soaks part of the damage.
static func _monster_attack_building(sys: SurvivalSystem, monster: MonsterCardData) -> void:
	var standing: Array = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if not built.is_ruined:
				standing.append(built)
	if standing.is_empty():
		return

	var pick: int = sys._rng.randi_range(0, standing.size() - 1)
	var target: BuildingState = standing[pick]
	var damage := maxi(monster.damage_to_buildings - _settlement_defense(sys), 0)
	if damage <= 0:
		sys.log_message.emit(_tr("Palisada odpiera atak na %s.") % _tr(target.data.display_name))
		return
	target.hp = maxi(target.hp - damage, 0)
	sys.log_message.emit(_tr("%s niszczy %s (-%d HP, zostało %d/%d).") % [
		_tr(monster.display_name), _tr(target.data.display_name), damage,
		target.hp, sys.building_max_hp(target.data),
	])
	sys._check_ruin(target)


## Monster attacks are resisted by the whole settlement's defense, not
## just whatever tile the monster happens to be raiding.
static func _settlement_defense(sys: SurvivalSystem) -> int:
	var defense := 0
	for board_tile in sys.state.board:
		for built in board_tile.buildings:
			if not built.is_ruined:
				defense += built.data.defense
	return defense


# --- Night events ---


static func _resolve_event(sys: SurvivalSystem, event: EventCardData) -> void:
	if event == null:
		return
	sys.log_message.emit(_tr("Zdarzenie: %s — %s") % [_tr(event.display_name), _tr(event.description)])

	var health_delta := event.health_delta
	var warmth_delta := event.warmth_delta
	if event.shelter_protects and _has_night_protection(sys):
		var mitigated_health := mini(health_delta + sys.NIGHT_PROTECTION_VALUE, 0)
		var mitigated_warmth := mini(warmth_delta + sys.NIGHT_PROTECTION_VALUE, 0)
		if mitigated_health != health_delta or mitigated_warmth != warmth_delta:
			sys.log_message.emit(_tr("Szałas osłania cię przed nocą."))
		health_delta = maxi(health_delta, mitigated_health)
		warmth_delta = maxi(warmth_delta, mitigated_warmth)

	# Card verb "ward_night" softens this night's health/warmth losses on top of
	# any shelter, whether or not the event is shelter-protected.
	if sys._extra_night_protection > 0 and (health_delta < 0 or warmth_delta < 0):
		if health_delta < 0:
			health_delta = mini(health_delta + sys._extra_night_protection, 0)
		if warmth_delta < 0:
			warmth_delta = mini(warmth_delta + sys._extra_night_protection, 0)
		sys.log_message.emit(_tr("Warta łagodzi skutki nocy."))

	sys._apply_stat_deltas(health_delta, event.hunger_delta, event.thirst_delta, warmth_delta)
	sys._add_food(event.food_delta)
	sys._add_water(event.water_delta)
	sys._add_wood(event.wood_delta)
	sys._add_materials(event.materials_delta)
	sys.state.next_day_energy_delta += event.next_day_energy_delta
	sys.state.next_day_move_penalty += event.next_day_move_penalty


## Apply the player's chosen option on a decision event. A risky choice may
## backfire and apply its own failure deltas. Returns a short PL summary of the
## outcome for the UI confirmation popup.
static func _resolve_event_choice(
	sys: SurvivalSystem, event: EventCardData, choice_index: int
) -> String:
	sys.log_message.emit(_tr("Zdarzenie: %s — %s") % [_tr(event.display_name), _tr(event.description)])
	var idx := clampi(choice_index, 0, event.choices.size() - 1)
	var choice := event.choices[idx]
	var backfired: bool = choice.risk_chance > 0 \
		and sys._rng.randi_range(0, 99) < choice.risk_chance
	if backfired:
		sys._apply_stat_deltas(
			-choice.risk_health,
			choice.risk_hunger_delta,
			choice.risk_thirst_delta,
			choice.risk_warmth_delta
		)
		sys._add_food(choice.risk_food_gain)
		sys._add_water(choice.risk_water_gain)
		sys._add_wood(choice.risk_wood_gain)
		sys._add_materials(choice.risk_materials_gain)
		sys.state.next_day_energy_delta += choice.risk_next_day_energy_delta
		if choice.risk_health > 0:
			sys._record_damage(choice.risk_health, _tr("Zdarzenie: %s") % _tr(event.display_name))
		var fail_parts := _event_choice_failure_parts(choice)
		var fail_summary := _tr("Nie udało się!")
		if not fail_parts.is_empty():
			fail_summary += " (" + ", ".join(fail_parts) + ")"
		sys.log_message.emit(fail_summary)
		return fail_summary
	sys._apply_stat_deltas(
		choice.health_delta, choice.hunger_delta, choice.thirst_delta, choice.warmth_delta
	)
	sys._add_food(choice.food_gain)
	sys._add_water(choice.water_gain)
	sys._add_wood(choice.wood_gain)
	sys._add_materials(choice.materials_gain)
	sys.state.next_day_energy_delta += choice.next_day_energy_delta
	var parts := _event_choice_success_parts(choice)
	if choice.grant_random_card and not sys._card_pool.is_empty():
		var card: CardData = sys._card_pool[sys._rng.randi_range(0, sys._card_pool.size() - 1)]
		sys.state.deck.append(card)
		sys.log_message.emit(_tr("Zyskujesz kartę do talii: %s.") % _tr(card.display_name))
		parts.append("nowa karta: %s" % _tr(card.display_name))
	if _tr(choice.result_text) != "":
		sys.log_message.emit(_tr(choice.result_text))
	var summary: String = _tr(choice.result_text)
	if not parts.is_empty():
		summary += "\n(" + ", ".join(parts) + ")" if summary != "" else "(" + ", ".join(parts) + ")"
	return summary if summary != "" else _tr("Gotowe.")


static func _event_choice_success_parts(choice: EventChoiceData) -> PackedStringArray:
	var parts: PackedStringArray = []
	if choice.health_delta != 0: parts.append(_tr("%+d zdrowia") % choice.health_delta)
	if choice.hunger_delta != 0: parts.append(_tr("%+d sytości") % choice.hunger_delta)
	if choice.thirst_delta != 0: parts.append(_tr("%+d nawodnienia") % choice.thirst_delta)
	if choice.warmth_delta != 0: parts.append(_tr("%+d ciepła") % choice.warmth_delta)
	if choice.food_gain != 0: parts.append(_tr("%+d jedzenia") % choice.food_gain)
	if choice.water_gain != 0: parts.append(_tr("%+d wody") % choice.water_gain)
	if choice.wood_gain != 0: parts.append(_tr("%+d drewna") % choice.wood_gain)
	if choice.materials_gain != 0: parts.append(_tr("%+d kamienia") % choice.materials_gain)
	if choice.next_day_energy_delta != 0: parts.append(_tr("%+d energii jutro") % choice.next_day_energy_delta)
	return parts


static func _event_choice_failure_parts(choice: EventChoiceData) -> PackedStringArray:
	var parts: PackedStringArray = []
	if choice.risk_health > 0: parts.append(_tr("-%d zdrowia") % choice.risk_health)
	if choice.risk_hunger_delta != 0: parts.append(_tr("%+d sytości") % choice.risk_hunger_delta)
	if choice.risk_thirst_delta != 0: parts.append(_tr("%+d nawodnienia") % choice.risk_thirst_delta)
	if choice.risk_warmth_delta != 0: parts.append(_tr("%+d ciepła") % choice.risk_warmth_delta)
	if choice.risk_food_gain != 0: parts.append(_tr("%+d jedzenia") % choice.risk_food_gain)
	if choice.risk_water_gain != 0: parts.append(_tr("%+d wody") % choice.risk_water_gain)
	if choice.risk_wood_gain != 0: parts.append(_tr("%+d drewna") % choice.risk_wood_gain)
	if choice.risk_materials_gain != 0: parts.append(_tr("%+d kamienia") % choice.risk_materials_gain)
	if choice.risk_next_day_energy_delta != 0: parts.append(_tr("%+d energii jutro") % choice.risk_next_day_energy_delta)
	return parts


# --- Night protection (shelter) ---


static func _has_night_protection(sys: SurvivalSystem) -> bool:
	# Building passives are global, so any standing (non-ruined) Szalas counts.
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.data.special == "night_protection" and not built.is_ruined:
				return true
	return false


static func _wear_night_protection(sys: SurvivalSystem, message: String) -> void:
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.data.special == "night_protection" and not built.is_ruined:
				sys._apply_building_wear(built, sys.BUILDING_PASSIVE_WEAR, message, tile)
				sys.board_changed.emit(sys.state)
				return


## True if a standing shelter (night_protection) sits on the tile the player is
## camped on tonight. Used to soften that tile's biome camp penalties — a reason
## to build a hut where you sleep, not just anywhere.
static func _current_tile_has_shelter(sys: SurvivalSystem) -> bool:
	for built in sys.current_tile().buildings:
		if built.data.special == "night_protection" and not built.is_ruined:
			return true
	return false


## Night penalties from the biome the player is camped on (the tile they ended the
## day on). Cold biomes drain extra warmth, dry ones extra thirst, foul ones risk
## sickness. A shelter on the camped tile halves the warmth loss and sickness risk.
static func camp_modifiers(sys: SurvivalSystem) -> Dictionary:
	var biome: BiomeData = sys.current_tile().biome
	var warmth_loss: int = biome.camp_warmth_loss
	var sickness_chance: float = biome.camp_sickness_chance
	if _current_tile_has_shelter(sys):
		warmth_loss = maxi(warmth_loss - 1, 0)
		sickness_chance *= 0.5
	return {
		"warmth_loss": warmth_loss,
		"thirst_loss": biome.camp_thirst_loss,
		"sickness_chance": sickness_chance,
		"sickness_damage": biome.camp_sickness_damage,
	}


# --- Building passives, wear and campfire fuel ---


static func resolve_building_passives(sys: SurvivalSystem, apply_stat_passives: bool = true) -> void:
	var building_logs: PackedStringArray = []
	var wear_logs: PackedStringArray = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var data: BuildingCardData = built.data
			var snapshot: Dictionary = sys._action_state_snapshot()
			sys._add_food(data.food_gain)
			sys._add_water(data.water_gain)
			sys._add_wood(data.wood_gain)
			sys._add_materials(data.materials_gain)
			if apply_stat_passives:
				sys._apply_stat_deltas(
					data.health_delta, data.hunger_delta, data.thirst_delta,
					building_warmth_value(sys, built)
				)
			var summary: String = sys._action_delta_summary(snapshot)
			if summary != "":
				building_logs.append("%s %s" % [_tr(data.display_name), summary])
				if _should_passive_wear(sys, data, apply_stat_passives):
					if sys._apply_building_wear(built, sys.BUILDING_PASSIVE_WEAR, "", tile):
						wear_logs.append("%s -%d HP" % [_tr(data.display_name), sys.BUILDING_PASSIVE_WEAR])
	if not building_logs.is_empty():
		sys.log_message.emit(_tr("Budynki nocą: %s.") % "; ".join(building_logs))

	if not wear_logs.is_empty():
		sys.log_message.emit(_tr("Praca budynków zużywa: %s.") % "; ".join(wear_logs))


static func standing_building_stat_passives(sys: SurvivalSystem) -> Dictionary:
	var totals := {
		"health": 0,
		"hunger": 0,
		"thirst": 0,
		"warmth": 0,
	}
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			totals["health"] += built.data.health_delta
			totals["hunger"] += built.data.hunger_delta
			totals["thirst"] += built.data.thirst_delta
			totals["warmth"] += building_warmth_value(sys, built)
	return totals


## Campfire warmth is fuel-gated (0 once hp hits 0, i.e. unlit) and gets a
## one-night bonus after "Duży ogień" is used. Every other building just
## reports its flat data.warmth_delta.
static func building_warmth_value(sys: SurvivalSystem, built: BuildingState) -> int:
	if built.data.id != "building_campfire":
		return built.data.warmth_delta
	if built.hp <= 0:
		return 0
	var value: int = built.data.warmth_delta
	if built.campfire_boost_active:
		value += sys.CAMPFIRE_STOKE_BONUS_WARMTH
	return value


## Explicit, separate log line for the "Duży ogień" bonus — the combined
## warmth passives get netted against nightly decay in a single number, which
## can make a working bonus look like it "did nothing" if it's masked by the
## cap or decay. This spells it out regardless of the net result.
static func _campfire_boost_summary(sys: SurvivalSystem) -> String:
	var boosted: PackedStringArray = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.data.id == "building_campfire" \
				and built.hp > 0 and built.campfire_boost_active:
				boosted.append(_tr(built.data.display_name))
	if boosted.is_empty():
		return ""
	return _tr("Duży ogień grzeje dodatkowo: +%d ciepła (%s).") % [
		sys.CAMPFIRE_STOKE_BONUS_WARMTH, ", ".join(boosted)
	]


static func _stat_passive_summary(sys: SurvivalSystem, passives: Dictionary) -> String:
	var parts: PackedStringArray = []
	sys._append_delta_part(parts, int(passives.get("health", 0)), "zdrowia")
	sys._append_delta_part(parts, int(passives.get("hunger", 0)), _tr("sytości"))
	sys._append_delta_part(parts, int(passives.get("thirst", 0)), "nawodnienia")
	sys._append_delta_part(parts, int(passives.get("warmth", 0)), _tr("ciepła"))
	return ", ".join(parts)


static func _resolve_scheduled_building_wear(sys: SurvivalSystem) -> void:
	var wear_logs: PackedStringArray = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var building_id: String = built.data.id
			if sys.NIGHTLY_WEAR_BUILDING_IDS.has(building_id):
				if sys._apply_building_wear(built, sys.DAILY_BUILDING_WEAR, "", tile):
					wear_logs.append("%s -%d HP" % [_tr(built.data.display_name), sys.DAILY_BUILDING_WEAR])
			elif sys.state.day % 2 == 0 and sys.EVERY_OTHER_DAY_WEAR_BUILDING_IDS.has(building_id):
				if sys._apply_building_wear(built, sys.DAILY_BUILDING_WEAR, "", tile):
					wear_logs.append("%s -%d HP" % [_tr(built.data.display_name), sys.DAILY_BUILDING_WEAR])
			elif sys.state.day % 3 == 0 and sys.EVERY_THIRD_DAY_WEAR_BUILDING_IDS.has(building_id):
				if sys._apply_building_wear(built, sys.DAILY_BUILDING_WEAR, "", tile):
					wear_logs.append("%s -%d HP" % [_tr(built.data.display_name), sys.DAILY_BUILDING_WEAR])
			elif sys.state.day % 4 == 0 and sys.EVERY_FOURTH_DAY_WEAR_BUILDING_IDS.has(building_id):
				if sys._apply_building_wear(built, sys.DAILY_BUILDING_WEAR, "", tile):
					wear_logs.append("%s -%d HP" % [_tr(built.data.display_name), sys.DAILY_BUILDING_WEAR])
	if not wear_logs.is_empty():
		sys.log_message.emit(_tr("Zużycie budynków: %s.") % "; ".join(wear_logs))


## Burns 1 night of campfire fuel (hp) per standing campfire. Never ruins the
## campfire — it just goes unlit at 0 (see _check_ruin/building_warmth_value).
static func _resolve_campfire_fuel(sys: SurvivalSystem) -> void:
	var burning: PackedStringArray = []
	var expired: PackedStringArray = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.data.id != "building_campfire" or built.hp <= 0:
				continue
			built.hp -= 1
			if built.hp > 0:
				# Every campfire is named "Ognisko" and the log line already says
				# so — repeating the name here doubled it ("Ognisko: Ognisko: ...").
				burning.append(_tr("paliwo na %d nocy") % built.hp)
			else:
				expired.append(_tr(built.data.display_name))
	if not burning.is_empty():
		sys.log_message.emit(_tr("Ognisko: %s.") % "; ".join(burning))
	if not expired.is_empty():
		sys.log_message.emit(_tr("%s wygasło: dołóż drewno, żeby znów dawało ciepło.") %
			", ".join(expired))


static func _should_passive_wear(
	sys: SurvivalSystem, data: BuildingCardData, apply_stat_passives: bool
) -> bool:
	if data == null or sys.PASSIVE_WEAR_EXCLUDED_BUILDING_IDS.has(data.id):
		return false
	if data.food_gain != 0 or data.water_gain != 0 or data.wood_gain != 0 or data.materials_gain != 0:
		return true
	if apply_stat_passives and (
		data.health_delta != 0 or data.hunger_delta != 0
		or data.thirst_delta != 0 or data.warmth_delta != 0
	):
		return true
	return false


static func _resolve_stat_passive_building_wear(sys: SurvivalSystem, stat_key: String) -> void:
	var wear_logs: PackedStringArray = []
	for tile in sys.state.board:
		for built in tile.buildings:
			if built.is_ruined or not _should_passive_wear(sys, built.data, true):
				continue
			var value := 0
			match stat_key:
				"health":
					value = built.data.health_delta
				"hunger":
					value = built.data.hunger_delta
				"thirst":
					value = built.data.thirst_delta
				"warmth":
					value = building_warmth_value(sys, built)
			if value == 0:
				continue
			if sys._apply_building_wear(built, sys.BUILDING_PASSIVE_WEAR, "", tile):
				wear_logs.append("%s -%d HP" % [_tr(built.data.display_name), sys.BUILDING_PASSIVE_WEAR])
	if not wear_logs.is_empty():
		sys.log_message.emit(_tr("Praca budynków zużywa: %s.") % "; ".join(wear_logs))


# --- Spoilage and the overnight needs balance ---


## Some surplus food spoils each day; the Kucharz and Spiżarnia (slow_spoilage)
## reduce it.
static func _resolve_spoilage(sys: SurvivalSystem) -> void:
	if sys.state.food < sys.SPOILAGE_MIN_FOOD:
		return
	var raw := sys.DAILY_FOOD_SPOILAGE
	if sys.state.food >= sys.HIGH_SPOILAGE_FOOD:
		raw += 1
	var base := int(round(raw * sys.state.character_class.spoilage_multiplier))
	base += sys._act2_rule("act2_food_spoilage_delta")
	var spoiled := maxi(base - sys._count_special("slow_spoilage"), 0)
	if spoiled > 0:
		sys.state.food = maxi(sys.state.food - spoiled, 0)
		sys.log_message.emit(_tr("Część zapasów się psuje. -%d jedzenia.") % spoiled)


static func _resolve_needs(sys: SurvivalSystem) -> void:
	var state: RunState = sys.state
	# Spoilage first, so spoiled food can't be eaten tonight.
	_resolve_spoilage(sys)
	var needs_snapshot: Dictionary = sys._action_state_snapshot()
	var night_crises := 0
	# Where the player camped tonight: harsh biomes add extra night pressure.
	var camp := camp_modifiers(sys)
	var stat_passives := standing_building_stat_passives(sys)
	var passive_summary := _stat_passive_summary(sys, stat_passives)
	if passive_summary != "":
		sys.log_message.emit(_tr("Budynki wspierają potrzeby nocą: %s.") % passive_summary)

	var health_passive := int(stat_passives.get("health", 0))
	if health_passive != 0:
		var health_before_passive := state.health
		state.health = clampi(state.health + health_passive, 0, state.max_health)
		if state.health > health_before_passive:
			_resolve_stat_passive_building_wear(sys, "health")

	# Hunger: building passives and decay resolve as one nightly balance, then
	# food is eaten from stock (class can change food efficiency).
	var hunger_decay: int = sys.DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta \
		+ sys._act2_rule("act2_hunger_decay_delta")
	var food_value := int(round(sys.FOOD_HUNGER_VALUE * state.character_class.food_hunger_multiplier))
	state.hunger = clampi(
		state.hunger + int(stat_passives.get("hunger", 0)) - hunger_decay,
		0,
		RunState.MAX_HUNGER
	)
	var food_eaten := 0
	while state.food > 0 and state.hunger <= RunState.MAX_HUNGER - food_value:
		state.food -= 1
		state.hunger += food_value
		food_eaten += 1
		sys.log_message.emit(_tr("Zjadasz porcję jedzenia (+%d sytości).") % food_value)
	if state.hunger <= 0:
		var hunger_dmg := _deprivation_damage(sys, sys.STARVATION_DAMAGE)
		state.health = maxi(state.health - hunger_dmg, 0)
		night_crises += 1
		sys._record_damage(hunger_dmg, _tr("Głód"))
		sys.log_message.emit(_tr("Sytość spadła do 0: tracisz zdrowie z głodu (-%d zdrowia).") % hunger_dmg)

	# Thirst: building passives and decay resolve together, then drink from
	# stock. Summer makes water pressure harsher.
	var thirst_decay: int = sys.DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta \
		+ sys._act2_rule("act2_thirst_decay_delta")
	if state.season == RunState.Season.SUMMER:
		thirst_decay += sys.SUMMER_EXTRA_THIRST_DECAY
		sys.log_message.emit(_tr("Letni upał wysusza cię szybciej. -%d nawodnienia.") %
			sys.SUMMER_EXTRA_THIRST_DECAY)
	if int(camp["thirst_loss"]) > 0:
		thirst_decay += int(camp["thirst_loss"])
		sys.log_message.emit(_tr("Sucha okolica obozu odbiera dodatkowe nawodnienie. -%d nawodnienia.") %
			int(camp["thirst_loss"]))
	state.thirst = clampi(
		state.thirst + int(stat_passives.get("thirst", 0)) - thirst_decay,
		0,
		RunState.MAX_THIRST
	)
	var water_drunk := 0
	while state.water > 0 and state.thirst <= RunState.MAX_THIRST - sys.WATER_THIRST_VALUE:
		state.water -= 1
		state.thirst += sys.WATER_THIRST_VALUE
		water_drunk += 1
		sys.log_message.emit(_tr("Pijesz wodę (+%d nawodnienia).") % sys.WATER_THIRST_VALUE)
	if state.thirst <= 0:
		var thirst_dmg := _deprivation_damage(sys, sys.DEHYDRATION_DAMAGE)
		state.health = maxi(state.health - thirst_dmg, 0)
		night_crises += 1
		sys._record_damage(thirst_dmg, "Odwodnienie")
		sys.log_message.emit(_tr("Nawodnienie spadło do 0: tracisz zdrowie z odwodnienia (-%d zdrowia).") % thirst_dmg)

	# Warmth: nights are cold; campfires and other passives offset decay before
	# the max cap is applied, so +10 warmth and -3 night becomes a real +7.
	var warmth_decay: int = sys.DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta \
		+ sys._act2_rule("act2_warmth_decay_delta")
	if state.season == RunState.Season.WINTER:
		warmth_decay += sys.WINTER_EXTRA_WARMTH_DECAY
		sys.log_message.emit(_tr("Zimowa noc odbiera dodatkowe ciepło. -%d ciepła.") %
			sys.WINTER_EXTRA_WARMTH_DECAY)
	if int(camp["warmth_loss"]) > 0:
		warmth_decay += int(camp["warmth_loss"])
		sys.log_message.emit(_tr("Zimny biom obozu wychładza cię nocą. -%d ciepła.") %
			int(camp["warmth_loss"]))
	var campfire_boost_text := _campfire_boost_summary(sys)
	if campfire_boost_text != "":
		sys.log_message.emit(campfire_boost_text)
	state.warmth = clampi(
		state.warmth + int(stat_passives.get("warmth", 0)) - warmth_decay,
		0,
		RunState.MAX_WARMTH
	)
	if state.warmth <= 0:
		var warmth_dmg := _deprivation_damage(sys, sys.FREEZING_DAMAGE)
		if _has_night_protection(sys):
			warmth_dmg = maxi(warmth_dmg - 1, 0)
			_wear_night_protection(sys, _tr("Schron bierze na siebie czesc mrozu (-1 HP)."))
		state.health = maxi(state.health - warmth_dmg, 0)
		night_crises += 1
		sys._record_damage(warmth_dmg, _tr("Mróz"))
		sys.log_message.emit(_tr("Ciepło spadło do 0: tracisz zdrowie z zimna (-%d zdrowia).") % warmth_dmg)

	# Camp sickness: foul biomes (Bagno) can flare a disease overnight. A shelter
	# on the camped tile halves the odds (folded into camp["sickness_chance"]).
	var sickness_chance: float = camp["sickness_chance"]
	var sickness_damage: int = int(camp["sickness_damage"])
	if sickness_chance > 0.0 and sickness_damage > 0 and sys._rng.randf() < sickness_chance:
		var sick_dmg := _deprivation_damage(sys, sickness_damage) if state.bum_happened else sickness_damage
		state.health = maxi(state.health - sick_dmg, 0)
		sys._record_damage(sick_dmg, "Choroba")
		sys.log_message.emit(_tr("Wyziewy obozu wywołują chorobę nocą (-%d zdrowia).") % sick_dmg)

	if night_crises > 0:
		var penalty: int = night_crises * sys.NIGHT_CRISIS_ENERGY_PENALTY
		state.next_day_energy_delta -= penalty
		sys.log_message.emit(_tr("Nocny kryzys wyczerpuje cie. Jutro -%d energii.") % penalty)

	if food_eaten > 0 or water_drunk > 0:
		sys.needs_consumed.emit(food_eaten, water_drunk)
	var needs_summary: String = sys._action_delta_summary(needs_snapshot)
	if needs_summary != "":
		sys.log_message.emit(_tr("Bilans potrzeb po nocy: %s.") % needs_summary)


## Hunger/thirst/cold must be a visible threat: before BUM each empty need deals
## its full damage, and after BUM it bites harder.
static func _deprivation_damage(sys: SurvivalSystem, full_damage: int) -> int:
	return full_damage + 1 if sys.state.bum_happened else full_damage
