class_name RunFx
extends RefCounted
## Fullscreen/ambient FX of the run scene, extracted from run.gd: the BUM
## transition sequence, seasonal weather overlays, one-shot world FX (card
## feedback, tile FX) and the critical-stat vignettes. Pure presentation —
## it only spawns/animates layers on the nodes the run scene hands it.
## All assets are optional (guarded by ResourceLoader.exists).

## BUM transition FX (fullscreen overlays). Additive ones sit on black, the
## rest are chroma-keyed to alpha; see tools/chroma_key_blue.gd.
const BUM_FX := {
	"omen": "res://assets/art/fx/bum/fx_omen_glow.png",
	"flash": "res://assets/art/fx/bum/fx_bum_flash.png",
	"shock": "res://assets/art/fx/bum/fx_shockwave_ring.png",
	"petals": "res://assets/art/fx/bum/fx_blast_petals.png",
	"rift1": "res://assets/art/fx/bum/fx_sky_rift_01.png",
	"rift2": "res://assets/art/fx/bum/fx_sky_rift_02.png",
	"crack": "res://assets/art/fx/bum/fx_screen_crack_overlay.png",
	"wilt": "res://assets/art/fx/bum/fx_wilt_overlay.png",
	"rot": "res://assets/art/fx/corruption/fx_rot_wipe.png",
	"cloud1": "res://assets/art/fx/corruption/fx_plague_cloud_01.png",
	"cloud2": "res://assets/art/fx/corruption/fx_plague_cloud_02.png",
	"vignette": "res://assets/art/fx/corruption/fx_corruption_vignette.png",
	"motes": "res://assets/art/fx/corruption/fx_spore_motes_loop.png",
}
const BUM_FX_ADDITIVE := ["omen", "flash", "motes"]
## Corruption FX layers that get recolored per disaster (the blast itself stays
## natural). Plague keeps them green; Eclipse tints them icy blue.
const ACT2_TINT_LAYERS := ["rot", "cloud1", "cloud2", "wilt", "petals", "vignette", "motes"]
const WEATHER_RAIN := "res://assets/art/fx/weather/fx_rain_overlay.png"
const WEATHER_SNOW := "res://assets/art/fx/weather/fx_snow_overlay.png"
const WEATHER_FROST := "res://assets/art/fx/weather/fx_frost_edges.png"
const HEAL_FX := "res://assets/art/fx/cards/fx_heal_spark.png"
const RESOURCE_FX := "res://assets/art/fx/cards/fx_resource_gain.png"
## Pre-wired (assets not yet generated — guarded by ResourceLoader.exists).
const LOW_HP_FX := "res://assets/art/fx/ui/fx_low_hp_vignette.png"
const LOW_HUNGER_FX := "res://assets/art/fx/ui/fx_low_hunger_vignette.png"
const LOW_THIRST_FX := "res://assets/art/fx/ui/fx_low_thirst_vignette.png"
## Low-HP danger vignette shows at or below this fraction of max health.
const LOW_HP_FRACTION := 0.3
const NEED_WARNING_FRACTION := 0.3
const NEED_WARNING_COLORS := {
	"hunger": Color(1.0, 0.55, 0.18, 1.0),
	"thirst": Color(0.22, 0.62, 1.0, 1.0),
	"warmth": Color(0.78, 0.95, 1.0, 1.0),
}
const NEED_WARNING_FX := {
	"hunger": LOW_HUNGER_FX,
	"thirst": LOW_THIRST_FX,
	"warmth": WEATHER_FROST,
}

var _run: Control
var _background: ColorRect
var _background_art: TextureRect
var _weather_overlay: TextureRect
var _frost_overlay: TextureRect
var _low_hp_overlay: TextureRect
var _low_hp_tween: Tween
var _need_warning_overlays: Dictionary = {}
var _need_warning_tweens: Dictionary = {}
## Per-disaster tint for the corruption layers, set by play_bum_fx.
var _bum_tint := Color(1, 1, 1)


func _init(run: Control, background: ColorRect, background_art: TextureRect) -> void:
	_run = run
	_background = background
	_background_art = background_art


## Creates the persistent ambient layers (weather, frost, critical vignettes).
func create_overlays() -> void:
	_weather_overlay = _make_ambient_overlay(0.5)
	_frost_overlay = _make_ambient_overlay(0.45)
	_create_low_hp_overlay()
	_create_need_warning_overlays()


