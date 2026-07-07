class_name NightOverlayView
extends ColorRect
## Night-event popup extracted from run.gd: swaps the painted panel scene per
## card kind (single/decision/monster), builds the pinned choice buttons,
## plays the reveal FX and the claw flash, and settles the night through
## SurvivalSystem (apply_night_choice / resolve_night). The run scene only
## forwards night_card_drawn into show_card() and keeps its tutorial hook.

## Blocked-choice feedback wants a line in the run log.
signal log_line(text: String)

const NIGHT_POPUP_SINGLE_SCENE := preload("res://ui/night_popup_single.tscn")
const NIGHT_POPUP_DECISION_SCENE := preload("res://ui/night_popup_decision.tscn")
const NIGHT_POPUP_DECISION_TWO_SCENE := preload("res://ui/night_popup_decision_two.tscn")
const NIGHT_POPUP_MONSTER_SCENE := preload("res://ui/night_popup_monster.tscn")
const NIGHT_FX := {
	"spotlight": "res://assets/art/ui/overlay_night_spotlight.png",
	"glow": "res://assets/art/fx/cards/fx_card_reveal_glow.png",
	"burst": "res://assets/art/fx/cards/fx_card_reveal_burst.png",
	"shine": "res://assets/art/fx/cards/fx_card_shine_sweep.png",
	"dust": "res://assets/art/fx/cards/fx_card_dust_puff.png",
}
const NIGHT_BUTTON_HOVER_COLOR := Color(0.96, 0.72, 0.28, 1.0)
const NIGHT_BUTTON_HOVER_SCALE := Vector2(1.045, 1.045)
const CLAW_FX := "res://assets/art/fx/monster_attack/fx_claw_slash.png"
const PANEL_BASE := Vector2(840, 630)
const OVERLAY_PADDING := Vector2(32, 32)

var _survival: SurvivalSystem
var _night_panel: Control
var _night_panel_art: TextureRect
var _night_title: Label
var _night_illustration: TextureRect
var _night_summary: RichTextLabel
var _night_desc: Label
var _night_continue_button: Button
var _night_choices: Control
var _night_result: Label
var _night_fx: Array[Node] = []
var _night_tween: Tween
var _night_hover_tweens: Dictionary = {}
var _night_block_tweens: Dictionary = {}
var _night_popup_kind := ""
var _night_choice_buttons: Array[Button] = []
var _night_choice_labels: Array[RichTextLabel] = []
var _act2 := false
var _act2_text_color := Color.WHITE


func _ready() -> void:
	visible = false
	_night_panel = $Panel
	_use_night_popup_scene(false, false)


## The run scene injects the survival system before begin().
func setup(survival: SurvivalSystem) -> void:
	_survival = survival


## Current popup panel (swapped per card kind) — the tutorial highlights it.
func panel() -> Control:
	return _night_panel


## Post-BUM look: recolors the popup copy to the disaster's log text color.
func set_act2(look: Dictionary) -> void:
	_act2 = true
	_act2_text_color = look["log_text"]
	if _night_summary != null:
		_night_summary.add_theme_color_override("default_color", _act2_text_color)
		_night_desc.add_theme_color_override("font_color", _act2_text_color)
		_night_result.add_theme_color_override("font_color", _act2_text_color)


## Scales the panel to the viewport (same rule as run.gd's centered panels).
func fit(viewport_size: Vector2) -> void:
	if _night_panel == null:
		return
	var available := Vector2(
		maxf(viewport_size.x - OVERLAY_PADDING.x * 2.0, 1.0),
		maxf(viewport_size.y - OVERLAY_PADDING.y * 2.0, 1.0)
	)
	var panel_scale := minf(1.0, minf(available.x / PANEL_BASE.x, available.y / PANEL_BASE.y))
	_night_panel.scale = Vector2(panel_scale, panel_scale)
	_night_panel.pivot_offset = _night_panel.size * 0.5


func show_card(card: CardData) -> void:
	_clear_night_card()
	visible = true
	var is_monster := card is MonsterCardData
	var has_choices := card is EventCardData and not (card as EventCardData).choices.is_empty()
	var choice_count := (card as EventCardData).choices.size() if card is EventCardData else 0
	_use_night_popup_scene(is_monster, has_choices, choice_count)
	# Locked until the reveal animation finishes, so the card is always read
	# before its effects resolve (re-enabled on the reveal tween's `finished`).
	_night_continue_button.disabled = true
	_night_title.text = tr(card.display_name)
	_night_desc.text = tr(card.description)
	# The flavour text alone doesn't say what the attack does — the player had
	# to check the log afterwards. Fold the same numbers already shown in the
	# EffectsLabel into the description itself so they're impossible to miss.
	if is_monster:
		var monster_effect := _night_card_effect_summary(card)
		if monster_effect != "":
			_night_desc.text += "\n\n%s" % monster_effect
	_night_desc.visible = true
	_night_result.visible = false

	_night_summary.text = StatIcons.iconify(_night_summary_text(card), 15)
	_night_summary.visible = true
	_build_night_choices(card)
	_play_night_reveal(_night_illustration_texture(card), _night_tint(card))
	# Monster SFX plays in run.gd (ui/ scripts stay autoload-free for -s tests).
	if is_monster:
		_spawn_claw_flash()


