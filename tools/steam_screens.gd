extends Node
## One-off Steam screenshot tour: drives a REAL run (GameManager + SurvivalSystem
## + run scene UI) in a 1920x1080 window and saves PNGs to docs/steam_screens/<lang>/.
## The player's run/meta saves are backed up before the tour and restored on exit.
##
## Run (window will appear for ~1-2 minutes):
##   Godot.exe --path . tools/steam_screens.tscn            (Polish)
##   Godot.exe --path . tools/steam_screens.tscn -- lang=en (English)

const SHOT_SIZE := Vector2i(1920, 1080)
const SAVE_PATHS := ["user://run_save.json", "user://meta_state.json"]

var _lang := "pl"
var _backups := {}
var _run_dead := false
var _monster_seen := false
var _levelup_shot_done := false
var _last_night_card: CardData = null


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("lang="):
			_lang = arg.trim_prefix("lang=")
	call_deferred("_start")


func _start() -> void:
	# Survive scene changes: hand the current_scene slot to a placeholder.
	# Cache tree/root first — get_tree() is null while self is detached.
	var tree := get_tree()
	var root := tree.root
	var placeholder := Node.new()
	root.add_child(placeholder)
	root.remove_child(self)
	root.add_child(self)
	tree.current_scene = placeholder
	_run_tour()


func _run_tour() -> void:
	AudioServer.set_bus_mute(0, true)
	TranslationServer.set_locale(_lang)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(SHOT_SIZE)
	DisplayServer.window_set_position(Vector2i(0, 0))
	_backup_saves()
	var gm: Node = get_tree().root.get_node_or_null("GameManager")
	if gm == null:
		push_error("GameManager autoload missing")
		_finish(1)
		return
	gm.meta_state.seen_tutorial = true

	# 1) Main menu.
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	await _sleep(1.2)
	await _capture("01_menu")

	# 2) Start a real run (easiest class keeps the tour alive).
	gm.selected_class_id = "herbalist"
	gm.start_new_run()
	await _sleep(1.5)
	var survival: SurvivalSystem = gm.survival
	if survival == null:
		push_error("no survival system after start_new_run")
		_finish(1)
		return
	survival.run_ended.connect(func(_won: bool, _days: int) -> void: _run_dead = true)
	survival.night_card_drawn.connect(func(card: CardData) -> void:
		_last_night_card = card
		if card is MonsterCardData:
			_monster_seen = true)

	# 3) Play Act I days; capture the board + a night card mid-run.
	for day_i in range(7):
		if _run_dead:
			break
		await _play_day_actions(survival)
		if day_i == 5:
			await _capture("02_act1_board")
		var want_night := day_i == 5
		await _end_day_and_resolve(survival, "03_night_event" if want_night else "")

	# 4) Force BUM on the next dawn, then shoot the corrupted board.
	if not _run_dead:
		survival.state.bum_day = survival.state.day + 1
		await _play_day_actions(survival)
		await _end_day_and_resolve(survival, "")
		await _sleep(5.0)  # BUM FX sequence
		await _capture("04_act2_board")

	# 5) Keep playing Act II until a monster night shows up (max 10 nights).
	for _i in range(10):
		if _run_dead or _monster_seen:
			break
		await _play_day_actions(survival)
		await _end_day_and_resolve(survival, "", true)
	if not _monster_seen and not _run_dead:
		# Fallback: whatever the last Act II night is, still a valid shot.
		await _play_day_actions(survival)
		await _end_day_and_resolve(survival, "05_act2_night")

	_finish(0)


