class_name BumResolver
extends RefCounted
## BUM (the mid-run catastrophe) extracted from SurvivalSystem: the strike
## itself, pre-BUM region securing and dawn omens. Stateless — every function
## takes the owning SurvivalSystem, so all run state, constants and signals
## stay in one place and SurvivalSystem's public API is unchanged (it
## delegates here).


## Static funcs have no Object.tr(); route player-facing text through the
## TranslationServer directly (same catalog, PL source text as the key).
static func _tr(text: String) -> String:
	return TranslationServer.translate(text)


## The catastrophe: tiles flip to their corrupted faces, every building
## rolls a damage percent (>= 50% = ruin), and the event deck is rebuilt
## with corrupted biome hazards, disaster events and monster cards.
static func trigger(sys: SurvivalSystem) -> void:
	var state := sys.state
	state.bum_happened = true
	sys.log_message.emit("=== KATASTROFA ===")
	sys.log_message.emit(_tr("Niebo pęka. %s") % _tr(state.disaster.description))

	for tile in state.board:
		tile.is_corrupted = true
		var bum_defense_reduction := defense_damage_reduction(sys)
		for built in tile.buildings:
			var max_hp := sys.building_max_hp(built.data)
			var raw_percent := sys._rng.randi_range(
				sys.BUM_DAMAGE_PERCENT_MIN, sys.BUM_DAMAGE_PERCENT_MAX
			)
			var defense_reduction := bum_defense_reduction
			var secure_reduction := sys.BUM_SECURE_DAMAGE_REDUCTION if tile.bum_secured else 0
			var durability_reduction := durability_damage_reduction(sys, max_hp)
			var percent := maxi(
				raw_percent - defense_reduction - secure_reduction - durability_reduction,
				sys.BUM_MIN_EFFECTIVE_DAMAGE_PERCENT
			)
			built.hp = maxi(built.hp - roundi(max_hp * percent / 100.0), 0)
			sys._check_ruin(built)
			var reduction_text := _reduction_text(
				defense_reduction, secure_reduction, durability_reduction
			)
			if not built.is_ruined:
				sys.log_message.emit("%s: katastrofa %d%% -> %d%%%s (HP %d/%d)." % [
					_tr(built.data.display_name), raw_percent, percent,
					reduction_text, built.hp, max_hp
				])
			else:
				sys.log_message.emit("%s nie wytrzymuje: katastrofa %d%% -> %d%%%s." % [
					_tr(built.data.display_name), raw_percent, percent, reduction_text
				])
		tile.bum_secured = false

	sys._rebuild_event_deck()

	sys.log_message.emit(_tr("Świat już nie jest ten sam. Przetrwaj do dnia %d.") % sys.WIN_DAY)
	if state.disaster != null and _tr(state.disaster.act2_rule_text) != "":
		sys.log_message.emit(_tr(state.disaster.act2_rule_text))
	sys.bum_struck.emit(state.disaster)
	sys.board_changed.emit(state)


## Defense (Palisada/Wieża/Bastion) protects the whole settlement, not just the
## tile it stands on — a wall on one side of the camp still slows the disaster
## down everywhere.
static func defense_damage_reduction(sys: SurvivalSystem) -> int:
	var defense := 0
	for board_tile in sys.state.board:
		for built in board_tile.buildings:
			if not built.is_ruined:
				defense += built.data.defense
	return mini(
		defense * sys.BUM_DEFENSE_DAMAGE_REDUCTION_PER_POINT,
		sys.BUM_DEFENSE_DAMAGE_REDUCTION_MAX
	)


static func durability_damage_reduction(sys: SurvivalSystem, max_hp: int) -> int:
	return clampi(
		max_hp - sys.BUM_DURABILITY_BASELINE_HP,
		0,
		sys.BUM_DURABILITY_DAMAGE_REDUCTION_MAX
	)


static func _reduction_text(
	defense_reduction: int, secure_reduction: int, durability_reduction: int
) -> String:
	var parts: PackedStringArray = []
	if defense_reduction > 0:
		parts.append("obrona rejonu -%d%%" % defense_reduction)
	if secure_reduction > 0:
		parts.append("zabezpieczenie -%d%%" % secure_reduction)
	if durability_reduction > 0:
		parts.append(_tr("wytrzymałość -%d%%") % durability_reduction)
	if parts.is_empty():
		return ""
	return " (%s)" % ", ".join(parts)


# --- Region securing (pre-BUM preparation) ---


static func secured_tile_count(sys: SurvivalSystem) -> int:
	var count := 0
	for tile in sys.state.board:
		if tile.bum_secured:
			count += 1
	return count


static func secure_current_tile_cost(sys: SurvivalSystem) -> Dictionary:
	var secured := secured_tile_count(sys)
	return {
		"energy": sys.BUM_SECURE_BASE_ENERGY_COST + secured * sys.BUM_SECURE_EXTRA_ENERGY_COST,
		"food": 0,
		"thirst": 0,
		"wood": sys.BUM_SECURE_BASE_WOOD_COST + secured * sys.BUM_SECURE_EXTRA_WOOD_COST,
		"materials": sys.BUM_SECURE_BASE_MATERIALS_COST + secured * sys.BUM_SECURE_EXTRA_MATERIALS_COST,
	}


