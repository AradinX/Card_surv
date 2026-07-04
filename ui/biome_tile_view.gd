class_name BiomeTileView
extends Button
## Visual board tile composed in Godot: a clean biome background, an ornate
## chroma-keyed frame (corruption frame after BUM), a centered nameplate, a
## "you are here" marker and a row of building slots (empty / occupied by a
## built building, with its HP), all driven from the tile state.
signal building_pressed(building_index: int, anchor_rect: Rect2)
signal card_dropped(payload: Dictionary)
signal secure_region_pressed(anchor_rect: Rect2)

const NORMAL_BG_DIR := "res://assets/art/biomes/backgrounds/normal"
const CORRUPTED_BG_DIR := "res://assets/art/biomes/backgrounds/corrupted"
const UNKNOWN_BG := "res://assets/art/biomes/discovery/biome_unknown.png"
const TILE_FRAME := "res://assets/art/biomes/frames/biome_tile_frame.png"
const CORRUPTION_FRAME := "res://assets/art/biomes/overlays/biome_corruption_overlay.png"
const SECURE_REGION_FRAME := "res://assets/art/biomes/overlays/biome_secure_region_frame.png"
const TITLE_PLATE := "res://assets/art/biomes/frames/biome_title_plate.png"
const SECURE_REGION_ICON := "res://assets/art/ui/icons/icon_secure_region.png"
const SECURE_REGION_ICON_FALLBACK := "res://assets/art/ui/icons/icon_repair_round.png"
## Marker on the current tile. Defaults to the universal medallion; per-class
## medallions (marker_<class_id>.png) override it when present — see
## set_marker_for_class(), called once by run.gd at run start.
const PLAYER_MARKER := "res://assets/art/biomes/overlays/biome_current_player.png"
const CLASS_MARKER_DIR := "res://assets/art/characters"
static var _marker_path: String = PLAYER_MARKER
## Hover tooltip on the current-tile marker (class name + ability summary).
static var _marker_tooltip: String = ""
@export var secure_region_frame_texture: Texture2D
const BUILDING_ART_ALIASES := {
	"building_stone_storage": "building_quarry",
}


## Pick the current-tile marker + hover tooltip for the played class (falls back
## to the universal medallion if that class has no portrait marker yet).
static func set_marker_for_class(character_class: CharacterClassData) -> void:
	if character_class == null:
		_marker_path = PLAYER_MARKER
		_marker_tooltip = ""
		return
	var path := "%s/marker_%s.png" % [CLASS_MARKER_DIR, character_class.id]
	_marker_path = path if ResourceLoader.exists(path) else PLAYER_MARKER
	_marker_tooltip = TranslationServer.translate(character_class.display_name)
	var summary := character_class.ability_summary()
	if summary != "":
		_marker_tooltip += "\n" + summary
const BUILDING_ART_DIR := "res://assets/art/cards/illustrations/buildings_act1_candidates"
## Discovery fog layers, stacked bottom -> top (reveal_01 at the back,
## reveal_02 on top). Peeled away in REVEAL_FADE_ORDER, with reveal_03 left for
## the final dissipating animation.
const REVEAL_STACK := [
	["reveal_01", "res://assets/art/fx/discovery/fx_tile_reveal_01.png"],
	["fog_loop", "res://assets/art/fx/discovery/fx_fog_loop_01.png"],
	["reveal_03", "res://assets/art/fx/discovery/fx_tile_reveal_03.png"],
	["reveal_02", "res://assets/art/fx/discovery/fx_tile_reveal_02.png"],
]
## Layers faded one after another (slowly); "reveal_03" closes with the
## dissipating fade + expand.
## Per-layer dissolve timing [start_delay, duration]; the windows overlap so
## the reveal reads as one continuous animation rather than separate steps.
## reveal_03 (closing) is timed to finish together with fog_loop and adds the
## expand — see CLOSING_DUR / play_discovery_fx.
const REVEAL_FADE := {
	"reveal_02": [0.0, 0.95],
	"reveal_01": [0.4, 1.15],
	"fog_loop": [0.55, 0.95],
}
const CLOSING_DUR := 1.1
## Radial dissolve: the transparent disc grows from the centre outwards as
## `progress` rises, so each fog layer clears from the middle to the edges.
const DISSOLVE_SHADER := "shader_type canvas_item;
uniform float progress : hint_range(0.0, 1.5) = 0.0;
uniform float softness : hint_range(0.01, 1.0) = 0.22;
void fragment() {
	vec4 col = texture(TEXTURE, UV);
	float d = distance(UV, vec2(0.5)) / 0.70710678;
	col.a *= smoothstep(progress - softness, progress, d);
	COLOR = col;
}"
const BIOME_ART_IDS := {
	"forest": "forest",
	"meadows": "meadow",
	"mountains": "mountains",
	"swamp": "swamp",
	"river": "river",
	"wasteland": "wasteland",
	"caves": "caves",
	"coast": "coast",
}
## Smoldering FX on a ruined building (all optional — skipped if absent).
const RUIN_SMOKE_FX := "res://assets/art/fx/smoke/fx_smoke_loop.png"
const RUIN_FIRE_FX := "res://assets/art/fx/fire/fx_small_fire_loop.png"
const RUIN_BURN_FX := "res://assets/art/fx/fire/fx_burn_marks.png"
const SLOT_SIZE := Vector2(50, 62)
## Max slots shown on a tile, and a small per-slot vertical offset so the row
## reads less like a rigid grid.
const MAX_SLOTS := 3
const SLOT_STAGGER := [16, 0, 9]