## Cheat the stats up (screenshots, not a challenge run), then do a simple
## bot day: gather, build once, play safe cards, move to an undiscovered tile.
func _play_day_actions(survival: SurvivalSystem) -> void:
	var st: RunState = survival.state
	st.health = st.max_health
	st.hunger = 8
	st.thirst = 8
	st.warmth = 8
	st.food = mini(st.food + 3, 8)
	st.water = mini(st.water + 3, 8)
	st.wood = mini(st.wood + 4, 12)
	st.materials = mini(st.materials + 3, 12)
	await _clear_levelup(survival)
	for card in survival.available_gather_actions():
		if survival.can_play_gather(card) == "":
			survival.play_gather(card)
			await _sleep(0.15)
	for building in survival.available_buildings():
		if survival.can_build(building) == "":
			survival.build(building)
			await _sleep(0.3)
			break
	for _safety in range(8):
		var played := false
		for i in range(survival.hand.size()):
			var card: CardData = survival.hand[i]
			var action := card as ActionCardData
			if action != null and action.health_delta < 0:
				continue
			if survival.can_play(card) == "":
				survival.play_card(i)
				played = true
				break
		if not played:
			break
		await _sleep(0.15)
	for tile_index in range(st.board.size()):
		if not st.board[tile_index].is_discovered and survival.can_move(tile_index) == "":
			survival.move_to(tile_index)
			await _sleep(0.4)
			break


## End the day, wait for the night popup reveal, optionally screenshot it,
## then click through the popup buttons like a player would.
func _end_day_and_resolve(
	survival: SurvivalSystem, shot_name: String, shoot_if_monster := false
) -> void:
	if _run_dead:
		return
	survival.end_day()
	await _sleep(3.2)  # back + flip + reveal FX (button enables after tween)
	if shot_name != "":
		await _capture(shot_name)
	elif shoot_if_monster and _last_night_card is MonsterCardData:
		await _capture("05_monster_night")
	var overlay := _find_node(get_tree().root, "NightEventOverlay")
	var continue_button := _find_button(overlay, "ContinueButton")
	var choice := _first_visible_choice(overlay)
	if choice != null:
		await _wait_enabled(choice)
		choice.pressed.emit()
		await _sleep(1.0)
		continue_button = _find_button(overlay, "ContinueButton")
	if continue_button != null:
		await _wait_enabled(continue_button)
		continue_button.pressed.emit()
	else:
		survival.resolve_night(0)
	await _sleep(0.8)
	await _clear_levelup(survival)


## The level-up overlay blocks the board; shoot it once, then take +1 max HP.
func _clear_levelup(survival: SurvivalSystem) -> void:
	for _i in range(6):
		var overlay := _find_node(get_tree().root, "LevelUpOverlay") as CanvasItem
		if overlay == null or not overlay.visible:
			return
		if not _levelup_shot_done:
			_levelup_shot_done = true
			await _capture("06_level_up")
		var health_button := _find_button(overlay, "HealthButton")
		if health_button != null and health_button.visible:
			health_button.pressed.emit()
		else:
			survival.claim_max_health()
		await _sleep(0.6)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var dir := "res://docs/steam_screens/%s" % _lang
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var path := "%s/%s.png" % [dir, name]
	img.save_png(path)
	print("SHOT %s (%dx%d)" % [path, img.get_width(), img.get_height()])


func _sleep(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_enabled(button: Button) -> void:
	for _i in range(30):
		if not button.disabled:
			return
		await _sleep(0.2)


func _find_node(from: Node, target_name: String) -> Node:
	if from == null:
		return null
	if from.name == target_name:
		return from
	for child in from.get_children():
		var found := _find_node(child, target_name)
		if found != null:
			return found
	return null


func _find_button(from: Node, target_name: String) -> Button:
	var node := _find_node(from, target_name)
	var button := node as Button
	if button != null and button.visible:
		return button
	return null


func _first_visible_choice(overlay: Node) -> Button:
	for i in range(3):
		var button := _find_button(overlay, "ChoiceButton%d" % i)
		if button != null:
			return button
	return null


func _backup_saves() -> void:
	for path in SAVE_PATHS:
		if FileAccess.file_exists(path):
			_backups[path] = FileAccess.get_file_as_bytes(path)


func _finish(code: int) -> void:
	for path in SAVE_PATHS:
		if _backups.has(path):
			var file := FileAccess.open(path, FileAccess.WRITE)
			if file != null:
				file.store_buffer(_backups[path])
		elif FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Steam screenshot tour done (lang=%s), saves restored." % _lang)
	get_tree().quit(code)
