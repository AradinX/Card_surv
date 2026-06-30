class_name CardView
extends Button
## Visual representation of a single card (action, building or biome gather
## action). Dumb view: shows data, disables itself when the card can't be
## played. Clicks are handled via the inherited "pressed" signal.

signal card_drag_started(payload: Dictionary)
signal card_drag_finished


@onready var _name_label: Label = $NameLabel
@onready var _cost_label: Label = $CostLabel
@onready var _desc_label: Label = $DescLabel
@onready var _effect_label: Label = get_node_or_null("EffectLabel") as Label
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
	"barter_materials": "action_explore",
	"barter_wood": "action_chop_wood",
	"mine_stone": "action_explore",
	"big_hunt": "action_forage",
	"campfire": "action_rest",
	"deadfall_wood": "action_chop_wood",
	"craft_tools": "action_craft_tools",
	"expedition": "action_explore",
	"explore": "action_explore",
	"feast": "action_forage",
	"find_water": "action_spring_source",
	"first_aid": "action_treat_wounds",
	"fishing": "action_forage",
	"forage": "action_forage",
	"gather_sticks": "action_chop_wood",
	"gather_sticks_up": "action_chop_wood",
	"gather_wood": "action_chop_wood",
	"haul_wood": "action_chop_wood",
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

var _drag_payload: Dictionary = {}
var _drag_tween: Tween


## `cost_override` lets the caller show a context-dependent cost (e.g. the
## effective build cost incl. class discount + post-BUM surcharge) instead of the
## card's static base cost.
func setup(card: CardData, block_reason: String, cost_override: String = "") -> void:
	_name_label.text = card.display_name
	_cost_label.text = cost_override if cost_override != "" else _format_costs(card)
	# Flavour on its own label (top), effects on a separate label (bottom) so the
	# effect line can never be clipped by a long flavour or font auto-fit.
	_desc_label.text = card.description
	var effects := _effects_summary(card)
	if card is BuildingCardData:
		effects += ("  ·  " if effects != "" else "") + "%d HP" % (card as BuildingCardData).max_hp
	if _effect_label != null:
		_effect_label.text = effects
		_effect_label.visible = effects != ""
	disabled = block_reason != ""
	tooltip_text = block_reason
	self_modulate = Color(0.62, 0.62, 0.62, 1.0) if disabled else Color.WHITE
	_apply_art(card)
	_apply_text_layout(card)
	_fit_all_text()
	call_deferred("_fit_all_text")


func set_drag_payload(payload: Dictionary) -> void:
	_drag_payload = payload


func _get_drag_data(_at_position: Vector2) -> Variant:
	if disabled or _drag_payload.is_empty():
		return null
	_play_pickup_animation()
	var preview_size := size
	if preview_size.x <= 1.0 or preview_size.y <= 1.0:
		preview_size = custom_minimum_size
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.custom_minimum_size = Vector2.ONE
	var preview := duplicate() as CardView
	preview.disabled = true
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.size = preview_size
	preview.custom_minimum_size = preview_size
	preview.pivot_offset = preview_size * 0.5
	preview.position = -preview_size * 0.54
	preview.modulate = Color(1.06, 1.06, 1.0, 0.92)
	preview.scale = Vector2(1.08, 1.08)
	preview.rotation_degrees = -2.0
	holder.add_child(preview)
	set_drag_preview(holder)
	card_drag_started.emit(_drag_payload)
	return _drag_payload


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_restore_after_drag()
		card_drag_finished.emit()


