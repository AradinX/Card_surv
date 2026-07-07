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
@onready var _effect_label: RichTextLabel = get_node_or_null("EffectLabel") as RichTextLabel
@onready var _illustration: TextureRect = $Illustration
@onready var _frame: TextureRect = $Frame

const FRAME_BUILDING := "res://assets/art/cards/frames/card_frame_building.png"
const FRAME_BUILDING_ACT2 := "res://assets/art/cards/frames/card_frame_building_act2.png"
const FRAME_EVENT := "res://assets/art/cards/frames/card_frame_event.png"
const FRAME_MONSTER := "res://assets/art/cards/frames/card_frame_monster.png"
const ACTION_ART_DIR := "res://assets/art/cards/illustrations/actions_act1_candidates"
const BUILDING_ART_DIR := "res://assets/art/cards/illustrations/buildings_act1_candidates"
const EVENT_ART_DIR := "res://assets/art/cards/illustrations/events"
const MONSTER_ART_DIR := "res://assets/art/cards/illustrations/monsters"
# Action cards resolve to a dedicated `action_<id>.png` first (see
# _illustration_path); this map only covers the few ids whose art lives under a
# different filename. find_water reuses the "Źródło" (spring_source) illustration.
const ACTION_ART_ALIASES := {
	"find_water": "action_spring_source",
}

const MONSTER_ART_ALIASES := {
	"crow_swarm": "monster_crow_swarm",
	"plague_wolf": "monster_plague_wolf",
	"plague_zombie": "monster_rotting_one",
	"rat_swarm": "monster_rat_swarm",
}

var _drag_payload: Dictionary = {}
var _drag_tween: Tween
var _block_reason := ""
var _feedback_tween: Tween
var _feedback_frame: Panel
var _disaster_id := ""
var _cost_row: HBoxContainer
var _effects_text := ""


## `cost_override` lets the caller show a context-dependent cost (e.g. the
## effective build cost incl. class discount + post-BUM surcharge) instead of the
## card's static base cost. `cost_values` carries the same cost as raw numbers
## ({energy, food, wood, materials}) for the icon cost row.
func setup(
		card: CardData,
		block_reason: String,
		cost_override: String = "",
		effects_override: Variant = null,
		disaster_id: String = "",
		cost_values: Dictionary = {}) -> void:
	_disaster_id = disaster_id
	_name_label.text = tr(card.display_name)
	_cost_label.text = cost_override if cost_override != "" else _format_costs(card)
	# Flavour on its own label (top), effects on a separate label (bottom) so the
	# effect line can never be clipped by a long flavour or font auto-fit.
	_desc_label.text = tr(_description_for_display(card))
	var effects := str(effects_override) if effects_override != null else _effects_summary(card)
	if card is BuildingCardData:
		effects += ("  ·  " if effects != "" else "") + "%d HP" % (card as BuildingCardData).max_hp
	if _effect_label != null:
		_effects_text = effects
		_effect_label.visible = effects != ""
	_block_reason = block_reason
	disabled = false
	tooltip_text = block_reason
	self_modulate = Color(0.62, 0.62, 0.62, 1.0) if is_play_blocked() else Color.WHITE
	_apply_art(card)
	_apply_text_layout(card)
	_apply_cost_icons(card, cost_values)
	_fit_all_text()
	call_deferred("_fit_all_text")


func set_drag_payload(payload: Dictionary) -> void:
	_drag_payload = payload


func is_play_blocked() -> bool:
	return _block_reason != ""


func block_reason() -> String:
	return _block_reason


