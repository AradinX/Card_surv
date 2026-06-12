class_name BiomeTileView
extends Button
## Visual board tile composed in Godot from a clean biome background plus
## editable labels. Green-key decorative overlays stay out until keying is set.

const NORMAL_BG_DIR := "res://assets/art/biomes/backgrounds/normal"
const CORRUPTED_BG_DIR := "res://assets/art/biomes/backgrounds/corrupted"
const BIOME_ART_IDS := {
	"forest": "forest",
	"meadows": "meadow",
	"mountains": "mountains",
}
const BUILDING_PREVIEW_LIMIT := 2

@onready var _background: TextureRect = $Background
@onready var _state_overlay: ColorRect = $StateOverlay
@onready var _title_plate: ColorRect = $Content/VBox/TitlePlate
@onready var _title_label: Label = $Content/VBox/TitlePlate/TitleLabel
@onready var _slots_label: Label = $Content/VBox/TitlePlate/SlotsLabel
@onready var _building_rows: VBoxContainer = $Content/VBox/BuildingRows
@onready var _empty_hint: Label = $Content/VBox/EmptyHint
@onready var _marker: Label = $Marker


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
	_marker.visible = is_current
	_title_plate.color = Color(0.10, 0.17, 0.10, 0.86) if not tile.is_corrupted \
		else Color(0.08, 0.13, 0.08, 0.90)
	_state_overlay.color = _overlay_color(is_current, block_reason, tile.is_corrupted)
	_refresh_buildings(tile)


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
		return Color(0.95, 0.78, 0.28, 0.18)
	if block_reason == "":
		return Color(0.42, 0.95, 0.48, 0.13)
	if is_corrupted:
		return Color(0.02, 0.04, 0.02, 0.42)
	return Color(0.02, 0.025, 0.02, 0.28)


func _refresh_buildings(tile: TileState) -> void:
	for child in _building_rows.get_children():
		_building_rows.remove_child(child)
		child.queue_free()

	_empty_hint.visible = tile.buildings.is_empty()
	for i in mini(tile.buildings.size(), BUILDING_PREVIEW_LIMIT):
		var built := tile.buildings[i]
		var label := Label.new()
		label.text = _building_line(built)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_color_override("font_color", Color(0.95, 0.89, 0.70, 1.0))
		label.add_theme_color_override("font_shadow_color", Color(0.05, 0.04, 0.03, 1.0))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		_building_rows.add_child(label)

	if tile.buildings.size() > BUILDING_PREVIEW_LIMIT:
		var extra := Label.new()
		extra.text = "+%d" % (tile.buildings.size() - BUILDING_PREVIEW_LIMIT)
		extra.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		extra.add_theme_font_size_override("font_size", 12)
		extra.add_theme_color_override("font_color", Color(0.95, 0.89, 0.70, 1.0))
		_building_rows.add_child(extra)


func _building_line(built: BuildingState) -> String:
	if built.is_ruined:
		return "RUINA: %s" % built.data.display_name
	return "%s %d HP" % [built.data.display_name, built.hp]