@onready var _background: TextureRect = $Background
@onready var _state_overlay: ColorRect = $StateOverlay
@onready var _secure_region_frame: TextureRect = $SecureRegionFrame
@onready var _frame: TextureRect = $Frame
@onready var _player_marker: TextureRect = $PlayerMarker
@onready var _title_plate: TextureRect = $TitlePlate
@onready var _title_label: Label = $TitlePlate/TitleLabel
@onready var _slots_label: Label = $TitlePlate/SlotsLabel
@onready var _slots_row: HBoxContainer = $SlotsRow
@onready var _secure_region_button: TextureButton = $BuildingsButton

var _reveal_tween: Tween
var _reveal_layers: Dictionary = {}
var _slot_tweens: Array[Tween] = []
var _accept_card_drops := false
var _drop_highlight := false
static var _dissolve_shader: Shader


func _ready() -> void:
	_slots_row.mouse_filter = Control.MOUSE_FILTER_PASS
	_configure_secure_region_frame()
	_configure_secure_region_button()


func secure_region_button_rect() -> Rect2:
	if _secure_region_button != null and _secure_region_button.visible:
		return _secure_region_button.get_global_rect()
	return get_global_rect()


func set_accept_card_drops(enabled: bool) -> void:
	_accept_card_drops = enabled


