class_name HelpOverlayView
extends ColorRect
## Paged "how to play" overlay (used by the main menu, auto-shown on first launch).
## Pure text — pages defined here; call open() to show from page 1.

const PAGES := [
	{
		"title": "Dzień 50 — cel",
		"body": "Cała rozgrywka to sen. Przetrwaj do dnia 50, a obudzisz się wyspany.\n\nPilnuj 4 statystyk: Zdrowie, Sytość, Nawodnienie i Ciepło. Gdy Zdrowie spadnie do zera — budzik wyrywa cię z koszmaru (przegrana).",
	},
	{
		"title": "Dzień i karty",
		"body": "Każdego dnia masz pulę Energii. Za nią: zagrywasz karty z ręki, używasz akcji biomu (każda 1×/dzień), stawiasz budynki i przemieszczasz się między kaflami (1 energia).\n\nNa dole widzisz PROGNOZĘ NOCY — ile stracisz i ile masz zapasów. Gdy skończysz, kliknij „Koniec dnia”.",
	},
	{
		"title": "Plansza i mgła",
		"body": "Osada to 6 kafli biomów. Na starcie widzisz tylko jeden — reszta to nieznany teren.\n\nWejście na sąsiedni kafel (lub karta zwiadu, np. „Rozejrzyj się”) odkrywa go. UWAGA: odkrycie aktywuje też jego NOCNE ZAGROŻENIA. Las daje drewno, Góry materiały — te biomy są zawsze.",
	},
	{
		"title": "Noc i wybory",
		"body": "Po „Końcu dnia” losuje się nocne zdarzenie — przeczytaj kartę i kliknij „Dalej”. Niektóre zdarzenia dają WYBÓR (np. nakarmić obcego czy go okraść) — decyzja należy do ciebie, część opcji jest ryzykowna.\n\nBuduj produkcję wcześnie i nie zaniedbuj Ciepła.",
	},
	{
		"title": "BUM — katastrofa",
		"body": "Około połowy snu uderza katastrofa (Plaga lub Zaćmienie). Kafle gniją albo marzną, budynki padają w ruinę, a nocą pojawiają się potwory.\n\nPlaga = wojna o jedzenie, Zaćmienie = wojna o ciepło. Odbuduj się INACZEJ: po BUM dostępne są specjalne budynki Aktu II (Bastion, Lazaret). Powodzenia!",
	},
]

@onready var _title: Label = $Panel/PanelMargin/VBox/Title
@onready var _body: Label = $Panel/PanelMargin/VBox/Body
@onready var _counter: Label = $Panel/PanelMargin/VBox/Nav/Counter
@onready var _prev: Button = $Panel/PanelMargin/VBox/Nav/PrevButton
@onready var _next: Button = $Panel/PanelMargin/VBox/Nav/NextButton
@onready var _close: Button = $Panel/PanelMargin/VBox/CloseButton

var _page := 0


func _ready() -> void:
	visible = false
	ButtonSkin.apply_minimal_many([_prev, _next, _close])
	_prev.pressed.connect(func() -> void: _show_page(_page - 1))
	_next.pressed.connect(func() -> void: _show_page(_page + 1))
	_close.pressed.connect(func() -> void: visible = false)


func open() -> void:
	_show_page(0)
	visible = true


func _show_page(index: int) -> void:
	_page = clampi(index, 0, PAGES.size() - 1)
	_title.text = PAGES[_page]["title"]
	_body.text = PAGES[_page]["body"]
	_counter.text = "%d / %d" % [_page + 1, PAGES.size()]
	_prev.disabled = _page == 0
	_next.disabled = _page == PAGES.size() - 1
