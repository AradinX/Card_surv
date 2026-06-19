extends Control
## End-of-run screen: win/lose summary + retry / back to menu.

@onready var _result_label: Label = $Center/VBox/ResultLabel
@onready var _days_label: Label = $Center/VBox/DaysLabel
@onready var _coin_label: Label = $Center/VBox/CoinLabel
@onready var _retry_button: Button = $Center/VBox/RetryButton
@onready var _menu_button: Button = $Center/VBox/MenuButton


func _ready() -> void:
	ButtonSkin.apply_many([_retry_button, _menu_button])
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