func hide_event() -> void:
	visible = false
	_clear_night_card()


func _night_popup_scene(is_monster: bool, has_choices: bool, choice_count: int = 0) -> PackedScene:
	if is_monster:
		return NIGHT_POPUP_MONSTER_SCENE
	if has_choices and choice_count == 2:
		return NIGHT_POPUP_DECISION_TWO_SCENE
	if has_choices:
		return NIGHT_POPUP_DECISION_SCENE
	return NIGHT_POPUP_SINGLE_SCENE


func _use_night_popup_scene(is_monster: bool, has_choices: bool, choice_count: int = 0) -> void:
	var kind := "monster" if is_monster else ("decision_two" if has_choices and choice_count == 2 else ("decision" if has_choices else "single"))
	if _night_popup_kind == kind and is_instance_valid(_night_panel):
		_bind_night_popup_nodes()
		return
	_night_popup_kind = kind
	if is_instance_valid(_night_panel):
		remove_child(_night_panel)
		_night_panel.queue_free()
	_night_panel = _night_popup_scene(is_monster, has_choices, choice_count).instantiate() as Control
	add_child(_night_panel)
	move_child(_night_panel, 0)
	_bind_night_popup_nodes()
	fit(get_viewport_rect().size)


func _bind_night_popup_nodes() -> void:
	_night_panel_art = _night_panel.get_node("PanelArt") as TextureRect
	_night_title = _night_panel.get_node("TitleLabel") as Label
	_night_illustration = _night_panel.get_node("Illustration") as TextureRect
	_night_summary = _night_panel.get_node("EffectsLabel") as RichTextLabel
	_night_desc = _night_panel.get_node("DescLabel") as Label
	_night_continue_button = _night_panel.get_node("ContinueButton") as Button
	_night_choices = _night_panel.get_node("ChoiceButtons") as Control
	_night_result = _night_panel.get_node("ResultLabel") as Label
	_collect_night_choice_controls()
	var continue_callable := Callable(self, "_on_night_continue")
	if not _night_continue_button.pressed.is_connected(continue_callable):
		_night_continue_button.pressed.connect(continue_callable)
	_clear_night_button_chrome(_night_continue_button)
	_setup_night_button_hover(_night_continue_button)
	# Each scene's DescLabel is hand-tuned to its painted sheet — it is the
	# reference rect. ResultLabel mirrors it exactly (same place, same size),
	# and both center their text. _on_night_choice widens only the result,
	# over the sheet freed by the choice notes.
	_night_result.anchor_left = _night_desc.anchor_left
	_night_result.anchor_top = _night_desc.anchor_top
	_night_result.anchor_right = _night_desc.anchor_right
	_night_result.anchor_bottom = _night_desc.anchor_bottom
	_night_result.offset_left = _night_desc.offset_left
	_night_result.offset_top = _night_desc.offset_top
	_night_result.offset_right = _night_desc.offset_right
	_night_result.offset_bottom = _night_desc.offset_bottom
	for sheet_label: Label in [_night_desc, _night_result]:
		sheet_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sheet_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# The summary note and choice sheets are small and their icon lines wrap —
	# extra leading keeps wrapped lines from stacking on each other.
	_night_summary.add_theme_constant_override("line_separation", 5)
	for choice_label in _night_choice_labels:
		choice_label.add_theme_constant_override("line_separation", 3)
	if _act2:
		_night_summary.add_theme_color_override("default_color", _act2_text_color)
		_night_desc.add_theme_color_override("font_color", _act2_text_color)
		_night_result.add_theme_color_override("font_color", _act2_text_color)
	for i in range(_night_choice_buttons.size()):
		var button := _night_choice_buttons[i]
		_clear_night_button_chrome(button)
		var label: Control = _night_choice_labels[i] if i < _night_choice_labels.size() else null
		_setup_night_button_hover(button, label)
		button.text = ""


func _clear_night_button_chrome(button: Button) -> void:
	if button == null:
		return
	var empty_style := StyleBoxEmpty.new()
	button.flat = true
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, empty_style)


