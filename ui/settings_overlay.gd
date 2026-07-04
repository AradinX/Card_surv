class_name SettingsOverlayView
extends ColorRect
## Reusable settings panel (display + audio) for the main menu and the in-run
## pause menu. Backed by the static Settings; each control applies AND saves
## live. Call open() to show it synced to saved values; emits `closed` on OK.

signal closed

const PANEL_BASE_SIZE := Vector2(540, 500)
const PANEL_PADDING := Vector2(32, 32)

@onready var _panel: PanelContainer = $Panel
@onready var _fullscreen_check: CheckButton = $Panel/PanelMargin/VBox/FullscreenRow/FullscreenCheck
@onready var _vsync_check: CheckButton = $Panel/PanelMargin/VBox/VsyncRow/VsyncCheck
@onready var _volume_slider: HSlider = $Panel/PanelMargin/VBox/VolumeRow/VolumeSlider
@onready var _volume_value: Label = $Panel/PanelMargin/VBox/VolumeRow/VolumeValue
@onready var _music_slider: HSlider = $Panel/PanelMargin/VBox/MusicRow/MusicSlider
@onready var _music_value: Label = $Panel/PanelMargin/VBox/MusicRow/MusicValue
@onready var _sfx_slider: HSlider = $Panel/PanelMargin/VBox/SfxRow/SfxSlider
@onready var _sfx_value: Label = $Panel/PanelMargin/VBox/SfxRow/SfxValue
@onready var _language_option: OptionButton = $Panel/PanelMargin/VBox/LanguageRow/LanguageOption
@onready var _close_button: Button = $Panel/PanelMargin/VBox/CloseButton

## OptionButton index -> Settings.language value.
const LANGUAGES := ["", "pl", "en"]


func _ready() -> void:
	visible = false
	ButtonSkin.apply_minimal_many([_close_button])
	_close_button.pressed.connect(_on_close)
	_fullscreen_check.toggled.connect(Settings.set_fullscreen)
	_vsync_check.toggled.connect(Settings.set_vsync)
	_volume_slider.value_changed.connect(_on_volume_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_language_option.add_item("Auto (system)")
	_language_option.add_item("Polski")
	_language_option.add_item("English")
	_language_option.item_selected.connect(_on_language_selected)
	_apply_responsive_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_apply_responsive_layout()


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var available := Vector2(
		maxf(viewport_size.x - PANEL_PADDING.x * 2.0, 1.0),
		maxf(viewport_size.y - PANEL_PADDING.y * 2.0, 1.0)
	)
	var panel_scale := minf(1.0, minf(available.x / PANEL_BASE_SIZE.x, available.y / PANEL_BASE_SIZE.y))
	_panel.scale = Vector2(panel_scale, panel_scale)
	_panel.pivot_offset = _panel.size * 0.5


## Show the overlay with controls synced to the current saved values.
func open() -> void:
	_fullscreen_check.set_pressed_no_signal(Settings.fullscreen)
	_vsync_check.set_pressed_no_signal(Settings.vsync)
	_volume_slider.set_value_no_signal(Settings.master_volume)
	_volume_value.text = "%d%%" % roundi(Settings.master_volume * 100.0)
	_music_slider.set_value_no_signal(Settings.music_volume)
	_music_value.text = "%d%%" % roundi(Settings.music_volume * 100.0)
	_sfx_slider.set_value_no_signal(Settings.sfx_volume)
	_sfx_value.text = "%d%%" % roundi(Settings.sfx_volume * 100.0)
	_language_option.select(maxi(LANGUAGES.find(Settings.language), 0))
	visible = true


func _on_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	_volume_value.text = "%d%%" % roundi(value * 100.0)


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)
	_music_value.text = "%d%%" % roundi(value * 100.0)


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)
	_sfx_value.text = "%d%%" % roundi(value * 100.0)


func _on_language_selected(index: int) -> void:
	Settings.set_language(LANGUAGES[clampi(index, 0, LANGUAGES.size() - 1)])


func _on_close() -> void:
	visible = false
	closed.emit()
