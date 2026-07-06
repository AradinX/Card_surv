extends SceneTree
## Popupy przełączone na Act II: brak błędów skryptu, font "X" 24 po
## re-skinie i jasny/ciemny wariant kolorów tekstu zależnie od aktu.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scenes := {
		"confirm": "res://ui/confirm_popup.tscn",
		"secure": "res://ui/secure_popup.tscn",
		"deck": "res://ui/deck_popup.tscn",
	}
	for key: String in scenes:
		var popup: Node = (load(scenes[key]) as PackedScene).instantiate()
		root.add_child(popup)
		await process_frame
		popup.set_act2()
		assert(popup.get_node("Panel/CloseButton").get_theme_font_size("font_size") == 24)
	var building: BuildingPopupView = (load("res://ui/building_popup_view.tscn") as PackedScene).instantiate()
	root.add_child(building)
	await process_frame
	building.set_content({"act2": true, "hp_text": "HP 3/5"})
	var use_color: Color = building.get_node("Root/UseButton").get_theme_color("font_color")
	assert(use_color.r > 0.8)
	building.set_content({"act2": false, "hp_text": "HP 3/5"})
	use_color = building.get_node("Root/UseButton").get_theme_color("font_color")
	assert(use_color.r < 0.2)
	print("ACT2 POPUP CHECK OK")
	quit(0)