func _setup_night_button_hover(button: Button, target: Control = null) -> void:
	if button == null:
		return
	var visual: Control = target if target != null else button
	visual.pivot_offset = visual.size * 0.5
	if not button.has_meta("night_hover_normal_color"):
		button.set_meta("night_hover_normal_color", _visual_font_color(visual))
	var enter_callable := Callable(self, "_on_night_button_hover_changed").bind(button, target, true)
	var exit_callable := Callable(self, "_on_night_button_hover_changed").bind(button, target, false)
	if not button.mouse_entered.is_connected(enter_callable):
		button.mouse_entered.connect(enter_callable)
	if not button.mouse_exited.is_connected(exit_callable):
		button.mouse_exited.connect(exit_callable)
	if not button.focus_entered.is_connected(enter_callable):
		button.focus_entered.connect(enter_callable)
	if not button.focus_exited.is_connected(exit_callable):
		button.focus_exited.connect(exit_callable)
	_on_night_button_hover_changed(button, target, false)


func _on_night_button_hover_changed(button: Button, target: Control, hovered: bool) -> void:
	if button == null or not is_instance_valid(button):
		return
	var visual: Control = target if target != null and is_instance_valid(target) else button
	if visual == null or not is_instance_valid(visual):
		return
	var normal_color: Color = button.get_meta("night_hover_normal_color", _visual_font_color(visual))
	var block_reason := str(button.get_meta("choice_block_reason", ""))
	var can_hover := hovered and not button.disabled and block_reason == ""
	var target_scale := NIGHT_BUTTON_HOVER_SCALE if can_hover else Vector2.ONE
	var target_color := NIGHT_BUTTON_HOVER_COLOR if can_hover else normal_color
	visual.pivot_offset = visual.size * 0.5
	var key := visual.get_instance_id()
	var existing: Tween = _night_hover_tweens.get(key) as Tween
	if existing != null:
		existing.kill()
	var tween := create_tween().set_parallel(true)
	_night_hover_tweens[key] = tween
	tween.tween_property(visual, "scale", target_scale, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void:
		_night_hover_tweens.erase(key)
	).set_delay(0.1)
	_set_visual_font_color(visual, target_color)


func _reset_night_button_hover(button: Button, target: Control = null) -> void:
	if button == null or not is_instance_valid(button):
		return
	var visual: Control = target if target != null and is_instance_valid(target) else button
	if visual == null or not is_instance_valid(visual):
		return
	var key := visual.get_instance_id()
	var existing: Tween = _night_hover_tweens.get(key) as Tween
	if existing != null:
		existing.kill()
	_night_hover_tweens.erase(key)
	visual.scale = Vector2.ONE
	var normal_color: Color = button.get_meta("night_hover_normal_color", _visual_font_color(visual))
	_set_visual_font_color(visual, normal_color)


## Labels/Buttons colour their text via "font_color", RichTextLabels (choice
## notes with inline stat icons) via "default_color".
func _visual_font_color(visual: Control) -> Color:
	if visual is RichTextLabel:
		return visual.get_theme_color("default_color")
	return visual.get_theme_color("font_color")


func _set_visual_font_color(visual: Control, color: Color) -> void:
	if visual is RichTextLabel:
		visual.add_theme_color_override("default_color", color)
	elif visual is Label or visual is Button:
		visual.add_theme_color_override("font_color", color)


func _collect_night_choice_controls() -> void:
	_night_choice_buttons.clear()
	_night_choice_labels.clear()
	for i in range(1, 4):
		var button := _night_panel.get_node_or_null("ChoiceButtons/ChoiceButton%d" % i) as Button
		if button != null:
			_night_choice_buttons.append(button)
		var label := _night_panel.get_node_or_null("ChoiceButtons/ChoiceText%d" % i) as RichTextLabel
		if label != null:
			_night_choice_labels.append(label)


func _ordered_night_choice_indices(choices: Array) -> Array[int]:
	var regular_indices: Array[int] = []
	var risk_indices: Array[int] = []
	for i in range(choices.size()):
		if _night_choice_is_risky(choices[i]):
			risk_indices.append(i)
		else:
			regular_indices.append(i)
	regular_indices.append_array(risk_indices)
	return regular_indices


func _night_choice_is_risky(choice) -> bool:
	if choice == null:
		return false
	var label := str(choice.get("label")).to_lower()
	return int(choice.get("risk_chance")) > 0 or label.find("ryzyko") != -1


func _disconnect_night_choice_button(button: Button) -> void:
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable")
		if callable.get_object() != self:
			continue
		var method := str(callable.get_method())
		if method == "_on_night_choice" or method == "_on_night_choice_button_pressed":
			button.pressed.disconnect(callable)


func _on_night_choice_button_pressed(button: Button) -> void:
	var block_reason := str(button.get_meta("choice_block_reason", ""))
	if block_reason != "":
		_play_night_choice_blocked_feedback(button, block_reason)
		return
	var choice_index := int(button.get_meta("choice_index", -1))
	if choice_index >= 0:
		_on_night_choice(choice_index)


