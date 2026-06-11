# Dzień 50 (tytuł roboczy; wcześniej „Karcianka: Przetrwanie")

Karciany roguelike survivalowy 2D (desktop, Godot 4.5), singleplayer.
**Pełny koncept gry jest w [README.md](README.md)** — to on wyznacza kierunek:
run ~60–90 min w dwóch aktach (budowa osady na planszy 6 kafli biomów →
katastrofa **BUM** → przetrwanie do dnia 50), wszystko jest kartą (akcje,
budynki, zdarzenia, potwory, kafle biomów), klasy postaci, meta-progresja
„różnorodność zamiast siły".

Stan obecny: grywalny jest prototyp z etapów 1–2 (wyprawa po mapie węzłów
à la Slay the Spire) — to fundament, na którym powstaje vertical slice
z README (sekcja 10). Szkielet danych pod Dzień 50 jest już założony
(patrz changelog); stare elementy mapy węzłów usuwamy dopiero w momencie,
gdy nowy system planszy faktycznie je zastępuje.

## Stan projektu / Changelog

### Etap 1 — rdzeń pętli (UKOŃCZONY, 2026-06-10)

- Pełna pętla dnia: statystyki (Zdrowie/Sytość/Energia), ręka 4 kart,
  zagrywanie kart akcji z kosztami, talia zdarzeń na koniec dnia.
- 9 kart akcji + 12 kart zdarzeń jako zasoby `.tres`.
- Systemy bez zależności od UI: `RunSystem`, `Deck`, `CardLibrary`.
- Przepływ scen: menu -> run -> wynik (`GameManager` autoload).
- Smoke test headless; po przejściu balansowym naiwny bot wygrywał ~80% runów.

### Etap 2 — mapa wyprawy i deckbuilding (UKOŃCZONY, 2026-06-10)

- Proceduralna mapa: 12–15 węzłów w 4 warstwach + finał, połączenia
  „schodkowe" bez przecięć (`MapGenerator`), test niezmienników na 200 mapach.
- Typy węzłów: Teren (dzień przetrwania), Zdarzenie specjalne (5 spotkań
  fabularnych z opcjami i konsekwencjami), Znalezisko (wybór 1 z 3 kart),
  Odpoczynek (+3 zdrowia LUB usunięcie karty), Finał (dzień z wielką burzą:
  dodatkowe -4 zdrowia łagodzone schronieniem).
- Deckbuilding: talia startowa 10 kart (`data/decks/starter_deck.tres`),
  każdy dzień tasuje świeżą talię dnia z talii gracza, pula nagród = 21 kart
  akcji (12 nowych, m.in. synergie drewna i ekonomia talii: Zwiad/Adrenalina).
- `ExpeditionSystem` (logika wyprawy) nad `RunSystem` (logika jednego dnia);
  wygrana = przetrwanie węzła finałowego, licznik 20 dni usunięty.
- Ekran mapy z panelami interludiów; statystyki przenoszą się między węzłami.
- Znane ograniczenia: brak save/load, balans zgrubny (tuning botem: ~86%
  wygranych naiwnego bota, średnio ~3,3 dnia terenowego na run), spotkania
  losują się bez powtórek dopiero w ramach jednego runu, `MetaState` nadal
  pusty (obóz = etap 3).

### Zwrot projektowy — koncept „Dzień 50" + szkielet danych (2026-06-11)

- Projekt dostał pełny koncept docelowej gry (README.md): plansza 6 kafli
  biomów zamiast mapy węzłów, budynki jako karty z HP, katastrofa BUM
  w połowie runu, potwory w Akcie II, klasy postaci, 4 statystyki
  (HP/Głód/Pragnienie/Ciepło), poziomy w runie, meta-progresja
  „różnorodność zamiast siły".
- Założony szkielet danych pod vertical slice (definicje + przykładowe
  `.tres`, jeszcze NIE wpięte w rozgrywkę): `BiomeData` (3 biomy z
  awersem i skorumpowanym rewersem), `BuildingCardData` (Ognisko, Szałas,
  Studnia), `MonsterCardData` (Zgnilec), `DisasterData` (Plaga),
  `CharacterClassData` (Kucharz), stany runtime `TileState`/`BuildingState`.
- `RunState` rozszerzony o pola szkieletowe (pragnienie, ciepło, woda,
  XP/poziom, klasa, katastrofa, plansza kafli) — stare pola mapy węzłów
  oznaczone jako legacy do usunięcia przy wymianie systemu.
- `load_test` waliduje nowe katalogi danych (typy, sloty 2–4, spójność
  potwór↔katastrofa, talia startowa klasy).
- Stara rozgrywka (etap 2) pozostaje w pełni grywalna.

## Jak uruchomić

