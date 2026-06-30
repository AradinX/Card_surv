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
		"body": "Osada to 6 kafli biomów. Na starcie widzisz tylko jeden — reszta to nieznany teren.\n\nWejście na sąsiedni kafel (lub karta zwiadu, np. „Rozejrzyj się”) odkrywa go. UWAGA: odkrycie aktywuje też jego NOCNE ZAGROŻENIA. Las daje drewno, Góry kamień — te biomy są zawsze.",
	},
	{
		"title": "Noc i wybory",
		"body": "Po „Końcu dnia” losuje się nocne zdarzenie — przeczytaj kartę i kliknij „Dalej”. Niektóre zdarzenia dają WYBÓR (np. nakarmić obcego czy go okraść) — decyzja należy do ciebie, część opcji jest ryzykowna.\n\nBuduj produkcję wcześnie i nie zaniedbuj Ciepła.",
	},
	{
		"title": "BUM — katastrofa",
		"body": "BUM uderza później w Akcie I. Kafle gniją albo marzną, budynki dostają ciężkie obrażenia, a nocą pojawiają się potwory.\n\nPrzed BUM możesz zabezpieczyć maksymalnie dwa rejony przyciskiem na aktualnym kaflu. Kosztuje to energię, sytość, nawodnienie i dużo kamienia, ale zmniejsza obrażenia BUM i zużycie budynków w Akcie I. Po BUM odbuduj się INACZEJ: specjalne budynki Aktu II, naprawy i rozbiórka ruin.",
	},
]

const TUTORIAL_PAGES := [
	{
		"title": "Szybki start",
		"body": "Cel jest prosty: przetrwaj do dnia 50. Każdego dnia wydajesz Energię na karty, akcje biomu, budowę, użycie budynków i ruch.\n\nNajważniejsze paski to Zdrowie, Sytość, Nawodnienie i Ciepło. Jeśli sytość, nawodnienie albo ciepło spadną do 0, zaczniesz realnie tracić zdrowie.",
	},
	{
		"title": "Dzień 1: zapasy",
		"body": "Na starcie zobacz górny pasek: jedzenie, woda, drewno i kamień mają limity typu 3/8.\n\nNajpierw zagraj kartę lub akcję biomu, która daje brakujący zasób. Przykład: Źródło daje wodę, Szukaj materiałów daje kamień, zbieranie drewna daje drewno. Karty zagrywasz przez przeciągnięcie.",
	},
	{
		"title": "Dzień 1: budowa",
		"body": "Wejdź w Budowanie i sprawdź, co możesz postawić na aktualnym biomie. Budynki mają koszt, HP i efekt.\n\nPrzykład: Ognisko pomaga z ciepłem nocą, Studnia daje wodę, Spiżarnia pomaga z jedzeniem. Po zbudowaniu kliknij budynek na kaflu, żeby zobaczyć jego opis i akcje.",
	},
	{
		"title": "Zabezpieczenie rejonu",
		"body": "Gdy na aktualnym kaflu stoi budynek, w prawym dolnym rogu kafla pojawia się przycisk zabezpieczenia rejonu.\n\nTo ciężka decyzja przygotowawcza przed BUM: płacisz energią, sytością, nawodnieniem i kamieniem. W zamian budynki w tym rejonie dostają mniejsze obrażenia BUM i mają tylko część szansy na codzienne lub użytkowe zużycie HP w Akcie I. Limit zabezpieczonych rejonów jest niski, więc wybieraj bazę świadomie.",
	},
	{
		"title": "Akcje budynków",
		"body": "Niektóre budynki działają pasywnie nocą, a część ma akcję za energię.\n\nPrzykład: przy Ognisku możesz dodatkowo się ogrzać, Warsztat może wykonać narzędzia, Studnia pozwala nabrać wodę. Użycie budynku zużywa jego HP, więc nie klikaj wszystkiego bez potrzeby.",
	},
	{
		"title": "Koniec dnia",
		"body": "Przed kliknięciem Koniec dnia najedź na przycisk i sprawdź, ile stracisz nocą. W nocy gra pokaże kartę zdarzenia oraz kartkę z bilansem.\n\nPo nocy zapasy jedzenia i wody mogą zostać automatycznie zużyte, żeby podnieść sytość i nawodnienie.",
	},
	{
		"title": "Dzień 2: decyzja",
		"body": "Drugiego dnia zwykle wybierasz kierunek: budować produkcję, odkrywać kafel albo ratować potrzeby.\n\nOdkrycie nowego biomu daje więcej opcji, ale też dokłada jego nocne zagrożenia. Jeśli masz mało zasobów, czasem lepiej najpierw wzmocnić obecny kafel.",
	},
	{
		"title": "BUM",
		"body": "BUM jest losowany w dalszej części Aktu I. Zanim uderzy, log zacznie pokazywać omeny.\n\nZabezpieczone rejony mają większą szansę dowieźć kluczowe budynki do Aktu II. Po BUM odbudowa jest droższa, więc naprawiaj to, co przetrwało, rozbieraj ruiny i pilnuj ciepła, wody oraz jedzenia.",
	},
]

const PANEL_BASE_SIZE := Vector2(720, 560)
const PANEL_PADDING := Vector2(32, 32)

@onready var _panel: PanelContainer = $Panel
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
	_show_page(0)
	visible = true


func _show_page(index: int) -> void:
	_page = clampi(index, 0, TUTORIAL_PAGES.size() - 1)
	_title.text = TUTORIAL_PAGES[_page]["title"]
	_body.text = TUTORIAL_PAGES[_page]["body"]
	_counter.text = "%d / %d" % [_page + 1, TUTORIAL_PAGES.size()]
	_prev.disabled = _page == 0
	_next.disabled = _page == TUTORIAL_PAGES.size() - 1