func _play_night_choice_blocked_feedback(button: Button, reason: String) -> void:
	if button == null or not is_instance_valid(button):
		return
	button.tooltip_text = reason
	log_line.emit(reason)
	var frame := _ensure_night_choice_feedback_frame(button)
	frame.visible = true
	var key := button.get_instance_id()
	var existing: Tween = _night_block_tweens.get(key) as Tween
	if existing != null:
		existing.kill()
	button.position.x = round(button.position.x)
	var base_position := button.position
	frame.modulate.a = 1.0
	var tween := create_tween()
	_night_block_tweens[key] = tween
	tween.tween_property(button, "position:x", base_position.x - 6.0, 0.04)
	tween.tween_property(button, "position:x", base_position.x + 6.0, 0.06)
	tween.tween_property(button, "position:x", base_position.x - 4.0, 0.05)
	tween.tween_property(button, "position:x", base_position.x + 3.0, 0.05)
	tween.tween_property(button, "position:x", base_position.x, 0.05)
	tween.tween_property(frame, "modulate:a", 0.0, 0.25)
	tween.finished.connect(func() -> void:
		_night_block_tweens.erase(key)
		if is_instance_valid(frame):
			frame.visible = false
	)


func _ensure_night_choice_feedback_frame(button: Button) -> Panel:
	var frame := button.get_node_or_null("BlockFeedbackFrame") as Panel
	if frame != null:
		return frame
	frame = Panel.new()
	frame.name = "BlockFeedbackFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.45, 0.02, 0.02, 0.0)
	box.border_color = Color(1.0, 0.1, 0.04, 0.95)
	box.set_border_width_all(3)
	box.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", box)
	button.add_child(frame)
	button.move_child(frame, button.get_child_count() - 1)
	frame.visible = false
	return frame


## Same lookup CardView uses for events/monsters, without needing a CardView
## instance (the panel shows the illustration directly, not a full card).
func _night_illustration_texture(card: CardData) -> Texture2D:
	var path := ""
	if card is MonsterCardData:
		path = "%s/%s.png" % [
			CardView.MONSTER_ART_DIR, CardView.MONSTER_ART_ALIASES.get(card.id, card.id)
		]
	elif card is EventCardData:
		path = "%s/%s.png" % [CardView.EVENT_ART_DIR, card.id]
	if path != "" and ResourceLoader.exists(path):
		return load(path)
	return null


## Decision events show one button per choice (with its effect summary), pinned
## to note slots baked into the active popup scene. Buttons start disabled and
## unlock when the reveal ends.
func _build_night_choices(card: CardData) -> void:
	var choices: Array = card.get("choices") if card is EventCardData else []
	_reset_night_choice_controls()
	if choices == null or choices.is_empty():
		_night_choices.visible = false
		_night_continue_button.visible = true
		return
	_night_choices.visible = true
	_night_result.visible = false
	_night_continue_button.visible = false
	var choice_indices := _ordered_night_choice_indices(choices)
	for i in range(_night_choice_buttons.size()):
		var button := _night_choice_buttons[i]
		var hover_label: Control = _night_choice_labels[i] if i < _night_choice_labels.size() else null
		_reset_night_button_hover(button, hover_label)
		var label: RichTextLabel = _night_choice_labels[i] if i < _night_choice_labels.size() else null
		var has_choice := i < choice_indices.size()
		button.visible = has_choice
		if label != null:
			label.visible = has_choice
		if not has_choice:
			continue
		var choice_index := choice_indices[i]
		var choice = choices[choice_index]
		var block_reason := _survival.night_choice_block_reason(choice_index) if _survival != null else ""
		button.disabled = true
		button.set_meta("choice_block_reason", block_reason)
		button.set_meta("choice_index", choice_index)
		button.tooltip_text = block_reason
		button.modulate = Color(0.72, 0.68, 0.62, 1.0) if block_reason != "" else Color.WHITE
		button.text = ""
		if label != null:
			label.text = "[center]%s[/center]" % StatIcons.iconify(
				_choice_button_text(choice, block_reason), 14)
			label.modulate = Color(0.72, 0.68, 0.62, 1.0) if block_reason != "" else Color.WHITE
		_disconnect_night_choice_button(button)
		button.pressed.connect(Callable(self, "_on_night_choice_button_pressed").bind(button))


func _reset_night_choice_controls() -> void:
	for i in range(_night_choice_buttons.size()):
		var button := _night_choice_buttons[i]
		var label: Control = _night_choice_labels[i] if i < _night_choice_labels.size() else null
		_reset_night_button_hover(button, label)
		button.visible = false
		button.disabled = true
		button.text = ""
		button.tooltip_text = ""
		button.modulate = Color.WHITE
		button.set_meta("choice_block_reason", "")
		button.set_meta("choice_index", -1)
	for label in _night_choice_labels:
		label.visible = false
		label.text = ""
		label.modulate = Color.WHITE