# --- BUM transition ---


## Cataclysm: a layered fullscreen sequence — dread glow, blast (flash +
## shockwave + torn petals), the sky tearing, then creeping rot/plague that
## wipes the lush board over to its corrupted Act II face. A dark vignette and
## drifting spores stay for the rest of the run. `on_flash_peak` swaps the UI
## to its Act II look under the flash so the player never sees a raw flip.
func play_bum_fx(look: Dictionary, on_flash_peak: Callable) -> void:
	for id in BUM_FX:
		if not ResourceLoader.exists(BUM_FX[id]):
			on_flash_peak.call()
			return
	_bum_tint = look["fx_tint"]

	var fx := Control.new()
	_run.add_child(fx)
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center: Vector2 = _run.size * 0.5
	var omen := _make_fx_layer("omen", fx)
	var flash := _make_fx_layer("flash", fx)
	var shock := _make_fx_layer("shock", fx)
	shock.pivot_offset = center
	shock.scale = Vector2(0.15, 0.15)
	var petals := _make_fx_layer("petals", fx)
	petals.pivot_offset = center
	petals.scale = Vector2(0.6, 0.6)
	var rift1 := _make_fx_layer("rift1", fx)
	var rift2 := _make_fx_layer("rift2", fx)
	var crack := _make_fx_layer("crack", fx)
	var wilt := _make_fx_layer("wilt", fx)
	var rot := _make_fx_layer("rot", fx)
	var cloud1 := _make_fx_layer("cloud1", fx)
	var cloud2 := _make_fx_layer("cloud2", fx)
	# Persistent Act II atmosphere — parented to the scene, then moved to sit
	# just above the board background and BELOW the gameplay UI, so it blends
	# into the backdrop instead of covering the HUD and cards. The transient fx
	# container stays on top (added later) for the blast.
	var vignette := _make_fx_layer("vignette", _run)
	var motes := _make_fx_layer("motes", _run)
	var bg_index := _background_art.get_index()
	_run.move_child(vignette, bg_index + 1)
	_run.move_child(motes, bg_index + 2)

	var t := _run.create_tween().set_parallel(true)
	# 1) Dread glow swells and fades.
	t.tween_property(omen, "modulate:a", 0.7, 0.25)
	t.tween_property(omen, "modulate:a", 0.0, 0.6).set_delay(0.55)
	# 2) Blast: flash, expanding shockwave ring and torn petals. The Act II look
	# is swapped in under the flash peak.
	t.tween_property(flash, "modulate:a", 1.0, 0.08).set_delay(0.25)
	t.tween_property(flash, "modulate:a", 0.0, 0.5).set_delay(0.42)
	t.tween_callback(on_flash_peak).set_delay(0.34)
	t.tween_property(shock, "modulate:a", 0.9, 0.1).set_delay(0.26)
	t.tween_property(shock, "scale", Vector2(1.55, 1.55), 0.6) \
		.set_delay(0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(shock, "modulate:a", 0.0, 0.35).set_delay(0.55)
	t.tween_property(petals, "modulate:a", 1.0, 0.12).set_delay(0.28)
	t.tween_property(petals, "scale", Vector2(1.3, 1.3), 0.75) \
		.set_delay(0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(petals, "modulate:a", 0.0, 0.5).set_delay(0.62)
	# 3) The sky tears (rift_01 -> rift_02) and the screen cracks.
	t.tween_property(rift1, "modulate:a", 0.95, 0.2).set_delay(0.5)
	t.tween_property(rift1, "modulate:a", 0.0, 0.3).set_delay(0.82)
	t.tween_property(rift2, "modulate:a", 0.95, 0.3).set_delay(0.8)
	t.tween_property(crack, "modulate:a", 0.8, 0.25).set_delay(0.6)
	# 4) Rot and plague creep in and wipe the board to Act II; the pretty Act I
	# flowers wilt and brown along the ground.
	t.tween_property(rot, "modulate:a", 1.0, 0.65).set_delay(0.85)
	t.tween_property(wilt, "modulate:a", 1.0, 0.7).set_delay(0.8)
	t.tween_property(cloud1, "modulate:a", 0.9, 0.7).set_delay(0.9)
	t.tween_property(cloud2, "modulate:a", 0.85, 0.7).set_delay(1.05)
	# 5) Persistent atmosphere settles in.
	t.tween_property(vignette, "modulate:a", 1.0, 0.8).set_delay(1.45)
	t.tween_property(motes, "modulate:a", 0.5, 1.0).set_delay(1.6)
	# 6) Transient corruption fades out, revealing the settled Act II board.
	t.tween_property(rift2, "modulate:a", 0.0, 0.6).set_delay(1.7)
	t.tween_property(crack, "modulate:a", 0.0, 0.7).set_delay(1.7)
	t.tween_property(rot, "modulate:a", 0.0, 0.9).set_delay(2.0)
	t.tween_property(wilt, "modulate:a", 0.0, 0.9).set_delay(2.05)
	t.tween_property(cloud1, "modulate:a", 0.0, 0.8).set_delay(2.1)
	t.tween_property(cloud2, "modulate:a", 0.0, 0.8).set_delay(2.2)

	t.finished.connect(func() -> void:
		if is_instance_valid(fx):
			fx.queue_free()
		_loop_spore_motes(motes)
	)


func _make_fx_layer(id: String, parent: Control) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(BUM_FX[id])
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.modulate.a = 0.0
	if id in ACT2_TINT_LAYERS:
		# self_modulate tints RGB while the alpha fade rides on modulate.a.
		layer.self_modulate = _bum_tint
	parent.add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if id in BUM_FX_ADDITIVE:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		layer.material = mat
	return layer


## Gentle breathing loop for the lingering spore haze.
func _loop_spore_motes(motes: TextureRect) -> void:
	if not is_instance_valid(motes):
		return
	var loop := _run.create_tween().set_loops()
	loop.tween_property(motes, "modulate:a", 0.28, 3.5).set_trans(Tween.TRANS_SINE)
	loop.tween_property(motes, "modulate:a", 0.5, 3.5).set_trans(Tween.TRANS_SINE)


# --- Seasonal weather ---


## A full-screen ambient layer above the scrim but below the gameplay UI, so it
## never covers popups.
func _make_ambient_overlay(alpha: float) -> TextureRect:
	var overlay := TextureRect.new()
	overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.modulate.a = alpha
	overlay.visible = false
	_run.add_child(overlay)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_run.move_child(overlay, _background.get_index() + 1)
	return overlay


## Rain in spring/autumn, snow + frost vignette in winter, clear in summer.
func update_weather(season: int) -> void:
	if _weather_overlay == null:
		return
	var path := ""
	match season:
		RunState.Season.WINTER:
			path = WEATHER_SNOW
		RunState.Season.SPRING, RunState.Season.AUTUMN:
			path = WEATHER_RAIN
		_:
			path = ""
	if path != "" and ResourceLoader.exists(path):
		_weather_overlay.texture = load(path)
		_weather_overlay.visible = true
	else:
		_weather_overlay.visible = false

	var is_winter := season == RunState.Season.WINTER
	if is_winter and ResourceLoader.exists(WEATHER_FROST):
		_frost_overlay.texture = load(WEATHER_FROST)
		_frost_overlay.visible = true
	else:
		_frost_overlay.visible = false


# --- One-shot world FX ---


## Pops a heal/resource sparkle over a just-played card.
func card_feedback_fx(card: CardData, view: Control) -> void:
	card_feedback_fx_at(card, view.global_position + view.size * 0.5)


func card_feedback_fx_at(card: CardData, center: Vector2) -> void:
	if not (card is ActionCardData):
		return
	var action := card as ActionCardData
	var path := ""
	if action.health_delta > 0:
		path = HEAL_FX
	elif action.food_gain > 0 or action.water_gain > 0 \
			or action.wood_gain > 0 or action.materials_gain > 0:
		path = RESOURCE_FX
	if path == "" or not ResourceLoader.exists(path):
		return
	spawn_world_fx(path, center, Vector2(150, 150))


## A one-shot FX at a screen point, auto-freed when it finishes. Additive glows
## (sparks) on black; cut-out FX (dust, rubble) keep normal blending.
func spawn_world_fx(path: String, center: Vector2, fx_size: Vector2, additive := true) -> void:
	var fx := TextureRect.new()
	fx.texture = load(path)
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.size = fx_size
	fx.position = center - fx_size * 0.5
	fx.pivot_offset = fx_size * 0.5
	fx.modulate.a = 0.0
	fx.scale = Vector2(0.7, 0.7)
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = mat
	_run.add_child(fx)
	var t := _run.create_tween()
	t.tween_property(fx, "modulate:a", 1.0, 0.1)
	t.parallel().tween_property(fx, "scale", Vector2(1.2, 1.2), 0.32)
	t.tween_property(fx, "modulate:a", 0.0, 0.3)
	t.tween_callback(fx.queue_free)


# --- Critical-stat vignettes ---


func _create_low_hp_overlay() -> void:
	_low_hp_overlay = TextureRect.new()
	_low_hp_overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_low_hp_overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_low_hp_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_low_hp_overlay.modulate.a = 0.0
	_low_hp_overlay.visible = false
	if ResourceLoader.exists(LOW_HP_FX):
		_low_hp_overlay.texture = load(LOW_HP_FX)
	_run.add_child(_low_hp_overlay)
	_low_hp_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Pulsing red vignette when health is critically low (skipped if asset absent).
func update_low_hp_vignette(state: RunState) -> void:
	if _low_hp_overlay == null or _low_hp_overlay.texture == null:
		return
	var critical := state.health > 0 \
		and state.health <= int(ceil(state.max_health * LOW_HP_FRACTION))
	if critical and not _low_hp_overlay.visible:
		_low_hp_overlay.visible = true
		_low_hp_tween = _run.create_tween().set_loops()
		_low_hp_tween.tween_property(_low_hp_overlay, "modulate:a", 0.7, 0.6) \
			.set_trans(Tween.TRANS_SINE)
		_low_hp_tween.tween_property(_low_hp_overlay, "modulate:a", 0.28, 0.6) \
			.set_trans(Tween.TRANS_SINE)
	elif not critical and _low_hp_overlay.visible:
		if _low_hp_tween != null:
			_low_hp_tween.kill()
			_low_hp_tween = null
		_low_hp_overlay.visible = false
		_low_hp_overlay.modulate.a = 0.0


func _create_need_warning_overlays() -> void:
	for id in NEED_WARNING_COLORS.keys():
		var texture_path := str(NEED_WARNING_FX.get(id, ""))
		if not ResourceLoader.exists(texture_path):
			texture_path = LOW_HP_FX
		if not ResourceLoader.exists(texture_path):
			continue
		var overlay := TextureRect.new()
		overlay.texture = load(texture_path)
		overlay.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		overlay.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var color: Color = NEED_WARNING_COLORS[id]
		color.a = 0.0
		overlay.modulate = color
		overlay.visible = false
		_run.add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_need_warning_overlays[id] = overlay


func update_need_warning_vignettes(state: RunState) -> void:
	_update_need_warning_vignette("hunger", state.hunger, RunState.MAX_HUNGER, 0.42, 0.16)
	_update_need_warning_vignette("thirst", state.thirst, RunState.MAX_THIRST, 0.46, 0.18)
	_update_need_warning_vignette("warmth", state.warmth, RunState.MAX_WARMTH, 0.44, 0.16)


func _update_need_warning_vignette(
	id: String, current: int, maximum: int, high_alpha: float, low_alpha: float
) -> void:
	var overlay := _need_warning_overlays.get(id) as TextureRect
	if overlay == null:
		return
	var critical := current <= int(ceil(maximum * NEED_WARNING_FRACTION))
	if critical and not overlay.visible:
		overlay.visible = true
		var color: Color = NEED_WARNING_COLORS[id]
		color.a = low_alpha
		overlay.modulate = color
		var peak_alpha := high_alpha + 0.12 if current <= 0 else high_alpha
		var base_alpha := low_alpha + 0.06 if current <= 0 else low_alpha
		var tween := _run.create_tween().set_loops()
		tween.tween_property(overlay, "modulate:a", peak_alpha, 0.65) \
			.set_trans(Tween.TRANS_SINE)
		tween.tween_property(overlay, "modulate:a", base_alpha, 0.65) \
			.set_trans(Tween.TRANS_SINE)
		_need_warning_tweens[id] = tween
	elif not critical and overlay.visible:
		var tween := _need_warning_tweens.get(id) as Tween
		if tween != null:
			tween.kill()
			_need_warning_tweens[id] = null
		overlay.visible = false
		overlay.modulate.a = 0.0