func _play_pickup_animation() -> void:
	if _drag_tween != null:
		_drag_tween.kill()
	pivot_offset = size * 0.5
	z_index = 20
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.tween_property(self, "scale", Vector2(0.96, 0.96), 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drag_tween.tween_property(self, "modulate:a", 0.55, 0.10) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _restore_after_drag() -> void:
	if _drag_tween != null:
		_drag_tween.kill()
	_drag_tween = create_tween().set_parallel(true)
	_drag_tween.tween_property(self, "scale", Vector2.ONE, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drag_tween.tween_property(self, "modulate:a", 1.0, 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drag_tween.finished.connect(func() -> void:
		z_index = 0
	)


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
	var text_bottom := 0.815 if has_cost_bar else 0.93
	_desc_label.anchor_top = 0.575
	if _effect_label != null and _effect_label.visible:
		# Split the text window: flavour on top, effects on their own band.
		_desc_label.anchor_bottom = 0.73
		_effect_label.anchor_top = 0.73
		_effect_label.anchor_bottom = text_bottom
	else:
		_desc_label.anchor_bottom = text_bottom


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
	_fit_label_font(_name_label, 14, 6, 2)
	_fit_label_font(_desc_label, 11, 5, 5)
	if _effect_label != null and _effect_label.visible:
		_fit_label_font(_effect_label, 10, 4, 3)
	if _cost_label.visible:
		_fit_label_font(_cost_label, 10, 5, 2)


func _fit_label_font(label: Label, max_size: int, min_size: int, max_lines: int) -> void:
	var box_size := _label_box_size(label)
	if box_size.x <= 1.0 or box_size.y <= 1.0:
		label.add_theme_constant_override("line_spacing", 0)
		label.add_theme_font_size_override("font_size", min_size)
		label.max_lines_visible = max_lines
		return

	label.add_theme_constant_override("line_spacing", 0)
	label.max_lines_visible = max_lines
	for font_size in range(max_size, min_size - 1, -1):
		if _label_text_fits(label, box_size, font_size, max_lines):
			label.add_theme_font_size_override("font_size", font_size)
			return
	label.add_theme_font_size_override("font_size", min_size)


func _label_text_fits(label: Label, box_size: Vector2, font_size: int, max_lines: int) -> bool:
	label.add_theme_font_size_override("font_size", font_size)

	var line_count := label.get_line_count()
	var visible_line_count := label.get_visible_line_count()
	if line_count > max_lines or line_count > visible_line_count:
		return false

	var font := label.get_theme_font("font")
	if font == null:
		return _estimate_text_fits(label.text, box_size, font_size, max_lines)
	var measured := font.get_multiline_string_size(
		label.text,
		label.horizontal_alignment,
		box_size.x,
		font_size,
		-1
	)
	return measured.x <= box_size.x + 1.0 and measured.y <= box_size.y + 1.0


func _estimate_text_fits(sample_text: String, box_size: Vector2, font_size: int, max_lines: int) -> bool:
	var chars_per_line := maxi(floori(box_size.x / maxf(font_size * 0.55, 1.0)), 1)
	var lines := ceili(float(sample_text.length()) / chars_per_line)
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


## Generated, consistent list of a card's effects + amounts (PL).
func _effects_summary(card: CardData) -> String:
	var p: PackedStringArray = []
	if card is ActionCardData:
		var a := card as ActionCardData
		_push_delta(p, a.health_delta, "zdrowia")
		_push_delta(p, a.hunger_delta, "sytości")
		_push_delta(p, a.thirst_delta, "nawodnienia")
		_push_delta(p, a.warmth_delta, "ciepła")
		_push_delta(p, a.energy_delta, "energii")
		_push_delta(p, a.food_gain, "jedzenia")
		_push_delta(p, a.water_gain, "wody")
		_push_delta(p, a.wood_gain, "drewna")
		_push_delta(p, a.materials_gain, "kamienia")
		var sp := _action_special_text(a.special)
		if sp != "":
			p.append(sp)
	elif card is BuildingCardData:
		var b := card as BuildingCardData
		_push_delta(p, b.food_gain, "jedzenia nocą")
		_push_delta(p, b.water_gain, "wody nocą")
		_push_delta(p, b.wood_gain, "drewna nocą")
		_push_delta(p, b.materials_gain, "kamienia nocą")
		_push_delta(p, b.health_delta, "zdrowia nocą")
		_push_delta(p, b.warmth_delta, "ciepła nocą")
		if b.defense > 0:
			p.append("obrona %d" % b.defense)
		_push_delta(p, b.food_cap_bonus, "limitu jedzenia")
		_push_delta(p, b.water_cap_bonus, "limitu wody")
		_push_delta(p, b.wood_cap_bonus, "limitu drewna")
		_push_delta(p, b.materials_cap_bonus, "limitu kamienia")
		var sp := _building_special_text(b.special)
		if sp != "":
			p.append(sp)
	elif card is MonsterCardData:
		var m := card as MonsterCardData
		if m.damage_to_player > 0:
			p.append("-%d zdrowia gracza" % m.damage_to_player)
		if m.damage_to_buildings > 0:
			p.append("-%d HP budynku" % m.damage_to_buildings)
		if p.is_empty():
			p.append("atak bez obrażeń")
	if p.is_empty():
		return ""
	return "  ·  ".join(p)


func _push_delta(parts: PackedStringArray, value: int, stat_name: String) -> void:
	if value != 0:
		parts.append("%+d %s" % [value, stat_name])


func _action_special_text(special: String) -> String:
	match special:
		"craft_tools": return "narzędzia (+zbiory)"
		"explore": return "+1 losowe znalezisko"
		"double_explore": return "+2 losowe znaleziska"
		"draw_two": return "+2 karty do ręki"
		"scout_reveal": return "odkrywa sąsiedni teren"
		"free_move": return "następny ruch za darmo"
		"repair_tile": return "doraźna naprawa budynku"
		"ward_night": return "warta: łagodzi tę noc"
		"set_trap": return "wnyki: blokują atak potwora"
		"momentum": return "kolejne karty dziś zwracają energię"
		"rhythm": return "+1 energii za każdą kartę zagraną dziś"
		"combo_food": return "+2 jedzenia, jeśli grałeś już jedzenie"
		_: return ""


func _building_special_text(special: String) -> String:
	match special:
		"night_protection": return "ochrona nocna"
		"slow_spoilage": return "wolniejsze psucie jedzenia"
		"unlock_crafting": return "konserwuje budynki nocą"
		_: return ""


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
			parts.append("Kamień %d" % action.materials_cost)
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		parts.append("Energia %d" % building.energy_cost)
		if building.food_cost > 0:
			parts.append("Jedzenie %d" % building.food_cost)
		if building.wood_cost > 0:
			parts.append("Drewno %d" % building.wood_cost)
		if building.materials_cost > 0:
			parts.append("Kamień %d" % building.materials_cost)
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