## Full choice copy: clear risk odds plus explicit success/failure outcomes.
func _choice_button_text(choice, block_reason: String = "") -> String:
	var label := _choice_label_without_risk(tr(choice.label))
	var title := label
	if choice.risk_chance > 0:
		title = tr("%s (%d%% na sukces)") % [label, 100 - choice.risk_chance]

	var lines: PackedStringArray = [title]
	var success := _choice_success_summary(choice)
	if success != "":
		lines.append("%s: %s" % [tr("Sukces") if choice.risk_chance > 0 else tr("Efekt"), success])
	if choice.risk_chance > 0:
		lines.append(tr("Porażka: %s") % _choice_failure_summary(choice))
	if block_reason != "":
		lines.append(block_reason)
	return "\n".join(lines)


func _choice_label_without_risk(label: String) -> String:
	return label.replace(" (ryzyko)", "").replace("(ryzyko)", "").strip_edges()


func _choice_success_summary(choice) -> String:
	var parts: PackedStringArray = []
	if choice.health_delta != 0: parts.append(tr("%+d zdrowia") % choice.health_delta)
	if choice.hunger_delta != 0: parts.append(tr("%+d sytości") % choice.hunger_delta)
	if choice.thirst_delta != 0: parts.append(tr("%+d nawodnienia") % choice.thirst_delta)
	if choice.warmth_delta != 0: parts.append(tr("%+d ciepła") % choice.warmth_delta)
	if choice.food_gain != 0: parts.append(tr("%+d jedzenia") % choice.food_gain)
	if choice.water_gain != 0: parts.append(tr("%+d wody") % choice.water_gain)
	if choice.wood_gain != 0: parts.append(tr("%+d drewna") % choice.wood_gain)
	if choice.materials_gain != 0: parts.append(tr("%+d kamienia") % choice.materials_gain)
	if choice.next_day_energy_delta != 0: parts.append(tr("%+d energii jutro") % choice.next_day_energy_delta)
	if choice.grant_random_card: parts.append("+1 karta do talii")
	return _join_effect_parts(parts)


func _choice_failure_summary(choice) -> String:
	var parts: PackedStringArray = []
	if choice.risk_health > 0: parts.append(tr("-%d zdrowia") % choice.risk_health)
	if choice.risk_hunger_delta != 0: parts.append(tr("%+d sytości") % choice.risk_hunger_delta)
	if choice.risk_thirst_delta != 0: parts.append(tr("%+d nawodnienia") % choice.risk_thirst_delta)
	if choice.risk_warmth_delta != 0: parts.append(tr("%+d ciepła") % choice.risk_warmth_delta)
	if choice.risk_food_gain != 0: parts.append(tr("%+d jedzenia") % choice.risk_food_gain)
	if choice.risk_water_gain != 0: parts.append(tr("%+d wody") % choice.risk_water_gain)
	if choice.risk_wood_gain != 0: parts.append(tr("%+d drewna") % choice.risk_wood_gain)
	if choice.risk_materials_gain != 0: parts.append(tr("%+d kamienia") % choice.risk_materials_gain)
	if choice.risk_next_day_energy_delta != 0: parts.append(tr("%+d energii jutro") % choice.risk_next_day_energy_delta)
	return _join_effect_parts(parts) if not parts.is_empty() else "brak efektu"


## Effect lines used to be one dense comma string; with inline icons the +/-
## items sat on top of each other. Gains come first, losses second, with wide
## gaps inside groups and `group_sep` between them (newline = one line of +,
## one line of -).
func _join_effect_parts(parts: PackedStringArray, group_sep := "     ") -> String:
	var gains: PackedStringArray = []
	var losses: PackedStringArray = []
	for part in parts:
		(losses if part.begins_with("-") else gains).append(part)
	var groups: PackedStringArray = []
	if not gains.is_empty():
		groups.append("  ".join(gains))
	if not losses.is_empty():
		groups.append("  ".join(losses))
	return group_sep.join(groups)


func _night_summary_text(card: CardData) -> String:
	var lines: PackedStringArray = []
	var card_effect := _night_card_effect_summary(card)
	if card_effect != "":
		lines.append(tr("Karta: %s") % card_effect)
	var passives := _night_building_passive_summary()
	if passives != "":
		lines.append(tr("Budynki: %s") % passives)
	lines.append(tr("Noc: %s") % _night_needs_summary())
	var total := _night_total_summary(card)
	if total != "":
		# Blank line pushes the block to the bottom of the note; the header
		# gets its own line, then gains and losses each on their own line.
		lines.append("")
		lines.append(tr("Podsumowanie:"))
		lines.append(total)
	return "\n".join(lines)


