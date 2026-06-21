extends Control
## End-of-run screen: win/lose summary + retry / back to menu.

## Mood FX (pre-wired — guarded by ResourceLoader.exists).
const VICTORY_FX := "res://assets/art/fx/result/fx_victory_rays.png"
const DEFEAT_FX := "res://assets/art/fx/result/fx_defeat_haze.png"
## POV-from-bed backdrops (pre-wired — guarded). Win = sunny morning, clock 10:00;
## loss = dark room, alarm clock 05:00.
const WIN_BG := "res://assets/art/backgrounds/result/result_win_bed.png"
const LOSE_BG := "res://assets/art/backgrounds/result/result_lose_bed.png"
## Alarm-clock sting on a loss (the dream ends — pre-wired, plays if present).
const ALARM_SFX := "res://assets/audio/sfx/alarm_clock.ogg"
const SPARK := ["▁", "▂", "▃", "▄", "▅", "▆", "▇", "█"]

@onready var _background_art: TextureRect = $BackgroundArt
@onready var _clock_label: Label = $Center/VBox/ClockLabel
@onready var _result_label: Label = $Center/VBox/ResultLabel
@onready var _days_label: Label = $Center/VBox/DaysLabel
@onready var _summary_label: Label = $Center/VBox/SummaryLabel
@onready var _coin_label: Label = $Center/VBox/CoinLabel
@onready var _retry_button: Button = $Center/VBox/RetryButton
@onready var _menu_button: Button = $Center/VBox/MenuButton


## The whole run was a dream. Win = you sleep in (Saturday 10:00); loss = the
## alarm jolts you awake into Monday 5:00.
func _ready() -> void:
	ButtonSkin.apply_minimal_many([_retry_button, _menu_button])
	var won: bool = GameManager.last_run_won
	var bg_path := WIN_BG if won else LOSE_BG
	if ResourceLoader.exists(bg_path):
		_background_art.texture = load(bg_path)
		_background_art.visible = true
	_spawn_result_fx(won)
	if won:
		_clock_label.text = "Sobota, 10:00"
		_clock_label.modulate = Color(1.0, 0.9, 0.5)
		_result_label.text = "Budzisz się wyspany. To był tylko sen?"
		_result_label.modulate = Color(0.6, 1.0, 0.6)
		_days_label.text = "Przetrwałeś wszystkie %d dni." % GameManager.last_run_days
	else:
		_clock_label.text = "Poniedziałek, 5:00"
		_clock_label.modulate = Color(1.0, 0.4, 0.4)
		_result_label.text = "Budzik wyrywa cię z koszmaru."
		_result_label.modulate = Color(1.0, 0.55, 0.55)
		_days_label.text = "Sen urwał się w dniu %d." % GameManager.last_run_days
		_play_alarm()
	_summary_label.text = _build_summary(won)
	if GameManager.last_run_coin_awarded:
		_coin_label.text = "+1 złota moneta!  (masz: %d)" % GameManager.meta_state.gold_coins
	else:
		_coin_label.text = ""
	_retry_button.pressed.connect(GameManager.start_new_run)
	_menu_button.pressed.connect(GameManager.return_to_menu)


## Multi-line run recap: cause of death, key totals, HP sparkline and seed.
func _build_summary(won: bool) -> String:
	var s: Dictionary = GameManager.last_run_summary
	if s.is_empty():
		return ""
	var lines: PackedStringArray = []
	if not won and str(s.get("cause", "")) != "":
		lines.append("Przyczyna: %s" % s["cause"])
	if int(s.get("bum_day", 0)) > 0:
		lines.append("Katastrofa: %s (dzień %d)" % [s.get("disaster", "?"), s["bum_day"]])
	lines.append("Poziom: %d   ·   Obrażenia łącznie: %d" % [
		s.get("level", 1), s.get("damage_taken", 0)
	])
	lines.append("Budynki: %d stojących, %d w ruinie" % [
		s.get("buildings_standing", 0), s.get("buildings_ruined", 0)
	])
	var spark := _sparkline(s.get("health_history", []))
	if spark != "":
		lines.append("Zdrowie: %s" % spark)
	lines.append("Seed: %d" % s.get("seed", 0))
	return "\n".join(lines)


## Tiny unicode sparkline of the per-dawn health history.
func _sparkline(history: Array) -> String:
	if history.is_empty():
		return ""
	var hi := 1
	for v in history:
		hi = maxi(hi, int(v))
	var out := ""
	for v in history:
		var idx := clampi(int(round(float(v) / hi * (SPARK.size() - 1))), 0, SPARK.size() - 1)
		out += SPARK[idx]
	return out


func _play_alarm() -> void:
	if not ResourceLoader.exists(ALARM_SFX):
		return
	var player := AudioStreamPlayer.new()
	player.stream = load(ALARM_SFX)
	add_child(player)
	player.play()


## A full-screen mood overlay behind the text: golden rays on a win, cold haze
## on a loss. Skipped if the asset hasn't been generated yet.
func _spawn_result_fx(won: bool) -> void:
	var path := VICTORY_FX if won else DEFEAT_FX
	if not ResourceLoader.exists(path):
		return
	var fx := TextureRect.new()
	fx.texture = load(path)
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.modulate.a = 0.0
	if won:
		var mat := CanvasItemMaterial.new()
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		fx.material = mat
	add_child(fx)
	fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Sit behind the text/buttons (just above the background).
	move_child(fx, 1)
	create_tween().tween_property(fx, "modulate:a", 1.0, 0.8)
