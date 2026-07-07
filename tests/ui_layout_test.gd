extends SceneTree
## Instantiates the card and biome tile views headlessly. This catches script
## errors in UI-only code paths (text auto-fit, frame selection, tile labels)
## that the logic smoke tests do not touch.

const CARD_VIEW_SCENE := preload("res://ui/card_view.tscn")
const BIOME_TILE_VIEW_SCENE := preload("res://ui/biome_tile_view.tscn")
const TOP_STATUS_BAR_SCENE := preload("res://ui/top_status_bar_view.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	TranslationServer.set_locale("pl")  # assertions below check Polish strings regardless of runner locale
	var root_control := Control.new()
	root_control.size = Vector2(1280, 720)
	root.add_child(root_control)

	var cards := CardLibrary.load_cards_from_dir("res://data/cards/actions")
	cards.append_array(CardLibrary.load_cards_from_dir("res://data/buildings"))
	cards.append_array(CardLibrary.load_cards_from_dir("res://data/cards/events"))
	for resource in CardLibrary.load_resources_from_dir("res://data/monsters"):
		if resource is CardData:
			cards.append(resource)
	assert(not cards.is_empty(), "expected cards to instantiate CardView")

	var hud: TopStatusBarView = TOP_STATUS_BAR_SCENE.instantiate()
	root_control.add_child(hud)
	hud.setup_max_values()
	hud.set_day(1, SurvivalSystem.WIN_DAY, RunState.Season.SUMMER)
	var mock_state := RunState.new()
	hud.set_state(mock_state, 8)
	hud.set_act2()
	await process_frame
	var day_label := hud.find_child("DayLabel", true, false) as Label
	assert(day_label.text.begins_with("Dzień 1/"))
	var season_label := hud.find_child("SeasonLabel", true, false) as Label
	assert(season_label.text == "Lato")
	assert(season_label.tooltip_text.contains("Buff:"))
	assert(season_label.tooltip_text.contains("Debuff:"))
	assert(season_label.mouse_filter == Control.MOUSE_FILTER_STOP)
	var health_value := hud.find_child("HealthValue", true, false) as Label
	assert(health_value.text.contains("/"))
	hud.show_effect_preview({"health": 2, "water": -1})
	var badges_shown := 0
	for badge in _hud_badges(hud):
		if badge.text != "":
			badges_shown += 1
	assert(badges_shown == 2, "expected exactly the health and water badges")
	hud.clear_effect_preview()
	for badge in _hud_badges(hud):
		assert(badge.text == "")
	hud.queue_free()

	for card in cards:
		var view: CardView = CARD_VIEW_SCENE.instantiate()
		root_control.add_child(view)
		view.setup(card, "")
		await process_frame
		assert(view.get_node("NameLabel").get_theme_font_size("font_size") >= 6)
		assert(view.get_node("DescLabel").get_theme_font_size("font_size") >= 5)
		_assert_label_text_visible(view.get_node("NameLabel"))
		_assert_label_text_visible(view.get_node("DescLabel"))
		var effect_label := view.get_node("EffectLabel") as RichTextLabel
		if effect_label.visible:
			assert(
				effect_label.get_content_height() <= effect_label.size.y + 1.0,
				"EffectLabel clips '%s' (content %d px, box %d px)" % [
					effect_label.text,
					effect_label.get_content_height(),
					effect_label.size.y,
				]
			)
		if view.get_node("CostLabel").visible:
			_assert_label_text_visible(view.get_node("CostLabel"))
		view.queue_free()

	var biomes := CardLibrary.load_biomes_from_dir("res://data/biomes")
	assert(not biomes.is_empty(), "expected biomes to instantiate BiomeTileView")
	for biome in biomes:
		var tile := TileState.new()
		tile.biome = biome
		var view: BiomeTileView = BIOME_TILE_VIEW_SCENE.instantiate()
		root_control.add_child(view)
		view.setup(tile, true, "", biome.description)
		await process_frame
		assert(view.get_node("TitlePlate/TitleLabel").get_theme_font_size("font_size") >= 9)
		view.queue_free()

		tile.is_discovered = true
		view = BIOME_TILE_VIEW_SCENE.instantiate()
		root_control.add_child(view)
		view.setup(tile, true, "", biome.description)
		await process_frame
		assert(view.get_node("TitlePlate/TitleLabel").text == biome.display_name)
		view.play_discovery_fx()
		await process_frame
		assert(view._reveal_layers.size() == BiomeTileView.REVEAL_STACK.size())
		view.queue_free()

	print("UI layout test OK: %d cards, %d biomes" % [cards.size(), biomes.size()])
	quit(0)


func _hud_badges(hud: TopStatusBarView) -> Array[Label]:
	var badges: Array[Label] = []
	for cell in hud._cells.values():
		badges.append(cell["badge"] as Label)
	return badges


func _assert_label_text_visible(label: Label) -> void:
	assert(
		label.get_line_count() <= label.get_visible_line_count(),
		"%s clips '%s' (%d lines, %d visible, font %d)" % [
			label.name,
			label.text,
			label.get_line_count(),
			label.get_visible_line_count(),
			label.get_theme_font_size("font_size"),
		]
	)