## Net effect of the whole night — card + building passives + need decays —
## so the player doesn't have to sum three lines in their head. Empty for
## choice cards (the total depends on the pick).
func _night_total_summary(card: CardData) -> String:
	var totals := _building_passive_deltas()
	if card is MonsterCardData:
		totals[0] -= (card as MonsterCardData).damage_to_player
	elif card is EventCardData:
		var event := card as EventCardData
		if not event.choices.is_empty():
			return ""
		var event_deltas := _event_stat_deltas(event)
		for i in totals.size():
			totals[i] += event_deltas[i]
	var decays := _night_needs_decays()
	totals[1] -= decays[0]
	totals[2] -= decays[1]
	totals[3] -= decays[2]
	return _join_effect_parts(_stat_delta_parts(totals), "\n")


func _night_card_effect_summary(card: CardData) -> String:
	if card is MonsterCardData:
		var monster := card as MonsterCardData
		var monster_parts: PackedStringArray = []
		if monster.damage_to_player > 0:
			monster_parts.append(tr("-%d zdrowia") % monster.damage_to_player)
		if monster.damage_to_buildings > 0:
			monster_parts.append("-%d HP budynku" % monster.damage_to_buildings)
		return _join_effect_parts(monster_parts) if not monster_parts.is_empty() else tr("atak bez obrażeń")
	if not (card is EventCardData):
		return ""
	var event := card as EventCardData
	if not event.choices.is_empty():
		return tr("wybierz opcję poniżej")
	var event_parts := _stat_delta_parts(_event_stat_deltas(event))
	return _join_effect_parts(event_parts) if not event_parts.is_empty() else "brak zmian"


## [health, hunger, thirst, warmth, food, water, wood, stone, next_energy]
## for a no-choice event, with shelter protection already applied.
func _event_stat_deltas(event: EventCardData) -> Array[int]:
	var health_delta := event.health_delta
	var warmth_delta := event.warmth_delta
	if event.shelter_protects and _has_standing_special("night_protection"):
		health_delta = maxi(health_delta, mini(health_delta + SurvivalSystem.NIGHT_PROTECTION_VALUE, 0))
		warmth_delta = maxi(warmth_delta, mini(warmth_delta + SurvivalSystem.NIGHT_PROTECTION_VALUE, 0))
	return [health_delta, event.hunger_delta, event.thirst_delta, warmth_delta,
		event.food_delta, event.water_delta, event.wood_delta, event.materials_delta,
		event.next_day_energy_delta]


func _night_building_passive_summary() -> String:
	return _join_effect_parts(_stat_delta_parts(_building_passive_deltas()))


## Same layout as _event_stat_deltas, summed over standing (non-ruined)
## buildings. Workshop crafting (-1 wood, +1 stone) is folded into the numbers.
func _building_passive_deltas() -> Array[int]:
	var d: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0, 0]
	if _survival == null or _survival.state == null:
		return d
	var workshop_crafts := false
	for tile in _survival.state.board:
		for built in tile.buildings:
			if built.is_ruined:
				continue
			var data: BuildingCardData = built.data
			d[0] += data.health_delta
			d[1] += data.hunger_delta
			d[2] += data.thirst_delta
			d[3] += data.warmth_delta
			d[4] += data.food_gain
			d[5] += data.water_gain
			d[6] += data.wood_gain
			d[7] += data.materials_gain
			if data.special == "unlock_crafting" and _survival.state.wood > 0:
				workshop_crafts = true
	if workshop_crafts:
		d[6] -= 1
		d[7] += 1
	return d


func _night_needs_summary() -> String:
	var decays := _night_needs_decays()
	return tr("-%d sytości, -%d nawodnienia, -%d ciepła") % [decays[0], decays[1], decays[2]]


## Tonight's raw need decays as positive numbers: [hunger, thirst, warmth].
func _night_needs_decays() -> Array[int]:
	if _survival == null or _survival.state == null:
		return [SurvivalSystem.DAILY_HUNGER_DECAY, SurvivalSystem.DAILY_THIRST_DECAY,
			SurvivalSystem.DAILY_WARMTH_DECAY]
	var state := _survival.state
	var hunger_decay := SurvivalSystem.DAILY_HUNGER_DECAY + state.character_class.hunger_rate_delta
	var thirst_decay := SurvivalSystem.DAILY_THIRST_DECAY + state.character_class.thirst_rate_delta
	var warmth_decay := SurvivalSystem.DAILY_WARMTH_DECAY + state.character_class.warmth_rate_delta
	if state.bum_happened and state.disaster != null:
		hunger_decay += int(state.disaster.get("act2_hunger_decay_delta"))
		thirst_decay += int(state.disaster.get("act2_thirst_decay_delta"))
		warmth_decay += int(state.disaster.get("act2_warmth_decay_delta"))
	if state.season == RunState.Season.SUMMER:
		thirst_decay += SurvivalSystem.SUMMER_EXTRA_THIRST_DECAY
	if state.season == RunState.Season.WINTER:
		warmth_decay += SurvivalSystem.WINTER_EXTRA_WARMTH_DECAY
	return [hunger_decay, thirst_decay, warmth_decay]


