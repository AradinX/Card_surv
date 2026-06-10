# Karcianka: Przetrwanie

Singleplayerowa karcianka survivalowa 2D (desktop) w Godot 4.5. Gracz jest
ocalałym w dziczy — gra toczy się w turach (dniach), a celem prototypu jest
przetrwanie 20 dni. Przegrana: Zdrowie spada do 0.

## Stan projektu / Changelog

### Etap 1 — rdzeń pętli (UKOŃCZONY, 2026-06-10)

- Pełna pętla: cykl dnia, statystyki (Zdrowie/Sytość/Energia), ręka 4 kart,
  zagrywanie kart akcji z kosztami, talia zdarzeń na koniec dnia,
  wygrana (dzień 20) / przegrana (0 zdrowia).
- 9 kart akcji + 12 kart zdarzeń jako zasoby `.tres`.
- Systemy bez zależności od UI: `RunSystem`, `Deck`, `CardLibrary`.
- Przepływ scen: menu -> run -> wynik (`GameManager` autoload).
- Smoke test headless (`tests/smoke_test.gd`); po przejściu balansowym
  naiwny bot wygrywa ~80% runów.
- Znane ograniczenia: brak save/load, brak meta-progresji (placeholder),
  skład talii startowej zaszyty w stałej `ACTION_CARD_COPIES`, balans
  zgrubny (tuning tylko botem, nie ręcznym testowaniem).

### Etap 2 — mapa wyprawy i deckbuilding (W TRAKCIE)

Przekształcenie liniowego cyklu dni w wyprawę po proceduralnej mapie węzłów
(inspiracja Slay the Spire; wrogiem jest środowisko, nie walka):

- Mapa: 10–15 węzłów w 3–4 warstwach z rozgałęzieniami, gracz wybiera
  ścieżkę w górę; generator jako `systems/map_generator.gd`, dane węzłów
  niezależne od UI; ekran mapy (węzły-przyciski, połączenia, pozycja gracza).
- Typy węzłów: Teren (dzień przetrwania = obecna pętla), Zdarzenie specjalne
  (wybór fabularny z konsekwencjami), Znalezisko (wybór 1 z 3 kart do talii),
  Odpoczynek (regeneracja LUB usunięcie karty), Finał (trudne wyzwanie).
- Deckbuilding w runie: startowa talia ~10 kart, dobieranie/odrzut/
  przetasowanie z talii gracza, nagrody kartowe, 10–15 nowych kart akcji
  (synergie, np. drewno -> budowanie).
- Integracja: `RunState` + talia gracza, pozycja i stan mapy; przepływ
  menu -> mapa -> węzeł -> mapa -> ... -> finał -> wynik; statystyki
  przenoszą się między węzłami.
- Poza zakresem etapu 2: meta-progresja/obóz (etap 3), `MetaState` zostaje
  placeholderem.

## Jak uruchomić

1. Otwórz Godot 4.5+ (testowane na 4.5.1).
2. W Project Managerze: **Import** → wskaż `project.godot` w tym katalogu.
3. Uruchom grę klawiszem **F5** (główna scena: `scenes/main_menu.tscn`).

Walidacja z konsoli (bez otwierania edytora):

```
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
Godot_v4.5.1-stable_win64_console.exe --headless --path . --quit
```

Smoke test logiki (bez UI; rozgrywa 50 runów naiwnym botem i sprawdza,
że każdy kończy się wygraną albo przegraną):

```
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/smoke_test.gd
```

Poza tym testujemy ręcznie przez rozegranie runu w edytorze.

## Architektura

Kluczowa zasada: **dane ≠ logika ≠ UI**. Gra docelowo będzie roguelikiem
z meta-progresją (obóz między runami, permanentne ulepszenia, deckbuilding) —
obecna struktura ma to umożliwić bez refaktoru.

