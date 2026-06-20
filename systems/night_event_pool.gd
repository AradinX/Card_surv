class_name NightEventPool
extends RefCounted
## Weighted active pool of night-event cards with a bit of a brain on top of
## plain randomness:
##  - WEIGHT: relative draw frequency.
##  - COOLDOWN: minimum days between two appearances of the same card.
##  - CAP: optional hard limit of appearances per run.
##  - CATEGORY (neutral/weather/biome/omen/monster/disaster): phase weighting
##    boosts/suppresses whole categories depending on the run phase.
##  - SEVERITY (minor/medium/major): pacing avoids two "major" nights in a row.
##
## Draw history (last day used, times used, last severity) PERSISTS across
## candidate rebuilds — discovery and BUM change WHICH cards are in the pool,
## not the memory. Monsters take part with weight = copies_in_deck.
##
## Uses an injected RNG so runs can be seeded in the future.

enum Phase { ACT1, OMEN, ACT2 }

const DEFAULT_WEIGHT := 10
## Per-phase category weight multipliers (missing category -> 1.0).
const PHASE_CATEGORY_MULT := {
	Phase.ACT1: {"omen": 0.0},
	Phase.OMEN: {"omen": 5.0},
	Phase.ACT2: {"omen": 0.0, "monster": 3.0},
}

var _rng: RandomNumberGenerator
var _candidates: Array[CardData] = []
var _last_day: Dictionary = {}  # card id -> last day drawn
var _count: Dictionary = {}     # card id -> times drawn this run
var _last_severity: String = ""


func _init(rng: RandomNumberGenerator) -> void:
	_rng = rng


## Replaces the candidate set (deduped by id), keeping the cooldown/limit/pacing
## history. Biomes reference base events, so the same card can come from several
## sources — we only ever want one weighted entry per id.
func set_candidates(cards: Array[CardData]) -> void:
	_candidates = []
	var seen := {}
	for card in cards:
		if seen.has(card.id):
			continue
		seen[card.id] = true
		_candidates.append(card)


## Draws one card for the given day and phase. Honours caps always; relaxes
## cooldowns and then the no-double-major rule only if nothing else qualifies,
## so a night is never silent.
func draw(day: int, phase: int = Phase.ACT1) -> CardData:
	if _candidates.is_empty():
		return null
	var eligible := _filter(day, true, true)
	if eligible.is_empty():
		eligible = _filter(day, false, true)   # relax cooldown
	if eligible.is_empty():
		eligible = _filter(day, false, false)  # relax pacing too
	if eligible.is_empty():
		return null
	var card := _weighted_pick(eligible, phase)
	if card != null:
		_last_day[card.id] = day
		_count[card.id] = int(_count.get(card.id, 0)) + 1
		_last_severity = _severity(card)
	return card


func times_drawn(card_id: String) -> int:
	return int(_count.get(card_id, 0))


func _filter(day: int, respect_cooldown: bool, respect_pacing: bool) -> Array[CardData]:
	var out: Array[CardData] = []
	for card in _candidates:
		var cap := _max_per_run(card)
		if cap > 0 and int(_count.get(card.id, 0)) >= cap:
			continue
		if respect_cooldown:
			var cd := _cooldown(card)
			if cd > 0 and _last_day.has(card.id) and day - int(_last_day[card.id]) < cd:
				continue
		# Pacing: don't follow a major night with another major one.
		if respect_pacing and _last_severity == "major" and _severity(card) == "major":
			continue
		out.append(card)
	return out


func _weighted_pick(cards: Array[CardData], phase: int) -> CardData:
	var weights: Array[int] = []
	var total := 0
	for card in cards:
		var w := _phase_weight(card, phase)
		weights.append(w)
		total += w
	if total <= 0:
		return cards[_rng.randi_range(0, cards.size() - 1)]
	var roll := _rng.randi_range(1, total)
	var acc := 0
	for i in cards.size():
		acc += weights[i]
		if roll <= acc:
			return cards[i]
	return cards[cards.size() - 1]


func _phase_weight(card: CardData, phase: int) -> int:
	var base := _weight(card)
	var mult: Dictionary = PHASE_CATEGORY_MULT.get(phase, {})
	var factor: float = mult.get(_category(card), 1.0)
	return int(round(base * factor))


func _weight(card: CardData) -> int:
	if card is MonsterCardData:
		return maxi((card as MonsterCardData).copies_in_deck, 1)
	var w: Variant = card.get("weight")
	if w != null and int(w) > 0:
		return int(w)
	return DEFAULT_WEIGHT


func _cooldown(card: CardData) -> int:
	var c: Variant = card.get("cooldown_days")
	return int(c) if c != null else 0


func _max_per_run(card: CardData) -> int:
	var m: Variant = card.get("max_per_run")
	return int(m) if m != null else 0


func _category(card: CardData) -> String:
	if card is MonsterCardData:
		return "monster"
	var c: Variant = card.get("category")
	return str(c) if c != null and str(c) != "" else "neutral"


func _severity(card: CardData) -> String:
	if card is MonsterCardData:
		# Heavy hitters pace like majors; building-only swarms are lighter.
		return "major" if (card as MonsterCardData).damage_to_player >= 2 else "medium"
	var s: Variant = card.get("severity")
	return str(s) if s != null and str(s) != "" else "minor"
