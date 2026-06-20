class_name SettingsOverlayView
extends ColorRect
## Reusable settings panel (display + audio) for the main menu and the in-run
## pause menu. Backed by the static Settings; each control applies AND saves
## live. Call open() to show it synced to saved values; emits `closed` on OK.

signal closed

@onready var _fullscreen_check: CheckButton = $Panel/PanelMargin/VBox/FullscreenRow/FullscreenCheck
@onready var _vsync_check: CheckButton = $Panel/PanelMargin/VBox/VsyncRow/VsyncCheck
@onready var _volume_slider: HSlider = $Panel/PanelMargin/VBox/VolumeRow/VolumeSlider
@onready var _volume_value: Label = $Panel/PanelMargin/VBox/VolumeRow/VolumeValue
@onready var _close_button: Button = $Panel/PanelMargin/VBox/CloseButton


func _ready() -> void:
	visible = false
	ButtonSkin.apply_minimal_many([_close_button])
	_close_button.pressed.connect(_on_close)
	_fullscreen_check.toggled.connect(Settings.set_fullscreen)
	_vsync_check.toggled.connect(Settings.set_vsync)
	_volume_slider.value_changed.connect(_on_volume_changed)


## Show the overlay with controls synced to the current saved values.
func open() -> void:
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	_vsync_check.set_pressed_no_signal(Settings.vsync)
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_volume_value.text = "%d%%" % roundi(Settings.master_volume * 100.0)
	visible = true


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_volume_value.text = "%d%%" % roundi(value * 100.0)


func _on_close() -> void:
	visible = false
	closed.emit()
