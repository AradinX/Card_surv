class_name BiomeTileView
extends Button
## Visual board tile composed in Godot: a clean biome background, an ornate
## chroma-keyed frame (corruption frame after BUM), a centered nameplate, a
## "you are here" marker and a row of building slots (empty / occupied by a
## built building, with its HP), all driven from the tile state.
signal buildings_pressed

const NORMAL_BG_DIR := "res://assets/art/biomes/backgrounds/normal"
const CORRUPTED_BG_DIR := "res://assets/art/biomes/backgrounds/corrupted"
const UNKNOWN_BG := "res://assets/art/biomes/discovery/biome_unknown.png"
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
@onready var _buildings_button: TextureButton = $BuildingsButton


func _ready() -> void:
	_buildings_button.pressed.connect(func() -> void:
		buildings_pressed.emit()
	)


func setup(
	tile: TileState,
	is_current: bool,
	block_reason: String,
	tile_tooltip: String,
) -> void:
	if not tile.is_discovered:
		_setup_unknown_tile(tile, is_current, block_reason, tile_tooltip)
		return

	var biome_name := tile.biome.corrupted_display_name if tile.is_corrupted \
		else tile.biome.display_name
	_title_label.text = biome_name
	_slots_label.text = "%d/%d" % [tile.buildings.size(), tile.biome.building_slots]
	_fit_title_plate_text()
	call_deferred("_fit_title_plate_text")
	tooltip_text = tile_tooltip
	disabled = block_reason != ""
	self_modulate = Color(0.68, 0.68, 0.68, 1.0) if disabled and not is_current \
		else Color.WHITE

	_background.texture = load(_background_path(tile))
	_background.self_modulate = Color.WHITE
	_frame.texture = load(CORRUPTION_FRAME if tile.is_corrupted else TILE_FRAME)
	_title_plate.texture = load(TITLE_PLATE)
	_player_marker.texture = load(PLAYER_MARKER)
	_player_marker.visible = is_current
	_buildings_button.visible = not tile.buildings.is_empty()
	_state_overlay.color = _overlay_color(is_current, block_reason, tile.is_corrupted)
	_refresh_slots(tile)


func _setup_unknown_tile(
	tile: TileState,
	is_current: bool,
	block_reason: String,
	tile_tooltip: String
) -> void:
	_title_label.text = "Nieznany teren"
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
	_title_plate.texture = load(TITLE_PLATE)
	_player_marker.texture = load(PLAYER_MARKER)
	_player_marker.visible = is_current
	_buildings_button.visible = false
	_state_overlay.color = _unknown_overlay_color(block_reason, tile.is_corrupted)
	_clear_slots()


func _fit_title_plate_text() -> void:
	_fit_label_font(_title_label, 14, 9, 2)
	_fit_label_font(_slots_label, 11, 8, 1)


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
func _refresh_slots(tile: TileState) -> void:
	_clear_slots()

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


func _clear_slots() -> void:
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
