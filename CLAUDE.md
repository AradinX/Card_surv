# Dzień 50 (tytuł roboczy; wcześniej „Karcianka: Przetrwanie")

Karciany roguelike survivalowy 2D (desktop, Godot 4.5), singleplayer.
**Pełny koncept gry jest w [README.md](README.md)** — to on wyznacza kierunek:
run ~60–90 min w dwóch aktach (budowa osady na planszy 6 kafli biomów →
katastrofa **BUM** → przetrwanie do dnia 50), wszystko jest kartą (akcje,
budynki, zdarzenia, potwory, kafle biomów), klasy postaci, meta-progresja
„różnorodność zamiast siły".

Stan obecny: gra toczy się na planszy 6 kafli biomów (kroki 1–2 vertical
slice'a z README sekcja 10) — mapa węzłów z etapu 2 została zastąpiona
i usunięta (historia w gicie). Run = przetrwaj do dnia 15 (placeholder do
czasu BUM); 4 statystyki, budynki jako karty, akcje biomu, ruch za energię,
XP i poziomy z nagrodami 1 z 3 (deckbuilding w runie).

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

### Vertical slice krok 1 — plansza biomów (UKOŃCZONY, 2026-06-12)

- `SurvivalSystem` + `BoardGenerator` zastąpiły `ExpeditionSystem`/
  `RunSystem`/`MapGenerator`; mapa węzłów, spotkania (`EncounterData`)
  i scena mapy USUNIĘTE z repo (zostały w historii gita).
- Plansza 3×2 z 6 kafli biomów (pula 3: Las/Łąki/Góry, każdy min. raz),
  ruch na sąsiedni kafel za 1 energię, start na losowym kaflu.
- 4 statystyki przetrwania (Zdrowie/Sytość/Nawodnienie/Ciepło) + woda jako
  zasób; energia 10/dzień; wygrana = przetrwanie do dnia 15 (placeholder
  do czasu BUM).
- Budynki jako karty w talii: zbudowanie zdejmuje kartę z talii na stół
  (slot kafla, HP, globalne pasywy dzienne); talia startowa Kucharza =
  9 akcji + Ognisko/Studnia/Szałas; modyfikatory klasy wpięte (jedzenie
  ×1,5, budowanie +1 energii, bonusy HP/zniżki gotowe pod inne klasy).
- Akcje biomu: karty zbierania danego kafla dostępne tylko na nim,
  każda 1×/dzień (nowa karta Źródło = woda w Lesie/Górach); karty
  zagrożeń biomów planszy trafiają do wspólnej talii zdarzeń runu.
- Zdarzenia chronione schronieniem działają z budynkiem night_protection
  (Szałas, -2 obrażeń/utraty ciepła); Zimna noc/Ulewa biją w ciepło.
- Wycofane: build_shelter/quick_build (zastąpione budynkami),
  `shelter_level`, licznik węzłów; Opatrz rany +1→+2 zdrowia (balans).
- Smoke test: bot na planszy (zachłannie karty + akcje biomu + 2 ruchy
  dziennie), 43/50 wygranych (~86%); board_test zastąpił map_test.
- Znane ograniczenia: brak nagród kartowych/XP (talia statyczna w runie),
  brak pór roku, BUM/potwory/naprawy jeszcze nie wpięte, balans zgrubny.

### Vertical slice krok 2 — XP i poziomy w runie (UKOŃCZONY, 2026-06-12)

- XP za działania: zagranie karty/akcji biomu +1, budowa budynku +3;
  próg awansu rośnie (8 + 4×(poziom−1)); awanse kolejkują się
  w `pending_rewards` (zapisywane w `RunState`).
- Nagroda awansu = wybór 1 z 3: +1 maks. energii / +1 maks. zdrowia
  (+2 leczenia) / nowa karta do talii (wybór 1 z 3 z puli 20 kart akcji)
  — deckbuilding wrócił do runu. Uproszczenie względem README:
  zamiast „ulepszenia karty" (system ulepszeń jeszcze nie istnieje)
  nagrodą jest karta z puli.
- `max_health`/`max_energy` są teraz polami `RunState` (rosną w runie);
  stałe `MAX_*` to wartości startowe.
- UI: panel awansu (overlay blokujący klik, kolejka nagród), etykieta
  poziomu i XP w pasku górnym, paski zdrowia/energii o dynamicznym maks.
- Smoke bot wybiera nagrody losowo: 46/50 wygranych (~92%, śr. poziom
  6,4) — lekko ponad bazowe ~86%, bo nagrody to czysta korzyść; trudność
  doważy BUM.

## Jak uruchomić

1. Otwórz Godot 4.5+ (testowane na 4.5.1).
2. W Project Managerze: **Import** → wskaż `project.godot` w tym katalogu.
3. Uruchom grę klawiszem **F5** (główna scena: `scenes/main_menu.tscn`).

Testy headless (bez otwierania edytora; po dodaniu nowych klas najpierw
`--import`, żeby odświeżyć cache klas globalnych):

```
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/smoke_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/board_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/load_test.gd
```

- `smoke_test` — naiwny bot rozgrywa 50 pełnych runów na planszy (karty
  z ręki + akcje biomu + wędrówka), sprawdza że każdy kończy się
  wygraną/przegraną.
- `board_test` — niezmienniki 200 wygenerowanych plansz + sąsiedztwo kafli.
- `load_test` — poprawność typów ręcznie pisanych zasobów `.tres`.

Poza tym testujemy ręcznie przez rozegranie runu w edytorze.

## Architektura

Kluczowa zasada: **dane ≠ logika ≠ UI**. Docelowo dojdzie meta-progresja
(kolekcja, odblokowania, drabinka trudności — README sekcja 8); struktura
ma to umożliwić bez refaktoru.

```
data/cards/actions/   karty akcji (.tres, ActionCardData) — czyste dane
data/cards/events/    karty zdarzeń końca dnia (.tres, EventCardData)
data/decks/           talie (.tres, DeckData) — talia startowa Kucharza
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
  resources/          definicje zasobów danych: CardData + pochodne
                      (Action/Building/Monster/Event), DeckData, BiomeData,
                      DisasterData, CharacterClassData oraz stan runtime
                      planszy: TileState/BuildingState
systems/              logika gry, NIEZALEŻNA od scen i UI (RefCounted + sygnały)
  survival_system.gd    cały run na planszy: dni, statystyki, ruch,
                        budynki, akcje biomu, zdarzenia, XP/awanse,
                        warunki końca
  board_generator.gd    generacja planszy 6 kafli (3×2) + sąsiedztwo
  deck.gd               generyczna talia (dobieranie, odrzut, przetasowanie)
  card_library.gd       ładowanie zasobów .tres z katalogów data/
scenes/               sceny + ich skrypty (tylko UI i podpięcie sygnałów)
  main_menu, run (plansza + ręka + okolica + log), result
ui/                   reużywalne komponenty UI (card_view — akcje i budynki)
tests/                testy headless (SceneTree, uruchamiane z -s)
```

### Przepływ

menu -> **run (cała wyprawa na jednym ekranie)** -> wynik

- `GameManager` (autoload) tworzy `SurvivalSystem` i ładuje dane (klasa
  Kucharz z talią startową, pula biomów, karty zdarzeń), po czym pokazuje
  scenę runu.
- Scena runu (`run.gd`) podpina się pod sygnały `survival` PRZED startem
  (`start()` buduje stan, `begin()` odpala dzień 1 — żaden sygnał nie
  ginie); kolejne dni startują automatycznie po zakończeniu poprzedniego.
- Systemy komunikują się WYŁĄCZNIE sygnałami (`stats_changed`,
  `hand_changed`, `board_changed`, `gather_actions_changed`,
  `log_message`, `run_ended`...). Nie znają scen ani węzłów drzewa.

### Pętla dnia (na planszy)

1. Świt: świeże przetasowanie pełnej talii gracza (akcje + niezbudowane
   budynki), ręka 4 kart, energia 10 (modyfikatory zdarzeń z poprzedniego
   dnia działają tutaj), licznik akcji biomu wyzerowany.
2. Gracz zagrywa karty z ręki (akcje natychmiastowe; budynek = zdjęcie
   karty z talii na slot bieżącego kafla), korzysta z akcji zbierania
   bieżącego biomu (każda 1×/dzień) i przemieszcza się na sąsiednie kafle
   (1 energia); kończy dzień przyciskiem.
3. Noc: pasywy budynków (globalne) → karta zdarzenia (Szałas łagodzi
   chronione) → sytość/nawodnienie spadają i automatyczne jedzenie/picie →
   głód/odwodnienie/zamarzanie biją w zdrowie → śmierć (przegrana) /
   dzień 15 przeżyty (wygrana) / kolejny dzień.

Balans (stałe w `run_state.gd`, `survival_system.gd`): startowe maks.
statystyki 10 (zdrowie/energia rosną nagrodami awansu), energia 10/dzień
(cap maks.+1 ze Słonecznym porankiem), ruch 1 energii, sytość i nawodnienie
-2 dziennie, ciepło -1 dziennie, 1 jedzenie = +2 sytości (Kucharz: +3),
1 woda = +2 nawodnienia, głód/odwodnienie/mróz -2 zdrowia dziennie, Szałas
-2 obrażeń z chronionych zdarzeń, narzędzia +1 do zysku jedzenia/drewna,
XP: +1 karta/akcja biomu, +3 budynek, próg 8 + 4×(poziom−1), wygrana
w dniu 15. Punkt odniesienia: naiwny bot ze smoke testu wygrywa ~92%
runów (46/50, śr. poziom 6,4).

## Dane jako zasoby

Karty, talie, biomy, budynki, potwory, katastrofy i klasy to `.tres`
w `data/` — ZERO logiki w definicjach. Nowa karta/biom/klasa = nowy plik,
bez zmian w kodzie (wyjątek: nowa wartość `special` wymaga obsługi
w systemach).

- `CardData` (bazowa): `id`, `display_name`, `description`
- `ActionCardData`: koszty (`energy_cost`, `food/wood/materials_cost`),
  efekty (`health/hunger/thirst/warmth/energy_delta`,
  `food/water/wood/materials_gain`), `special` ("none" | "craft_tools" |
  "explore" | "double_explore" | "draw_two")
- `BuildingCardData`: koszty budowy, `max_hp` (próg 50% = ruina),
  `defense`, pasywne efekty dzienne (GLOBALNE — niezależne od pozycji),
  `special` ("slow_spoilage" | "night_protection" | "unlock_crafting";
  wpięte: night_protection)
- `EventCardData`: delty statystyk/zasobów (w tym woda/ciepło),
  `next_day_energy_delta`, `shelter_protects` (łagodzone przez budynek
  night_protection)
- `DeckData`: lista kart — akcje i budynki (kopie = wielokrotne wpisy
  tego samego zasobu)
- `BiomeData`: `building_slots` (2–4), `gather_cards` (akcje dostępne
  tylko na kaflu, każda 1×/dzień), `extra_event_cards` (zagrożenia biomu
  dokładane do talii zdarzeń runu) + komplet pól `corrupted_*` (rewers
  kafla po BUM — jeszcze nieużywany)
- `MonsterCardData`: `disaster_id`, obrażenia dla gracza i budynków,
  `copies_in_deck` (szkielet — potwory wchodzą z BUM)
- `DisasterData`: pula potworów + dodatkowe karty zdarzeń Aktu II (szkielet)
- `CharacterClassData`: talia startowa + modyfikatory zasad (mnożniki
  jedzenia/psucia, koszty budowania, HP budynków, redukcja obrażeń)
- `TileState`/`BuildingState`: stan runtime planszy (kafel + `is_corrupted`
  + budynki z HP) — częścią `RunState`, gotowe pod save/load

## Punkty rozbudowy (NIE implementować bez decyzji)

- `MetaState` — pusty placeholder; tu trafią kolekcja, odblokowania
  (biomy/katastrofy/klasy) i drabinka trudności (README sekcja 8,
  milestone 2).
- `RunState` jest `Resource` z `@export` (w tym plansza, talia i postęp
  poziomów) — gotowy pod save/load; pola `disaster`/`bum_happened` czekają
  na krok BUM.
- `BoardGenerator` używa wstrzykiwanego RNG (`SurvivalSystem` ma własny) —
  gotowe pod seedowane runy.
- Kolejne kroki wg README sekcja 10 (każdy osobną decyzją): uproszczone
  pory roku, BUM (Plaga: flip kafli na `corrupted_*`, procentowe
  uszkodzenia budynków, potwory, obrona), wydłużenie runu do ~30 dni,
  ulepszanie kart (wtedy wraca jako nagroda awansu).

## Konwencje

- GDScript ze **statycznym typowaniem** (typy parametrów, zwracane, `:=`).
- Pliki: `snake_case.gd` / `.tscn` / `.tres`; klasy: `PascalCase`
  (`class_name`); stałe: `SCREAMING_SNAKE_CASE`; sygnały i metody: `snake_case`.
- Teksty widoczne dla gracza po polsku; kod, nazwy i komentarze po angielsku.
- Logika w `systems/` nie może importować niczego ze `scenes/` ani `ui/`.
- Po każdym większym kroku: aktualizacja changelogu w tym pliku.
- Małe, częste commity z opisowymi komunikatami (po polsku).