func play_blocked_feedback(reason: String = "") -> void:
	var text := reason if reason != "" else _block_reason
	if text != "":
		tooltip_text = text
	_ensure_feedback_frame()
	_feedback_frame.visible = true
	if _feedback_tween != null:
		_feedback_tween.kill()
	position.x = round(position.x)
	var base_position := position
	_feedback_frame.modulate.a = 1.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(self, "position:x", base_position.x - 6.0, 0.04)
	_feedback_tween.tween_property(self, "position:x", base_position.x + 6.0, 0.06)
	_feedback_tween.tween_property(self, "position:x", base_position.x - 4.0, 0.05)
	_feedback_tween.tween_property(self, "position:x", base_position.x + 3.0, 0.05)
	_feedback_tween.tween_property(self, "position:x", base_position.x, 0.05)
	_feedback_tween.tween_property(_feedback_frame, "modulate:a", 0.0, 0.25)
	_feedback_tween.finished.connect(func() -> void:
		if is_instance_valid(_feedback_frame):
			_feedback_frame.visible = false
	)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if is_play_blocked():
		play_blocked_feedback()
		return null
	if _drag_payload.is_empty():
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
## everything else (actions, buildings, gather cards) uses the base frame —
## swapped for its corroded Act II variant after BUM (a non-empty disaster id
## means the run is post-BUM). Plug-and-play: no file = Act I frame stays.
func _frame_path(card: CardData) -> String:
	if card is MonsterCardData:
		return FRAME_MONSTER
	if card is EventCardData:
		return FRAME_EVENT
	if _disaster_id != "" and ResourceLoader.exists(FRAME_BUILDING_ACT2):
		return FRAME_BUILDING_ACT2
	return FRAME_BUILDING


func _apply_text_layout(card: CardData) -> void:
	var has_cost_bar := not (card is EventCardData or card is MonsterCardData)
	_cost_label.visible = has_cost_bar
	var text_bottom := 0.815 if has_cost_bar else 0.93
	_desc_label.anchor_top = 0.575
	if _effect_label != null and _effect_label.visible:
		# Split the text window: flavour on top, effects on their own band
		# (slightly taller since inline stat icons need more line height).
		_desc_label.anchor_bottom = 0.715
		_effect_label.anchor_top = 0.715
		_effect_label.anchor_bottom = text_bottom
	else:
		_desc_label.anchor_bottom = text_bottom


func _description_for_display(card: CardData) -> String:
	if card is ActionCardData and _disaster_id != "":
		return (card as ActionCardData).description_for(_disaster_id)
	return card.description


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
		if _disaster_id != "":
			var disaster_dedicated := "%s/action_%s_%s.png" % [
				ACTION_ART_DIR, card.id, _disaster_id
			]
			if ResourceLoader.exists(disaster_dedicated):
				return disaster_dedicated
		# Prefer a dedicated illustration if one exists; otherwise fall back to the
		# shared alias art. This makes new per-card art plug-and-play: drop in
		# action_<id>.png and it overrides the alias/shared art automatically, with
		# no code change and no regression before the file exists.
		var dedicated := "%s/action_%s.png" % [ACTION_ART_DIR, card.id]
		if ResourceLoader.exists(dedicated):
			return dedicated
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
		_fit_effect_font(10, 4)
	if _cost_label.visible:
		_fit_label_font(_cost_label, 10, 5, 2)


## RichTextLabel variant of the fit: the bbcode is re-rendered per candidate
## font size so the inline stat icons shrink together with the text, then the
## font drops until the content height fits the label's window.
func _fit_effect_font(max_size: int, min_size: int) -> void:
	var box_size := _label_box_size(_effect_label)
	for font_size in range(max_size, min_size - 1, -1):
		_effect_label.add_theme_font_size_override("normal_font_size", font_size)
		_effect_label.text = "[center]%s[/center]" % StatIcons.iconify(
			_effects_text, font_size + 3)
		if box_size.y <= 1.0 or _effect_label.get_content_height() <= box_size.y + 1.0:
			return


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


