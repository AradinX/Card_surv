class_name CreditsOverlayView
extends ColorRect
## Credits + license summary overlay (used by the main menu). Pure text; call
## open() to show. Mirrors the help/settings overlay pattern.

const CREDITS := """DZIEŃ 50
Karciany roguelike survivalowy — wersja demo


———  ZESPÓŁ  ———

Projekt, kod i game design
    AradinX

Silnik gry
    Godot Engine 4.5  (licencja MIT)


———  GRAFIKA  ———

Cała grafika wygenerowana przez AI z autorskich promptów
(oryginalna dla tej gry — brak stocków i cudzych prac):
    •  GPT Image  (OpenAI)


———  MUZYKA I DŹWIĘK  ———

Cała ścieżka muzyczna i efekty dźwiękowe wygenerowane
w Suno (plan Pro) z autorskich promptów.


———  WSPARCIE  ———

Asystent kodu i treści: Claude (Anthropic)


———  LICENCJE  ———

Grafika oraz audio to output wygenerowany przez autora
z własnych promptów; wykorzystanie zgodne z regulaminami
dostawców (OpenAI / Suno).
Pełny wykaz: assets/art/LICENSES.txt oraz
assets/audio/LICENSES.txt

Godot Engine — licencja MIT,
© Juan Linietsky, Ariel Manzur i kontrybutorzy.


———  PODZIĘKOWANIA  ———

Dla wszystkich playtesterów dema — dziękujemy za grę!"""

const PANEL_BASE_SIZE := Vector2(760, 600)
const PANEL_PADDING := Vector2(32, 32)

@onready var _panel: PanelContainer = $Panel
@onready var _body: Label = $Panel/PanelMargin/VBox/Scroll/Body
@onready var _close: Button = $Panel/PanelMargin/VBox/CloseButton


func _ready() -> void:
	visible = false
	ButtonSkin.apply_minimal(_close)
	_body.text = CREDITS
	_close.pressed.connect(func() -> void: visible = false)
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


func open() -> void:
	visible = true
	_apply_responsive_layout()