func set_drop_highlight(enabled: bool) -> void:
	_drop_highlight = enabled
	if enabled:
		_state_overlay.color = Color(0.45, 0.72, 0.24, 0.24)
	elif is_node_ready():
		_state_overlay.color = Color.TRANSPARENT


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return _accept_card_drops and _is_card_payload(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _is_card_payload(data):
		return
	card_dropped.emit(data as Dictionary)


func _is_card_payload(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload := data as Dictionary
	return payload.get("type", "") == "play_card" and payload.has("source")


func play_discovery_fx() -> void:
	if _reveal_tween != null:
		_reveal_tween.kill()
	_clear_reveal_layers()

	# Stack the fog as real layers over the tile (bottom -> top), all at full
	# opacity so the biome stays fully hidden until the mist is peeled away. The
	# reveal must END on the biome, not start on it.
	for entry in REVEAL_STACK:
		var layer := _make_reveal_layer(entry[1])
		add_child(layer)
		_reveal_layers[entry[0]] = layer

	var closing: TextureRect = _reveal_layers["reveal_03"]
	closing.pivot_offset = size * 0.5

	# All dissolves run in parallel with overlapping windows (REVEAL_FADE), so
	# they read as one continuous animation rather than separate steps. Each
	# layer clears from its centre outwards via the radial dissolve shader.
	const DISSOLVE_FULL := 1.25
	_reveal_tween = create_tween().set_parallel(true)
	for id in REVEAL_FADE:
		var timing: Array = REVEAL_FADE[id]
		_reveal_tween.tween_property(_reveal_layers[id].material,
			"shader_parameter/progress", DISSOLVE_FULL, timing[1]) \
			.set_delay(timing[0]).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Closing layer (reveal_03) finishes together with fog_loop and also expands
	# from the centre (mist blowing away) for the final beat.
	var fog_timing: Array = REVEAL_FADE["fog_loop"]
	var closing_delay: float = fog_timing[0] + fog_timing[1] - CLOSING_DUR
	_reveal_tween.tween_property(closing.material, "shader_parameter/progress",
		DISSOLVE_FULL, CLOSING_DUR) \
		.set_delay(closing_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_reveal_tween.tween_property(closing, "scale", Vector2(1.22, 1.22), CLOSING_DUR) \
		.set_delay(closing_delay).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_reveal_tween.finished.connect(_clear_reveal_layers)


func _make_reveal_layer(path: String) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(path)
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.anchor_right = 1.0
	layer.anchor_bottom = 1.0
	layer.offset_right = 0.0
	layer.offset_bottom = 0.0
	if _dissolve_shader == null:
		_dissolve_shader = Shader.new()
		_dissolve_shader.code = DISSOLVE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = _dissolve_shader
	mat.set_shader_parameter("progress", 0.0)
	layer.material = mat
	return layer


func _clear_reveal_layers() -> void:
	for layer in _reveal_layers.values():
		if is_instance_valid(layer):
			layer.queue_free()
	_reveal_layers.clear()


func setup(
	tile: TileState,
	is_current: bool,
	block_reason: String,
	tile_tooltip: String,
	building_tooltips: Array[String] = [],
	secure_visible: bool = false,
	secure_disabled: bool = true,
	secure_tooltip: String = "",
	disaster_id: String = "",
) -> void:
	if not tile.is_discovered:
		_setup_unknown_tile(tile, is_current, block_reason, tile_tooltip)
		return

	var biome_name := tile.biome.corrupted_name_for(disaster_id) if tile.is_corrupted \
		else tr(tile.biome.display_name)
	_title_label.text = biome_name
	_slots_label.text = "%d/%d" % [tile.buildings.size(), tile.biome.building_slots]
	_fit_title_plate_text()
	call_deferred("_fit_title_plate_text")
	tooltip_text = tile_tooltip
	disabled = block_reason != ""
	self_modulate = Color(0.68, 0.68, 0.68, 1.0) if disabled and not is_current \
		else Color.WHITE

	_background.texture = load(_background_path(tile, disaster_id))
	_background.self_modulate = Color.WHITE
	_frame.texture = load(CORRUPTION_FRAME if tile.is_corrupted else TILE_FRAME)
	_frame.visible = not tile.bum_secured
	_title_plate.texture = load(TITLE_PLATE)
	_player_marker.texture = load(_marker_path)
	_player_marker.visible = is_current
	# Hover the marker to read the played class's abilities (PASS so the tile
	# still receives clicks underneath).
	_player_marker.tooltip_text = _marker_tooltip if is_current else ""
	_player_marker.mouse_filter = Control.MOUSE_FILTER_PASS if is_current \
		else Control.MOUSE_FILTER_IGNORE
	_secure_region_frame.visible = tile.bum_secured
	_secure_region_button.visible = secure_visible
	_secure_region_button.disabled = secure_disabled
	_secure_region_button.tooltip_text = secure_tooltip
	_state_overlay.color = _overlay_color(is_current, block_reason, tile.is_corrupted)
	if _drop_highlight:
		_state_overlay.color = Color(0.45, 0.72, 0.24, 0.24)
	_refresh_slots(tile, building_tooltips)


func _setup_unknown_tile(
	tile: TileState,
	is_current: bool,
	block_reason: String,
	tile_tooltip: String
) -> void:
	_title_label.text = tr("Nieznany teren")
	_slots_label.text = "?"
	_fit_title_plate_text()
	call_deferred("_fit_title_plate_text")
	tooltip_text = tile_tooltip
	disabled = block_reason != ""
	self_modulate = Color.WHITE

	_background.texture = load(_unknown_background_path())
	_background.self_modulate = Color(0.25, 0.34, 0.32, 1.0) \
		if not tile.is_corrupted else Color(0.22, 0.28, 0.22, 1.0)
	_frame.texture = load(TILE_FRAME)
	_frame.visible = true
	_title_plate.texture = load(TITLE_PLATE)
	_player_marker.texture = load(_marker_path)
	_player_marker.visible = is_current
	# Hover the marker to read the played class's abilities (PASS so the tile
	# still receives clicks underneath).
	_player_marker.tooltip_text = _marker_tooltip if is_current else ""
	_player_marker.mouse_filter = Control.MOUSE_FILTER_PASS if is_current \
		else Control.MOUSE_FILTER_IGNORE
	_secure_region_frame.visible = false
	_secure_region_button.visible = false
	_secure_region_button.tooltip_text = ""
	_state_overlay.color = _unknown_overlay_color(block_reason, tile.is_corrupted)
	if _drop_highlight:
		_state_overlay.color = Color(0.45, 0.72, 0.24, 0.24)
	_clear_slots()


func _fit_title_plate_text() -> void:
	_fit_label_font(_title_label, 14, 9, 2)
	_fit_label_font(_slots_label, 11, 8, 1)


func _configure_secure_region_frame() -> void:
	if _secure_region_frame == null:
		return
	_secure_region_frame.visible = false
	_secure_region_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_secure_region_frame.z_index = 0
	_secure_region_frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_secure_region_frame.stretch_mode = TextureRect.STRETCH_SCALE
	if secure_region_frame_texture != null:
		_secure_region_frame.texture = secure_region_frame_texture
	elif ResourceLoader.exists(SECURE_REGION_FRAME):
		_secure_region_frame.texture = load(SECURE_REGION_FRAME)


func _configure_secure_region_button() -> void:
	if _secure_region_button == null:
		return
	var icon_path := SECURE_REGION_ICON if ResourceLoader.exists(SECURE_REGION_ICON) else SECURE_REGION_ICON_FALLBACK
	if ResourceLoader.exists(icon_path):
		var icon_texture := load(icon_path)
		_secure_region_button.texture_normal = icon_texture
		_secure_region_button.texture_hover = icon_texture
		_secure_region_button.texture_pressed = icon_texture
		_secure_region_button.texture_disabled = icon_texture
	_secure_region_button.visible = false
	_secure_region_button.z_index = 1
	_secure_region_button.pressed.connect(func() -> void:
		secure_region_pressed.emit(_secure_region_button.get_global_rect())
	)


func _fit_label_font(label: Label, max_size: int, min_size: int, max_lines: int) -> void:
	var box_size := _label_box_size(label)
	if box_size.x <= 1.0 or box_size.y <= 1.0:
		label.add_theme_font_size_override("font_size", min_size)
		return
	for font_size in range(max_size, min_size - 1, -1):
		if _label_text_fits(label, box_size, font_size, max_lines):
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", min_size)


func _label_text_fits(label: Label, box_size: Vector2, font_size: int, max_lines: int) -> bool:
	var font := label.get_theme_font("font")
	if font == null:
		var chars_per_line := maxi(floori(box_size.x / maxf(font_size * 0.55, 1.0)), 1)
		var lines := ceili(float(label.text.length()) / chars_per_line)
		return lines <= max_lines and lines * font_size * 1.2 <= box_size.y
	var measured := font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		box_size.x,
		font_size,
		max_lines
	)
	return measured.x <= box_size.x + 1.0 and measured.y <= box_size.y + 1.0


func _label_box_size(label: Label) -> Vector2:
	if label.size.x > 1.0 and label.size.y > 1.0:
		return label.size
	var parent_control := label.get_parent() as Control
	var base_size := Vector2(160.0, 42.0)
	if parent_control != null:
		base_size = parent_control.size
		if base_size.x <= 1.0 or base_size.y <= 1.0:
			base_size = Vector2(
				(parent_control.anchor_right - parent_control.anchor_left) * custom_minimum_size.x
					+ parent_control.offset_right - parent_control.offset_left,
				(parent_control.anchor_bottom - parent_control.anchor_top) * custom_minimum_size.y
					+ parent_control.offset_bottom - parent_control.offset_top
			)
	return Vector2(
		(label.anchor_right - label.anchor_left) * base_size.x
			+ label.offset_right - label.offset_left,
		(label.anchor_bottom - label.anchor_top) * base_size.y
			+ label.offset_bottom - label.offset_top
	)


func _background_path(tile: TileState, disaster_id: String) -> String:
	var art_id := str(BIOME_ART_IDS.get(tile.biome.id, tile.biome.id))
	if not tile.is_corrupted:
		var normal_path := "%s/biome_%s_normal_bg.png" % [NORMAL_BG_DIR, art_id]
		if ResourceLoader.exists(normal_path):
			return normal_path
		return "%s/biome_forest_normal_bg.png" % NORMAL_BG_DIR
	if disaster_id != "":
		var disaster_path := "%s/biome_%s_%s_bg.png" % [CORRUPTED_BG_DIR, art_id, disaster_id]
		if ResourceLoader.exists(disaster_path):
			return disaster_path
	## Fallback: plague art (always present) if the disaster-specific tile is missing.
	var plague_path := "%s/biome_%s_plague_bg.png" % [CORRUPTED_BG_DIR, art_id]
	if ResourceLoader.exists(plague_path):
		return plague_path
	return "%s/biome_forest_normal_bg.png" % NORMAL_BG_DIR


func _unknown_background_path() -> String:
	if ResourceLoader.exists(UNKNOWN_BG):
		return UNKNOWN_BG
	return "%s/biome_forest_normal_bg.png" % NORMAL_BG_DIR


func _overlay_color(is_current: bool, block_reason: String, is_corrupted: bool) -> Color:
	if is_current:
		return Color(0.95, 0.78, 0.28, 0.14)
	if block_reason == "":
		return Color(0.42, 0.95, 0.48, 0.1)
	if is_corrupted:
		return Color(0.02, 0.04, 0.02, 0.42)
	return Color(0.02, 0.025, 0.02, 0.28)


func _unknown_overlay_color(block_reason: String, is_corrupted: bool) -> Color:
	if block_reason == "":
		return Color(0.08, 0.24, 0.2, 0.24) if not is_corrupted \
			else Color(0.05, 0.16, 0.07, 0.34)
	return Color(0.015, 0.02, 0.018, 0.26)


## One slot per building slot of the biome. Empty slot = a plain
## semi-transparent rectangle; occupied = the building's art with its name and
## HP (or RUINA) on a label below it.
func _refresh_slots(tile: TileState, building_tooltips: Array[String] = []) -> void:
	_clear_slots()

	var count := mini(tile.biome.building_slots, MAX_SLOTS)
	for i in count:
		var slot := _make_slot()
		var tip := ""
		var occupied := i < tile.buildings.size()
		if i < tile.buildings.size():
			tip = building_tooltips[i] if i < building_tooltips.size() else ""
			_fill_occupied_slot(slot, tile.buildings[i], tip)
		# Wrap each slot so a per-slot top margin can stagger the row.
		var slot_wrap := MarginContainer.new()
		slot_wrap.mouse_filter = Control.MOUSE_FILTER_STOP if occupied else Control.MOUSE_FILTER_IGNORE
		slot_wrap.tooltip_text = tip
		slot_wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		slot_wrap.add_theme_constant_override("margin_top", SLOT_STAGGER[i % SLOT_STAGGER.size()])
		if occupied:
			var building_index := i
			slot_wrap.gui_input.connect(func(event: InputEvent) -> void:
				if event is InputEventMouseButton \
						and event.button_index == MOUSE_BUTTON_LEFT \
						and event.pressed:
					building_pressed.emit(building_index, slot_wrap.get_global_rect())
					accept_event()
			)
		slot_wrap.add_child(slot)
		_slots_row.add_child(slot_wrap)


func _clear_slots() -> void:
	for tween in _slot_tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	_slot_tweens.clear()
	for child in _slots_row.get_children():
		_slots_row.remove_child(child)
		child.queue_free()


func _make_slot() -> Panel:
	var slot := Panel.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.04, 0.05, 0.04, 0.42)
	box.border_color = Color(0.85, 0.78, 0.5, 0.45)
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	slot.add_theme_stylebox_override("panel", box)
	return slot


func _fill_occupied_slot(slot: Panel, built: BuildingState, building_tooltip: String) -> void:
	slot.mouse_filter = Control.MOUSE_FILTER_PASS
	slot.tooltip_text = building_tooltip
	var art_id := str(BUILDING_ART_ALIASES.get(built.data.id, built.data.id))
	var art_path := "%s/%s.png" % [BUILDING_ART_DIR, art_id]
	if ResourceLoader.exists(art_path):
		var thumb := TextureRect.new()
		thumb.texture = load(art_path)
		thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		thumb.clip_contents = true
		thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect_anchors(thumb, 0.07, 0.05, 0.93, 0.54)
		if built.is_ruined:
			thumb.self_modulate = Color(0.72, 0.42, 0.42, 0.9)
		slot.add_child(thumb)

	if built.is_ruined:
		_add_ruin_smoke(slot)

	var is_campfire := built.data.id == "building_campfire"
	var hp_low := not is_campfire and not built.is_ruined \
		and built.hp * 2 < built.data.max_hp
	var tag := Label.new()
	if built.is_ruined:
		tag.text = "%s\nRUINA" % tr(built.data.display_name)
	elif is_campfire:
		tag.text = "%s\n%s" % [
			tr(built.data.display_name),
			(tr("pali się: %d n.") % built.hp) if built.hp > 0 else tr("wygasłe"),
		]
	else:
		tag.text = "%s\n%d HP" % [tr(built.data.display_name), built.hp]
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.clip_text = true
	tag.add_theme_font_size_override("font_size", 7)
	var tag_color := Color(0.97, 0.92, 0.74, 1.0)
	if built.is_ruined or hp_low:
		tag_color = Color(1.0, 0.55, 0.5, 1.0)
	tag.add_theme_color_override("font_color", tag_color)
	tag.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 1.0))
	tag.add_theme_constant_override("shadow_offset_x", 1)
	tag.add_theme_constant_override("shadow_offset_y", 1)
	_set_rect_anchors(tag, 0.0, 0.55, 1.0, 1.0)
	slot.add_child(tag)