1. Otwórz Godot 4.5+ (testowane na 4.5.1).
2. W Project Managerze: **Import** → wskaż `project.godot` w tym katalogu.
3. Uruchom grę klawiszem **F5** (główna scena: `scenes/main_menu.tscn`).

Testy headless (bez otwierania edytora; po dodaniu nowych klas najpierw
`--import`, żeby odświeżyć cache klas globalnych):

```
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/smoke_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/map_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/load_test.gd
```

- `smoke_test` — naiwny bot rozgrywa 50 pełnych wypraw (mapa + dni +
  spotkania + nagrody), sprawdza że każda kończy się wygraną/przegraną.
- `map_test` — niezmienniki struktury 200 wygenerowanych map.
- `load_test` — poprawność typów ręcznie pisanych zasobów `.tres`.

Poza tym testujemy ręcznie przez rozegranie runu w edytorze.

## Architektura

Kluczowa zasada: **dane ≠ logika ≠ UI**. Docelowo dojdzie meta-progresja
(kolekcja, odblokowania, drabinka trudności — README sekcja 8); struktura
ma to umożliwić bez refaktoru.

```
data/cards/actions/   karty akcji (.tres, ActionCardData) — czyste dane
data/cards/events/    karty zdarzeń końca dnia (.tres, EventCardData)
data/decks/           talie (.tres, DeckData) — talia startowa
data/encounters/      spotkania fabularne (.tres) [LEGACY mapy węzłów]
data/biomes/          kafle biomów planszy (.tres, BiomeData) — awers +
                      skorumpowany rewers (po BUM)
data/buildings/       karty budynków (.tres, BuildingCardData)
data/monsters/        karty potworów Aktu II (.tres, MonsterCardData)
data/disasters/       typy katastrofy BUM (.tres, DisasterData)
data/classes/         klasy postaci (.tres, CharacterClassData)
scripts/
  game_manager.gd     autoload "GameManager": przepływ scen
  run_state.gd        RunState (Resource): stan runu — statystyki, zasoby,
                      talia gracza, plansza, pozycja (gotowy pod save/load)
  meta_state.gd       MetaState (Resource): placeholder pod meta-progresję
  resources/          definicje zasobów danych: CardData + pochodne,
                      DeckData, BiomeData, DisasterData, CharacterClassData,
                      TileState/BuildingState (stan runtime planszy),
                      EncounterData, MapData/MapNodeData [LEGACY]
systems/              logika gry, NIEZALEŻNA od scen i UI (RefCounted + sygnały)
  expedition_system.gd  warstwa wyprawy po mapie węzłów [LEGACY — do
                        zastąpienia systemem planszy biomów]
  run_system.gd         pojedynczy dzień przetrwania
  map_generator.gd      proceduralna generacja MapData [LEGACY]
  deck.gd               generyczna talia (dobieranie, odrzut, przetasowanie)
  card_library.gd       ładowanie zasobów .tres z katalogów data/
scenes/               sceny + ich skrypty (tylko UI i podpięcie sygnałów)
  main_menu, map (ekran mapy + panele interludiów), run (dzień), result
ui/                   reużywalne komponenty UI (card_view)
tests/                testy headless (SceneTree, uruchamiane z -s)
```

Elementy `[LEGACY]` obsługują grywalny prototyp etapu 2 — usuwamy je
dopiero wtedy, gdy odpowiedni kawałek vertical slice'a je zastąpi
(historia zostaje w gicie).

### Przepływ

menu -> **mapa** -> węzeł -> (mapa | dzień) -> ... -> finał -> wynik

- `GameManager` (autoload) tworzy `ExpeditionSystem` i ładuje dane
  (talia startowa, pula kart, zdarzenia, spotkania), po czym pokazuje mapę.
- Ekran mapy (`map.gd`) renderuje węzły z `RunState.map`; interludia
  (Znalezisko/Odpoczynek/Zdarzenie) obsługuje lokalnie panelami, a węzły
  Teren/Finał przełączają na scenę dnia przez `GameManager.go_to_day()`.
- Scena dnia (`run.gd`) podpina się pod sygnały `expedition.day_system`
  PRZED startem dnia (`prepare_day()` / `start_prepared_day()` — żaden
  sygnał nie ginie).
- Systemy komunikują się WYŁĄCZNIE sygnałami (`stats_changed`,
  `hand_changed`, `day_ended`, `return_to_map`, `expedition_ended`...).
  Nie znają scen ani węzłów drzewa.

### Pętla dnia (węzeł Teren/Finał)

1. Świeże przetasowanie pełnej talii gracza, ręka 4 kart, energia
   zresetowana (modyfikatory zdarzeń z poprzedniego dnia działają tutaj).
2. Gracz zagrywa karty (koszt energii + ew. zasobów), kończy dzień przyciskiem.
3. Koniec dnia: (Finał: wielka burza -4 zdrowia, łagodzona schronieniem) →
   karta zdarzenia → spadek sytości i automatyczne jedzenie → głodowanie →
   śmierć (przegrana) / Finał przeżyty (wygrana) / powrót na mapę.

