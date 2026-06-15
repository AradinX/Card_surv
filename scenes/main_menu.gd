extends Control
## Main menu: start a new run or quit.

@onready var _start_button: Button = $Center/VBox/StartButton
@onready var _quit_button: Button = $Center/VBox/QuitButton


func _ready() -> void:
	ButtonSkin.apply_many([_start_button, _quit_button])
	_start_button.pressed.connect(GameManager.start_new_run)
	_quit_button.pressed.connect(get_tree().quit)