static func secure_current_tile_summary(sys: SurvivalSystem) -> String:
	var cost := secure_current_tile_cost(sys)
	var parts: PackedStringArray = []
	sys._append_cost_part(parts, int(cost["energy"]), "energii")
	sys._append_cost_part(parts, int(cost["wood"]), "drewna")
	sys._append_cost_part(parts, int(cost["materials"]), "kamienia")
	return ", ".join(parts)


## Returns "" when the current tile/base region can be prepared for BUM.
static func can_secure_current_tile(sys: SurvivalSystem) -> String:
	if not sys._day_active:
		return _tr("Dzień dobiegł końca.")
	if sys.state.bum_happened:
		return _tr("Po katastrofie jest już za późno na fortyfikacje.")
	if sys.current_tile().buildings.is_empty():
		return _tr("Najpierw postaw tu przynajmniej jeden budynek.")
	if sys.current_tile().bum_secured:
		return _tr("Ten rejon jest już zabezpieczony.")
	if secured_tile_count(sys) >= sys.BUM_SECURED_TILE_LIMIT:
		return _tr("Limit zabezpieczonych rejonów: %d.") % sys.BUM_SECURED_TILE_LIMIT
	var cost := secure_current_tile_cost(sys)
	if sys.state.energy < int(cost["energy"]):
		return _tr("Za mało energii (potrzeba %d).") % int(cost["energy"])
	if sys.state.wood < int(cost["wood"]):
		return _tr("Za mało drewna (potrzeba %d).") % int(cost["wood"])
	if sys.state.materials < int(cost["materials"]):
		return _tr("Za mało kamienia (potrzeba %d).") % int(cost["materials"])
	return ""


static func secure_current_tile(sys: SurvivalSystem) -> void:
	var block_reason := can_secure_current_tile(sys)
	if block_reason != "":
		sys.log_message.emit(block_reason)
		return
	var cost := secure_current_tile_cost(sys)
	sys.state.energy -= int(cost["energy"])
	sys.state.wood -= int(cost["wood"])
	sys.state.materials -= int(cost["materials"])
	sys.current_tile().bum_secured = true
	sys.log_message.emit(_tr("Zabezpieczasz rejon: %s (%s; -%d%% obrażeń w razie katastrofy, %d%% szans na zwykłe zużycie HP przed kryzysem).") % [
		sys._tile_name(sys.current_tile()),
		secure_current_tile_summary(sys),
		sys.BUM_SECURE_DAMAGE_REDUCTION,
		sys.ACT1_SECURED_WEAR_CHANCE_PERCENT,
	])
	sys.stats_changed.emit(sys.state)
	sys.board_changed.emit(sys.state)


## A secured region can absorb Act I wear on its buildings (60% chance the
## wear still lands — see ACT1_SECURED_WEAR_CHANCE_PERCENT).
static func secured_tile_absorbs_wear(sys: SurvivalSystem, tile: TileState, built: BuildingState) -> bool:
	if tile == null:
		tile = sys._tile_for_building(built)
	if tile == null or sys.state.bum_happened or not tile.bum_secured:
		return false
	if sys._rng.randi_range(0, 99) < sys.ACT1_SECURED_WEAR_CHANCE_PERCENT:
		return false
	sys.log_message.emit(_tr("Zabezpieczony rejon chroni %s przed zużyciem.") % _tr(built.data.display_name))
	return true


# --- Omens (foreshadowing before the sealed BUM day) ---


## Per-disaster foreshadowing lines (keyed by DisasterData.id). Plague reads as
## rot/sickness, Eclipse as cold/dark; unknown disasters fall back to plague.
const BUM_OMENS := {
	"plague": [
		"Martwe ptaki leżą pod drzewami. Żadne zwierzę ich nie tyka.",
		"Ziemia zadrżała. Na horyzoncie stoi zielonkawa łuna.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Zwierzyna ucichła. Las wstrzymuje oddech.",
	],
	"eclipse": [
		"Słońce wschodzi blade i zimne. Cień trwa dłużej niż powinien.",
		"Woda w naczyniach pokryła się rano cienkim lodem.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Ptaki odleciały na południe za wcześnie. Robi się cicho i mroźno.",
	],
	"rift": [
		"Ziemia drży coraz częściej. W skałach pojawiają się rysy.",
		"Ze szczelin w gruncie unosi się gorący, siarkowy pył.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Nocą słychać głuchy huk gdzieś w głębi ziemi.",
	],
	"flood": [
		"Rzeki wezbrały, a deszcz nie ustaje od dni.",
		"Woda podchodzi pod obóz. Grunt zamienia się w błoto.",
		"Sny są coraz cięższe. Coś nadchodzi.",
		"Powietrze jest ciężkie od wilgoci. Wszystko pleśnieje.",
	],
}


static func is_omen_window(sys: SurvivalSystem) -> bool:
	return not sys.state.bum_happened \
		and sys.state.disaster != null \
		and sys.state.bum_day > 0 \
		and sys.state.day >= sys.state.bum_day - sys.BUM_OMEN_LEAD_DAYS


## Foreshadowing in the last days before BUM (the player senses SOMETHING).
static func log_omen(sys: SurvivalSystem) -> void:
	var key: String = sys.state.disaster.id if sys.state.disaster != null else ""
	var omens: Array = BUM_OMENS.get(key, BUM_OMENS["plague"])
	sys.log_message.emit(_tr("Omen: %s") % _tr(omens[sys.state.day % omens.size()]))
