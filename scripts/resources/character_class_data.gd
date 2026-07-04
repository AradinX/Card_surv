class_name CharacterClassData
extends Resource
## Definition of a playable class (Kucharz, Budowlaniec, Wojskowy) —
## Dzien 50 concept, README section 7. Modifiers are read by systems;
## 1.0 / 0 means "no change from the base rules".

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## Display/difficulty order used when presenting unlocked classes.
## 0 = the starting class (Skaut). Roulette selection itself is random.
@export var unlock_order: int = 0

## Class starter deck (~10 cards incl. 1-2 unique ones).
@export var starter_deck: DeckData

@export_group("Modifiers")
## Multiplier on hunger restored by food (Kucharz 1.5, Budowlaniec < 1).
@export var food_hunger_multiplier: float = 1.0
## Multiplier on food spoilage speed (Kucharz < 1).
@export var spoilage_multiplier: float = 1.0
## Extra energy cost of building cards (Kucharz/Wojskowy +1).
@export var build_energy_cost_delta: int = 0
## Flat discount on building resource costs (Budowlaniec).
@export var build_resource_discount: int = 0
## Bonus HP for constructed buildings (Budowlaniec).
@export var building_hp_bonus: int = 0
## Flat reduction of monster damage dealt to the player (Wojskowy).
@export var monster_damage_reduction: int = 0
## Extra daily hunger decay (Wojskowy +1, negative = hardier appetite).
@export var hunger_rate_delta: int = 0

@export_group("Modifiers — extended")
## Extra daily thirst decay (negative = drinks less).
@export var thirst_rate_delta: int = 0
## Extra daily warmth decay (negative = resists cold).
@export var warmth_rate_delta: int = 0
## Adjusts the energy cost of moving between tiles (negative = cheaper, min 0).
@export var move_energy_delta: int = 0
## Extra cards drawn into the opening hand each dawn.
@export var bonus_hand_cards: int = 0
## Health restored automatically at every dawn (a passive medic/hardy trait).
@export var daily_health_regen: int = 0
## Multiplier on all XP gained (a fast-learner trait).
@export var xp_multiplier: float = 1.0

## Adjusts starting (and maximum) health — a tanky class is +, a frail one −.
@export var health_bonus: int = 0
## Adjusts maximum energy per day (Informatyk −2, etc.).
@export var max_energy_bonus: int = 0

@export_group("Starting resources")
@export var start_food: int = 0
@export var start_water: int = 0
@export var start_wood: int = 0
@export var start_materials: int = 0


## Human-readable list of this class's gameplay modifiers (Polish, one "• " line
## per non-default field). Shared by the menu character panel and the in-run
## marker tooltip. Returns "" when the class has no modifiers.
func ability_summary() -> String:
	var lines: PackedStringArray = []
	if food_hunger_multiplier > 1.0:
		lines.append(tr("Jedzenie syci o %d%% więcej") % roundi((food_hunger_multiplier - 1.0) * 100.0))
	elif food_hunger_multiplier < 1.0:
		lines.append(tr("Jedzenie syci o %d%% mniej") % roundi((1.0 - food_hunger_multiplier) * 100.0))
	if spoilage_multiplier < 1.0:
		lines.append(tr("Wolniejsze psucie jedzenia"))
	elif spoilage_multiplier > 1.0:
		lines.append(tr("Szybsze psucie jedzenia"))
	if build_resource_discount > 0:
		lines.append(tr("Budowa tańsza o %d surowca") % build_resource_discount)
	if build_energy_cost_delta < 0:
		lines.append(tr("Budowa tańsza o %d energii") % -build_energy_cost_delta)
	elif build_energy_cost_delta > 0:
		lines.append(tr("Budowa droższa o %d energii") % build_energy_cost_delta)
	if building_hp_bonus != 0:
		lines.append("%+d HP budowli" % building_hp_bonus)
	if monster_damage_reduction > 0:
		lines.append(tr("−%d obrażeń od potworów") % monster_damage_reduction)
	elif monster_damage_reduction < 0:
		lines.append(tr("+%d obrażeń od potworów") % -monster_damage_reduction)
	if hunger_rate_delta < 0:
		lines.append(tr("Mniejszy głód"))
	elif hunger_rate_delta > 0:
		lines.append(tr("Większy głód"))
	if thirst_rate_delta < 0:
		lines.append(tr("Mniejsze pragnienie"))
	elif thirst_rate_delta > 0:
		lines.append(tr("Większe pragnienie"))
	if warmth_rate_delta < 0:
		lines.append(tr("Wolniej marznie"))
	elif warmth_rate_delta > 0:
		lines.append(tr("Szybciej marznie"))
	if move_energy_delta < 0:
		lines.append(tr("Tańszy ruch po mapie"))
	elif move_energy_delta > 0:
		lines.append(tr("Droższy ruch po mapie"))
	if bonus_hand_cards > 0:
		lines.append("+%d karta na start dnia" % bonus_hand_cards)
	if daily_health_regen > 0:
		lines.append(tr("+%d zdrowia co świt") % daily_health_regen)
	if xp_multiplier > 1.0:
		lines.append("+%d%% XP" % roundi((xp_multiplier - 1.0) * 100.0))
	elif xp_multiplier < 1.0:
		lines.append("−%d%% XP" % roundi((1.0 - xp_multiplier) * 100.0))
	if health_bonus != 0:
		lines.append("%+d maks. zdrowia" % health_bonus)
	if max_energy_bonus != 0:
		lines.append("%+d energii dziennie" % max_energy_bonus)
	var starts: PackedStringArray = []
	if start_food != 0:
		starts.append("%+d jedz." % start_food)
	if start_water != 0:
		starts.append("%+d wody" % start_water)
	if start_wood != 0:
		starts.append("%+d drewna" % start_wood)
	if start_materials != 0:
		starts.append("%+d kamienia" % start_materials)
	if not starts.is_empty():
		lines.append(tr("Start: ") + ", ".join(starts))
	var out: PackedStringArray = []
	for line in lines:
		out.append("• " + line)
	return "\n".join(out)