func _label_box_size(label: Control) -> Vector2:
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
		_push_delta(p, a.hunger_delta, tr("sytości"))
		_push_delta(p, a.thirst_delta, "nawodnienia")
		_push_delta(p, a.warmth_delta, tr("ciepła"))
		_push_delta(p, a.energy_delta, "energii")
		_push_delta(p, a.food_gain, "jedzenia")
		_push_delta(p, a.water_gain, "wody")
		_push_delta(p, a.wood_gain, "drewna")
		_push_delta(p, a.materials_gain, "kamienia")
		_push_delta(p, a.next_day_energy_delta, "energii jutro")
		var sp := _action_special_text(a.special)
		if sp != "":
			p.append(sp)
	elif card is BuildingCardData:
		var b := card as BuildingCardData
		_push_delta(p, b.food_gain, tr("jedzenia nocą"))
		_push_delta(p, b.water_gain, tr("wody nocą"))
		_push_delta(p, b.wood_gain, tr("drewna nocą"))
		_push_delta(p, b.materials_gain, tr("kamienia nocą"))
		_push_delta(p, b.health_delta, tr("zdrowia nocą"))
		_push_delta(p, b.warmth_delta, tr("ciepła nocą"))
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
			p.append(tr("-%d zdrowia gracza") % m.damage_to_player)
		if m.damage_to_buildings > 0:
			p.append(tr("-%d HP budynku") % m.damage_to_buildings)
		if p.is_empty():
			p.append(tr("atak bez obrażeń"))
	if p.is_empty():
		return ""
	return "  ·  ".join(p)


func _push_delta(parts: PackedStringArray, value: int, stat_name: String) -> void:
	if value != 0:
		parts.append("%+d %s" % [value, tr(stat_name)])


func _action_special_text(special: String) -> String:
	match special:
		"craft_tools": return tr("narzędzia (+zbiory)")
		"explore": return "+1 losowe znalezisko"
		"double_explore": return "+2 losowe znaleziska"
		"draw_two": return tr("+2 karty do ręki")
		"scout_reveal": return tr("odkrywa sąsiedni teren")
		"free_move": return tr("następny ruch dziś za darmo")
		"repair_tile": return tr("doraźna naprawa budynku")
		"ward_night": return tr("warta: łagodzi tę noc")
		"set_trap": return tr("wnyki: blokują atak potwora")
		"momentum": return tr("kolejne karty dziś zwracają energię")
		"rhythm": return ""
		"combo_food": return tr("+2 jedzenia, jeśli grałeś już jedzenie")
		"next_move_cost": return tr("następny ruch dziś kosztuje +1 energii")
		_: return ""


func _building_special_text(special: String) -> String:
	match special:
		"night_protection": return "ochrona nocna"
		"slow_spoilage": return "wolniejsze psucie jedzenia"
		"unlock_crafting": return tr("narzędzia po zbudowaniu")
		_: return ""


