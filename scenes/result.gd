extends Control
## End-of-run screen: win/lose summary + retry / back to menu.

@onready var _result_label: Label = $Center/VBox/ResultLabel
@onready var _days_label: Label = $Center/VBox/DaysLabel
@onready var _retry_button: Button = $Center/VBox/RetryButton
@onready var _menu_button: Button = $Center/VBox/MenuButton


func _ready() -> void:
	if GameManager.last_run_won:
		_result_label.text = "WYGRANA!"
		_result_label.modulate = Color(0.5, 1.0, 0.5)
		_days_label.text = "Przetrwałeś wielką burzę po %d dniach wyprawy." % GameManager.last_run_days
	else:
		_result_label.text = "KONIEC GRY"
		_result_label.modulate = Color(1.0, 0.45, 0.45)
		_days_label.text = "Dzicz pokonała cię w dniu %d." % GameManager.last_run_days
	_retry_button.pressed.connect(GameManager.start_new_run)
	_menu_button.pressed.connect(GameManager.return_to_menu)
