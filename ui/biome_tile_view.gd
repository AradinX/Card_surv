class_name BiomeTileView
extends Button
## Visual board tile composed in Godot: a clean biome background, an ornate
## chroma-keyed frame (corruption frame after BUM), a centered nameplate, a
## "you are here" marker and a row of building slots (empty / occupied by a
## built building, with its HP), all driven from the tile state.

const NORMAL_BG_DIR := "res://assets/art/biomes/backgrounds/normal"
const CORRUPTED_BG_DIR := "res://assets/art/biomes/backgrounds/corrupted"
const TILE_FRAME := "res://assets/art/biomes/frames/biome_tile_frame.png"
const CORRUPTION_FRAME := "res://assets/art/biomes/overlays/biome_corruption_overlay.png"
const TITLE_PLATE := "res://assets/art/biomes/frames/biome_title_plate.png"
const PLAYER_MARKER := "res://assets/art/biomes/overlays/biome_current_player.png"
const BUILDING_ART_DIR := "res://assets/art/cards/illustrations/buildings_act1_candidates"
const BIOME_ART_IDS := {
	"forest": "forest",
	"meadows": "meadow",
	"mountains": "mountains",
}
const SLOT_SIZE := Vector2(50, 62)
## Max slots shown on a tile, and a small per-slot vertical offset so the row
## reads less like a rigid grid.
const MAX_SLOTS := 3
const SLOT_STAGGER := [16, 0, 9]

@onready var _background: TextureRect = $Background
@onready var _state_overlay: ColorRect = $StateOverlay
@onready var _frame: TextureRect = $Frame
@onready var _player_marker: TextureRect = $PlayerMarker
@onready var _title_plate: TextureRect = $TitlePlate
@onready var _title_label: Label = $TitlePlate/TitleLabel
@onready var _slots_label: Label = $TitlePlate/SlotsLabel
@onready var _slots_row: HBoxContainer = $SlotsRow


func setup(
	tile: TileState,
	is_current: bool,
	block_reason: String,
	tile_tooltip: String,
) -> void:
	var biome_name := tile.biome.corrupted_display_name if tile.is_corrupted \
		else tile.biome.display_name
	_title_label.text = biome_name
	_slots_label.text = "%d/%d" % [tile.buildings.size(), tile.biome.building_slots]
	tooltip_text = tile_tooltip
	disabled = block_reason != ""
	self_modulate = Color(0.68, 0.68, 0.68, 1.0) if disabled and not is_current \
		else Color.WHITE

	_background.texture = load(_background_path(tile))
	_frame.texture = load(CORRUPTION_FRAME if tile.is_corrupted else TILE_FRAME)
	_title_plate.texture = load(TITLE_PLATE)
	_player_marker.texture = load(PLAYER_MARKER)
	_player_marker.visible = is_current
	_state_overlay.color = _overlay_color(is_current, block_reason, tile.is_corrupted)
	_refresh_slots(tile)


func _background_path(tile: TileState) -> String:
	var art_id := str(BIOME_ART_IDS.get(tile.biome.id, tile.biome.id))
	var file_name := "biome_%s_%s_bg.png" % [
		art_id, "plague" if tile.is_corrupted else "normal"
	]
	var dir := CORRUPTED_BG_DIR if tile.is_corrupted else NORMAL_BG_DIR
	var path := "%s/%s" % [dir, file_name]
	if ResourceLoader.exists(path):
		return path
	return "%s/biome_forest_normal_bg.png" % NORMAL_BG_DIR


func _overlay_color(is_current: bool, block_reason: String, is_corrupted: bool) -> Color:
	if is_current:
		return Color(0.95, 0.78, 0.28, 0.14)
	if block_reason == "":
		return Color(0.42, 0.95, 0.48, 0.1)
	if is_corrupted:
		return Color(0.02, 0.04, 0.02, 0.42)
	return Color(0.02, 0.025, 0.02, 0.28)


## One slot per building slot of the biome. Empty slot = a plain
## semi-transparent rectangle; occupied = the building's art with its name and
## HP (or RUINA) on a label below it.
func _refresh_slots(tile: TileState) -> void:
	for child in _slots_row.get_children():
		_slots_row.remove_child(child)
		child.queue_free()

	var count := mini(tile.biome.building_slots, MAX_SLOTS)
	for i in count:
		var slot := _make_slot()
		if i < tile.buildings.size():
			_fill_occupied_slot(slot, tile.buildings[i])
		# Wrap each slot so a per-slot top margin can stagger the row.
		var wrap := MarginContainer.new()
		wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		wrap.add_theme_constant_override("margin_top", SLOT_STAGGER[i % SLOT_STAGGER.size()])
		wrap.add_child(slot)
		_slots_row.add_child(wrap)


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


func _fill_occupied_slot(slot: Panel, built: BuildingState) -> void:
	var art_path := "%s/%s.png" % [BUILDING_ART_DIR, built.data.id]
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

	var tag := Label.new()
	tag.text = "%s\nRUINA" % built.data.display_name if built.is_ruined \
		else "%s\n%d HP" % [built.data.display_name, built.hp]
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.clip_text = true
	tag.add_theme_font_size_override("font_size", 7)
	tag.add_theme_color_override(
		"font_color",
		Color(1.0, 0.55, 0.5, 1.0) if built.is_ruined else Color(0.97, 0.92, 0.74, 1.0)
	)
	tag.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.02, 1.0))
	tag.add_theme_constant_override("shadow_offset_x", 1)
	tag.add_theme_constant_override("shadow_offset_y", 1)
	_set_rect_anchors(tag, 0.0, 0.55, 1.0, 1.0)
	slot.add_child(tag)


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
