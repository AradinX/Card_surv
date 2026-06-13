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

const FRAME_ACTION := "res://assets/art/cards/frames/card_frame_action.png"
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


func setup(card: CardData, block_reason: String) -> void:
	_name_label.text = card.display_name
	_cost_label.text = _format_costs(card)
	_desc_label.text = card.description
	disabled = block_reason != ""
	tooltip_text = block_reason
	self_modulate = Color(0.62, 0.62, 0.62, 1.0) if disabled else Color.WHITE
	_apply_art(card)


func _apply_art(card: CardData) -> void:
	_frame.texture = load(_frame_path(card))
	var illustration_path := _illustration_path(card)
	if illustration_path != "" and ResourceLoader.exists(illustration_path):
		_illustration.texture = load(illustration_path)
		_illustration.visible = true
	else:
		_illustration.texture = null
		_illustration.visible = false


func _frame_path(card: CardData) -> String:
	if card is BuildingCardData:
		return FRAME_BUILDING
	if card is MonsterCardData:
		return FRAME_MONSTER
	if card is EventCardData:
		return FRAME_EVENT
	return FRAME_ACTION


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


func _format_costs(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card is ActionCardData:
		var action := card as ActionCardData
		parts.append("E%d" % action.energy_cost)
		if action.food_cost > 0:
			parts.append("J%d" % action.food_cost)
		if action.wood_cost > 0:
			parts.append("D%d" % action.wood_cost)
		if action.materials_cost > 0:
			parts.append("M%d" % action.materials_cost)
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		parts.append("HP%d" % building.max_hp)
		parts.append("E%d" % building.energy_cost)
		if building.food_cost > 0:
			parts.append("J%d" % building.food_cost)
		if building.wood_cost > 0:
			parts.append("D%d" % building.wood_cost)
		if building.materials_cost > 0:
			parts.append("M%d" % building.materials_cost)
	elif card is MonsterCardData:
		var monster := card as MonsterCardData
		parts.append("P")
		if monster.damage_to_player > 0:
			parts.append("Z%d" % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			parts.append("B%d" % monster.damage_to_buildings)
	elif card is EventCardData:
		parts.append("NOC")
	return "\n".join(parts)