func _format_costs(card: CardData) -> String:
	var parts: PackedStringArray = []
	if card is ActionCardData:
		var action := card as ActionCardData
		parts.append(tr("Energia %d") % action.energy_cost)
		if action.food_cost > 0:
			parts.append(tr("Jedzenie %d") % action.food_cost)
		if action.wood_cost > 0:
			parts.append(tr("Drewno %d") % action.wood_cost)
		if action.materials_cost > 0:
			parts.append(tr("Kamień %d") % action.materials_cost)
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		parts.append(tr("Energia %d") % building.energy_cost)
		if building.food_cost > 0:
			parts.append(tr("Jedzenie %d") % building.food_cost)
		if building.wood_cost > 0:
			parts.append(tr("Drewno %d") % building.wood_cost)
		if building.materials_cost > 0:
			parts.append(tr("Kamień %d") % building.materials_cost)
	elif card is MonsterCardData:
		var monster := card as MonsterCardData
		var dmg: PackedStringArray = []
		if monster.damage_to_player > 0:
			dmg.append("gracz %d" % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			dmg.append("budynki %d" % monster.damage_to_buildings)
		return tr("Atak — %s") % ", ".join(dmg) if not dmg.is_empty() else tr("Potwór")
	elif card is EventCardData:
		return tr("Zdarzenie nocne")
	return "   ·   ".join(parts)


## When the stat icon set exists (assets/art/ui/icons/stats/), the textual cost
## line is swapped for icon+number pairs in the same frame window. Missing icons
## (or monster/event cards) keep the current text — plug-and-play like card art.
func _apply_cost_icons(card: CardData, cost_values: Dictionary) -> void:
	var parts := _icon_cost_parts(card, cost_values)
	var icons: Array[Texture2D] = []
	for part in parts:
		icons.append(StatIcons.texture(part[0]))
	if parts.is_empty() or icons.has(null):
		if _cost_row != null:
			_cost_row.visible = false
		return
	if _cost_row == null:
		_cost_row = HBoxContainer.new()
		_cost_row.name = "CostIconRow"
		_cost_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cost_row.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(_cost_row)
		_cost_row.anchor_left = _cost_label.anchor_left
		_cost_row.anchor_top = _cost_label.anchor_top
		_cost_row.anchor_right = _cost_label.anchor_right
		_cost_row.anchor_bottom = _cost_label.anchor_bottom
	# Pixel sizes below were tuned for the 132x198 hand card; the deck popup's
	# minis (92x138) and the zoom preview (198x297) reuse this scene, so the
	# frame-window offsets, icon size and font all scale with the card height —
	# otherwise the row overflows the mini card's frame.
	var card_scale := _card_scale()
	_cost_row.add_theme_constant_override("separation", maxi(2, roundi(3.0 * card_scale)))
	_cost_row.offset_left = _cost_label.offset_left * card_scale
	_cost_row.offset_top = _cost_label.offset_top * card_scale
	_cost_row.offset_right = _cost_label.offset_right * card_scale
	_cost_row.offset_bottom = _cost_label.offset_bottom * card_scale
	for child in _cost_row.get_children():
		child.queue_free()
	var font_color := _cost_label.get_theme_color("font_color")
	for i in parts.size():
		var icon := TextureRect.new()
		icon.texture = icons[i]
		icon.custom_minimum_size = Vector2(roundi(15.0 * card_scale), 0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_cost_row.add_child(icon)
		var amount := Label.new()
		amount.text = str(parts[i][1])
		amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		amount.mouse_filter = Control.MOUSE_FILTER_IGNORE
		amount.add_theme_font_size_override("font_size", maxi(7, roundi(11.0 * card_scale)))
		amount.add_theme_color_override("font_color", font_color)
		_cost_row.add_child(amount)
	_cost_row.visible = true
	_cost_label.visible = false


## Ratio of this card's height to the base 132x198 hand card (card_view.tscn).
func _card_scale() -> float:
	var height := size.y
	if height <= 1.0:
		height = custom_minimum_size.y
	if height <= 1.0:
		return 1.0
	return height / 198.0


## [[icon_key, amount], ...] for the cost row; empty = keep the text line.
func _icon_cost_parts(card: CardData, cost_values: Dictionary) -> Array:
	var energy := 0
	var food := 0
	var wood := 0
	var materials := 0
	if not cost_values.is_empty():
		energy = int(cost_values.get("energy", 0))
		food = int(cost_values.get("food", 0))
		wood = int(cost_values.get("wood", 0))
		materials = int(cost_values.get("materials", 0))
	elif card is ActionCardData:
		var action := card as ActionCardData
		energy = action.energy_cost
		food = action.food_cost
		wood = action.wood_cost
		materials = action.materials_cost
	elif card is BuildingCardData:
		var building := card as BuildingCardData
		energy = building.energy_cost
		food = building.food_cost
		wood = building.wood_cost
		materials = building.materials_cost
	else:
		return []
	var parts := [["energy", energy]]
	if food > 0:
		parts.append(["food", food])
	if wood > 0:
		parts.append(["wood", wood])
	if materials > 0:
		parts.append(["stone", materials])
	return parts


func _ensure_feedback_frame() -> void:
	if _feedback_frame != null and is_instance_valid(_feedback_frame):
		return
	_feedback_frame = Panel.new()
	_feedback_frame.name = "BlockFeedbackFrame"
	_feedback_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_feedback_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.45, 0.02, 0.02, 0.0)
	box.border_color = Color(1.0, 0.1, 0.04, 0.95)
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	_feedback_frame.add_theme_stylebox_override("panel", box)
	add_child(_feedback_frame)
	move_child(_feedback_frame, get_child_count() - 1)
	_feedback_frame.visible = false
