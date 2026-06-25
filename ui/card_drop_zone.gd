class_name CardDropZone
extends Control

signal card_dropped(payload: Dictionary)

var drop_enabled := false:
	set(value):
		drop_enabled = value
		mouse_filter = Control.MOUSE_FILTER_STOP if drop_enabled else Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return drop_enabled and _is_card_payload(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _is_card_payload(data):
		return
	card_dropped.emit(data as Dictionary)


func _is_card_payload(data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var payload := data as Dictionary
	return payload.get("type", "") == "play_card" and payload.has("source")