```
data/cards/actions/   karty akcji (.tres, ActionCardData) — czyste dane
data/cards/events/    karty zdarzeń (.tres, EventCardData) — czyste dane
scripts/
  game_manager.gd     autoload "GameManager": przepływ menu -> run -> wynik
  run_state.gd        RunState (Resource): stan pojedynczego runu
  meta_state.gd       MetaState (Resource): placeholder pod meta-progresję
  resources/          definicje zasobów danych (CardData i pochodne)
systems/              logika gry, NIEZALEŻNA od scen i UI (RefCounted + sygnały)
  run_system.gd       rdzeń pętli: cykl dnia, zagrywanie kart, zdarzenia, win/lose
  deck.gd             generyczna talia (dobieranie, odrzut, przetasowanie)
  card_library.gd     ładowanie kart .tres z katalogów data/
scenes/               sceny + ich skrypty (tylko UI i podpięcie sygnałów)
ui/                   reużywalne komponenty UI (card_view)
```

### Przepływ

- `GameManager` (autoload) tworzy `RunSystem`, zmienia scenę na `run.tscn`.
- `run.gd` w `_ready()` podpina się pod sygnały `RunSystem`, po czym woła
  `GameManager.begin_run()` — dzięki temu żaden sygnał nie ginie przed
  podpięciem UI.
- `RunSystem` komunikuje się WYŁĄCZNIE sygnałami (`stats_changed`,
  `hand_changed`, `log_message`, `run_ended`...). Nie zna scen ani węzłów.
- Koniec runu: `RunSystem.run_ended` → `GameManager.end_run` → `result.tscn`.

### Pętla dnia

1. Start dnia: dobierz rękę (4 karty) z talii akcji, energia zresetowana.
2. Gracz zagrywa karty (koszt energii + ew. zasobów), w dowolnym momencie
   kończy dzień.
3. Koniec dnia: karta zdarzenia (pogoda/zagrożenie/znalezisko) → spadek głodu
   i automatyczne jedzenie → obrażenia z wygłodzenia → sprawdzenie
   śmierci / wygranej (dzień 20) → następny dzień.

Balans (stałe w `run_state.gd` i `run_system.gd`): maks. zdrowie/sytość 10,
energia 6/dzień, sytość spada o 3 dziennie, 1 jedzenie = +2 sytości,
wygłodzenie = -2 zdrowia/dzień. Schronienie (max 2) redukuje obrażenia od
zdarzeń z `shelter_protects = true` o swój poziom (najcięższa pogoda zawsze
zadaje min. 1). Narzędzia: +1 do zysku jedzenia i drewna z kart. Punkt
odniesienia: naiwny bot ze smoke testu wygrywa ~80% runów.

## Karty jako dane

Karty to zasoby `.tres` w `data/cards/` — ZERO logiki w definicjach kart.
Nowa karta = nowy plik `.tres`, bez zmian w kodzie (wyjątek: nowe `special`
wymaga obsługi w `run_system.gd`).

- `CardData` (bazowa): `id`, `display_name`, `description`
- `ActionCardData`: koszty (`energy_cost`, `food/wood/materials_cost`),
  efekty (`health/hunger/energy_delta`, `food/wood/materials_gain`),
  `special` ("none" | "build_shelter" | "craft_tools" | "explore")
- `EventCardData`: delty statystyk i zasobów, `next_day_energy_delta`,
  `shelter_protects`

Skład talii startowej: 2 kopie każdej karty akcji (stała
`ACTION_CARD_COPIES` w `run_system.gd`) — przy wdrażaniu deckbuildingu
zastąpić zasobem `DeckData`.

## Punkty rozbudowy (NIE implementować bez decyzji)

- `MetaState` — pusty placeholder; tu trafią permanentne ulepszenia i stan
  obozu między runami.
- `RunState` jest `Resource` z `@export` — gotowy pod save/load.
- `RunSystem` ma własny `RandomNumberGenerator` — gotowy pod seedowane runy.
- Deckbuilding: zamienić stałą kompozycję talii na zasób `DeckData`.

## Konwencje

- GDScript ze **statycznym typowaniem** (typy parametrów, zwracane, `:=`).
- Pliki: `snake_case.gd` / `.tscn` / `.tres`; klasy: `PascalCase`
  (`class_name`); stałe: `SCREAMING_SNAKE_CASE`; sygnały i metody: `snake_case`.
- Teksty widoczne dla gracza po polsku; kod, nazwy i komentarze po angielsku.
- Logika w `systems/` nie może importować niczego ze `scenes/` ani `ui/`.
- Małe, częste commity z opisowymi komunikatami (po polsku).
