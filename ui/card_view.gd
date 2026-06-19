class_name CardView
extends Button
## Visual representation of a single card (action, building or biome gather
## action). Dumb view: shows data, disables itself when the card can't be
## played. Clicks are handled via the inherited "pressed" signal.


@onready var _name_label: Label = $NameLabel
@onready var _cost_label: Label = $CostLabel
@onready var _desc_label: Label = $DescLabel
@onready var _illustration: TextureRect = $Illustration
@onready var _frame: TextureRect = $Frame

const FRAME_BUILDING := "res://assets/art/cards/frames/card_frame_building.png"
const FRAME_EVENT := "res://assets/art/cards/frames/card_frame_event.png"
const FRAME_MONSTER := "res://assets/art/cards/frames/card_frame_monster.png"
const ACTION_ART_DIR := "res://assets/art/cards/illustrations/actions_act1_candidates"
const BUILDING_ART_DIR := "res://assets/art/cards/illustrations/buildings_act1_candidates"
const EVENT_ART_DIR := "res://assets/art/cards/illustrations/events"
const MONSTER_ART_DIR := "res://assets/art/cards/illustrations/monsters"

const ACTION_ART_ALIASES := {
	"adrenaline": "action_rest",
	"big_hunt": "action_forage",
	"campfire": "action_rest",
	"craft_tools": "action_craft_tools",
	"expedition": "action_explore",
	"explore": "action_explore",
	"feast": "action_forage",
	"find_water": "action_spring_source",
	"first_aid": "action_treat_wounds",
	"fishing": "action_forage",
	"forage": "action_forage",
	"gather_sticks": "action_chop_wood",
	"gather_wood": "action_chop_wood",
	"herbs": "action_treat_wounds",
	"hunt": "action_forage",
	"rest": "action_rest",
	"scavenge": "action_explore",
	"scout": "action_scout",
	"snare_trap": "action_forage",
	"woodcraft": "action_chop_wood",
}

const MONSTER_ART_ALIASES := {
	"crow_swarm": "monster_crow_swarm",
	"plague_wolf": "monster_plague_wolf",
	"plague_zombie": "monster_rotting_one",
	"rat_swarm": "monster_rat_swarm",
}


## `cost_override` lets the caller show a context-dependent cost (e.g. the
## effective build cost incl. class discount + post-BUM surcharge) instead of the
## card's static base cost.
func setup(card: CardData, block_reason: String, cost_override: String = "") -> void:
	_name_label.text = card.display_name
	_cost_label.text = cost_override if cost_override != "" else _format_costs(card)
	_desc_label.text = _format_description(card)
	disabled = block_reason != ""
	tooltip_text = block_reason
	self_modulate = Color(0.62, 0.62, 0.62, 1.0) if disabled else Color.WHITE
	_apply_art(card)
	_apply_text_layout(card)
	_fit_all_text()
	call_deferred("_fit_all_text")


func _apply_art(card: CardData) -> void:
	_frame.texture = load(_frame_path(card))
	var illustration_path := _illustration_path(card)
	if illustration_path != "" and ResourceLoader.exists(illustration_path):
		_illustration.texture = load(illustration_path)
		_illustration.visible = true
	else:
		_illustration.texture = null
		_illustration.visible = false


## Monster-attack and nature/biome night events get their own frames;
## everything else (actions, buildings, gather cards) uses the base frame.
func _frame_path(card: CardData) -> String:
	if card is MonsterCardData:
		return FRAME_MONSTER
	if card is EventCardData:
		return FRAME_EVENT
	return FRAME_BUILDING


func _apply_text_layout(card: CardData) -> void:
	var has_cost_bar := not (card is EventCardData or card is MonsterCardData)
	_cost_label.visible = has_cost_bar
	if has_cost_bar:
		_desc_label.anchor_top = 0.575
		_desc_label.anchor_bottom = 0.815
	else:
		_desc_label.anchor_top = 0.575
		_desc_label.anchor_bottom = 0.93


func _illustration_path(card: CardData) -> String:
	if card is BuildingCardData:
		return "%s/%s.png" % [BUILDING_ART_DIR, card.id]
	if card is MonsterCardData:
		return "%s/%s.png" % [
			MONSTER_ART_DIR, MONSTER_ART_ALIASES.get(card.id, card.id)
		]
	if card is EventCardData:
		return "%s/%s.png" % [EVENT_ART_DIR, card.id]
	if card is ActionCardData:
		return "%s/%s.png" % [
			ACTION_ART_DIR, ACTION_ART_ALIASES.get(card.id, "action_%s" % card.id)
		]
	return ""


## Card text has fixed frame windows in the bitmap. Labels are clipped as a
## backstop, then font size is reduced until the rendered text fits that window.
func _fit_all_text() -> void:
	_fit_label_font(_name_label, 14, 7, 2)
	_fit_label_font(_desc_label, 11, 6, 7)
	if _cost_label.visible:
		_fit_label_font(_cost_label, 10, 6, 2)


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
		return _estimate_text_fits(label.text, box_size, font_size, max_lines)
	var measured := font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		box_size.x,
		font_size,
		max_lines
	)
	return measured.x <= box_size.x + 1.0 and measured.y <= box_size.y + 1.0


func _estimate_text_fits(text: String, box_size: Vector2, font_size: int, max_lines: int) -> bool:
	var chars_per_line := maxi(floori(box_size.x / maxf(font_size * 0.55, 1.0)), 1)
	var lines := ceili(float(text.length()) / chars_per_line)
	var line_height := font_size * 1.2
	return lines <= max_lines and lines * line_height <= box_size.y


func _label_box_size(label: Label) -> Vector2:
	if label.size.x > 1.0 and label.size.y > 1.0:
		return label.size
	var base_size := size
	if base_size.x <= 1.0 or base_size.y <= 1.0:
		base_size = custom_minimum_size
	return Vector2(
		(label.anchor_right - label.anchor_left) * base_size.x
			+ label.offset_right - label.offset_left,
		(label.anchor_bottom - label.anchor_top) * base_size.y
			+ label.offset_bottom - label.offset_top
	)


## Building cards carry their durability (HP) in the description rather than in
## the cost bar — HP is a property of the placed building, not a build cost.
func _format_description(card: CardData) -> String:
	if card is BuildingCardData:
		return "%s\nWytrzymałość: %d HP" % [card.description, (card as BuildingCardData).max_hp]
	return card.description


func _format_costs(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card is ActionCardData:
		var action := card as ActionCardData
		parts.append("Energia %d" % action.energy_cost)
		if action.food_cost > 0:
			parts.append("Jedzenie %d" % action.food_cost)
		if action.wood_cost > 0:
			parts.append("Drewno %d" % action.wood_cost)
		if action.materials_cost > 0:
			parts.append("Materiały %d" % action.materials_cost)
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		parts.append("Energia %d" % building.energy_cost)
		if building.food_cost > 0:
			parts.append("Jedzenie %d" % building.food_cost)
		if building.wood_cost > 0:
			parts.append("Drewno %d" % building.wood_cost)
		if building.materials_cost > 0:
			parts.append("Materiały %d" % building.materials_cost)
	elif card is MonsterCardData:
		var monster := card as MonsterCardData
		var dmg: PackedStringArray = []
		if monster.damage_to_player > 0:
			dmg.append("gracz %d" % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			dmg.append("budynki %d" % monster.damage_to_buildings)
		return "Atak — %s" % ", ".join(dmg) if not dmg.is_empty() else "Potwór"
	elif card is EventCardData:
		return "Zdarzenie nocne"
	return "   ·   ".join(parts)