Balans (stałe w `run_state.gd`, `run_system.gd`, `expedition_system.gd`):
maks. zdrowie/sytość 10, energia 6/dzień (cap 7 ze Słonecznym porankiem),
sytość -3 dziennie, 1 jedzenie = +2 sytości, głodowanie -2 zdrowia/dzień,
schronienie max 2 (redukuje obrażenia pogodowe o poziom), narzędzia +1 do
zysku jedzenia/drewna, odpoczynek +3 zdrowia, burza finałowa -4. Punkt
odniesienia: naiwny bot ze smoke testu wygrywa ~86% wypraw.

## Dane jako zasoby

Karty, talie, biomy, budynki, potwory, katastrofy i klasy to `.tres`
w `data/` — ZERO logiki w definicjach. Nowa karta/biom/klasa = nowy plik,
bez zmian w kodzie (wyjątek: nowa wartość `special` wymaga obsługi
w systemach).

- `CardData` (bazowa): `id`, `display_name`, `description`
- `ActionCardData`: koszty (`energy_cost`, `food/wood/materials_cost`),
  efekty (`health/hunger/energy_delta`, `food/wood/materials_gain`),
  `special` ("none" | "build_shelter" | "craft_tools" | "explore" |
  "double_explore" | "draw_two")
- `EventCardData`: delty statystyk/zasobów, `next_day_energy_delta`,
  `shelter_protects`
- `DeckData`: lista kart (kopie = wielokrotne wpisy tego samego zasobu)
- `EncounterData`: tytuł, tekst, `options: Array[EncounterOptionData]`;
  opcja: delty + `grants_card_choice`; ujemne delty zasobów są CENĄ opcji
  (niedostępna, gdy gracza nie stać) — zdrowie/sytość stosują się zawsze
  (spotkanie może zabić) [LEGACY]
- `MapData`/`MapNodeData`: struktura mapy węzłów (generowana w runtime,
  jako Resource) [LEGACY]

Szkielet Dnia 50 (jeszcze nie wpięty w rozgrywkę):

- `BiomeData`: `building_slots` (2–4), `gather_cards` (działają tylko gdy
  gracz stoi na kaflu), `extra_event_cards` (zagrożenia biomu) + komplet
  pól `corrupted_*` (rewers kafla po BUM)
- `BuildingCardData`: koszty budowy, `max_hp` (próg 50% = ruina),
  `defense`, pasywne efekty dzienne (GLOBALNE — niezależne od pozycji),
  `special` ("slow_spoilage" | "night_protection" | "unlock_crafting")
- `MonsterCardData`: `disaster_id`, obrażenia dla gracza i budynków,
  `copies_in_deck` (ile kopii trafia do talii zdarzeń po BUM)
- `DisasterData`: pula potworów + dodatkowe karty zdarzeń Aktu II
- `CharacterClassData`: talia startowa + modyfikatory zasad (mnożniki
  jedzenia/psucia, koszty budowania, HP budynków, redukcja obrażeń)
- `TileState`/`BuildingState`: stan runtime planszy (kafel + `is_corrupted`
  + budynki z HP) — częścią `RunState`, gotowe pod save/load

## Punkty rozbudowy (NIE implementować bez decyzji)

- `MetaState` — pusty placeholder; tu trafią kolekcja, odblokowania
  (biomy/katastrofy/klasy) i drabinka trudności (README sekcja 8,
  milestone 2).
- `RunState` jest `Resource` z `@export` (w tym plansza i talia) — gotowy
  pod save/load.
- `ExpeditionSystem`/`MapGenerator` używają wstrzykiwanego RNG — gotowe pod
  seedowane runy; nowy system planszy ma przejąć ten wzorzec.
- Kolejny krok wg README sekcja 10 (vertical slice): system planszy 6 kafli
  + ruch za 1 energię, budynki w slotach, nowe statystyki w pętli dnia,
  XP/poziomy, BUM (Plaga) — każdy kawałek osobną decyzją/krokiem.

## Konwencje

- GDScript ze **statycznym typowaniem** (typy parametrów, zwracane, `:=`).
- Pliki: `snake_case.gd` / `.tscn` / `.tres`; klasy: `PascalCase`
  (`class_name`); stałe: `SCREAMING_SNAKE_CASE`; sygnały i metody: `snake_case`.
- Teksty widoczne dla gracza po polsku; kod, nazwy i komentarze po angielsku.
- Logika w `systems/` nie może importować niczego ze `scenes/` ani `ui/`.
- Po każdym większym kroku: aktualizacja changelogu w tym pliku.
- Małe, częste commity z opisowymi komunikatami (po polsku).
