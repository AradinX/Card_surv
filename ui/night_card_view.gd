class_name NightCardView
extends CardView
## Card popup layout for night events and monsters. It reuses CardView's data
## binding, art loading and text fitting, but has text windows aligned to
## card_frame_event.png / card_frame_monster.png instead of the hand-card frame.


func _apply_text_layout(_card: CardData) -> void:
	_cost_label.visible = false

	_set_rect_anchors(_name_label, 0.115, 0.048, 0.885, 0.155)
	_set_rect_anchors(_illustration, 0.125, 0.205, 0.875, 0.57)
	_set_rect_anchors(_desc_label, 0.115, 0.635, 0.885, 0.91)


func _fit_all_text() -> void:
	_fit_label_font(_name_label, 16, 8, 2)
	_fit_label_font(_desc_label, 12, 7, 7)


func _set_rect_anchors(node: Control, l: float, t: float, r: float, b: float) -> void:
	node.anchor_left = l
	node.anchor_top = t
	node.anchor_right = r
	node.anchor_bottom = b
	node.offset_left = 0.0
	node.offset_top = 0.0
	node.offset_right = 0.0
	node.offset_bottom = 0.0