## "+2 wody"-style parts from [health, hunger, thirst, warmth, food, water,
## wood, stone, next_energy]; zero deltas are skipped.
func _stat_delta_parts(d: Array[int]) -> PackedStringArray:
	var parts: PackedStringArray = []
	if d[0] != 0: parts.append(tr("%+d zdrowia") % d[0])
	if d[1] != 0: parts.append(tr("%+d sytości") % d[1])
	if d[2] != 0: parts.append(tr("%+d nawodnienia") % d[2])
	if d[3] != 0: parts.append(tr("%+d ciepła") % d[3])
	if d[4] != 0: parts.append(tr("%+d jedzenia") % d[4])
	if d[5] != 0: parts.append(tr("%+d wody") % d[5])
	if d[6] != 0: parts.append(tr("%+d drewna") % d[6])
	if d[7] != 0: parts.append(tr("%+d kamienia") % d[7])
	if d[8] != 0: parts.append(tr("%+d energii jutro") % d[8])
	return parts


func _has_standing_special(special: String) -> bool:
	if _survival == null or _survival.state == null:
		return false
	for tile in _survival.state.board:
		for built in tile.buildings:
			if not built.is_ruined and built.data.special == special:
				return true
	return false


## Picking a choice applies it immediately but PAUSES on a result summary — the
## player reads what happened and clicks „Dalej" to settle the night.
func _on_night_choice(index: int) -> void:
	var summary := _survival.apply_night_choice(index)
	_reset_night_choice_controls()
	_night_choices.visible = false
	_night_desc.visible = false
	# The result reclaims the full description sheet now that the choice
	# notes (which used to cover its lower two-thirds) are gone.
	_night_result.anchor_top = 0.224
	_night_result.anchor_bottom = 0.678
	_night_result.text = summary
	_night_result.visible = true
	_night_summary.text = StatIcons.iconify(tr("Wybór: %s\nNoc: %s") % [
		summary.replace("\n", " "),
		_night_needs_summary()
	], 15)
	_night_continue_button.visible = true
	_night_continue_button.disabled = false


## Reveal FX tint by event category (monsters red, weather blue, biome green,
## disaster sickly purple, omen amber, neutral warm gold).
func _night_tint(card: CardData) -> Color:
	if card is MonsterCardData:
		return Color(1.0, 0.46, 0.4)
	var category := str(card.get("category")) if card is EventCardData else ""
	match category:
		"weather":
			return Color(0.62, 0.82, 1.0)
		"biome":
			return Color(0.72, 1.0, 0.62)
		"disaster":
			return Color(0.82, 0.52, 1.0)
		"omen":
			return Color(1.0, 0.72, 0.32)
		"monster":
			return Color(1.0, 0.46, 0.4)
		_:
			return Color(1.0, 0.92, 0.72)


