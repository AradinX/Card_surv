extends SceneTree
## Invariants of the weighted active night-event pool: per-run cap, cooldown
## spacing and weight bias. Deterministic via a seeded RNG.


func _init() -> void:
	_test_cap()
	_test_cooldown()
	_test_weight()
	_test_pacing()
	print("Night pool test OK")
	quit()


func _event(id: String, weight: int, cooldown: int, cap: int, severity: String = "minor") -> EventCardData:
	var e := EventCardData.new()
	e.id = id
	e.weight = weight
	e.cooldown_days = cooldown
	e.max_per_run = cap
	e.severity = severity
	return e


func _test_cap() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var pool := NightEventPool.new(rng)
	var cands: Array[CardData] = [_event("capped", 10, 0, 2)]
	pool.set_candidates(cands)
	var drawn := 0
	for day in range(1, 6):
		if pool.draw(day) != null:
			drawn += 1
	assert(drawn == 2, "max_per_run cap not respected")
	assert(pool.times_drawn("capped") == 2)


func _test_cooldown() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var pool := NightEventPool.new(rng)
	var cands: Array[CardData] = [_event("slow", 10, 3, 0), _event("fast", 10, 0, 0)]
	pool.set_candidates(cands)
	var last_slow := -100
	for day in range(1, 80):
		var card := pool.draw(day)
		if card != null and card.id == "slow":
			assert(day - last_slow >= 3, "cooldown spacing violated")
			last_slow = day


func _test_weight() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var pool := NightEventPool.new(rng)
	var cands: Array[CardData] = [_event("rare", 1, 0, 0), _event("common", 50, 0, 0)]
	pool.set_candidates(cands)
	var rare := 0
	var common := 0
	for day in range(1, 401):
		var card := pool.draw(day)
		if card.id == "rare":
			rare += 1
		else:
			common += 1
	assert(common > rare * 5, "weight bias not honoured (%d vs %d)" % [common, rare])


func _test_pacing() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pool := NightEventPool.new(rng)
	# A major and a non-major are always both available, so a major night must
	# never be followed immediately by another major.
	var cands: Array[CardData] = [
		_event("heavy", 10, 0, 0, "major"),
		_event("light", 10, 0, 0, "minor"),
	]
	pool.set_candidates(cands)
	var prev := ""
	for day in range(1, 80):
		var card := pool.draw(day)
		var sev: String = card.severity
		assert(not (prev == "major" and sev == "major"), "two major nights in a row")
		prev = sev
