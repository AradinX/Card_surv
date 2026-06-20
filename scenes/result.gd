extends Control
## End-of-run screen: win/lose summary + retry / back to menu.

## Mood FX (pre-wired — guarded by ResourceLoader.exists).
const VICTORY_FX := "res://assets/art/fx/result/fx_victory_rays.png"
const DEFEAT_FX := "res://assets/art/fx/result/fx_defeat_haze.png"

@onready var _result_label: Label = $Center/VBox/ResultLabel
@onready var _days_label: Label = $Center/VBox/DaysLabel
@onready var _coin_label: Label = $Center/VBox/CoinLabel
@onready var _retry_button: Button = $Center/VBox/RetryButton
@onready var _menu_button: Button = $Center/VBox/MenuButton


func _ready() -> void:
	ButtonSkin.apply_minimal_many([_retry_button, _menu_button])
	_spawn_result_fx(GameManager.last_run_won)
	if GameManager.last_run_won:
		_result_label.text = "WYGRANA!"
		_result_label.modulate = Color(0.5, 1.0, 0.5)
		_days_label.text = "Przetrwałeś %d dni w dziczy." % GameManager.last_run_days
	else:
		_result_label.text = "KONIEC GRY"
		_result_label.modulate = Color(1.0, 0.45, 0.45)
		_days_label.text = "Dzicz pokonała cię w dniu %d." % GameManager.last_run_days
	if GameManager.last_run_coin_awarded:
		_coin_label.text = "+1 złota moneta!  (masz: %d)" % GameManager.meta_state.gold_coins
	else:
		_coin_label.text = ""
	_retry_button.pressed.connect(GameManager.start_new_run)
	_menu_button.pressed.connect(GameManager.return_to_menu)


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