## The night illustration appears directly in the panel; accent FX sell the
## reveal without rotating or folding the image inside the frame.
## Spotlight + glow linger behind the panel; the rest are one-shot. `tint`
## colours the glow/burst per category.
func _play_night_reveal(illustration: Texture2D, tint: Color) -> void:
	_night_illustration.texture = illustration
	_night_illustration.pivot_offset = _night_illustration.size * 0.5
	_night_illustration.scale = Vector2.ONE
	_night_illustration.modulate.a = 0.0

	# Backdrop glow behind the panel (does not wash the illustration).
	var spotlight := _spawn_night_fx("spotlight", get_viewport_rect().size, true, Color.WHITE, 0)
	var glow := _spawn_night_fx("glow", Vector2(560, 560), true, tint, 1)
	# One-shot accents on top.
	var burst := _spawn_night_fx("burst", Vector2(620, 620), true, tint, -1)
	burst.scale = Vector2(0.6, 0.6)
	var shine := _spawn_night_fx("shine", Vector2(220, 320), true, Color.WHITE, -1)
	var dust := _spawn_night_fx("dust", Vector2(360, 180), true, tint, -1)
	dust.position.y += 120.0

	const REVEAL_DELAY := 0.18

	if _night_tween != null:
		_night_tween.kill()
	_night_tween = create_tween().set_parallel(true)
	# Dust puff as the card lands (at the very start).
	_night_tween.tween_property(dust, "modulate:a", 0.7, 0.15)
	_night_tween.tween_property(dust, "modulate:a", 0.0, 0.4).set_delay(0.2)
	# Spotlight settles in immediately and frames the panel.
	_night_tween.tween_property(spotlight, "modulate:a", 0.55, 0.45)
	# Fade the final illustration in place, without scale/rotation tricks.
	_night_tween.tween_property(_night_illustration, "modulate:a", 1.0, 0.22) \
		.set_delay(REVEAL_DELAY).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_night_tween.tween_property(glow, "modulate:a", 0.7, 0.45).set_delay(REVEAL_DELAY)
	# Shine sweeps across after the image is visible.
	var sx := shine.position.x
	_night_tween.tween_property(shine, "modulate:a", 0.85, 0.15).set_delay(REVEAL_DELAY + 0.1)
	_night_tween.tween_property(shine, "position:x", sx + 90.0, 0.4) \
		.set_delay(REVEAL_DELAY + 0.1).set_trans(Tween.TRANS_SINE)
	_night_tween.tween_property(shine, "modulate:a", 0.0, 0.2).set_delay(REVEAL_DELAY + 0.4)
	# Burst pops at the reveal moment.
	_night_tween.tween_property(burst, "modulate:a", 0.9, 0.1).set_delay(REVEAL_DELAY + 0.2)
	_night_tween.tween_property(burst, "scale", Vector2(1.35, 1.35), 0.55) \
		.set_delay(REVEAL_DELAY + 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_night_tween.tween_property(burst, "modulate:a", 0.0, 0.4).set_delay(REVEAL_DELAY + 0.45)
	# Card has been revealed and read - let the player acknowledge / choose.
	_night_tween.finished.connect(func() -> void:
		if is_instance_valid(_night_continue_button):
			_night_continue_button.disabled = false
		for choice_button in _night_choice_buttons:
			if choice_button.visible:
				choice_button.disabled = false
	)

func _spawn_night_fx(id: String, fx_size: Vector2, additive: bool, tint: Color, behind: int) -> TextureRect:
	var layer := TextureRect.new()
	layer.texture = load(NIGHT_FX[id])
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.size = fx_size
	layer.position = get_viewport_rect().size * 0.5 - fx_size * 0.5
	layer.pivot_offset = fx_size * 0.5
	layer.modulate = Color(tint.r, tint.g, tint.b, 0.0)
	if additive:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		layer.material = mat
	add_child(layer)
	# behind >= 0: move under the panel (backdrop); -1: stay on top (accent).
	if behind >= 0:
		move_child(layer, behind)
	_night_fx.append(layer)
	return layer


## A quick claw-slash flash over the night card when a monster attacks.
func _spawn_claw_flash() -> void:
	if not ResourceLoader.exists(CLAW_FX):
		return
	var sz := Vector2(380, 380)
	var claw := TextureRect.new()
	claw.texture = load(CLAW_FX)
	claw.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	claw.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	claw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	claw.size = sz
	claw.position = get_viewport_rect().size * 0.5 - sz * 0.5
	claw.pivot_offset = sz * 0.5
	claw.modulate = Color(1, 1, 1, 0)
	claw.scale = Vector2(0.7, 0.7)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	claw.material = mat
	add_child(claw)
	_night_fx.append(claw)
	# Strike just after the card has flipped to its monster face.
	var t := create_tween()
	t.tween_interval(1.25)
	t.tween_property(claw, "modulate:a", 1.0, 0.07)
	t.parallel().tween_property(claw, "scale", Vector2(1.15, 1.15), 0.18)
	t.tween_property(claw, "modulate:a", 0.0, 0.28)


## OK pressed: hide the popup, THEN resolve the night so the player sees the
## card before the stats move. The button is disabled until the reveal finishes
## (see show_card / _play_night_reveal), so the card is always read.
func _on_night_continue() -> void:
	hide_event()
	_survival.resolve_night()


func _clear_night_card() -> void:
	if _night_tween != null:
		_night_tween.kill()
		_night_tween = null
	for node in _night_fx:
		if is_instance_valid(node):
			node.queue_free()
	_night_fx.clear()
	_reset_night_button_hover(_night_continue_button)
	for tween in _night_hover_tweens.values():
		var hover_tween: Tween = tween as Tween
		if hover_tween != null:
			hover_tween.kill()
	_night_hover_tweens.clear()
	_night_illustration.texture = null
	_night_illustration.scale = Vector2.ONE
	_night_illustration.modulate.a = 1.0
	_reset_night_choice_controls()
	_night_result.visible = false
	_night_result.text = ""
	_night_desc.visible = false
	_night_desc.text = ""
	_night_summary.visible = false
	_night_summary.text = ""