## Smoldering FX on a ruined building's slot: scorch marks, a flickering fire at
## the base and smoke drifting up. Each part is optional.
func _add_ruin_smoke(slot: Control) -> void:
	# Scorch marks over the ruin thumb (cut-out, static).
	if ResourceLoader.exists(RUIN_BURN_FX):
		var burn := TextureRect.new()
		burn.texture = load(RUIN_BURN_FX)
		burn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		burn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		burn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		burn.modulate.a = 0.7
		slot.add_child(burn)
		_set_rect_anchors(burn, 0.07, 0.1, 0.93, 0.54)

	# Small flickering fire at the base of the ruin (additive).
	if ResourceLoader.exists(RUIN_FIRE_FX):
		var fire := TextureRect.new()
		fire.texture = load(RUIN_FIRE_FX)
		fire.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		fire.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fire.modulate.a = 0.0
		var fire_mat := CanvasItemMaterial.new()
		fire_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fire.material = fire_mat
		slot.add_child(fire)
		_set_rect_anchors(fire, 0.22, 0.26, 0.78, 0.6)
		var flicker := create_tween().set_loops()
		flicker.tween_property(fire, "modulate:a", 0.85, 0.35).set_trans(Tween.TRANS_SINE)
		flicker.tween_property(fire, "modulate:a", 0.5, 0.45).set_trans(Tween.TRANS_SINE)
		_slot_tweens.append(flicker)

	# Smoke drifting up out of the top of the ruin thumb (cut-out).
	if ResourceLoader.exists(RUIN_SMOKE_FX):
		var smoke := TextureRect.new()
		smoke.texture = load(RUIN_SMOKE_FX)
		smoke.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		smoke.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		smoke.mouse_filter = Control.MOUSE_FILTER_IGNORE
		smoke.modulate.a = 0.0
		slot.add_child(smoke)
		_set_rect_anchors(smoke, 0.05, -0.2, 0.95, 0.55)
		# Bound to this tile view (reliably in-tree); slots aren't in-tree yet here.
		var loop := create_tween().set_loops()
		loop.tween_property(smoke, "modulate:a", 0.5, 2.0).set_trans(Tween.TRANS_SINE)
		loop.tween_property(smoke, "modulate:a", 0.18, 2.0).set_trans(Tween.TRANS_SINE)
		_slot_tweens.append(loop)


## Lay a child out by fractional anchors (offsets zeroed) so its rect follows
## the parent slot size.
func _set_rect_anchors(node: Control, l: float, t: float, r: float, b: float) -> void:
	node.anchor_left = l
	node.anchor_top = t
	node.anchor_right = r
	node.anchor_bottom = b
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
