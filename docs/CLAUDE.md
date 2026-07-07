# Dzień 50 (tytuł roboczy; wcześniej „Karcianka: Przetrwanie")

Karciany roguelike survivalowy 2D (desktop, Godot 4.5), singleplayer.
**Pełny koncept gry jest w [README.md](README.md)** — to on wyznacza kierunek:
run ~60–90 min w dwóch aktach (budowa osady na planszy 6 kafli biomów →
katastrofa **BUM** → przetrwanie do dnia 50), wszystko jest kartą (akcje,
budynki, zdarzenia, potwory, kafle biomów), klasy postaci, meta-progresja
„różnorodność zamiast siły".

Stan obecny: gra toczy się na planszy 6 kafli biomów — mapa węzłów z etapu 2
została zastąpiona i usunięta (historia w gicie). Run = przetrwaj do dnia 50
w dwóch aktach: Akt I (budowa, eksploracja i zabezpieczanie wybranych rejonów),
BUM w dniu 20–26 (flip kafli, obrażenia budynków, zużycie zabezpieczeń), Akt II
(potwory nocą, naprawy, ruiny, obrona). 4 statystyki, budynki z katalogu, akcje
biomu, ruch za energię, XP i poziomy z nagrodami 1 z 3.

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

### Assety: wygenerowany zestaw ramek kart (2026-06-12)

- Płaskie deterministyczne ramki kart odrzucone; nowy zestaw 5 ramek
  (akcja/budynek/zdarzenie/potwór/nagroda, 1024x1536) wygenerowany
  Higgsfield GPT Image 2 z referencjami (rewersy kart + tła biomów),
  spójny z zatwierdzonymi rewersami; stare ramki zarchiwizowane
  w `assets/art/concepts/cards/legacy_flat_frames/`.
- `card_art_mask.png` przebudowana: 754x483 @ (135, 307) — przecięcie
  zmierzonych okien ilustracji wszystkich 5 ramek; prompty i pipeline
  w `docs/asset_plan/generated_asset_samples.md`.
- Komplet startowych ilustracji kart (warstwa artu pod ramkę, 1024x688,
  text-free): 3 budynki (Ognisko/Szałas/Studnia) + 7 akcji (Odpoczynek,
  Eksploruj, Rąb drewno, Zbieractwo, Opatrz rany, Źródło, Narzędzia)
  w `assets/art/cards/illustrations/{buildings,actions}/`. Wspólny scaffold
  promptu + referencje palety (rewers + tło lasu), GPT Image 2 medium.
- 4 potwory Plagi (Zgnilec, Zarażony wilk, Krucza chmara, Rój szczurów,
  1024x688, text-free) w `assets/art/cards/illustrations/monsters/` —
  ten sam pipeline, paleta skażona z referencji (rewers potwora + las Plagi).
- Dodatkowe 12 budynków (Spiżarnia, Warsztat, Palisada, Pułapki, Magazyn
  drewna, Port rybacki, Filtr wodny, Wieża obserwacyjna, Drwalnia, Farma,
  Kamieniołom, Zielarnia) w `assets/art/cards/illustrations/buildings/` —
  ten sam scaffold, GPT Image 2 medium (Magazyn drewna w low, by zmieścić
  się w budżecie). Katalog budynków ma teraz 15 ilustracji; brak jeszcze
  kart `.tres` pod nowe budynki (art wyprzedza dane/rozgrywkę).
- Korekta kierunku buildingow: `assets/art/cards/illustrations/buildings/`
  zostaje jako ciemny zestaw Act II/post-BUM. Zatwierdzony jasny komplet
  Act I (15 ilustracji, 1024x688, text-free, bez ramek i postaci) jest w
  `assets/art/cards/illustrations/buildings_act1_candidates/`; podglad:
  `docs/asset_plan/previews/preview_buildings_act1.png`.
- Korekta kierunku actions: `assets/art/cards/illustrations/actions/`
  zostaje jako ciemny zestaw Act II/post-BUM. Zatwierdzony jasny komplet
  Act I (10 ilustracji, 1024x688, text-free, bez ramek i postaci) jest w
  `assets/art/cards/illustrations/actions_act1_candidates/`; podglad:
  `docs/asset_plan/previews/preview_actions_act1.png`.
- Dodatkowe 3 ilustracje eksploracji/fog-of-war (Zwiad, Wytycz szlak,
  Mapa okolicy, 1024x688, text-free) w
  `assets/art/cards/illustrations/actions/`; format zgodny z nowymi
  standalone card illustrations i gotowy do złożenia z ramkami w Godot.
- Szeroki pack integracyjny P0/P1: `bg_run_table.png`, 36 ikon
  `assets/art/cards/icons/*.png`, pierwsze panele/przyciski/bary UI,
  markery/overlaye board oraz proste FX BUM/pogody/kart w `assets/art/fx/`.
  Assety są text-free; UI/FX to pierwsze placeholdery produkcyjne pod szybkie
  podpięcie i iterację w Godot. UWAGA (audyt 2026-06-12): zapowiadane tu
  wcześniej assety discovery kafli (`biome_unknown*`, mgła, ramki 9-slice,
  hint overlaye) NIE istnieją w repo — `assets/art/biomes/discovery/` jest
  pusty; do wygenerowania wg sekcji discovery w `ASSET_PLAN_DZIEN_50_GODOT.md`
  (istnieją tylko FX `assets/art/fx/discovery/`, popup discovery
  i `icon_discovery.png`).
- Korekta kierunku icons: obecne płaskie `assets/art/cards/icons/*.png`
  zostają na razie jako działający placeholder. Nowy deck-style candidate pack
  (36 ikon, text-free, złote medaliony + ciemna haftowana zieleń zgodna z
  backs/frames) jest w `assets/art/cards/icons_deck_style_candidates/`
  (`64x64`) oraz `source_128/`; legacy kopie są w
  `assets/art/concepts/cards/icons_legacy_flat_reference/`. Podglądy:
  `docs/asset_plan/previews/preview_icons_deck_style_64.png` i
  `docs/asset_plan/previews/preview_icons_deck_style_128.png`.

- Korekta biome UI layers: plaski deterministic repaint ramek/slotow zostal
  odrzucony jako zbyt paint-like. Produkcyjne `assets/art/biomes/frames` i
  `slot_markers` uzywaja surowych AI assetow na zielonym tle. `frames`
  zostaly ponownie wygenerowane w lzejszym stylu `biome_neighbor_highlight`
  (cienkie zlote bracket/corner accents, liscie), ale po korekcie
  `biome_tile_frame.png` ma byc zamknieta ciagla ramka bez przerw, a
  `biome_title_plate.png` ma miec ciemne zielono/brazowe wypelnienie pod
  czytelny jednokolorowy tekst w Godot. Slot markery uproszczono do dwoch
  aktywnych stanow: `slot_empty.png` i `slot_selectable.png`; oba maja byc
  zamkniete, lekkie, ornamentalne i z ciemnym wypelnionym srodkiem. Poprzednie zaakceptowane ramki
  zapisano w `assets/art/concepts/biomes/frames_before_neighbor_highlight_style/`,
  a przerwana/open-frame wersje w
  `assets/art/concepts/biomes/frames_neighbor_style_open_frame_reference/`.
  `assets/art/biomes/overlays` zostaly ponownie wygenerowane przez `imagegen`.
  Regula pipeline'u: zostawiac raw `#00FF00`, nie usuwac chroma-key podczas
  generowania, bo wycinanie potrafi obciac koncowki ramek i glow piksele.
  Podglady: `docs/asset_plan/previews/preview_biome_ai_candidates_greenkey.png`,
  `docs/asset_plan/previews/preview_biome_ai_candidates_on_forest.png` oraz
  `docs/asset_plan/previews/preview_biome_overlays_raw_green.png`,
  `docs/asset_plan/previews/preview_biome_frames_neighbor_style_raw_green.png`,
  `docs/asset_plan/previews/preview_biome_frames_closed_filled_raw_green.png`
  oraz `docs/asset_plan/previews/preview_biome_slots_closed_light_raw_green.png`.

### Audyt struktury assetów + porządki (2026-06-12)

- Pełne porównanie plików na dysku z dokumentacją
  (`docs/asset_plan/generated_asset_samples.md`, ten changelog).
- Usunięte duplikaty bajt-w-bajt w `assets/art/concepts/biomes/`:
  `legacy_biome_forest_normal_v3.png` i `legacy_biome_meadow_normal.png`
  (identyczne z `concept_biome_*_board_slots*.png` w tym samym katalogu).
  Świadome duplikaty zostają: próbki `*_act1_candidate.png` (approval
  history) i `move_arrow.png` w `board/markers/` + `board/player_marker/`.
- `docs/` dostał `.gdignore` — Godot nie importuje już
  podglądów z dokumentacji.
- Skorygowane nieaktualne ścieżki/wymiary w `generated_asset_samples.md`:
  maska 800x520 → 754x483 @ (135, 307); `building_well_card` →
  `concepts/cards/concept_building_well_card.png`; stare kafle biomów →
  `concepts/biomes/concept_biome_*_board_slots*.png`; sekcja
  `ai_layer_candidates` (katalog usunięty po promocji do produkcji).
- Wykryty brak: assety discovery kafli z planu (`biome_unknown*` itd.)
  nigdy nie trafiły do repo mimo wcześniejszego wpisu — oznaczone jako
  MISSING w docs, do wygenerowania przy kroku fog-of-war.
- Wiele nowszych PNG nie ma jeszcze plików `.import` — wygenerują się
  automatycznie przy następnym otwarciu/`--import` Godota.

### Vertical slice krok 3 — BUM (Plaga) i Akt II (UKOŃCZONY, 2026-06-12)

- Run wydłużony do 30 dni; BUM uderza o świcie dnia losowanego z 13–16
  (typ i dzień zapadają przy starcie runu, gracz ich nie zna); od 3 dni
  przed BUM skryptowane omeny w logu (foreshadowing).
- BUM: wszystkie kafle flipują na `corrupted_*` (nazwa, opis, akcje
  zbierania, zdarzenia), każdy budynek losuje 10–80% uszkodzeń; HP poniżej
  50% maks. = RUINA (pasywy/obrona/speciale przestają działać).
- Talia zdarzeń Aktu II budowana od nowa: zdarzenia bazowe + zagrożenia
  skorumpowanych biomów + zdarzenia katastrofy (Gnijące zapasy, Koszmary
  w `data/cards/events/plague/`) + karty potworów × `copies_in_deck`.
- Potwory (4 typy Plagi, komplet z artem): Zgnilec 2/2 ×2, Zarażony wilk
  3/0 ×2, Krucza chmara 1/1 ×2, Rój szczurów 0/3 ×2 (obrażenia
  gracz/budynki × kopie). Atak nocą: gracz dostaje obrażenia (Szałas
  łagodzi o 2, klasa może redukować), losowy stojący budynek dostaje
  obrażenia minus suma `defense` budynków na jego kaflu; potwór wraca do
  talii (nie znika).
- Podstawowa obrona: Palisada (`data/buildings/palisade.tres`, defense 2,
  12 HP) — budynki weszły do puli nagród awansu (kolejne kopie do
  zbudowania); pula = 20 akcji + 4 budynki.
- Naprawa (na swoim kaflu, budynek nie-ruina): 1 energia + 1 drewno za
  każde 2 brakujące HP, przywraca do pełna. Rozbiórka ruiny: 1 energia,
  zwrot połowy drewna/materiałów kosztu budowy, zwalnia slot.
- Skorumpowane akcje zbierania (`data/cards/actions/corrupted/` — poza
  pulą nagród): Skażona zwierzyna (+3 jedzenia, -1 zdrowia; Martwy Las
  i Zgniłe Łąki), Mętna woda (+1 wody; Martwy Las i Wyjące Góry).
- UI: HP/RUINA budynków na kaflach, pasek „Budynki:" z przyciskami
  naprawy/rozbiórki na bieżącym kaflu, tło ciemnieje po BUM
  (sygnał `bum_struck`), tooltip kafla pokazuje opis skorumpowany.
- Balans botem (50 runów): ~56–62% wygranych, śr. ~27 dni, śr. poziom ~9;
  większość porażek po BUM — katastrofa jest skokiem trudności zgodnie
  z założeniem (Akt I solo: ~90%). Tuning: zombie 3→2 kopie, rzut
  uszkodzeń 10–90→10–80, Szałas działa też na ataki potworów.
- Bot w smoke teście: naprawia/rozbiera na swoim kaflu i nie gra kart
  z ujemnym zdrowiem, gdy ma ≥2 jedzenia.

### Nowe decyzje projektowe z rozmowy GPT (2026-06-12, NIE zaimplementowane)

- Akt I ma docelowo używać fog-of-war na planszy: startowo widoczny jest
  tylko kafel startowy, pozostałe 5 kafli to `Nieznany teren`. Wejście na
  sąsiedni kafel odkrywa biom, sloty, akcje zbierania i zagrożenia; karty
  `Eksploruj`/`Zwiad`/`Mapa okolicy` mogą później podglądać lub oznaczać
  kafle przed ruchem.
- Nocne zdarzenia nie powinny być czystym losowaniem ze wszystkich kart.
  Docelowy model: aktywna pula = karty bazowe + karty odkrytych biomów +
  sezon + omen BUM + po BUM potwory/katastrofa. Karty mają wagi, cooldowny,
  limity na run i tagi, żeby rzadkie kary (powódź, choroby bagien) nie
  spamowały gracza.
- `Spokojna noc` ma być prawdziwą neutralną kartą w talii zdarzeń, a nie
  brakiem zdarzenia.
- Po kliknięciu `Zakończ dzień` UI ma pokazywać dużą kartę nocnego zdarzenia
  na przyciemnionym ekranie (docelowo rewers -> flip -> opis -> `OK` ->
  rozliczenie efektów + wpis do dziennika). Obecnie zdarzenia rozliczają się
  automatycznie w logu.
- Asset plan został rozszerzony o zakryte kafle, mgłę, ikony odkrywania,
  karty zwiadu i prompty dla `Nieznanego terenu`; sekcje discovery są na
  końcu `ASSET_PLAN_DZIEN_50_GODOT.md`.

### Segregacja assetów + pierwsza warstwa grafiki w grze (2026-06-13)

- Pełny audyt użycia assetów: `docs/asset_plan/asset_usage_audit.md` mapuje
  każdy katalog `assets/art/` na status WPIĘTE / ZAPAS / _reference. Wniosek:
  realnie ładowana jest mała część biblioteki, reszta to zapas pod iterację.
- Nieużywane/odrzucone i materiały referencyjne wyjechały do
  `assets/_reference/` (z `.gdignore`, poza importem Godota): `unused/`
  (`bg_biome_board.png` dup, `biome_neighbor_highlight`, `neighbor_connector`,
  `card_frame_reward`), `concepts/` (historia), `icons_deck_style_candidates/`
  (kandydat ikon, nigdzie nieużyty), `biomes_greenkey_src/` (surowe źródła).
- Pierwsza warstwa grafiki realnie w grze:
  - `main_menu.tscn`: tło `bg_run_table.png` + scrim.
  - `run.tscn`: tło planszy `bg_biome_board_act1.png`; po BUM `run.gd` podmienia
    na `bg_biome_board_act2.png` (sygnał `bum_struck`).
  - `card_view`: ramki per typ karty (akcja/budynek → bazowa, zdarzenie,
    potwór) + ilustracje Akt I (`*_act1_candidates`, aliasy id→plik).
  - `biome_tile_view`: złożenie kafla z chroma-keyowanych assetów —
    tło biomu + ramka `biome_tile_frame` (Akt I) / `biome_corruption_overlay`
    (Akt II) + nameplate `biome_title_plate` (NinePatchRect, nazwa + sloty) +
    marker `biome_current_player` na bieżącym kaflu.
- Chroma-key: 6 assetów biomów dostarczono na surowym `#00FF00`; wycięte do
  alpha progiem `G>150 ∧ R<120 ∧ B<120 ∧ (G−R)>80 ∧ (G−B)>80` (oszczędza złoto,
  liście, szmaragdy) + tłumienie green-spillu. Reguła: keyować dopiero po
  wygenerowaniu, nie ruszać ciemnej zieleni paneli ani klejnotów.
- Jeszcze ZAPAS (gotowe, niewpięte): `assets/art/ui/*` (paski/przyciski/panele —
  UI stoi na domyślnym theme), `assets/art/fx/*`, `cards/icons/*`, ciemne
  zestawy ilustracji Akt II (`illustrations/{actions,buildings}/`),
  `slot_markers/slot_{empty,selectable}` (pionowe 2:3, nie pasują do
  poziomego miniaturowego kafla — czekają na panel rozkładu slotów).
- Testy po zmianach: `load_test` OK, `board_test` OK (200 plansz),
  `smoke_test` 30/50 (~60%, śr. 26,8 dnia, poziom 8,8) — bez regresji.

### Poprawki wyglądu sceny runu (2026-06-13)

- Kafle biomów: ramka (`Frame`) dostaje lekki overscan (anchory −3,5%…+3,5%),
  żeby złoty ornament dochodził do krawędzi kafla (wcześniej był wcięty przez
  przezroczysty margines arta).
- Nameplate kafla: `NinePatchRect` → zwykły `TextureRect`. NinePatch wymuszał
  min. szerokość = suma patch-marginesów (~460 px) na ~244 px kaflu, co
  rozwalało plakietkę (czarne paski) i wypychało liczbę slotów poza kafel.
  Teraz `biome_title_plate` skaluje się do paska nagłówka, nazwa + sloty
  trzymają się w środku.
- Tło planszy przyciemnione/ochłodzone (`BackgroundArt.self_modulate` +
  mocniejszy scrim), żeby nie konkurowało wizualnie z kaflami lokalizacji.
- Karty: opis mniejszą czcionką i w szerszym/wyższym oknie (koniec
  wychodzenia tekstu poza ramkę); koszty pełnymi słowami
  (Energia/Jedzenie/Drewno/Materiały/Wytrzymałość) zamiast skrótów E/J/D/M.
- `Zakończ dzień` przeniesiony do prawego górnego rogu (TopBar + spacer);
  rząd kart okolicy/ręki ma teraz pełną szerokość.
- Weryfikacja: headless instancjonowanie `biome_tile_view` (normalny +
  skażony) i `card_view` (12 kart talii) bez błędów; `load`/`board`/`smoke`
  bez regresji (smoke 34/50).

### Kafel: sloty budowli + układ wg mockupu (2026-06-13)

- Kafel przebudowany pod referencyjny układ gracza: plakietka nazwy
  wyśrodkowana u góry (nie pełna szerokość), marker gracza
  (`biome_current_player`) przeniesiony w prawy górny róg. PNG markera
  przycięty do samego medalionu (415×413), żeby wypełniał róg bez pustego
  marginesu (poprzednio wyśrodkowany pełnoklatkowy art robił się mały).
- Dodany rząd slotów budowli u dołu kafla (`SlotsRow`, wyśrodkowany): jeden
  widget na `building_slots` biomu. Pusty slot = prosty półprzezroczysty
  prostokąt (`Panel` + `StyleBoxFlat`, cienka złota ramka); zajęty = miniatura
  artu budynku (`buildings_act1_candidates`, COVERED) z etykietą „Nazwa + N HP"
  pod spodem, a dla ruiny czerwone „Nazwa + RUINA". Tekstowe `BuildingRows`
  zastąpione slotami. Ozdobne `slot_markers/slot_{empty,selectable}` odrzucone
  jako mało czytelne — wracają do statusu ZAPAS.
- Karty budynków: HP (Wytrzymałość) przeniesione z paska kosztów do opisu
  (`_format_description`) — koszt pokazuje już tylko surowce budowy.
- Weryfikacja: headless instancjonowanie kafla z zajętym i zruinowanym
  slotem + 12 kart bez błędów; `load`/`board`/`smoke` bez regresji
  (smoke 32/50).

### Drobne poprawki: sloty + karty okolicy (2026-06-13)

- Sloty budowli na kaflu zmniejszone (68×90 → 50×62), maks. 3 na kafel
  (`MAX_SLOTS`), ułożone z lekkim pionowym przesunięciem (`SLOT_STAGGER`),
  żeby rząd nie wyglądał jak sztywna siatka. `meadows.tres` building_slots
  4 → 3 (spójność z limitem).
- Bug: karty okolicy po użyciu tylko się wyszarzały zamiast znikać. Dodano
  `SurvivalSystem.available_gather_actions()` (akcje bez zużytych dzisiaj);
  `run.gd` buduje i odświeża rząd okolicy z tej listy — zużyta karta znika
  z rzędu (logika 1×/dzień bez zmian, bot/smoke bez regresji).

### Dopieszczenie układu (2026-06-13)

- Sloty: etykieta nazwa/HP mniejsza (8 → 7), więcej miejsca + `clip_text`,
  żeby tekst nie wystawał poza obrys slotu.
- Karty: czcionka opisu dobierana do długości tekstu
  (`CardView._apply_desc_font`, 7–11 px) — długie opisy nie wychodzą już poza
  okno ramki (Godot nie ma natywnego shrink-to-fit dla Label).
- `run.tscn` MidRow: log przesunięty na lewą krawędź (stały 340×220), plansza
  biomów dostała `size_flags_horizontal = expand` → kafle wypełniają resztę
  szerokości i są większe.

### Renderer: gl_compatibility → Forward Plus (Vulkan) (2026-06-13)

- Na laptopie hybrydowym (iGPU Intel + dGPU NVIDIA) gra renderowana przez
  OpenGL (`gl_compatibility`) lądowała na iGPU Intela; klatki dla monitora
  zewnętrznego (podpiętego do RTX 4060) były kopiowane między GPU, przez co
  monitor zewnętrzny się tnie/„wariuje" (ekran laptopa OK). Porównanie z
  działającym projektem potwierdziło, że różnicą był renderer.
- `project.godot`: usunięto override `renderer/rendering_method=gl_compatibility`
  (+ `.mobile`), dodano tag `"Forward Plus"` w `config/features` → projekt
  używa domyślnego Forward Plus (Vulkan), który respektuje wybór GPU i
  prezentuje natywnie na 4060. `max_fps=60` i `vsync_mode=1` bez zmian.
- Po zmianie wymagany restart edytora; `--import` + `load_test` OK.

### Czytelność kart i ramek biomów (2026-06-13)

- `card_frame_action.png` został wycofany z finalnych assetów. Karty akcji,
  budynków, okolicy i wyborów nagród używają `card_frame_building.png`.
  `card_frame_event.png` i `card_frame_monster.png` zostają osobnymi,
  ręcznie poprawionymi ramkami i nie są kopiami building.
- `card_view`: pola nazwy, opisu i kosztu są traktowane jako sztywne okna
  tekstu. Label ma `clip_text`, a skrypt mierzy tekst i zmniejsza font
  w zadanych granicach, żeby tytuł/opis nie wychodziły poza ramkę karty.
- `night_card_view`: osobna scena dla kart nocnych zdarzeń i potworów w
  popupie nocy. Dziedziczy po `CardView`, ale ma własne okna tekstu dopasowane
  do `card_frame_event.png` i `card_frame_monster.png`. Ręka, okolica i nagrody
  nadal używają `card_view.tscn`.
- `biome_tile_view`: `biome_title_plate` jest wyświetlany szerzej i wyżej na
  kaflu, z mniejszym fontem oraz auto-fit dla nazwy biomu i licznika slotów.
- `top_status_bar_view`: górny HUD został wydzielony do osobnej sceny z
  ramką Aktu I/Aktu II, fixed layoutem, clippingiem tekstów, paskami statystyk,
  zasobami i przyciskiem końca dnia. `run.gd` przekazuje do niej stan runu,
  a po BUM wywołuje `set_act2()`.

### Vertical slice: fog of war / odkrywanie mapy (2026-06-15)

- `TileState` ma teraz `is_discovered`. Po starcie runu odkryty jest tylko
  kafel startowy; pozostale kafle sa zakryte jako `Nieznany teren`.
- Wejscie na sasiedni zakryty kafel kosztuje standardowo 1 energie i odkrywa
  jego biom, sloty, akcje zbierania oraz budynki. Log dopisuje komunikat
  `Odkrywasz nowy teren`.
- `BiomeTileView` ma osobny tryb renderowania kafla nieodkrytego: nie pokazuje
  prawdziwej nazwy biomu, slotow, budynkow ani ikon budynkow. Sasiedni zakryty
  kafel dostaje tooltip informujacy, ze wejscie odkryje teren.
- Nocna talia zdarzen jest przebudowywana z hazardow tylko odkrytych biomow.
  Po BUM ta sama zasada dotyczy skorumpowanych hazardow; zdarzenia katastrofy
  i potwory dochodza dopiero w Akcie II. To sprawia, ze eksploracja realnie
  zwieksza pule ryzyka, a nie jest tylko efektem wizualnym.
- Dodano `tests/fog_of_war_test.gd`; sprawdza, ze startuje dokladnie jeden
  odkryty kafel i ze pierwszy ruch odkrywa kolejny.

### Vertical slice: pory roku (2026-06-15)

- `RunState` ma teraz `season` (`SPRING`, `SUMMER`, `AUTUMN`, `WINTER`).
  Harmonogram 30-dniowego vertical slice'a: dni 1-7 Wiosna, 8-14 Lato,
  15-22 Jesien, 23-30 Zima.
- Pora roku zmienia sie o swicie i wpisuje komunikat do logu. HUD pokazuje
  ja obok dnia (`Dzien X/30  Wiosna/Lato/Jesien/Zima`).
- Pierwsze modyfikatory sezonowe sa celowo male i bez nowych kart:
  Wiosna daje +1 jedzenia przy akcjach zbierajacych jedzenie, Lato zwieksza
  nocny spadek nawodnienia o 1, Jesien daje +1 drewna przy akcjach z drewnem,
  Zima zwieksza nocny spadek ciepla o 1.
- Dodano `tests/season_test.gd`; sprawdza przejscia sezonow. Smoke po zmianie:
  24/50 wygranych bota, srednio 25.7 dnia, zgony po BUM 19. Balans do dalszego
  strojenia po testach recznych.

### FX odkrywania: zwolnienie + chroma-key (2026-06-15)

- `BiomeTileView.play_discovery_fx` przebudowany na WARSTWY zamiast jednego
  TextureRect przełączającego klatki. Cztery nałożone obrazy mgły, stos od
  spodu: `fx_tile_reveal_01` → `fx_fog_loop_01` → `fx_tile_reveal_03` →
  `fx_tile_reveal_02` (wierzch). Tworzone dynamicznie jako dzieci kafla, na
  pełnej alfie — kafel jest CAŁKOWICIE zakryty od razu (biom nie miga przed
  animacją). Warstwy gasną od ŚRODKA NA ZEWNĄTRZ shaderem `DISSOLVE_SHADER`
  (radialny smoothstep: przezroczysty okrąg rośnie od środka ku krawędziom,
  param `progress` 0→1.25). Zaniki biegną RÓWNOLEGLE z przesunięciem
  (`set_parallel` + `set_delay`, stagger 0.4s), więc nachodzą na siebie i
  czytają się jak jedna płynna animacja, a nie kilka osobnych. Czasy
  [start, czas] per warstwa w `REVEAL_FADE`: reveal_02 [0.0, 0.95], reveal_01
  [0.4, 1.15], fog_loop [0.55, 0.95]; `fx_tile_reveal_03` zamyka (dissolve +
  skala →1.22 od środka, `CLOSING_DUR` 1.1) i jest tak zsynchronizowane, by
  kończyć RÓWNO z fog_loop (~1.5s całość). Każda warstwa dostaje własny `ShaderMaterial`
  (wspólny `Shader` w `static`). Węzeł `RevealFx` usunięty ze sceny; warstwy
  tworzone/zwalniane w kodzie (`_make_reveal_layer`, `_clear_reveal_layers`,
  kolejność w `REVEAL_STACK`/`REVEAL_FADE_ORDER`, sprzątanie na
  `tween.finished`). `ui_layout_test` sprawdza liczbę utworzonych warstw.
- 5 klatek FX discovery (`assets/art/fx/discovery/*.png`) wycięte z surowego
  zielonego tła do alfy. UWAGA: szeroka heurystyka odcienia (każda zieleń)
  zjadała zgaszone zielone dekoracje lasu — odrzucona. Działający klucz tnie
  po ODLEGŁOŚCI koloru od dokładnego green-screena (próbka z rogów ≈ RGB
  20,238,25): d≤80 przezroczyste, 80–145 miękka krawędź + despill, >145
  pełny art. Las/mgła/iskry są daleko w przestrzeni koloru, więc zostają.
- Jednorazowy tool `tools/chroma_key_fx.gd` (SceneTree, `-s`) keyuje listę
  PNG w miejscu — można skierować na kolejne foldery FX (bum/weather/...).
- WAŻNE: `assets/_reference/concepts/fx_before_imagegen_rework/` to STARSZA
  wersja FX (czarne rogi, inny styl), NIE źródło green-screena. Green-screenowe
  oryginały odtwarza się z gita: `git checkout -- assets/art/fx/discovery/*.png`.
  Weryfikacja: `--import` + `ui_layout_test` OK.

### Animacja BUM: przejście Akt I → Akt II (2026-06-15)

- 13 nowych assetów FX wygenerowanych (GPT Image przez Codex) wg tabeli z
  rozmowy: `assets/art/fx/bum/*` (omen_glow, bum_flash, shockwave_ring,
  blast_petals, sky_rift_01/02, screen_crack_overlay, wilt_overlay) i
  `assets/art/fx/corruption/*` (rot_wipe, plague_cloud_01/02, corruption_vignette,
  spore_motes_loop). Pełnoekranowe 16:9, text-free.
- Pipeline: wycinanki dostarczone na solid blue `#0000FF`, additive (omen/flash/
  motes) na czerni. Nowy tool `tools/chroma_key_blue.gd` (klucz po odległości od
  `#0000FF`, INNER 90 / OUTER 150 + despill) wyciął 10 niebieskich do alfy;
  czarne zostają i wpinane są z `CanvasItemMaterial` blend `add`.
- `run.gd`: dawny natychmiastowy `_on_bum_struck` zastąpiony `_play_bum_fx` —
  warstwowa, nachodząca sekwencja (`create_tween().set_parallel` + `set_delay`):
  (1) łuna omenu, (2) błysk + rozszerzający się shockwave_ring + rozrzut płatków,
  (3) pęknięcie nieba rift_01→02 + screen_crack, (4) wpełzająca zgnilizna/plaga
  wycierająca planszę na Akt II + więdnące kwiaty (`wilt_overlay`, dolny pas,
  transient), (5) stała ciemna winieta + dryfujące zarodniki
  (pętla oddychania alfą). Podmiana wyglądu Aktu II (`_apply_act2_look`: tło,
  scrim, skórki przycisków, HUD, log) odpalana w szczycie błysku (~0.34s), więc
  gracz nie widzi „surowego" flipa UI. Całość ~3s; brak assetów → fallback do
  natychmiastowego `_apply_act2_look`. Stała winieta + zarodniki są po animacji
  przenoszone (`move_child`) tuż nad tło planszy a POD UI gameplayu, więc wtapiają
  się w tło i nie zasłaniają HUD/kart (transientowy blast zostaje na wierzchu).
- Weryfikacja: `--import` bez błędów, `ui_layout_test` OK, `smoke_test` 31/50
  (~62%, bez regresji).

### Animacja: odsłonięcie nocnej karty (flip) (2026-06-16)

- 5 nowych assetów FX (GPT Image przez Codex): `fx/cards/fx_card_reveal_glow`,
  `fx_card_shine_sweep`, `fx_card_reveal_burst`, `fx_card_dust_puff` oraz
  `ui/overlay_night_spotlight`. Glow/shine/dust/spotlight na czerni/granacie
  (additive), tylko `reveal_burst` na solid blue → wycięty `chroma_key_blue.gd`.
  Rewersy do flipa już istniały (`cards/backs/card_back_{event,monster}`).
- `run.gd` `_on_night_card_drawn`: karta wjeżdża REWERSEM i obraca się do frontu —
  rewers jest przytrzymany (`HOLD` 0.95s, żeby gracz go przeczytał), potem flip
  z podmianą back→front w połowie (0.22s); pozostałe fazy przesunięte o `HOLD`.
  Rewers (`TextureRect`) i front (`NightCardView`) to BEZPOŚREDNIE dzieci
  `CardSlot` (CenterContainer centruje oba w tym samym rect 132×198, pivot w
  środku), flipowane osobno przez `scale.x` — karta kończy wyśrodkowana
  (wcześniejszy wrapper `Control` na full-rect zostawiał przesunięcie). Rewers
  dobierany po typie karty (monster/event).
- FX (`_spawn_night_fx`, fullscreen w `NightEventOverlay`): spotlight + glow
  wchodzą pod panel (`move_child`, backdrop — nie zmywają lica karty) i zostają;
  shine przejeżdża po karcie w trakcie flipa; burst (iskry) strzela w momencie
  odsłonięcia (skala 0.6→1.35, additive); dust puff przy „lądowaniu". Tint
  czerwony dla potworów, ciepły złoty dla zdarzeń. Wszystko sprzątane w
  `_clear_night_card` (FX + tween killowane przy ukryciu/następnej karcie).
- Weryfikacja: `--import` bez błędów, `ui_layout_test` OK.

### Aktywna pula nocnych zdarzeń (2026-06-16)

- Prosta talia zdarzeń (`Deck`) zastąpiona `systems/night_event_pool.gd`
  (`NightEventPool`): ważony losowy dobór z cooldownami, limitami na run
  i tagami. Historia (ostatni dzień użycia, licznik) PRZETRWA przebudowy puli
  — discovery/BUM zmieniają tylko zestaw kandydatów, nie pamięć cooldownów.
- `EventCardData` dostał pola `weight` (domyślnie 10), `cooldown_days`,
  `max_per_run` (0 = bez limitu) i `tags` — wszystkie wstecznie zgodne, więc
  istniejące karty bez zmian działają jak dotąd (waga jednolita). Potwory biorą
  udział w puli z wagą = `copies_in_deck`, bez cooldownu i limitu (wracają).
- `SurvivalSystem`: `_event_deck` → `_night_pool`; `draw()` bierze dzień,
  potwory/zdarzenia nie są już „odkładane" do talii (pula sama steruje
  powtarzalnością). Gdy wszystko na cooldownie, cooldowny są rozluźniane (noc
  nigdy nie jest „pusta"), ale limity zawsze obowiązują.
- „Spokojny wieczór" (`calm_day`, zerowe delty) to teraz pełnoprawna karta puli
  z podbitą wagą (24) — prawdziwa neutralna noc, nie brak zdarzenia.
- KATEGORIE + SEVERITY: `EventCardData` ma `category`
  (`neutral/weather/biome/omen/monster/disaster`) i `severity`
  (`minor/medium/major`); wpisane we wszystkie 14 zdarzeń (potwory =
  kategoria `monster`, severity z `damage_to_player`). Pula używa ich do:
  - PACING: nie losuje dwóch nocy `major` z rzędu (rozluźniane tylko gdy nie
    ma alternatywy, więc noc nigdy nie jest pusta);
  - FAZY: `NightEventPool.Phase` (ACT1/OMEN/ACT2) mnoży wagi kategorii
    (`PHASE_CATEGORY_MULT`) — w oknie omenów omeny ×5, przed nim ×0;
  - DEDUPLIKACJA po `id` (biomy odwołują się do kart bazowych — jedna ważona
    pozycja na kartę).
- UI: `run.gd` `_night_tint` koloruje glow/burst odsłonięcia wg kategorii
  (monster=czerwony, weather=błękit, biome=zieleń, disaster=fiolet, omen=
  bursztyn, neutral=ciepłe złoto).
- Omeny (foreshadowing w logu) startują teraz od stałego `OMEN_START_DAY = 7`
  (zamiast 3 dni przed BUM), więc zawsze zdążą się pojawić przed BUM (13–16).
- Strojenie przykładowe: Burza (w7, cd3, major), Choroba (w6, cd4, max3,
  major), Wilki (w6, cd3, major), Zimna noc/Ulewa (cd2, medium), Szczury
  (cd2, medium), zdarzenia Plagi (cd2, medium). Reszta na domyślnej wadze 10.
- `tests/night_pool_test.gd`: niezmienniki limitu, cooldownu, biasu wag i
  pacingu „bez 2× major" (seedowany RNG). Smoke 37/50 (~74%, śr. 28,5 dnia) —
  pacing złagodził serie kar (anty-frustracja), do ewentualnego doważenia.

### Odblokowane 11 budynków (2026-06-16)

- Art budynków wyprzedzał dane — 11 ilustracji (Farma, Port rybacki, Spiżarnia,
  Pułapki, Drwalnia, Magazyn drewna, Kamieniołom, Warsztat, Filtr wodny,
  Zielarnia, Wieża obserwacyjna) nie miało kart `.tres`. Dodano `BuildingCardData`
  w `data/buildings/` (id = nazwa pliku artu `building_*`, więc grafika i token
  na kaflu wskakują bez zmian w kodzie). `GameManager` ładuje cały katalog →
  same wchodzą do puli nagród awansu. Talia budynków: 4 → 15.
- Pasywy oparte WYŁĄCZNIE o wpięte pola (`food/water/wood/materials_gain`,
  `health_delta`, `defense`) — specjale `slow_spoilage`/`unlock_crafting` nadal
  no-op, więc Spiżarnia/Warsztat działają przez zwykłe +1 jedzenia / +1 mat.
- Balans: smoke 40/50 (~80%, śr. 29 dni) — wzrost, bo bot chciwie buduje, a
  więcej produkcyjnych budynków = większy dochód. Do doważenia (koszty/HP/pasywy
  albo mocniejszy Akt II). `load`/`ui_layout` (51 kart) OK.

### Rozszerzenie puli zdarzeń z bazy GPT (2026-06-16)

- Z dokumentu `dzien_50_baza_kart_v0_1.md` (baza ~108 zdarzeń od GPT) wdrożono
  BEZPIECZNY podzbiór **28 kart** — tylko te działające na obecnych mechanikach;
  warunki niewspierane (sezon/biom/budynek, losowość, mitygacje, obrażenia
  budynku ze zdarzeń) „zbakowano" na stałe efekty albo usunięto. Status i lista
  zablokowanych mechanik: nagłówek w tamtym pliku.
- Dodane: NEUTRAL 4, WEATHER 9, OMEN 6 (bazowe w `data/cards/events/`), BIOME 5
  (`events/biome/`, wpięte w `extra_event_cards` Lasu/Łąk/Gór) i DISASTER/Plaga 4
  (`events/plague/`, wpięte w `plague.tres`). Pula zdarzeń: 18 → 42 (+4 potwory).
- OMEN jako pełne karty (wcześniej tylko logi): kategoria `omen` pojawia się
  wyłącznie w oknie dzień≥7→BUM — `NightEventPool.PHASE_CATEGORY_MULT` daje omen
  ×5 w fazie OMEN, ×0 w ACT1 i ACT2.
- Balans: smoke 43/50 (~86%, śr. 29 dni, zgony po BUM 6) — WZROST, bo nadmiar
  kart minor/neutral rozcieńcza rzadkie majory (łagodniejsze noce). Wymaga
  osobnego przejścia balansowego (wagi/severity kar albo silniejszy Akt II/BUM).
  `load`/`night_pool`/`ui_layout` (70 kart) OK.

### Dokręcenie trudności (2026-06-16)

- Gra była za łatwa (naiwny bot ~86%, „kemping na jednym kaflu + zagraj wszystkie
  karty" przechodził). Zacieśniono ekonomię przetrwania:
  - `DAILY_HUNGER_DECAY` 2→3, `DAILY_WARMTH_DECAY` 1→2 (nawodnienie zostaje 2);
    jedzenie i ciepło to teraz realna, ciągła presja (Ognisko staje się celem
    early game, nie luksusem).
  - `RunState.MAX_ENERGY` 10→9 — nie da się już zrobić wszystkiego w jeden dzień,
    trzeba priorytetyzować.
  - Kary deprywacji i próg BUM bez zmian (testowane warianty 3/3/2 + dmg 3 +
    BUM 25% przestrzeliły do ~10–16%; cofnięte).
- Tuning botem (iteracyjnie, smoke 50 runów): 86% → **36%** wygranych (śr. ~24
  dni). Akt II to teraz ściana (większość zgonów po BUM), zgodnie z założeniem
  „przetrwanie ma dawać satysfakcję". Cel dla świadomej gry: wyżej niż bot.
- Pozostałe testy bez regresji (`load`/`night_pool`/`board`/`fog`/`season`/
  `ui_layout` OK).

### Przemodelowanie ekonomii: capy + budowanie z katalogu + zasoby per biom (2026-06-18)

Trzy powiązane zmiany na prośbę gracza (gra była za łatwa: hoarding 100 jedzenia,
„kemping" na jednym kaflu, długie czekanie aż budynek się wylosuje):

- **#1 Capy magazynowania.** `RunState` ma `MAX_FOOD/WATER` 8, `MAX_WOOD/MATERIALS`
  12; `SurvivalSystem` clampuje KAŻDY przyrost zasobu (`_add_food/water/wood/
  materials`, używane wszędzie — akcje, pasywy, zdarzenia, explore, zwrot z
  rozbiórki). `BuildingCardData` dostał `*_cap_bonus`; budynki magazynowe
  podnoszą cap (Spiżarnia +6 jedz., Magazyn +8 drewna, Filtr/Studnia +4 wody,
  Warsztat +6 mat.) — dają wreszcie sens i ograniczają hoarding.
- **#3 Budynki poza talią.** Budynki nie są już kartami w talii ani nagrodą
  awansu — `SurvivalSystem` ma `_building_catalog` (z `GameManager`), API
  `building_catalog()`/`can_build()`/`build()`, a `run.gd` dodaje sekcję
  „Postaw budynek" w popupie kafla (medalion widoczny też na pustym bieżącym
  kaflu). Nagroda „karta" = tylko akcje (koniec rozcieńczania budynkami). KLUCZ:
  budować można TYLKO w Akcie I; po BUM `can_build` blokuje — to przywraca wagę
  katastrofie (brak darmowej odbudowy).
- **#2 Zasoby per biom.** Silne akcje zbierania (Rąb drewno, Poluj, Szukaj
  materiałów) zostają TYLKO jako akcje biomów (przypięte do kafla 1×/dzień):
  Las = drewno+mięso, Łąki = jedzenie, Góry = materiały+woda. Talia startowa
  przebudowana na utility + lekkie fallbacki (Zbieractwo ×2, Źródło, Odpoczynek,
  Opatrz rany, Zwiad, Narzędzia, Zioła, Eksploruj). Surowiec zdobywasz głównie
  TAM, gdzie występuje → wymusza ruch (anty-kemping). Sloty biomów 3/3/2 → 2/2/2.
- Dokręcony decay (3/3/3) i energia 8; BUM rujnuje 60–80% (wszystko → ruina,
  bez odbudowy); potwory Plagi zbuffowane.
- Tuning botem (iteracyjnie, ~12 przebiegów smoke): 86% → **46%** wygranych,
  śr. ~25 dni, zgony skupione w Akcie II (22/50). Świadoma gra celuje wyżej;
  do dalszego strojenia po playteście. Testy `load`/`board`/`night_pool`/`fog`/
  `season`/`ui_layout` bez regresji (`load`/`smoke` zaktualizowane pod nową
  talię 9 kart i katalog budynków).
- ZNANE: przy progu BUM 60% wszystkie budynki giną — inwestycja w budynki Aktu I
  nie „przenosi się" do Aktu II (świadomy wybór: katastrofa = czysta karta).
  Do rozważenia później: częściowe ocalenie + trudniejszy Akt II inną drogą.

### Tryb budowania (toggle) + budowa po BUM za karę (2026-06-19)

- **Nowy UI budowania (wg mockupu gracza).** Budowa wyszła z bocznego popupu do
  trybu przełączanego: przycisk **„Budowanie"** (ta sama ramka/wymiary co
  „Koniec dnia", w kolumnie nad nim). Klik podmienia rząd kart okolicy i ręki na
  **przewijalny katalog budynków jako karty** (`BuildScroll`/`BuildCards`,
  poziomy suwak); napis na przycisku zmienia się na **„Akcje"** i wraca do kart
  biomu/akcji. Karty budynków szarzeją, gdy nie stać / brak slotu na bieżącym
  kaflu. Tryb auto-wyłącza się przy „Koniec dnia". Boczny popup kafla
  (`BuildingActionPopup`) zostaje, ale już TYLKO do naprawy/rozbiórki.
- **Potwierdzenie budowy.** Klik karty budynku otwiera `ConfirmationDialog`
  („Buduj"/„Anuluj") z nazwą i efektywnym kosztem — koniec przypadkowego
  stawiania.
- **Budowa po BUM wróciła, ale za karę** (decyzja gracza: wygoda bez rozbrojenia
  katastrofy). `can_build` nie blokuje już po BUM; zamiast tego w Akcie II każdy
  budynek kosztuje **+3 energii, +5 drewna, +5 materiałów** (`POST_BUM_BUILD_*_
  SURCHARGE`, wliczone w `_building_*_cost`). Nowe API `effective_build_cost()`
  podaje UI realny koszt (zniżka klasy + dopłata po BUM).
- Balans: smoke **33/50 (~66%)**, śr. 26,8 dnia, zgony po BUM 15 — pośrodku
  między Aktem-I-only (~46%) a darmową odbudową (~84% przy dopłacie +1/+2/+2).
  Akt II nadal realnie zabija. Pozostałe testy bez regresji.

### Meta-progresja: złote monety + ruletka klas + efektywny koszt na karcie (2026-06-19)

- **Efektywny koszt budowy na karcie.** `CardView.setup` dostał opcjonalny
  `cost_override` — w trybie „Budowanie" karta pokazuje teraz realny koszt
  (zniżka klasy + dopłata po BUM) wprost na liście, nie tylko w oknie
  potwierdzenia. Zgodne wstecznie (ręka/okolica/nagrody bez zmian).
- **Złote monety.** Za każdy WYGRANY run +1 złota moneta (`MetaState.gold_coins`).
  `GameManager._on_run_ended` nalicza i zapisuje; ekran wyniku pokazuje „+1 złota
  moneta!". Stan trwa między uruchomieniami — `MetaState` zapisuje się do
  `user://meta_state.tres` (`load_or_new`/`save`, `CACHE_MODE_IGNORE`).
- **Ruletka postaci.** Za 3 monety (`MetaState.SPIN_COST`) `GameManager.
  spin_roulette()` odejmuje monety, losuje 1 z jeszcze ZABLOKOWANYCH klas,
  odblokowuje ją i zapisuje. Menu główne: licznik monet, `OptionButton` z
  odblokowanymi postaciami (wybór = `selected_class_id`, używany przez
  `start_new_run`), przycisk „Ruletka postaci (3 monety)" + overlay z animacją
  slot-machine (miganie nazw → ląduje na wygranej). Wyłączony, gdy < 3 monet lub
  wszystko odblokowane.
- **3 nowe klasy** (`data/classes/`): Budowlaniec (−1 surowiec, +4 HP budowli,
  jedzenie −20%), Wojskowy (−1 obrażeń od potworów, +1 głodu/dzień, +1 energii
  budowy), Łowca (głód −1/dzień, jedzenie +20%). Modyfikatory wpięte w
  `survival_system`. Kucharz zawsze odblokowany; reszta z ruletki. `GameManager`
  ładuje cały `data/classes/` do `class_catalog`. (Talie: patrz wpis niżej.)
- Testy: `load` (4 klasy), `ui_layout`, `smoke`, `board`, `night_pool`, `fog`,
  `season` bez regresji. Menu/wynik/run — sceny z autoloadem, niesprawdzalne
  przez `-s`; ścieżki węzłów zweryfikowane z `.tscn`.

### Unikalne talie startowe klas (2026-06-19)

- Nowe klasy nie współdzielą już talii Kucharza — każda ma własną
  `data/decks/*_deck.tres` (9 kart akcji), spójną z modyfikatorami:
  - **Kucharz** (`starter_deck`): generalista/jedzenie (bez zmian — baza smoke).
  - **Budowlaniec** (`builder_deck`): Chrust→Ciesielka→Wytwórz narzędzia
    (bootstrap drewno→materiały) + Opatrz rany/Zbieractwo/Źródło/Odpoczynek/Eksploruj.
  - **Łowca** (`hunter_deck`): zwiad/eksploracja (Daleka wyprawa, Eksploruj,
    Zwiad×2) + 2× Zioła (pewne leczenie) + Zbieractwo/Źródło/Odpoczynek.
    Modyfikator sam ogarnia głód, więc talia NIE dubluje jedzenia (to zabijało
    pierwszą wersję — była 1/30).
  - **Wojskowy** (`soldier_deck`): tempo/regeneracja (Adrenalina, Uczta, Opatrz
    rany, Zioła) + Zbieractwo/Źródło/Odpoczynek/Zwiad/Eksploruj.
- `smoke_test` rozszerzony: po głównym przebiegu (Kucharz) gra `CLASS_SAMPLE=30`
  runów każdą klasą i wypisuje win-rate (sygnał balansu, nie twardy gate).
  Wynik: Budowlaniec ~77%, Kucharz ~70%, Łowca ~73%, Wojskowy ~57% — wariety
  bez złamanej klasy. Wojskowy najtrudniejszy (większy głód + bot psuje sobie
  grę adrenaliną; człowiek zagra wyżej). LEKCJA: klasa z modyfikatorem na dany
  zasób nie powinna dublować go w talii — lepiej dać jej brakujące narzędzia
  (leczenie/utility), inaczej karty są „martwe" i klasa pada po BUM.
- ZAPAS na przyszłość: po 1 sygnaturowej (unikalnej) karcie na klasę — wymaga
  nowych `ActionCardData` (+ ew. obsługi nowego `special`).

### Save/load + drabinka klas + 3 nowe klasy + 7 kart akcji (2026-06-19)

- **Save/load runu.** `RunState` (już `Resource` z `@export`) serializuje się do
  `user://run_save.tres` (`ResourceSaver`/`ResourceLoader`, karty/biomy/klasa jako
  ext-ref po ścieżce; `TileState`/`BuildingState` inline). `GameManager`:
  `save_run`/`has_saved_run`/`delete_saved_run`/`continue_run`; **autozapis na
  każdym świcie** (`day_started`), kasowanie zapisu przy `run_ended` i przy „Nowa
  gra". `SurvivalSystem.resume(state, ...)` odbudowuje niepersystowane pomocniki
  (pula nagród, katalog budowli, kandydaci nocnej puli) i wznawia od świtu dnia
  (postęp W TRAKCIE dnia nie jest zapisywany — granulacja per dzień). Menu:
  przycisk **„Kontynuuj"** (aktywny tylko gdy jest zapis). `tests/save_load_test.gd`
  sprawdza round-trip wszystkich pól + odbudowę systemu.
- **Drabinka klas (ruletka easiest→hardest).** `CharacterClassData.unlock_order`;
  `GameManager.spin_roulette()` odblokowuje teraz NAJŁATWIEJSZĄ jeszcze
  zablokowaną klasę (nie losową), a `unlocked_classes()` sortuje po order.
  Kolejność: Kucharz(0) → Budowlaniec(1) → Zielarka(2) → Łowca(3) → Strateg(4)
  → Wędrowiec(5) → Wojskowy(6).
- **Nowe pola modyfikatorów** (`CharacterClassData`, domyślne = brak zmian, wpięte
  w `survival_system`): `thirst_rate_delta`, `warmth_rate_delta`,
  `move_energy_delta` (`move_energy_cost()`), `bonus_hand_cards` (większa ręka),
  `daily_health_regen` (leczenie o świcie), `xp_multiplier`, oraz `start_food/
  water/wood/materials`.
- **3 nowe klasy z umiejętnościami:** Zielarka (regen +1 HP/świt, talia leków;
  apetyt +1), Strateg (+1 karta/świt, XP +25%; budowa +1 energii), Wędrowiec
  (darmowy ruch, start +2 jedz./+2 wody; +1 utraty ciepła/dzień). Każda z własną
  talią (`data/decks/*_deck.tres`).
- **7 nowych kart akcji** (`data/cards/actions/`): Bukłak (+3 wody), Suszone mięso
  (+2 jedz.), Bandaż (+3 zdr., 1 mat.), Otul się (+3 ciepła), Przekąska (+1 jedz.,
  0 energii), Rozejrzyj się (`explore`), Głęboki sen (+2 zdr.). Wchodzą do puli
  nagród awansu (27 kart) — bez generacji wood/materials (te zostają per-biom).
- Balans (smoke, 30 runów/klasa): Zielarka ~97% (najłatwiejsza, wczesny unlock) →
  Kucharz/Budowlaniec/Łowca/Wędrowiec ~77–80% → Strateg ~73% → Wojskowy ~53%
  (najtrudniejszy). Główny przebieg 37/50 (~74%). Lekcja powtórzona: nowa klasa z
  jedną kartą leczenia (pierwsze Łowca/Wędrowiec) pada po BUM — trzeba 2 źródła HP.
- Testy: cała ósemka zielona (`load` 7 klas, `save_load`, `ui_layout` 77 kart,
  `smoke`, `board`, `night_pool`, `fog`, `season`).

### Pre-wiring FX + 2. katastrofa (Zaćmienie) + specjale budynków (2026-06-19)

- **#1 Pre-wiring brakujących FX** (assety jeszcze nie istnieją — wszystko pod
  `ResourceLoader.exists`, więc zadziała plug-and-play po wrzuceniu PNG):
  - **Winieta krytycznego HP** (`run.gd _update_low_hp_vignette`): pulsująca
    czerwona ramka, gdy zdrowie ≤ 30% maks. (`fx/ui/fx_low_hp_vignette`).
  - **FX budynków** na bieżącym kaflu (`_spawn_tile_fx`): kurz przy postawieniu
    (`fx_build_place`, w `_on_build_confirmed`), iskry przy naprawie
    (`fx_repair_sparkle`), zawalenie przy rozbiórce (`fx_ruin_collapse`) — przyciski
    naprawy/rozbiórki owinięte lambdą. `_spawn_world_fx` dostał param `additive`.
  - **Ekran wyniku** (`result.gd _spawn_result_fx`): promienie przy wygranej
    (`fx_victory_rays`, additive) / mroczna mgła przy przegranej (`fx_defeat_haze`).
- **#2 Druga katastrofa: Zaćmienie** (`data/disasters/eclipse.tres`) — zimno/mrok
  jako kontra do Plagi. 3 potwory (`frost_wraith` 4/1, `shadow_crawler` 2/3,
  `ice_swarm` 1/1) + 4 zdarzenia Aktu II (`events/eclipse/`: eternal_frost,
  black_sun, whisper_dark, frost_bite — biją w ciepło/energię). BUM losuje teraz
  z 2 katastrof (`GameManager` skanuje katalog). ZNANE: animacja BUM i skażone
  twarze kafli są wspólne (plague-themed) — Zaćmienie różni się mechaniką
  (potwory/zdarzenia), nie wizualem flipa. Brak artu potworów (frame-only).
- **#3 Specjale budynków wpięte:** dodano lekkie **psucie jedzenia**
  (`DAILY_FOOD_SPOILAGE` 1/dzień powyżej 4 jedzenia; redukują je
  `spoilage_multiplier` Kucharza i **Spiżarnia** `slow_spoilage`). **Warsztat**
  (`unlock_crafting`) przerabia 1 drewno → 1 materiał co świt. `special` ustawione
  na `pantry`/`workshop`; `_count_special` + `_resolve_spoilage`.
- Balans: smoke 40/50 (~80%), Akt I 0 zgonów, Akt II ~10 — psucie jest delikatne
  (early bez zmian). 9 klas, 2 katastrofy, 7 potworów, 80 kart. Cała ósemka
  testów zielona.

### Wpięcie FX: pogoda / pazur / iskry / dym ruin (2026-06-19)

- Wpięte 4 efekty (każdy pod `ResourceLoader.exists`, więc działa na obecnych
  i na zregenerowanych assetach — plug-and-play):
  - **Pogoda sezonowa** (`run.gd _create_weather_overlay`/`_update_weather`):
    deszcz wiosną/jesienią, śnieg zimą, czysto latem. Subtelna warstwa nad
    scrimem a pod UI (nie zasłania popupów).
  - **Pazur potwora** (`_spawn_claw_flash`): additywny błysk `fx_claw_slash` nad
    nocną kartą, gdy wylosowano potwora (tuż po flipie).
  - **Iskry kart** (`_card_feedback_fx`/`_spawn_world_fx`): `fx_heal_spark` przy
    karcie z `health_delta>0`, `fx_resource_gain` przy karcie z zyskiem zasobu —
    pojawia się nad zagrywaną kartą (pozycja łapana przed odświeżeniem ręki).
  - **Dym ruin** (`biome_tile_view _add_ruin_smoke`): pętla `fx_smoke_loop` nad
    slotem zruinowanego budynku (Akt II); tweeny czyszczone w `_clear_slots`.
- Dołożone (2. tura): **mróz zimą** (`fx_frost_edges` — osobna winieta obok
  śniegu, `_make_ambient_overlay`/`_frost_overlay`) oraz na ruinach **ogień**
  (`fx_small_fire_loop`, additywny flicker) + **ślady wypalenia** (`fx_burn_marks`)
  obok dymu. Cały wygenerowany zestaw FX jest teraz wpięty; do generacji zostają
  tylko `fx/buildings/*`, `fx/ui/fx_low_hp_vignette`, `fx/result/*`.

### 2 nowe klasy (Skaut, Informatyk) + HP klas + losowa ruletka (2026-06-19)

- **Nowe pola `CharacterClassData`:** `health_bonus` (maks. HP gracza +/−) i
  `max_energy_bonus` (maks. energia/dzień). Wpięte w `survival_system.start()`
  (klamrowane do ≥1); start zasobów klamrowany do [0, cap].
- **Skaut (`scout`) — nowa klasa DOMYŚLNA** (`MetaState.STARTING_CLASS_ID` cook→
  scout; Kucharz wchodzi do puli ruletki). Forgiving starter: +1 HP, budowa −1
  surowiec, −1 pragnienia/dzień, start +2 mat.; jedzenie i potwory normalne.
  Talia: scavenge (materiały gdziekolwiek — sygnatura) + sustain (forage/dried_
  meat/find_water/rest/first_aid/herbs/woodcraft/scout).
- **Informatyk (`informatyk`) — najtrudniejsza klasa (challenge).** Same debuffy:
  −2 energii, +1 głodu/dzień, +1 obrażeń od potworów (`monster_damage_reduction
  = -1`), budowa +1 energii, −1 HP, start −1 jedz./−1 wody. „Dusza": szybko się
  uczy — XP +25% (comeback przez nagrody awansu).
- **HP klas (urozmaicenie):** Wojskowy +3 (twardziel — był najsłabszy, teraz
  realnie tankuje Akt II), Budowlaniec +1, Skaut +1, Informatyk −1.
- **Ruletka znów LOSOWA** (`spin_roulette` losuje z zablokowanych, nie po
  `unlock_order`). `unlock_order` zostaje tylko do sortowania listy w menu.
- Balans (smoke, 30 runów/klasa, n=30 więc ±szum): Zielarka ~100% > Skaut ~93%
  > Wędrowiec/Strateg ~83% > Kucharz/Łowca ~77% > Budowlaniec ~70% > Wojskowy
  ~50–65% > **Informatyk ~37% (najtrudniejszy, zgodnie z założeniem)**. Główny
  przebieg (Kucharz) 42/50. 9 klas total.

### Poduszka na start + metryka zgonów Akt I/II (2026-06-19)

- Diagnoza: `smoke_test` rozbija teraz zgony na **Akt I (przed BUM)** vs **Akt II
  (po BUM)**. Okazało się, że early game NIE jest przeciążony — ~93% zgonów bota
  to Akt II (przy 2/2 starcie: 1 zgon Akt I na 50 runów, dzień 5).
- Mimo to start bywał odczuwalnie ciasny dla człowieka (cienki margines + nauka),
  więc `RunState` startuje teraz z **3 jedzenia / 3 wody** (było 2/2). Bonusy klas
  (`start_food/water`) stackują się na wierzch.
- Efekt (smoke): zgony Akt I 1→**0**, Akt II 13→12 (bez zmian), win-rate 72→76%.
  Czysto early-game easing — Akt II nietknięty.
- Dodatkowo: deprywacja (głód/odwodnienie/mróz) w **Akcie I bije za −1 HP, po BUM
  za −2** (`_deprivation_damage()` wg `bum_happened`). Ocaleni wchodzą w BUM
  zdrowsi → smoke 76→80%, zgony Akt II 12→10. Akt II dalej jest ścianą.

### Wpięcie ilustracji zdarzeń nocnych (2026-06-19)

- 37/42 ilustracji zdarzeń (pixel art, GPT Image) dostarczone przez gracza
  przeniesione z roboczego `events/` (root) do
  `assets/art/cards/illustrations/events/` — `card_view`/`night_card_view`
  ładują je automatycznie po `<id>.png`, zero zmian w kodzie. Brak jeszcze:
  5 zdarzeń Plagi (plague_fever/infected_well/larvae/spores, rotting_supplies)
  + 2 skażone akcje (murky_water, tainted_hunt) — renderują się z samą ramką.

### Wygląd Aktu II zależny od katastrofy (2026-06-19)

- `_on_bum_struck` w `run.gd` używał już sygnatury `(disaster)`, ale ignorował
  typ — Akt II zawsze wyglądał jak Plaga. Dodano słownik `ACT2_LOOK` keyowany
  po `DisasterData.id` (fallback `plague`): per katastrofa scrim ekranu, kolor
  logu, tint tła planszy (`BackgroundArt.self_modulate`) i tint warstw korupcji
  animacji BUM (`ACT2_TINT_LAYERS` przez `self_modulate`, alfa nadal jedzie po
  `modulate.a`). **Plaga** = zgniła zieleń (jak dotąd, board `0.4,0.42,0.47`),
  **Zaćmienie** = lodowy granat (scrim niebieski, board chłodny `0.34,0.4,0.52`,
  warstwy FX tintowane `0.55,0.7,1.05`). `_on_bum_struck` ustawia `_act2_look`
  przed `_play_bum_fx`, więc i animacja, i końcowy stan ekranu są spójne.
- ZNANE: skażone twarze kafli (`biome_*_plague_bg`, `biome_corruption_overlay`)
  pozostają zielone dla obu katastrof — tint zapieczonego zielonego artu na
  niebiesko daje muliste teal; czeka na osobny art kafli Zaćmienia.
- **Omeny też zależne od katastrofy** (`survival_system.gd BUM_OMENS`): foreshadowing
  w logu od dnia 7 do BUM dobierany po `state.disaster.id`. Plaga = gnicie/martwe
  ptaki/zielona łuna (jak dotąd), Zaćmienie = blade słońce/lód na wodzie/chłód.
  Fallback do plague. Dzięki temu Zaćmienie czyta się chłodno i przed (omeny),
  i po (ekran) BUM.
- Weryfikacja: `--import` + `load_test` OK (zmiany w `run.gd` UI i `survival_system`
  omeny).

### Nocny popup: rozliczenie dopiero po „OK" (2026-06-20)

- Realizacja decyzji projektowej z README: zdarzenie nocne nie rozlicza się już
  „w tle" w trakcie pokazu karty. `SurvivalSystem.end_day()` rozbity na dwie fazy:
  - `end_day()` — odrzuca rękę, DOBIERA nocną kartę z puli i ogłasza ją
    (`night_card_drawn`), ale NIC nie aplikuje; ustawia `_night_pending` +
    `_pending_night_card`.
  - `resolve_night()` — pasywy budynków → efekt karty (potwór/zdarzenie) →
    potrzeby (`_resolve_needs`) → `stats_changed` → śmierć/wygrana/awans dnia.
    Wołane po akceptacji popupu, więc gracz widzi kartę ZANIM ruszą się statystyki.
    Idempotentne per `end_day()`.
- `run.gd`: przycisk „OK" (`_on_night_continue`) chowa popup i woła `resolve_night()`.
  Przycisk jest WYŁĄCZONY do końca animacji odsłonięcia (`_night_tween.finished`),
  więc kara/nagroda nigdy nie spadnie zanim karta zostanie przeczytana.
- Headless (bot/`season_test`) woła `resolve_night()` zaraz po `end_day()` —
  przepływ pozostaje synchroniczny. Smoke bez regresji (43/50, ~86%, Akt I 0 zgonów,
  Akt II 7). `--import` + `season`/`save_load`/`night_pool`/`ui_layout`/`fog`/`board` OK.
- ZNANE/ZAPAS: popup pokazuje samą kartę; dedykowane „podsumowanie nocy" (lista
  konkretnych delt na overlayu po OK) wciąż do dorobienia — efekty trafiają do logu.

### Sygnaturowe karty klas (2026-06-20)

- Każda z 9 klas dostała 1 UNIKALNĄ kartę akcji oddającą jej tożsamość
  (`data/cards/actions/signature/*.tres`). Podkatalog `signature/` NIE jest
  skanowany przez pulę nagród (`CardLibrary.load_resources_from_dir` używa
  `get_files()` bez rekursji — jak `corrupted/`), więc sygnatury są dostępne
  WYŁĄCZNIE w talii startowej swojej klasy, nie wpadają do nagród awansu innych.
- Złożone z istniejących pól/`special` (zero nowej logiki w systemie):
  - Kucharz „Sycący gulasz" (2 jedz.→ +6 sytości/+2 ciepła/+1 zdr.),
    Budowlaniec „Prefabrykaty" (2 drewna→ +3 mat.), Zielarka „Maść z ziół"
    (+4 zdr./+1 sytości), Łowca „Tropy zwierzyny" (`double_explore`),
    Strateg „Plan dnia" (`draw_two`, 0 energii), Wędrowiec „Skrytka wędrowca"
    (+2 jedz./+2 wody), Wojskowy „Wojskowy dryl" (+2 energii/+1 ciepła, netto +1E),
    Skaut „Rozpoznanie" (`explore` + 1 mat.), Informatyk „Refaktoryzacja"
    (`draw_two` + 1 energii — „dusza"/comeback challenge-klasy).
- Wpięte przez PODMIANĘ 1 fillera w każdej talii (deck zostaje 9 kart): cook
  swap forage, builder/herbalist/soldier swap explore, hunter swap forage,
  informatyk swap dried_meat, nomad/planner swap survey, scout swap woodcraft.
- Balans (smoke): główny przebieg 43→**46/50** (~92%), per-klasa wszystkie w
  górę (sygnatura = czysta korzyść, zgodnie z założeniem „definiująca siła"):
  Zielarka 30, Strateg 29, Budowlaniec/Kucharz/Łowca 27, Skaut 26, Informatyk 23,
  Wojskowy 21, Wędrowiec 20 (swap survey→cache zabrał botowi losowe nagrody
  explore; dla człowieka pewny zysk). Spread 20–30/30 zachowany, drabinka nie
  złamana. `load`/`ui_layout` (80 kart) OK. Pula nagród nietknięta (27 akcji).
- ZNANE: sygnatury bez ilustracji — renderują się ramką+tekstem (`card_view`
  fallback `action_<id>.png`); art opcjonalny (kosmetyka).

### Dwa nowe biomy: Bagno i Rzeka (2026-06-20)

- Pula biomów 3→**5** (plansza wciąż 6 kafli: każdy biom ≥1× + losowe powtórki).
  `GameManager` ładuje cały `data/biomes/`, więc nowe `.tres` same wchodzą do puli.
- **Bagno** (`swamp`, 2 sloty): zbieranie woda+jedzenie (`find_water`+`forage`),
  hazardy „Bagienna febra" (-2 zdr.) i „Bagienne wyziewy" (-1 zdr./-1 energii jutro);
  rewers „Trujące Mokradła" (scavenge + skażone murky_water/tainted_hunt + sickness).
- **Rzeka** (`river`, 3 sloty): zbieranie woda+ryby (`find_water`+`fishing`),
  hazardy „Wezbrana rzeka" (-2 ciepła/-1 zdr., schronienie chroni) i „Rzeczna mgła"
  (-1 energii jutro); rewers „Czarna Rzeka" (scavenge + murky_water + sickness).
- 4 nowe karty zdarzeń biomowych w `data/cards/events/biome/` (ważone/cooldown/
  severity/tagi jak reszta puli; aktywne dopiero po odkryciu biomu — fog of war).
  Reszta kart reużyta z istniejących (zero nowych akcji zbierania).
- `ui/biome_tile_view.gd BIOME_ART_IDS` rozszerzony o `swamp`/`river`. BRAK teł —
  `_background_path` ma fallback do lasu, więc biomy są GRYWALNE od razu, tylko
  wyglądają jak las do czasu wygenerowania 4 PNG (swamp/river × normal/plague,
  1536×1024, pixel-art jak istniejące tła).
- Balans: smoke **47/50** (~94%, Akt I 0 zgonów, Akt II 3) — biomy nie psują
  trudności. `load` (5 biomów)/`board` (200 plansz)/`night_pool`/`ui_layout`
  (5 biomów)/`season`/`fog`/`save_load` bez regresji.

### Jeszcze 3 biomy: Pustkowie, Jaskinie, Wybrzeże (2026-06-20)

- Pula biomów 5→**8** (plansza 6 kafli losuje z rotacją — nie każdy biom co run,
  większa regrywalność). Każdy z odrębnym profilem zasobów:
  - **Pustkowie** (`wasteland`, 3 sloty): materiały+jedzenie (`scavenge`+`forage`),
    hazardy „Burza piaskowa" (-1 zdr./-1 energii jutro) i „Jałowa ziemia" (-2 syt.);
    rewers „Spopielone Pustkowie".
  - **Jaskinie** (`caves`, 2 sloty): materiały+woda (`scavenge`+`find_water`),
    hazardy „Obsuw skalny" (-2 zdr.) i „Nieprzenikniona ciemność" (-1 energii jutro);
    rewers „Zatrute Jaskinie".
  - **Wybrzeże** (`coast`, 3 sloty): ryby+złom (`fishing`+`scavenge`), hazardy
    „Sztorm" (-2 ciepła/-1 zdr., schronienie chroni) i „Przypływ" (-1 energii jutro);
    rewers „Martwe Wybrzeże".
- 6 nowych zdarzeń biomowych (`events/biome/`), reszta kart reużyta. `BIOME_ART_IDS`
  rozszerzony o `wasteland`/`caves`/`coast` — BRAK teł (6 PNG), fallback do lasu.
- Balans: smoke **41/50** (~82%, Akt I 0 zgonów, Akt II 9) — nowe hazardy +
  uboższe zasoby Pustkowia/Jaskiń lekko dokręciły trudność (świadomy efekt
  różnorodności). Cała ósemka testów (`load` 8 biomów/`board`/`ui_layout`/
  `night_pool`/`fog`/`season`/`save_load`/`smoke`) zielona.

### Marker kafla per postać (2026-06-20)

- Znacznik bieżącego kafla (dotąd jeden uniwersalny medalion `biome_current_player`)
  zmienia się teraz wg granej klasy. `BiomeTileView` ma `static var _marker_path`
  + `set_marker_for_class(class_id)` (szuka `assets/art/characters/marker_<id>.png`,
  fallback do uniwersalnego, gdy brak). `run.gd._ready` woła to raz na starcie
  z `state.character_class.id`, przed budową kafli. Oba miejsca renderujące marker
  używają `_marker_path`.
- ✅ **9 markerów wygenerowanych** (`assets/art/characters/marker_<id>.png`,
  2026-06-20): medaliony w stylu `biome_current_player` z twarzą postaci + cechą
  (5 kobiet: scout/herbalist/hunter/planner/nomad, 4 mężczyzn: cook/builder/
  soldier/informatyk). Dostarczone na solid blue → `chroma_key_blue.gd` (przezroczyste,
  ~580k px/medalion, krawędzie czyste) → `--import`. Każda klasa ma teraz swój
  medalion na bieżącym kaflu.

### Ekran ustawień (2026-06-20)

- Dotąd gra nie miała ŻADNYCH ustawień. Dodany lekki system `scripts/settings.gd`
  (`class_name Settings`, static-only): zapis/odczyt `user://settings.cfg`
  (`ConfigFile`) + aplikacja do `DisplayServer`/`AudioServer`.
- Ustawienia: **Pełny ekran** (`window_set_mode`), **VSync** (`window_set_vsync_mode`),
  **Głośność główna** (suwak 0–100% → `AudioServer` bus „Master", mute przy 0).
  `GameManager._ready()` woła `Settings.load_and_apply()` raz na starcie, więc
  wybory działają od następnego uruchomienia.
- UI: przycisk **„Ustawienia"** w menu (nad „Wyjdź") otwiera overlay
  (`SettingsOverlay`, wzorowany na ruletce) z CheckButtonami + suwakiem; każda
  zmiana od razu aplikuje się i zapisuje (`Settings.set_*`). Kontrolki synchronizują
  się z zapisanym stanem przy otwarciu (`set_*_no_signal`).
- ZAPAS: gra nie ma jeszcze dźwięku, więc suwak głośności steruje busem „Master"
  na zapas (gotowe pod przyszłe audio). Brak innych ustawień (rozdzielczość/język)
  — do dołożenia gdy zajdzie potrzeba.

### Menu pauzy (Esc) + reużywalny panel ustawień (2026-06-20)

- Panel ustawień wydzielony do reużywalnego komponentu `ui/settings_overlay.tscn`
  + `ui/settings_overlay.gd` (`class_name SettingsOverlayView`): self-contained,
  `open()` synchronizuje kontrolki ze stanem `Settings` i pokazuje, sygnał `closed`
  na OK. Menu główne korzysta teraz z instancji tego komponentu (inline overlay
  usunięty — DRY).
- **Menu pauzy w grze:** `run.gd._unhandled_input` łapie `ui_cancel` (Esc) i
  przełącza `PauseOverlay` (Wznów / Ustawienia / Wróć do menu). Esc przy otwartych
  ustawieniach wraca do pauzy; przy otwartym modalu nocy/awansu Esc jest ignorowane
  (te modale mają priorytet). „Wróć do menu" = `GameManager.return_to_menu` (run jest
  już zapisany autozapisem o świcie → „Kontynuuj" działa). Ustawienia dostępne też
  w trakcie runu (ta sama instancja komponentu w `run.tscn`).
- Weryfikacja: `--import` 0 błędów, `settings_overlay`/`main_menu`/`run` `.tscn`
  `can_instantiate=true`, `load`/`ui_layout`/`smoke` (44/50) bez regresji.
- Weryfikacja: `--import` (rejestracja `Settings`, 0 błędów), `main_menu.tscn`
  `can_instantiate=true`, `load`/`ui_layout` bez regresji. (Menu z autoloadem
  niezmienialne przez `-s` — zgodnie z normą projektu.)

### Minimalistyczny skin przycisków dla menu/wyniku/pauzy (2026-06-20)

- Ozdobna skórka przycisków (`button_theme_act1` — złota rama z winoroślą) pasuje
  do gęstej planszy runu, ale gryzła się z czystym menu i ekranem wyniku. Dodano
  `ButtonSkin.apply_minimal()`/`apply_minimal_many()` — płaski `StyleBoxFlat`:
  ciemne półprzezroczyste tło + cienka (2px) złota ramka + złoty tekst, jaśnieje
  przy hover; bez focus-ringa (`StyleBoxEmpty`). Zero nowego artu.
- Reguła stylu: **menu-like = minimal** (main menu, result, menu pauzy, OK ustawień),
  **gameplay na planszy = ozdobne** (Koniec dnia, Budowanie, naprawa/rozbiórka,
  nocne „Dalej", nagrody awansu — bez zmian). `apply_minimal` (instance override)
  wygrywa nad `button_theme_act1` z `.tscn`, więc nie trzeba ruszać scen.
- Weryfikacja: `--import` 0 błędów, 4 sceny `can_instantiate=true`, `ui_layout` OK.

### Sekcja Postacie + hover umiejętności + fix menu (2026-06-20)

- **Fix menu:** po dodaniu „Ustawienia" VBox menu przekraczał 720 px i wystawał poza
  ekran. Przyciski 100→64 px, separacja 16→12; mieści 6 pozycji z zapasem.
- **`CharacterClassData.ability_summary()`** — generuje czytelną listę buffów PL
  („• ...") z pól modyfikatorów (jeden wspólny opis dla menu i runu). Puste, gdy
  klasa nie ma modyfikatorów.
- **Sekcja „Postacie"** (przycisk w menu → overlay `CharactersOverlay`): galeria
  ODBLOKOWANYCH klas budowana w kodzie — medalion (`marker_<id>.png`) + nazwa +
  opis + buffy z `ability_summary()`. To realizuje pomysł „kart postaci"
  (medalion + opis buffów) bez osobnego `CardView`.
- **Hover w runie:** marker bieżącego kafla ma `tooltip_text` = nazwa klasy +
  umiejętności; `mouse_filter = PASS`, więc kafel nadal łapie kliknięcia.
  `BiomeTileView.set_marker_for_class()` przyjmuje teraz całą `CharacterClassData`
  (ścieżka medalionu + tooltip), `run.gd` przekazuje `state.character_class`.
- Weryfikacja: `--import` 0 błędów, sceny `can_instantiate=true`, `load`/`ui_layout`
  OK, podgląd `ability_summary` dla 4 klas poprawny.

### Balans Aktu II + ruletka z portretami + widoczne wyjście (2026-06-20)

Na podstawie feedbacku z gry:
- **Drewno w Akcie II:** skażony Las (`forest.tres` corrupted) nie dawał drewna →
  po BUM nie było jak naprawiać/budować. Dodano `gather_wood` do skażonych akcji
  Lasu (martwy las = martwe drewno). Drewno znów dostępne (w Martwym Lesie).
- **Ocalenie budynków po BUM:** było 60–80% obrażeń przy progu ruiny 50% →
  GWARANTOWANA ruina wszystkiego (0% szans). Zmienione na **35–80%** → budynek
  przeżywa, jeśli oberwie ≤50% (~**35% szans/budynek**), więc zwykle część
  zostaje. To nie był pech — wcześniej było 0%.
- **Więcej potworów:** wchodziły do puli z wagą = `copies_in_deck` (~2) vs zdarzenia
  ~10 → rzadkie. `NightEventPool.PHASE_CATEGORY_MULT[ACT2]` dostał `"monster": 3.0`
  → noce z potworami ~potrojone (≈5%→~14% nocy). Łatwo dostroić jedną liczbą.
- Balans (smoke): 48/50 (bot korzysta z ułatwionej ekonomii; świadomy gracz dostaje
  więcej zagrożeń od potworów). `night_pool`/`board`/`ui_layout`/`load` OK.
- **Ruletka z portretami:** overlay ruletki ma `RoulettePortrait` — `_animate_spin`
  miga medalionami (`marker_<id>.png`) razem z nazwami i ląduje na wylosowanej.
- **Widoczne wyjście do menu:** pauza była tylko pod Esc (mało odkrywalna). Dodano
  przycisk **„Menu (Esc)"** w kolumnie przycisków runu (nad „Budowanie") otwierający
  ten sam `PauseOverlay` (Wznów / Ustawienia / Wróć do menu).

### Nazwa docelowa + fix kodowania + ruletka tylko z zablokowanych (2026-06-20)

- **Nazwa gry → „Dzień 50"** (tytuł docelowy): `project.godot config/name` i tytuł
  w menu (`DZIEŃ 50`). Wcześniej „Karcianka: Przetrwanie" (robocza).
- **Fix „brak polskich znaków":** trzy placeholdery w scenach miały mojibake
  (UTF-8 zinterpretowane jako Latin-1) — naprawione: `run.tscn` tytuł awansu
  („nagrodÄ™"→„nagrodę", „â€”"→„—"), `top_status_bar_view.tscn` („SytoĹ›Ä‡"→
  „Sytość", „MateriaĹ‚y"/„NarzÄ™dzia"→„Materiały"/„Narzędzia"). To były domyślne
  teksty nadpisywane w kodzie, ale w plikach były błędne. Audyt: 0 mojibake w repo.
- **Ruletka losuje tylko z ZABLOKOWANYCH:** `_animate_spin` migał wszystkimi
  klasami; teraz `_on_roulette_pressed` łapie pulę zablokowanych PRZED losowaniem
  (`_locked_classes()`) i bęben miga tylko kandydatami (medalion + nazwa), lądując
  na wygranej. (`spin_roulette` i tak losował tylko z zablokowanych — to fix
  wizualny bębna.)
- Weryfikacja: `--import` 0 błędów, `main_menu` `can_instantiate=true`.

### Run do 50 dni + gating budynków + różnice katastrof + crank (2026-06-21)

- **Run do dnia 50** (`WIN_DAY 30→50`): BUM dzień 22–27 (było 13–16), omeny od dnia 16,
  sezony przeskalowane (wiosna ≤13, lato ≤25, jesień ≤38, zima reszta). `season_test`
  i podtytuł menu zaktualizowane.
- **Gwarantowany Las + Góry** na każdej planszy (`BoardGenerator.GUARANTEED_BIOME_IDS`)
  → drewno i materiały zawsze osiągalne, reszta 4 kafli losowo z puli 8.
- **Budynki gated po odkryciu biomu** (`BuildingCardData.required_biome_ids`, pusty =
  zawsze): Port rybacki→rzeka/wybrzeże, Drwalnia→las, Kamieniołom→góry/jaskinie,
  Farma→łąki, Filtr→rzeka/bagno/wybrzeże, Zielarnia→łąki/las/bagno. `can_build`
  blokuje z komunikatem „Wymaga odkrycia: ..." dopóki żaden wymagany biom nie jest
  odkryty. Bazowe budynki (ognisko/szałas/studnia/palisada/magazyny/warsztat) zawsze.
- **Mechaniczne różnice katastrof** (`DisasterData.act2_*` + `_act2_rule`): nie tylko
  kolor/obrażenia. **Plaga** = wojna o jedzenie (Akt II: +2 głodu/dzień, +2 psucia),
  **Zaćmienie** = wojna o ciepło/energię (Akt II: +3 utraty ciepła, −2 energii/dzień).
  Reguła logowana przy BUM (`act2_rule_text`).
- **Dokręcenie trudności:** potwory w Akcie II ×6 (waga kategorii), deprywacja po BUM
  bije za +1 (Akt I −1, Akt II +1 = realna kara za wyzerowanie statu). Smoke
  96%→**74%** (37/50), zgony Akt II 2→13 — Akt II to teraz ściana (Informatyk 23%
  najtrudniejszy, Zielarka/Wojskowy easy by design). Cała ósemka testów zielona.

### Prognoza nocy + ekran-budzik + bogate podsumowanie (2026-06-21)

- **Prognoza końca dnia** (`SurvivalSystem.end_of_day_forecast()` + `run.gd
  _update_forecast`): etykieta w kolumnie przycisków pokazuje nocne spadki
  (Sytość/Nawodnienie z uwzgl. klasy/sezonu/katastrofy) + zapasy + NETTO ciepła
  (pasywne ciepło budynków minus spadek). Koniec liczenia w głowie.
- **Zakończenie jako sen (budzik):** `result.gd` — wygrana = „Sobota, 10:00,
  budzisz się wyspany", przegrana = „Poniedziałek, 5:00, budzik wyrywa z koszmaru"
  + hook alarmu (`assets/audio/sfx/alarm_clock.ogg`, `ResourceLoader.exists`).
- **Bogaty ekran końcowy** (`SurvivalSystem.run_summary()` → `GameManager.
  last_run_summary`): przyczyna śmierci (śledzona w `_record_damage`: Głód/
  Odwodnienie/Mróz/Atak: <potwór>), katastrofa+dzień BUM, poziom, łączne obrażenia,
  budynki stojące/ruiny, **sparkline zdrowia** (▁▂▃ per świt) i **seed runu**.
- Weryfikacja: `--import` 0 błędów, 3 sceny `can_instantiate=true`, `ui_layout`/
  `save_load`/`smoke` (39/50) bez regresji.

### Wybory nocne + tutorial + narzędzia Aktu II + zwiad + sezony (2026-06-21)

- **Zdarzenia z wyborami** (`EventChoiceData` + `EventCardData.choices`): nocny popup
  pokazuje przyciski decyzji zamiast samego „Dalej"; wybrana opcja aplikuje swoje
  efekty (deltas/gains/`grant_random_card`), opcje ryzykowne mogą się „odwrócić"
  (`risk_chance`/`risk_health` → zamiast łupu obrażenia). `resolve_night(choice)`,
  headless bierze indeks 0. Karty bazowe puste = działają jak dotąd. Pierwsze:
  **Obcy wędrowiec** (nakarm/przegoń/okradnij) i **Opuszczony obóz** (bezpiecznie/
  ryzyko). Przyciski odblokowują się po animacji odsłonięcia (jak „Dalej").
- **Tutorial** (`ui/help_overlay.tscn` `HelpOverlayView`, 5 stron): przycisk „Jak grać"
  w menu + AUTO-pokaz przy pierwszym uruchomieniu (`MetaState.seen_tutorial`).
- **Pozytywne narzędzia Aktu II** (`BuildingCardData.act2_only`): budynki dostępne
  TYLKO po BUM i BEZ dopłaty post-BUM (`_has_post_bum_surcharge`) — realna ścieżka
  „odbuduj inaczej". Dodane: **Bastion** (obrona 3, 16 HP) i **Lazaret polowy**
  (+2 zdrowia/dzień).
- **Karty zwiadu odkrywają teren** (`special = "scout_reveal"`): „Rozejrzyj się"
  odsłania losowy sąsiedni NIEodkryty kafel bez wchodzenia — info, ale aktywuje
  jego nocne zagrożenia (ryzyko vs wiedza). `scout` zostaje dobieraniem kart.
- **Sezony zmieniają zbieranie:** zima tnie każdy zbiór surowca o 1
  (`WINTER_GATHER_PENALTY`) — obok istniejącej zwiększonej utraty ciepła zimą.
- Weryfikacja: `--import` 0 błędów, sceny `can_instantiate=true`, cała ósemka +
  smoke (39/50) bez regresji; `ui_layout` 83 karty.

### Tła ekranu końcowego (POV łóżko) + więcej zdarzeń z wyborami (2026-06-21)

- **Tła wyniku POV** (`result.gd` WIN_BG/LOSE_BG, pod `ResourceLoader.exists`):
  ekran końcowy pokazuje widok z łóżka na budzik — wygrana = słoneczny poranek
  10:00, przegrana = ciemny pokój 05:00. Pliki:
  `assets/art/backgrounds/result/result_{win,lose}_bed.png` (gdy brak — flat tło).
- **Więcej zdarzeń z wyborami** (2→**5**): + Dzikie zwierzę (poluj/przepłosz),
  Dziwne jagody (zjedz/zachowaj/wyrzuć), Hałas w ciemności (zbadaj/zabarykaduj/
  zignoruj). Smoke 36/50 (bot zawsze bierze opcję 0 = ryzykowną; świadomy gracz
  wybiera bezpiecznie). `ui_layout` 86 kart, reszta testów OK.

### 2 nowe katastrofy + Akt II + więcej wyborów + fix prognozy (2026-06-21)

- **Fix layoutu:** prognoza nocy rozpychała kolumnę przycisków → ekran runu się
  skrolował. Przeniesiona do PANELU DZIENNIKA (pasek pod logiem, stała wysokość) —
  koniec skrolowania. Format skrócony.
- **2 nowe katastrofy → 4 łącznie** (`rift` Pęknięcie, `flood` Powódź), każda
  z 3 potworami + 3 zdarzeniami Aktu II + WŁASNĄ regułą Aktu II + kolorem
  (`ACT2_LOOK`: rift = piaskowy brąz, flood = mętny błękit) + omenami. Pęknięcie:
  −2 energii / większe pragnienie; Powódź: −2 ciepła / +psucie. BUM losuje z 4.
  Rozróżnienie katastrofy = kolor ekranu + omeny (od dnia 16) + komunikat reguły
  przy BUM (`act2_rule_text`).
- **Akt II grubszy:** +2 budynki `act2_only` (Wzmocniony schron — ochrona nocna +
  ciepło; Cysterna — woda) → 4 łącznie; +2 potwory Zaćmienia (Mroźny ogar,
  Zamieć) → Zaćmienie ma teraz 5 potworów. Potwory `rift`/`flood`/nowe Zaćmienia
  są frame-only (art do wygenerowania).
- **Zdarzenia z wyborami 5→9:** Stary pustelnik, Zakopana skrytka, Zapędzony
  szabrownik, Zmarznięty podróżny (cel docelowy ~18 — do kontynuacji).
- **Tła ekranu końcowego (POV łóżko)** wpięte pod `ResourceLoader.exists`
  (`result_{win,lose}_bed.png`).
- Balans: smoke **28/50** — UWAGA: zaniżone, bo bot ZAWSZE bierze wybór nr 0
  (często ryzykowny); świadomy gracz wybierający bezpiecznie wygrywa wyraźnie
  więcej. 4 katastrofy = duży skok regrywalności (Akt II inny co run). Cała
  ósemka testów zielona, `ui_layout` 100 kart.

### Dopieszczenie zdarzeń z wyborami: UI + podsumowanie (2026-06-21)

- **Przyciski wyboru** zmienione z ozdobnej ramki kwiatowej na **minimalny styl**
  (`ButtonSkin.apply_minimal`) + `autowrap` + mniejszy font (14) — tekst się mieści.
- **Podsumowanie po wyborze:** klik opcji NIE rozlicza od razu nocy. `SurvivalSystem.
  apply_night_choice(i)` aplikuje pasywy + wybór (z rzutem ryzyka) i zwraca tekst
  wyniku (np. „Nie udało się! −3 zdrowia." albo „(+3 materiałów, +2 jedzenia)").
  Popup pokazuje wynik + przycisk „Dalej", który dopiero domyka noc
  (`resolve_night()` pomija już rozliczony wybór dzięki `_night_choice_done`).
  Headless/bot bez zmian (woła `resolve_night()` wprost). `run.tscn` `can_instantiate`
  OK, smoke 36/50, `ui_layout` 100 kart.

### Wpięcie 26 ilustracji + system audio (2026-06-22)

- **Obrazy:** 8 potworów (rift/flood/nowe Zaćmienia) + 4 budynki Aktu II + 14 zdarzeń
  wygenerowane przez gracza, wrzucone i zaimportowane — wpięte automatycznie
  (ścieżki = `id`). Gap-check: 0 braków. Tła ekranu wyniku (POV łóżko) też są.
- **AudioManager** (autoload, `scripts/audio_manager.gd`): jeden gracz muzyki (bus
  Music) + pula 6 głosów SFX (bus SFX). `play_music(key)` / `play_act2_music(id)` /
  `stop_music()` / `play_sfx(key)` — wszystko keyowane i pod `ResourceLoader.exists`,
  więc gra działa w ciszy bez plików i zaczyna grać po ich wrzuceniu (zero kodu).
  Muzyka loopuje (`stream.loop`).
- **Busy audio** (`default_bus_layout.tres`): Master → Music + SFX. `Settings` ma
  teraz `music_volume`/`sfx_volume` (zapis do `settings.cfg`, aplikacja do busów);
  panel ustawień zyskał suwaki **Muzyka** i **Efekty (SFX)** obok Głośności głównej.
- **Haki w grze:** muzyka menu / Akt I / Akt II per katastrofa / wygrana; SFX: BUM,
  budowa, atak potwora, awans, odkrycie kafla, jedzenie/picie, moneta, budzik
  (przegrana, przez bus SFX). Plik `assets/audio/LICENSES.txt` = spis oczekiwanych
  nazw plików + szablon licencji (CC0/komercyjne) pod bezpieczne wydanie.
- Weryfikacja: `--import` 0 błędów, 4 sceny `can_instantiate=true`, `ui_layout`
  (100 kart) + `smoke` (34/50) bez regresji.

### Warstwa ambientu natury pod muzyką (2026-06-22)

- `AudioManager` ma teraz osobną, zapętloną warstwę AMBIENTU (drugi gracz na busie
  Music): `play_ambience(key)`/`stop_ambience()` + słownik `AMBIENCE`
  (`ambience_forest.ogg` Akt I, `ambience_act2.ogg` Akt II). Gra POD muzyką — bo
  prawdziwy las/ptaki to nagrania natury (CC0), nie Suno. `run.gd` gra `forest`
  w Akcie I i przełącza na `act2` przy BUM; menu/wynik robią `stop_ambience()`.
  `assets/audio/ambience/` + wpis w `LICENSES.txt`. Pod `ResourceLoader.exists`.

### Audio wpięte — pliki gracza posprzątane (2026-06-22)

- Gracz wrzucił muzykę/ambient/SFX (Suno, `.wav`). Porządki: nowszy „Przebudzenie
  (wygrana)" → `music_win.wav` (usunięty duplikat); `AudioManager.SFX` przepięty na
  PODFOLDERY gracza (`sfx/cards|bum|monsters|day_cycle|ui/`); `eat`/`drink` rozdzielone
  na 2 klucze, `run.gd _on_needs_consumed` gra wg tego, co spożyto. Ambient ma 4
  warianty Aktu II (eclipse/flood/rift + generic; Plaga → fallback generic).
- Stan: muzyka (act1/menu/win + 4×act2) ✅, ambient (forest + 4×act2) ✅, 11 SFX ✅.
  BRAK (opcjonalne): `sfx/ui/coin.wav` (cisza przy nagrodzie monety) i
  `ambience_act2_plague` (gra generyczny `ambience_act2`). `--import` 0 błędów.

### Meta-progresja i dokumentacja stanu (2026-06-22)

- Przywrócono produkcyjny koszt ruletki: `MetaState.SPIN_COST = 3`.
- `MetaState.save/load_or_new` i `GameManager.spin_roulette` przyjmują opcjonalną
  ścieżkę zapisu, dzięki czemu testy nie dotykają prawdziwego `user://meta_state.tres`.
- Dodano `tests/meta_progression_test.gd`: brak losowania bez monet, koszt 3,
  dokładnie jedno odblokowanie, blokada po zebraniu wszystkich klas i save/load.
- README oraz `docs/INWENTARZ.md` przepisano pod faktyczny stan: run do dnia 50,
  8 biomów, 19 budynków, 15 potworów, 4 katastrofy, 9 klas i 9 testów.
- Weryfikacja: pełny zestaw 9 testów zielony; smoke 31/50, wszystkie zgony po BUM.

### Naprawa odtwarzania audio na Windows/WASAPI (2026-06-22)

- Przyczyna kompletnej ciszy muzyki/ambientu: `_set_loop()` włączał pętlę WAV,
  ale pozostawiał domyślne punkty `0..0`. Prawdziwy sterownik WASAPI zatrzymywał
  taki zerowy loop natychmiast (Dummy w headless myląco zostawiał `playing=true`).
- AudioManager ustawia teraz `loop_end` na pełną długość WAV.
- Wszystkie zwykłe `BaseButton` dostają automatycznie SFX kliknięcia, a `CardView`
  używa `card_play`; dopięto też brakujący SFX naprawy i +3 dB gain dla efektów.
- Dodano `tests/audio_test.gd`: katalogi, brakujące opcjonalne pliki, busy,
  ładowanie streamów i start muzyki/SFX. Test na realnym WASAPI przeszedł.
- Weryfikacja regresji: pełny zestaw 10 testów zielony; smoke 33/50.

### Muzyka WAV → OGG Vorbis przed demem (2026-06-23)

- Siedem utworów z `assets/audio/music/` przekonwertowano przez FFmpeg 8.1.1
  do OGG Vorbis `q=6`; nazwy bazowe bez zmian, więc AudioManager automatycznie
  wybiera OGG przed WAV.
- Łączny rozmiar muzyki spadł z 123,46 MB do 12,13 MB (−90,2%).
- Czasy wszystkich utworów są identyczne z WAV co do 0,001 s.
- OGG przeszły `audio_test` zarówno headless, jak i na prawdziwym WASAPI.
- Źródłowe WAV-y muzyki usunięto; ambient i krótkie SFX pozostają w WAV.

### Feedback z dema — runda 1 (odtworzona po cofnięciu) (2026-06-24)

Poprzedni chat cofnął te zmiany — odtworzone, plus nowy format opisu:
- **Opis karty = flavor + linia efektów** (`card_view._effects_summary`): linia 1 to
  krótki flavor (pole `description`, BEZ liczb), linia 2 to efekty GENEROWANE z danych
  (zawsze dokładne, spójne nazwy). Format jak prosił gracz: „Rozejrzyj się i zaplanuj
  dzień / +2 karty do ręki". Flavory akcji+budynków (57) przepisane na czyste przez
  `tools/set_flavors.gd` (ResourceSaver). Budynki dodają „Wytrzymałość: N HP".
- **Ognisko grzeje** — `warmth_delta` 2→4. **Twardy cap energii = 10** (usunięty
  overflow w 3 miejscach). **Zablokowane budynki ukryte** (`available_buildings()` —
  Kamieniołom dopiero po Górach, Akt II po BUM). **BUM 14–18** (omeny od dnia 8).
- `tools/dump_cards.gd`: kolumny „Opis (fabularny)" + „Co robi". Smoke ~33→**28/50**.
  Cała ósemka zielona.

### Feedback z dema — runda 2: zacisk ekonomii + biomowość (2026-06-27)

Skarga graczy: „ekonomia za mocna, w dniu ~10 cała baza zbudowana, pasywy
pokrywają potrzeby → nudne dojechanie do BUM" + „jagody/znaleziska lecą na
każdym biomie, mało kart skażonych". Diagnoza botem (baseline smoke): bot NIE
przegrywa przez mocną ekonomię — ginie w 100% w Akcie II (Akt I 0 zgonów). Czyli
„za mocna ekonomia" to problem TEMPA Aktu I (brak decyzji po dniu 10), nie
wygrywania. Cel: rozciągnąć rozbudowę do BUM, utrzymując regułę „Akt I ~0 zgonów".

- **Droższe budynki (zwł. materiały — najrzadszy zasób).** Podbite koszty 11
  budynków „dywanujących planszę": Farma, Zielarnia, Kamieniołom, Warsztat,
  Drwalnia, Magazyn drewna, Filtr wodny, Port rybacki, Wieża, Pułapki (+1 mat),
  Magazyn (+materiały). **Świadomie tanie zostają** wczesne przetrwanie: Ognisko
  (1e/3w), Szałas (2e/3w), Spiżarnia (1e/2w/2m), Studnia (3e/2w/2m), Palisada —
  żeby nie głodzić early game. Pierwsza, agresywniejsza wersja (Spiżarnia/Studnia
  też drogie) dała 5 zgonów Akt I → cofnięte do tanich; finalnie 2/50 (bot kempi,
  człowiek odkrywa biomy ≈ 0).
- **Biomowość eventów.** 5 generycznych „znalezisk" przeniesionych z bazowej puli
  (`data/cards/events/`) do `events/biome/` i wpiętych w pasujące biomy (pula
  bazowa = tylko top-level, podkatalog aktywny po odkryciu biomu): jagody
  (`berry_patch`→Łąki, `small_find`+`strange_berries`→Las) i znaleziska złomu
  (`lucky_find`→Pustkowie, `buried_cache`→Pustkowie+Jaskinie). Koniec jagód na
  Pustkowiu; eksploracja realnie zmienia pulę nocy (pula bazowa 39→34).
- **Skażone zbieranie Aktu II** (było tylko 2 karty): +`rotten_forage` (Zgniłe
  jagody, +2 jedz./−1 zdr.) i +`salvage_scrap` (Skażony złom, +1 mat./−1 zdr.).
  Wpięte w `corrupted_gather_cards`: rotten→Las/Łąki, salvage→Pustkowie/Jaskinie/
  Wybrzeże. Każdy skażony biom ma teraz 3 opcje zbierania zamiast 2.
- ZNANE/do następnej rundy: zbieranie wciąż się powtarza (forage/find_water/
  scavenge w wielu biomach) — głębszy dedup gather-kart to osobny pass; szersze
  cięcie faucetów zbierania WSTRZYMANE (bot pokazuje, że gra jest już po
  trudniejszej stronie — najpierw playtest człowieka). Win-rate Aktu II (bot 0%)
  to osobna oś, nietknięta.
- Testy: cała dziesiątka zielona (load/smoke/night_pool/board/ui_layout/fog/
  season/save_load/meta). Smoke 0/50 głównego runu (jak baseline — ściana Aktu II),
  Akt I zgony 2, śr. 18.6 dnia.

### Feedback z dema — runda 2b: skażone karty biomowe Aktu II (2026-06-27)

Skarga: po BUM każdy skażony biom recyklingował JEDNĄ kartę `Choroba` — mało
klimatu i mało realnej trudności. Dodano **8 unikalnych skażonych eventów
biomowych** (`data/cards/events/biome/<biom>_corrupt_*.tres`, category `biome`,
więc w fazie ACT2 mnożnik 1.0 — odpalają się normalnie po BUM), każdy z innym
wektorem nacisku, żeby Akt II bił w różne staty zależnie od tego, gdzie stoisz:
- Las „Szept z czerni" (−1 zdr./−2 energii jutro, schronienie chroni),
  Łąki „Rojowisko much" (−2 jedz./−1 zdr.), Góry „Wycie w szczelinach"
  (−2 ciepła/−1 zdr., schronienie), Bagno „Trupi wyziew" (−2 zdr./−1 nawod., major),
  Rzeka „Trupia woda" (−2 nawod./−1 zdr., major), Pustkowie „Spiekota popiołów"
  (−2 nawod./−1 zdr.), Jaskinie „Pełzająca ciemność" (−1 zdr./−2 energii jutro),
  Wybrzeże „Czarna piana" (−1 ciepła/−1 nawod./−1 zdr., schronienie).
- Wpięte do `corrupted_extra_event_cards` OBOK istniejącej `Choroby`/`Szczurów`/
  `Mgły` — każdy skażony biom ma teraz 2 nocne eventy zamiast 1. Karty są
  biome-gated (podkatalog, nieaktywne w puli bazowej) i odpalają się tylko gdy
  biom jest odkryty I skażony → eksploracja realnie zwiększa pulę ryzyka Aktu II.
- ZERO ryzyka dla Aktu I (to wyłącznie skażone rewersy). Smoke: Akt I zgony 1
  (szum), Akt II 49, śr. 19.8 dnia — Akt II celowo twardszy, zgodnie z prośbą
  „karty po BUM mają realnie utrudnić". Cała dziesiątka testów zielona.

### Walka z monotonią kart: wymiany, czasowniki, synergie, ulepszenia (2026-06-28)

Feedback graczy: „trzy karty na ręce, wszystkie robią +2 czegoś — monotonia".
Diagnoza: każda karta talii miała ten sam czasownik („zapłać energię → zyskaj"),
bez decyzji przy zagraniu. Cztery fale (27 nowych kart akcji + nowe `special`):

- **Fala 1 — wymiany/tempo (czyste dane, pula nagród).** 10 kart, w których coś
  bierzesz, by coś dać (sytuacyjne, czasem „martwe"): Forsowny marsz (+energia/
  −sytość), Nadludzki wysiłek (+energia/−zdrowie), Wymiana: jedzenie (drewno→
  jedzenie), Filtracja zapasów (jedzenie→woda), Obróbka kamienia (drewno→kamień),
  Objuczony kram / Handel okazyjny (konwersje), Dołóż do ognia (drewno→ciepło),
  Hartowanie (zdrowie→ciepło), Zacisnąć zęby (zdrowie→kamień).
- **Fala 2 — nowe czasowniki (`special` + handlery).** 7 nowych `special` w
  `_resolve_action` (dyspozytor) + hooki: `free_move` (Bieg — następny ruch za 0
  energii; `move_to`/`can_move`), `repair_tile` (Doraźna naprawa —
  `_repair_current_tile`, bez drewna), `ward_night` (Warta/Okopanie się — tej nocy
  −2 do strat zdrowia/ciepła ze zdarzeń i obrażeń potworów; `_resolve_event`/
  `_resolve_monster_attack`), `set_trap` (Wnyki/Zwabienie — negacja jednego
  nocnego ataku potwora). 6 kart.
- **Fala 3 — synergie/silniki (stan tury, reset o świcie).** `_turn_cards_played`,
  `_turn_food_played`, `_energy_refund_per_card` zerowane w `_start_day`; karty
  reagują na to, co zagrałeś wcześniej w turze: `momentum` (Zapał/Nieustępliwość —
  każda kolejna karta dziś zwraca +1 energii), `rhythm` (Rytm dnia/Kadencja —
  +1 energii za każdą wcześniejszą kartę), `combo_food` (Drugie śniadanie/
  Zbieractwo: Spiżarka — +2 jedzenia, jeśli grałeś już jedzenie). 5 kart.
  Akcje biomu też liczą się do combo (resolują przez `_resolve_action`).
- **Fala 4 — ulepszenia kart (talia EWOLUUJE, nie puchnie).** `ActionCardData`
  ma `upgrade_id` (res:// ścieżka wariantu w `data/cards/actions/upgrades/`, poza
  pulą nagród). Reużywa istniejące UI nagrody: `roll_card_rewards()` wstawia ≤1
  ulepszenie posiadanej karty, a `claim_card()` PODMIENIA bazę w talii zamiast
  dopisywać (`available_upgrades()`). 6 wariantów (Zbieractwo→Spiżarka,
  Źródło→Bystry strumień, Opatrz rany→Szwy, Odpoczynek→Głęboki sen, Zwiad→
  Rekonesans, Zioła→Mocny wywar) wpiętych w 6 baz. To zarazem leczy rozcieńczanie:
  awans może ulepszać, nie tylko dorzucać kolejny „faucet".
- **Balans (smoke).** Surowe dodanie 21 kart Fal 1–3 rozcieńczyło pulę nagród
  (28→49) → bot losujący nagrodę częściej brał karty sytuacyjne i ginął wcześniej
  (Akt I zgony 0→4). Fala 4 (ulepszenia) to ODWRÓCIŁA: bot bierze ulepszenia,
  talia silnieje → **Akt I zgony z powrotem 1** (dzień 12), śr. 21,4 dnia, win-rate
  per klasa w górę (Zielarka 26/30, Strateg 9, Wędrowiec 7). Bot dostał też
  rozsądną osłonę: nie gra kart samobójczych (−zdrowie/−sytość przy niskim stanie)
  i przy nagrodzie woli ulepszenie / kartę bez minusów (prawdziwszy sygnał niż
  losowy wybór). Akt II nadal jest ścianą (główny run ~1/50) — zgodnie z założeniem.
- Nowy `card_view._action_special_text` + `survival._action_special_log_text`
  opisują wszystkie nowe czasowniki na kartach i w logu.
- `tests/card_upgrade_test.gd`: ulepszenie podmienia bazę w miejscu (rozmiar talii
  bez zmian), zwykła nagroda dopisuje, ulepszenie znika z oferty po wzięciu.
- Testy: cała jedenastka zielona (load/night_pool/board/ui_layout 117 kart/fog/
  season/save_load/meta/audio/card_upgrade + smoke).

### Wyrównanie gałęzi drewna (2026-06-30)

Audyt kart (`KARTY_PODZIAL.md`) pokazał, że drewno było najcieńszym zasobem:
tylko 3 karty je produkowały i ŻADNA przez wymianę/ulepszenie/sygnaturkę (wymiany
tylko je zużywały). Dodano 4 karty przez różne kanały: `haul_wood` (Naręcze drewna,
−2E/+3D, pula), `deadfall_wood` (Wiatrołom, −1E/+2D, najtaniej na energię, pula),
`barter_wood` (Wymiana: drewno, −2 kamienia/+3 drewna — pierwsza konwersja DO drewna)
oraz `gather_sticks_up` (Chrust: Naręcze, +2D) jako ulepszenie Chrustu (`gather_sticks`
dostał `upgrade_id`; Budowlaniec ma Chrust ×2, więc ulepszenie realnie się pojawia).
Gałąź drewna ma teraz 7 producentów. Art: 4 nowe karty aliasowane na
`action_chop_wood` (`card_view.ACTION_ART_ALIASES`) — zero nowych dziur graficznych.
Smoke bez regresji (pula nagród 49→52, drewno to czysta ekonomia); `load`/`ui_layout`
(120 kart)/`card_upgrade` zielone.

### Ręka kafelkowa (wariant A) + karty-goście (2026-06-30)

Dotąd ręka = czyste losowe 4 z talii (świeży tasunek co świt) → potrafiła się
skleić (3× podobna karta / ręka bez ekonomii / „martwa ręka"). Wdrożono **dobór
kafelkowy z gwarancją różnorodności**:

- **Role kart** (wyliczane z pól, bez nowych danych): `ECONOMY` (zysk zasobu/wymiana),
  `SUSTAIN` (leczy stat teraz, bez zysku zasobu), `TEMPO` (energia/dobór/ruch/zwiad/
  naprawa/warta/pułapka/narzędzia), `PAYOFF` (synergie momentum/rhythm/combo_food).
  `_card_role()` + enum `HandRole`.
- **`_deal_bucketed_hand()`** w `_start_day`: ręka pokrywa ECONOMY+SUSTAIN+TEMPO
  (jeśli talia ma), 4. slot to wildcard; resztki talii idą do `_day_deck` (dobór
  w ciągu dnia, np. `draw_two`, działa jak dotąd). Anty-clump: `_pop_non_duplicate`
  unika 2× to samo id; nigdy 3 karty tego samego efektu. Tasowanie własnym `_rng`
  (`_rng_shuffle`) — seedowane runy/testy są deterministyczne.
- **Karty-goście (decyzja gracza: wczesna różnorodność BEZ psucia progresji).**
  Slot wildcard z szansą podbiera „gościa" z puli nagród, której gracz **jeszcze
  NIE ma** (`_guest_candidates` = `_card_pool` minus talia), preferując rolę
  nieobecną w ręce (zwykle PAYOFF). **Gość jest tylko na dziś — nie wchodzi do
  `state.deck`**, więc system nagród/ulepszeń zostaje nienaruszony. Szansa zależy
  od fazy: `HAND_GUEST_CHANCE_ACT1=0.5`, `ACT2=0.25` (więcej „na początek").
  Log „Improwizacja: …".
- **Fix przy okazji:** `bonus_hand_cards` (Strateg +1 karta/świt) realnie działa —
  dobór i `_draw_cards` używają `_hand_limit()` zamiast twardego `HAND_SIZE`
  (wcześniej cap kasował bonus).
- **Balans (smoke):** **Akt I zgony 0** (śr. dzień —) — gwarantowana funkcjonalna
  ręka zniosła śmierć z „martwej ręki". Klasy tempo zyskały najwięcej (Strateg
  22/30, Zielarka 20/30), trudne wciąż 0/30 (ich problem to Akt II, nie ręka).
  Główny run dalej 0/50 (ściana Aktu II). Szansa gościa to wygodne pokrętło, jeśli
  trzeba zbić wczesną siłę.
- `tests/hand_draw_test.gd`: co świt ręka ma ≥3 role (gdy talia je ma), brak 3×
  tego samego id, i gość pojawia się w oknie Aktu I. Cała dwunastka testów zielona.

### Wyrównanie kamienia + wzbogacenie talii startowych (2026-06-30)

Audyt (`KARTY_PODZIAL.md` + skrypt) potwierdził skargę „dużo energii, mało
drewna/kamienia w ręku" i znalazł głębszą przyczynę: **8/9 talii startowych nie
miało ŻADNEJ karty drewna, 7/9 — kamienia**, więc gwarantowany slot „ekonomia"
ręki kafelkowej dawał im wyłącznie jedzenie/wodę (drewno/kamień tylko ze zbierania
biomu i nagród). W puli energia była 2. najliczniejszym efektem (9), a kamień
najcieńszym (4).

- **Kamień w puli 4→6:** `mine_stone` (Wydobycie, −2E/+2M, raw) i `barter_materials`
  (Wymiana: kamień, −1J/+2M, domyka kwartet wymian jedzenie/woda/drewno/kamień).
  Aliasy artu → `action_explore`.
- **Talie startowe 9→11 (wszystkie 9 klas):** każda dostała +1 producenta drewna
  (haul_wood/deadfall_wood/gather_wood/gather_sticks) + 1 kartę różnorodności/kamienia
  (scavenge/knapping/woodcraft — albo czasownik: Budowlaniec `momentum`, Skaut `dash`).
  Teraz **każda klasa ma w starcie drewno I kamień** → realnie trafiają do ręki, a
  progresja jest mniej ukierunkowana na nagrodę „dodaj kartę" (startujesz bogatszy).
- **Energia zostawiona** — to rola TEMPO/PAYOFF (~1 slot w ręce kafelkowej), więc
  strukturalnie nie zalewa ręki; balans robimy dosypaniem drewna/kamienia, nie cięciem.
- **Bot:** dodano regułę „nie dłub w drewnie/kamieniu, gdy sytość/nawodnienie < 4"
  (rozsądny gracz robi potrzeby pierwsze) — inaczej naiwny bot przepalał energię na
  surowiec i ginął w Akcie I.
- **Balans (smoke):** gra NIE zrobiła się łatwiejsza (win-rate per klasa podobny/
  niższy: Strateg 15/30, Zielarka 11/30), Akt I zgony 2 (dzień 10). Cel osiągnięty
  bez trywializacji. `load_test` zaktualizowany (starter 9→11). Cała dwunastka zielona.

### Korekta reki: owned-only survival draw (2026-06-30)

Karty-goscie z reki kafelkowej byly dobra proteza na martwe rece, ale przesuwaly
gre w strone deckbuilderowego preview zamiast survivalu. Usunieto pozyczanie kart
spoza talii gracza:

- reka switu jest teraz budowana wylacznie z `state.deck`;
- najpierw idzie normalne losowanie z przetasowanej wlasnej talii;
- potem lekka korekta survivalowa: tylko jesli reka nie ma ZADNEJ karty
  ECONOMY/SUSTAIN, system podmienia jedna karte z pozostalego stosu;
- TEMPO/PAYOFF nie sa gwarantowane, wiec combo i silne tempo trzeba nadal zbudowac
  przez nagrody/ulepszenia, nie dostac jako gosc;
- anty-clump zostal tylko jako ochrona przed 3x ten sam `id` w rece.
- nagrody awansu nie sa juz plaskim `3 z calej puli`: po opcjonalnym ulepszeniu
  draft najpierw reaguje na realny kryzys (np. woda przy pragnieniu), potem
  probuje dodac tor klasy; spokojny poranek mocniej pokazuje archetyp i
  tempo/synergie zamiast kolejnej anonimowej ekonomii;
- kazda klasa ma wlasne biasy nagrod: Kucharz czesciej widzi FOOD/CONVERT/WARMTH,
  Budowlaniec WOOD/MATERIALS/REPAIR, Lowca ENERGY/NIGHT/FOOD itd.; to ma robic
  z awansu decyzje "jak moja klasa przetrwa", nie tylko "co ma najwyzsza cyfre";
- `ECONOMY` zostalo rozbite dla nagrod na konkretne potrzeby: FOOD/WATER/WOOD/
  MATERIALS/HEALTH/WARMTH/ENERGY/REPAIR/NIGHT/CONVERT/SYNERGY;
- nocne kryzysy sa ostrzejsze: jesli glod/pragnienie/cieplo spadna do 0,
  jutro tracisz energie; schron moze zlagodzic mroz o 1, ale sam dostaje zuzycie.

`tests/hand_draw_test.gd` sprawdza teraz: brak kart spoza posiadanej talii, co
najmniej jedna karta survivalowa gdy talia to wspiera, brak potrojnych zlepek.
`tests/card_upgrade_test.gd` dodatkowo lapie strukturę draftu nagrod: komplet
3 unikalnych opcji, obecnosc linii synergii i reakcje na kryzys wody. Do pomiaru balansu trzeba ponownie
odpalic smoke; oczekiwany efekt to wiecej survivalowego tarcia w Akcie I bez
powrotu kompletnie martwych rak.

Ten sam test sprawdza tez, ze spokojny draft dla Kucharza i Lowcy zawiera
przynajmniej jedna karte z ich osi klasowej, wiec archetyp powinien byc czuc
juz w nagrodach, a nie dopiero po przypadkowym trafieniu payoffu.

### Domknięcie przecieku gather + modyfikatory kafla (gdzie obozować) (2026-06-30)

Dwie powiązane zmiany zwiększające wagę decyzji „gdzie stać / gdzie spać":

- **Flaga `gather_only` + szczelna pula nagród.** `ActionCardData` ma teraz
  `gather_only: bool`. Karty zbierania przypięte do biomu (Poluj, Wędkowanie,
  Sidła, Suchy chrust) były fizycznie w `data/cards/actions/` top-level, więc
  wpadały do puli nagród awansu i dało się je wylosować → wejść do talii → grać
  z ręki na DOWOLNYM kaflu (łamiąc ekonomię „surowiec tam, gdzie biom").
  Dodano jeden punkt filtrowania `CardLibrary.load_reward_pool_from_dir()`
  (pomija `gather_only`), użyty przez start runu, wznowienie, tutorial i bota
  smoke — pula nie może się już rozjechać między miejscami. Karty dual-use
  z talii startowych (forage/find_water/scavenge/gather_wood/gather_sticks)
  zostają bez zmian; flagujemy tylko 4 czyste karty biomu (0 w taliach).
  Mechanizm zbierania (rząd „okolica") czyta `biome.gather_cards` niezależnie
  od talii — bez zmian.
- **Modyfikatory kafla per biom (`BiomeData.camp_*`).** Kafel, na którym gracz
  KOŃCZY dzień, narzuca nocną presję zależną od biomu — „gdzie obozować" staje
  się decyzją, nie tylko „skąd surowiec": **Góry/Jaskinie** `camp_warmth_loss`
  (+1 utraty ciepła nocą), **Pustkowie** `camp_thirst_loss` (+1 pragnienia),
  **Bagno** `camp_sickness_chance`/`camp_sickness_damage` (30% szans na chorobę
  = -2 zdrowia). Biomy bezpieczne (Las/Łąki/Rzeka/Wybrzeże) są neutralne, więc
  obozowanie nie jest karane wszędzie. **Schron** (night_protection) na TYM
  kaflu łagodzi: -1 do utraty ciepła i połowa szansy choroby — realny powód, by
  budować szałas tam, gdzie się śpi. Wpięte w `_resolve_needs` (ciepło/
  pragnienie/choroba, choroba zapisywana jako przyczyna „Choroba") oraz
  uczciwie w `end_of_day_forecast` (prognoza zawiera nocne spadki kafla, a
  tooltip „Koniec dnia" pokazuje ryzyko choroby).
- Testy: nowy `tests/biome_camp_test.gd` (flaga na 4 kartach, pula wyklucza
  dokładnie je, modyfikatory na 4 trudnych biomach + neutralny Las). Cała
  trzynastka zielona; smoke bez crashy (główny run 0/50 = istniejąca ściana
  Aktu II, Akt I zgony 1 — bez regresji). `card_view._illustration_path` woli
  teraz dedykowany `action_<id>.png` (fallback do aliasu) — pod podmianę artu.
  Do CI dopięto `card_upgrade_test`, `hand_draw_test` i `biome_camp_test`.

### Feedback z dema — Faza 1: ognisko na paliwo, zużycie budynków, obrona globalna, ceny (2026-07-01)

Pierwsza fala poprawek z drugiej rundy feedbacku dema (18 punktów spisanych przez
gracza po testach); ta fala obejmuje mechaniki budynków (punkty #3, #10–13, #15–17):

- **Ognisko przerobione na paliwo drewna.** `BuildingState.hp` dla ogniska to
  teraz zapas nocy ciepła (start 6), nie wytrzymałość konstrukcji — nigdy nie
  ulega zużyciu ani nie robi się z niego RUINA (`_check_ruin` je pomija).
  Dawna akcja „Ogrzej się" zastąpiona **„Dużym ogniem"** (1 drewno + 1 energia
  → +3 ciepła TEJ NOCY, jednorazowy bonus, nie rusza paliwa). Dawna „Napraw"
  zastąpiona **„Dołóż drewna"** (1 drewno → +3 nocy paliwa, bez górnego limitu —
  gracz może dokładać dowolnie dużo drewna na raz, kliknięcie po kliknięciu).
  `_resolve_campfire_fuel()` spala 1 noc paliwa co świt; przy 0 ognisko jest
  „wygasłe" (nie ruina) i wymaga dołożenia drewna, by znów grzać.
- **Warsztat przestał zużywać drewno co noc.** Usunięta pasywna „konserwacja"
  (`_resolve_workshop_maintenance`, wcześniej po cichu naprawiała losowy budynek
  kosztem drewna — konkurowała z ogniskiem o ten sam surowiec). Warsztat działa
  teraz wyłącznie przez swoją aktywną akcję „Wykonaj narzędzia" (energia + drewno
  + kamień → narzędzia) i podnosi limit kamienia.
- **Ruina dopiero przy 0 HP** (było: poniżej 50% maks. HP) — `_check_ruin`,
  `BUM_DAMAGE_PERCENT_*` komentarz zaktualizowany. Popup budynku i kafel planszy
  pokazują etykietę HP na czerwono, gdy budynek jest poniżej połowy maks. HP,
  ale nadal stoi (nie jest ruiną) — gracz widzi ostrzeżenie, zanim będzie za późno.
- **Zużycie budynków rozłożone na wolniejsze poziomy.** Wcześniej większość
  budynków produkujących zasób traciła -1 HP niemal co noc (przez
  `_should_passive_wear`), stąd wrażenie ciągłego biegania po naprawy. Dodano
  `EVERY_THIRD_DAY_WEAR_BUILDING_IDS` / `EVERY_FOURTH_DAY_WEAR_BUILDING_IDS`;
  wszystkie budynki poza dwoma podstawowymi (Ognisko na paliwie, reszta na
  jawnym harmonogramie 2/3/4-dniowym) straciły automatyczne zużycie „za każdym
  razem, gdy coś wyprodukują". Popup budynku dopisuje jawny tekst „Zużycie: -1
  HP co N dni".
- **Obrona (Palisada/Wieża/Bastion) działa globalnie**, nie tylko na kaflu, na
  którym stoi (`_bum_defense_damage_reduction`, `_tile_defense` sumują teraz
  całą planszę) — jedna warownia broni całej osady, uzasadnia wyższą cenę.
- **Wyrównanie cen budynków.** Ognisko, Szałas i (po diagnozie regresji, patrz
  niżej) Studnia/Spiżarnia/Palisada zostają w taniej, „rdzennej" warstwie
  przetrwania bez zmian. Pozostałe zwykłe budynki (Wieża, Warsztat, Drwalnia,
  Magazyn drewna, Filtr wodny, Port rybacki, Farma, Kamieniołom, Zielarnia,
  Pułapki) podrożały ×1.7. Budynki `act2_only` (Wzmocniony schron, Cysterna,
  Lazaret, Bastion) dostały nowe, wyraźnie najwyższe ceny (Bastion najdroższy ze
  wszystkich). Dopłata post-BUM (`POST_BUM_BUILD_*_SURCHARGE`) zmniejszona
  3/5/5 → 1/2/2 (bazowe koszty już wyższe) i całkowicie wyłączona dla Ogniska/
  Szałasu (`_has_post_bum_surcharge`) — koniec sytuacji, w której odbudowa
  Szałasu kosztowała więcej niż postawienie Bastionu.
- **Wymagany biom widoczny na karcie budowy** (`SurvivalSystem.
  required_biome_label`, np. „Tylko: Las / Góry") — gracz widzi ograniczenie
  zanim spróbuje budować, nie dopiero w bloku komunikatu.
- **Diagnoza regresji podczas weryfikacji.** Pierwsza wersja tej fazy zbiła
  smoke test do 0/50 z 16/50 zgonów w Akcie I (niezmiennik projektu to ~0).
  Przyczyny: (1) `smoke_test` bota pętla „napraw/rozbierz" demolowała też w
  pełni zdrowe budynki, bo `can_demolish` nie ma bramki po `is_ruined` — im
  rzadziej budynek się psuje (nowe wolniejsze warstwy zużycia!), tym częściej
  stał w pełnym HP i wpadał w tę furtkę; naprawiono logikę bota (rozbiórka
  tylko ruin, dokładanie drewna do ogniska tylko gdy faktycznie kończy się
  paliwo); (2) Studnia/Spiżarnia/Palisada przypadkowo trafiły do warstwy ×1.7,
  łamiąc ustalony wcześniej (2026-06-27) fundament „tania warstwa startowa" —
  cofnięte do oryginalnych cen. Po poprawkach: **42/50 wygranych (śr. 46 dni),
  Akt I zgony 3, Akt II zgony 5** — wyraźnie łatwiej niż poprzedni punkt
  odniesienia (~28–46%), głównie przez globalną obronę i rzadsze zużycie;
  ZNANE do rozważenia w kolejnej turze: czy dokręcić `BUM_DEFENSE_DAMAGE_
  REDUCTION_PER_POINT`/`_MAX` albo dopłatę post-BUM, żeby Akt II odzyskał
  status „ściany" zgodnie z pierwotnym założeniem.
- Testy: cała trzynastka (`load`/`board`/`ui_layout`/`night_pool`/`fog`/
  `season`/`save_load`/`meta`/`audio`/`card_upgrade`/`hand_draw`/`biome_camp`/
  `smoke`) zielona.

### Faza 1 — poprawki po feedbacku gracza: zużycie co 2 dni, czytelność Dużego ognia (2026-07-01)

- **Zużycie budynków z powrotem na jeden poziom co 2 dni** (gracz: wolał prostszy,
  szybszy rytm niż rozbity 2/3/4-dniowy). `EVERY_THIRD_DAY_WEAR_BUILDING_IDS` i
  `EVERY_FOURTH_DAY_WEAR_BUILDING_IDS` opróżnione, wszystkie budynki (poza
  ogniskiem, które zużywa tylko paliwo) wróciły do `EVERY_OTHER_DAY_WEAR_
  BUILDING_IDS`. Rdzeń poprawki z Fazy 1 zostaje: wciąż NIE ma już zużycia
  „za każdym razem, gdy budynek coś wyprodukuje" — tylko jawny harmonogram co
  2 dni. Smoke: 35/50 (~70%), Akt I zgony 4, Akt II zgony 11 — trochę trudniej
  niż wersja 3/4-dniowa, wciąż daleko od 0/50 sprzed Fazy 1.
- **Diagnoza „Duży ogień nie działa".** Zgłoszenie gracza: po użyciu akcji noc
  dawała tylko +4 ciepła zamiast spodziewanego bonusu. Zdiagnozowane headless
  skryptem (`_standing_building_stat_passives`/`_building_warmth_value` faktycznie
  liczą +7 = 4 bazowe + 3 z Dużego ognia — log „Budynki wspierają potrzeby
  nocą: +7 ciepła." to potwierdza) — mechanika działa poprawnie, ale wynik
  NETTO po nocnym spadku ciepła (np. +7 − 3 spadku = +4) maskował bonus,
  wyglądając jakby nie zadziałał. Naprawione przez czytelność, nie logikę:
  nowa, osobna linia logu `_campfire_boost_summary()` — „Duży ogień grzeje
  dodatkowo: +3 ciepła (Ognisko)." — pojawia się w nocy niezależnie od tego,
  jak wynik netto wygląda po zsumowaniu ze spadkiem/kapem ciepła.
- Testy: cała trzynastka zielona (smoke 35/50).

### Zużycie budynków wg kategorii: dochód/akcja/statyczne (2026-07-01)

Trzecia iteracja schematu zużycia, na wyraźną prośbę gracza — kategoryzacja wg
tego, co budynek robi, ta sama reguła w Akcie I i Akcie II (bez osobnej ścieżki
po BUM):

- **Dochód pasywny → co 1 dzień** (`NIGHTLY_WEAR_BUILDING_IDS`, lista już była
  odpytywana bez modulo, wystarczyło ją wypełnić): Studnia, Cysterna, Filtr
  wodny, Spiżarnia, Zielarnia, Lazaret, Farma, Pułapki, Port rybacki, Drwalnia,
  Magazyn drewna, Kamieniołom, Wzmocniony schron (ma dochód ciepła jak Szałas,
  ale zostaje w grupie produkcyjnej — NIE dostał wyjątku Szałasu; do ew.
  zmiany, jeśli okaże się zbyt kruchy w Akcie II).
- **Wyjątek: Szałas → co 2 dni** (`EVERY_OTHER_DAY_WEAR_BUILDING_IDS`, teraz
  tylko ten jeden budynek).
- **Statyczne (bez dochodu, bez akcji) → co 3 dni** (`EVERY_THIRD_DAY_WEAR_
  BUILDING_IDS`): Palisada, Bastion.
- **Wieża obserwacyjna i Warsztat** (mają akcję, zero dochodu pasywnego) — NIE
  są w żadnej z powyższych list: zużywają się WYŁĄCZNIE przy realnym użyciu
  akcji (`BUILDING_ACTION_WEAR`, bez zmian). Budynek produkcyjny użyty tego
  samego dnia traci 2 HP (harmonogram + akcja) — zamierzone, skomentowane
  w kodzie.
- `run.gd _building_wear_text()` rozpoznaje teraz też „co dzień" i „tylko przy
  użyciu akcji" (zamiast mylącego „brak zużycia" dla Wieży/Warsztatu).
- **Balans (smoke):** 32/50 (~64%, śr. 41,4 dnia), Akt I zgony **7** (śr. dzień
  12,9), Akt II zgony 11 — Akt I zauważalnie powyżej historycznego ~0–2
  (Studnia/Spiżarnia teraz w grupie „co dzień", nie mają wyjątku jak Szałas).
  To bezpośrednia konsekwencja nowej reguły gracza (dochód pasywny = zawsze co
  dzień, bez wyjątku dla tanich budynków startowych) — zaimplementowane zgodnie
  z instrukcją, ale odnotowane jako sygnał do ew. dalszego dostrojenia (np.
  wyjątek 2-dniowy dla Studni/Spiżarni, analogiczny do Szałasu).
- Testy: cała trzynastka zielona.

### Nocny popup przebudowany: panel z ilustracją zamiast karty w ramce (2026-07-02)

Gracz zgłosił, że nocny popup wyglądał źle: karta z własną ramką (`card_frame_event`/
`card_frame_monster`) siedziała wewnątrz ozdobnej ramki panelu — "ramka w ramce".
Po serii promptów/iteracji (`docs/asset_plan/ASSET_PROMPTS_NIGHT_POPUP.md`) wybrany
został wariant, w którym **panel przejmuje rolę karty**: ozdobna złota rama panelu
oprawia bezpośrednio samą ilustrację zdarzenia/potwora, a tytuł/opis/efekty są
tekstem na przypiętych kartkach pergaminu namalowanych na panelu.

- **3 nowe tła popupu** (1024×768, generowane `[$imagegen]`, wspólny układ stref):
  `night_popup_panel_event.png` (zwykłe zdarzenie), `night_popup_panel_event_choice.png`
  (zdarzenie z wyborem — dolne 2/3 kartki opisu to 3 przyklejone, asymetryczne
  karteczki na przyciski wyboru), `night_popup_panel_monster.png` (atak potwora —
  ten sam układ w mrocznym wariancie: krwawy księżyc, poczerniałe żelazo, zadrapania
  pazurów). Tło poza panelem przyszło z generatora już przezroczyste; jedyny chroma-key
  potrzebny w tej turze to niebieski placeholder pod ilustrację (`tools/
  chroma_key_night_popup.gd`, ten sam wzorzec co `chroma_key_panels.gd`, klucz
  `(0,0,255)`).
- **`NightEventOverlay`** w `run.tscn` przebudowany: zniknęła osobna `NotePanel`
  (dawny sticky-note na `log_panel_act1`) i `CardSlot` z `NightCardView`. Jeden
  `Panel` (Control, stały rozmiar 840×630, centrowany jak `secure_popup`) ma teraz:
  `PanelArt` (tło, podmieniane wg typu karty), `TitleLabel` (tytuł na płycie u góry),
  `Illustration` (TextureRect w wyciętej złotej ramie), `EffectsLabel` (kartka pod
  obrazkiem — efekty/atak/co się dzieje w nocy), `DescLabel`/`ResultLabel` (duża
  kartka po prawej — opis fabularny, zamieniany na wynik wyboru), `ContinueButton`
  (kartka „Dalej" w dolnej 1/3 dużej kartki) i `ChoiceButtons` (Control na 3 sloty
  wyboru w dolnych 2/3, pozycje `NIGHT_CHOICE_SLOTS` dopasowane do asymetrycznych
  karteczek w art). Wszystkie zakotwiczenia to przybliżone ułamki zmierzone z
  wygenerowanego PNG (piksel-scan przez headless Godota) — zgrubne, do ręcznego
  doszlifowania w edytorze jak przy `confirm_popup`/`secure_popup`.
- **`run.gd`**: `NightCardView`/`CARD_BACK`-na-dwóch-węzłach zastąpione JEDNYM
  `TextureRect` (`_night_illustration`), które samo flipuje się z rewersu
  (`CARD_BACK["event"/"monster"]`) na właściwą ilustrację (`_night_illustration_
  texture`, ta sama ścieżka co `CardView._illustration_path` dla zdarzeń/potworów,
  bez potrzeby instancjonowania `CardView`). Cała choreografia FX (spotlight/glow/
  burst/shine/dust, `HOLD` przed flipem) zachowana 1:1, tylko przepięta na jeden
  węzeł zamiast dwóch. `_night_panel_texture(is_monster, has_choices)` wybiera
  właściwe tło; `_build_night_choices` tworzy przyciski z zakotwiczeniem w
  konkretny slot zamiast `VBoxContainer`. Usunięte: `NIGHT_CARD_VIEW_SCENE`,
  `NIGHT_CARD_SIZE`, `NIGHT_NOTE_BASE`/`NIGHT_LAYOUT_GAP`/`_place_overlay_panel`
  (dawny dwupanelowy fit zastąpiony jednym `_fit_centered_panel`, jak przy
  `LevelUpOverlay`/`PauseOverlay`).
- Weryfikacja: `--import` 0 błędów, cała czternastka testów zielona (smoke 30/50,
  balans bez zmian — to czysto wizualna przebudowa UI, logika `SurvivalSystem`
  nietknięta). `ui/night_card_view.tscn`/`.gd` nie jest już używany przez `run.gd`,
  ale zostaje w repo — `tests/ui_layout_test.gd` nadal go instancjonuje jako
  niezależny regression-check karty w ramce event/monster (przydatny, gdyby
  card-frame'owy wygląd wrócił gdzie indziej, np. w innym popupie).

### Tła skorumpowanych biomów per katastrofa (2026-07-03)

- Wygenerowany brakujący komplet teł Aktu II wg
  `docs/asset_plan/ASSET_PROMPTS_DISASTER_BIOME_BACKGROUNDS.md`: 24 pliki
  (8 biomów × Zaćmienie/Powódź/Pęknięcie) w
  `assets/art/biomes/backgrounds/corrupted/biome_<biom>_<katastrofa>_bg.png`,
  ten sam rozmiar/styl co istniejący komplet Plagi.
- Domknięty dług z wpisu 2026-06-19 („skażone twarze kafli pozostają zielone
  dla obu katastrof"): oba miejsca hardkodujące sufiks `plague` niezależnie od
  wylosowanej katastrofy naprawione. `ui/biome_tile_view.gd _background_path()`
  i `setup()` przyjmują teraz `disaster_id` (przekazywane z `run.gd
  _refresh_tiles` jako `state.disaster.id`); `run.gd
  _secure_region_preview_texture()` też czyta realną katastrofę. Fallback
  zostaje trzystopniowy: art danej katastrofy → art Plagi (zawsze jest) →
  `biome_forest_normal_bg.png` — brak ryzyka czarnego ekranu, jeśli kiedyś
  zabraknie pliku dla nowej katastrofy.
- Weryfikacja: `--import` 0 błędów, cała czternastka testów zielona, smoke
  22/50 (zgodne z baseline — czysto wizualna zmiana, `SurvivalSystem` nietknięty).

### Pass balansu przed wydaniem: diagnoza przyczyn + Akt I + Budowlaniec (2026-07-04)

- **Smoke test raportuje przyczyny śmierci** (histogram z `run_summary()["cause"]`,
  rozbity na Akt I/II, także per klasa) — koniec strojenia w ciemno. Nowy one-off
  `tools/balance_trace.gd` odtwarza runy bota i zrzuca pełny log pierwszego runu
  zakończonego śmiercią z mrozu w Akcie I (bot-pętla skopiowana ze smoke; trzymać
  w synchronizacji tylko póki diagnostyka potrzebna).
- **Diagnoza Aktu I (12 zgonów/50, w tym Mróz ×10):** bot dochodził do gałęzi
  „buduj" dopiero przy wyczerpanej energii (zachłanne karty najpierw), więc NIGDY
  nie stawiał ogniska → ciepło 0 od dnia ~4 → −2 HP/noc do śmierci ~dzień 11.
  Poprawka BOTA (rozsądny gracz stawia ognisko od razu): jeśli nigdzie nie stoi
  ognisko, bot buduje je na początku kroku, zanim zagra karty. Akt I: 12 → **0–1**
  zgonów; główny przebieg 20 → **27–29/50**.
- **Budowlaniec (3–8/30, zgony: Odwodnienie ×9 / Głód ×8 w Akcie II):** talia
  czystej ekonomii drewna/kamienia bez zaplecza potrzeb. Dwie podmiany w
  `builder_deck.tres`: `momentum` → **Bukłak** (woda) i drugi `gather_sticks` →
  **Suszone mięso** (jedzenie). Efekt: **19/30**. Przy okazji usunięty MARTWY malus
  `food_hunger_multiplier = 0.8` z `builder.tres` — `round(2×0.8) = 2` znaczyło
  zero realnego efektu, a opis klasy okłamywał gracza („Jedzenie syci mniej −20%").
- **Pomiar końcowy (smoke):** 27/50 (śr. 43,2 dnia), Akt I 1 zgon, Akt II 22.
  Klasy: Zielarka 26, Skaut 24, Wędrowiec/Strateg 22, Łowca 20, Budowlaniec 19,
  Kucharz 17, **Wojskowy 8** (Głód ×11 — malus +1 głodu/dzień; kandydat do
  przyjrzenia się po ręcznym playteście), Informatyk 4 (challenge by design).
- Cała czternastka testów zielona (season_test raz segfault Godota przy wyjściu —
  flake, po powtórce zielony).

### Lokalizacja PL+EN (2026-07-04)

- **Klucz tłumaczenia = polski tekst źródłowy** (zero wymyślonych id): CSV
  `localization/strings.csv` (kolumny `keys,en`), importowany przez Godota do
  `strings.en.translation`, zarejestrowany w `project.godot`
  (`locale/fallback="pl"` — brak wpisu = gracz widzi polski oryginał).
  **1183 klucze, 100% przetłumaczone na EN** (tłumaczenie maszynowe do
  proofreadu przed premierą).
- **Kod:** `tools/wrap_tr.gd` (one-off) opakował ~400 literałów w `tr()`
  (2 przebiegi: diakrytyki + zdaniopodobne bez diakrytyków; pomija bloki
  `const`, komentarze, assert/print). Pliki statycznych funkcji
  (`night_resolver`, `bum_resolver`, `run_state`) używają lokalnego helpera
  `_tr()` → `TranslationServer.translate` (statyka nie ma `Object.tr`).
  Nazwy/opisy zasobów tłumaczone w miejscach KOMPOZYCJI (sed na akcesorach
  `.display_name/.description/.act2_rule_text/.result_text`); fragmenty
  („energii", „drewna") w helperach `_append_delta_part`/`_append_cost_part`/
  `_push_delta` (jedna poprawka zamiast 40 call-sitów). Słowniki `const`
  (BUM_OMENS, DISASTER_CORRUPTED_*, BIOME_DISPLAY_NAMES, TUTORIAL_PAGES)
  tłumaczone przy odczycie; statyczne teksty `.tscn` idą przez auto-translate
  Controli (klucz = tekst źródłowy).
- **Ekstrakcja:** `tools/extract_strings.gd` (zasoby `data/` + literały tr()/
  fragmenty helperów/teksty `.tscn` → merge z istniejącym CSV, bezpieczny
  re-run po dodaniu kart); `tools/loc_en.gd` (dump/merge partii tłumaczeń).
- **Ustawienia:** dropdown Język/Language (Auto/Polski/English) w
  `settings_overlay`; `Settings.language` w `settings.cfg`, aplikowany na
  starcie (`_apply_language`; pusty = locale systemu).
- **Test:** `load_test` sprawdza kompletność (każdy klucz CSV ma EN) i
  istnienie skompilowanego katalogu. Cała czternastka zielona (hand_draw raz
  flake segfault przy wyjściu, po powtórce zielony).
- DO ZROBIENIA przed premierą: proofread EN (natywny/user), ręczny playtest
  w EN pod przepełnienia tekstu (auto-fit fontów istnieje), zrzuty ekranu EN
  na stronę Steam.

## Jak uruchomić

1. Otwórz Godot 4.5+ (testowane na 4.5.1).
2. W Project Managerze: **Import** → wskaż `project.godot` w tym katalogu.
3. Uruchom grę klawiszem **F5** (główna scena: `scenes/main_menu.tscn`).

Testy headless (bez otwierania edytora; po dodaniu nowych klas najpierw
`--import`, żeby odświeżyć cache klas globalnych):

```
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/smoke_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/fog_of_war_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/season_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/board_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/load_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/ui_layout_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/night_pool_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/save_load_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/meta_progression_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/audio_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/card_upgrade_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/hand_draw_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/biome_camp_test.gd
```

- `smoke_test` — naiwny bot rozgrywa 50 pełnych runów na planszy (karty
  z ręki + akcje biomu + wędrówka), sprawdza że każdy kończy się
  wygraną/przegraną.
- `board_test` — niezmienniki 200 wygenerowanych plansz + sąsiedztwo kafli.
- `load_test` — poprawność typów ręcznie pisanych zasobów `.tres`.
- `season_test` — harmonogram pór roku w 30-dniowym vertical slice.
- `ui_layout_test` — headless instancjonowanie kart i kafli, łapie błędy
  w UI-only kodzie typu auto-fit tekstu i dobór ramek.
- `night_pool_test` — niezmienniki aktywnej puli nocnych zdarzeń: limit
  na run, odstęp cooldownu i bias wag (seedowany RNG).
- `meta_progression_test` — koszt ruletki, blokada przy braku monet, pojedyncze
  odblokowanie klasy oraz zapis/odczyt meta-stanu bez dotykania zapisu gracza.
- `audio_test` — dostępność audio, busy Music/SFX, ładowanie streamów oraz start
  odtwarzaczy; realny problem sterownika sprawdzamy dodatkowo bez `--headless`.
- `card_upgrade_test` — nagroda-ulepszenie podmienia bazową kartę w talii w
  miejscu (rozmiar bez zmian), a zwykła karta dopisuje.
- `hand_draw_test` — owned-only survival draw: każdy świt używa tylko kart
  z talii gracza, ma przynajmniej jedną kartę ECONOMY/SUSTAIN gdy talia to
  wspiera i unika 3× tej samej karty.
- `biome_camp_test` — flaga `gather_only` na kartach biomu, pula nagród
  wyklucza dokładnie je oraz modyfikatory kafla (`camp_*`) na trudnych biomach
  i neutralność biomów bezpiecznych.

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
  game_manager.gd     autoload "GameManager": przepływ scen, katalog klas,
                      wybór postaci, ruletka odblokowań (meta)
  run_state.gd        RunState (Resource): stan runu — statystyki, zasoby,
                      talia gracza, plansza, pozycja (gotowy pod save/load)
  meta_state.gd       MetaState (Resource): meta-progresja zapisywana do
                      user:// — złote monety + odblokowane klasy (ruletka)
  resources/          definicje zasobów danych: CardData + pochodne
                      (Action/Building/Monster/Event), DeckData, BiomeData,
                      DisasterData, CharacterClassData oraz stan runtime
                      planszy: TileState/BuildingState
systems/              logika gry, NIEZALEŻNA od scen i UI (RefCounted + sygnały)
  survival_system.gd    cały run na planszy: dni, statystyki, ruch,
                        budynki, akcje biomu, zdarzenia, XP/awanse,
                        BUM (flip planszy, uszkodzenia), potwory nocą,
                        naprawy/ruiny/rozbiórka, warunki końca
  board_generator.gd    generacja planszy 6 kafli (3×2) + sąsiedztwo
  deck.gd               generyczna talia (dobieranie, odrzut, przetasowanie)
  night_event_pool.gd   ważona pula nocnych zdarzeń (wagi, cooldowny, limity,
                        tagi; historia trwa między przebudowami puli)
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
   akcje), ręka 4 kart, energia 8 (modyfikatory zdarzeń z poprzedniego
   dnia działają tutaj), licznik akcji biomu wyzerowany.
2. Gracz zagrywa karty akcji z ręki (natychmiastowe), korzysta z akcji
   zbierania bieżącego biomu (każda 1×/dzień), stawia budynki z KATALOGU
   na slot bieżącego kafla (tryb „Budowanie" — karty budynków + potwierdzenie;
   po BUM dostępne, ale z dopłatą) i przemieszcza się na sąsiednie kafle
   (1 energia); kończy dzień przyciskiem.
3. Noc (obecnie): pasywy budynków (globalne, ruiny pomijane) → karta
   z talii zdarzeń: zwykłe zdarzenie (Szałas łagodzi chronione) ALBO po BUM
   potwór (rani gracza i losowy budynek; Szałas/defense łagodzą) →
   sytość/nawodnienie spadają i automatyczne jedzenie/picie →
   głód/odwodnienie/zamarzanie biją w zdrowie → śmierć (przegrana) /
   dzień 50 przeżyty (wygrana) / kolejny dzień.
   O świcie dnia BUM (20–26): flip planszy, uszkodzenia budynków,
   zużycie zabezpieczeń rejonów i przebudowa talii zdarzeń.
4. Noc (docelowo): po kliknięciu `Zakończ dzień` pojawia się duża karta
   zdarzenia z aktywnej, wagowanej puli; gracz klika `OK`, dopiero wtedy
   efekt i podsumowanie nocy są rozliczane oraz logowane.

Balans (stałe w `run_state.gd`, `survival_system.gd`): startowe maks.
statystyki 10 (zdrowie/energia rosną nagrodami awansu), **energia 8/dzień**
(cap maks.+1 ze Słonecznym porankiem), ruch 1 energii, **sytość/nawodnienie/
ciepło -3 dziennie** (Lato +1 do nawodnienia, Zima +1 do ciepła), 1 jedzenie =
+2 sytości (Kucharz: +3), 1 woda = +2 nawodnienia, głód/odwodnienie/mróz -2
zdrowia dziennie. **Capy magazynowania:** jedzenie/woda 8, drewno/materiały 12;
budynki magazynowe podnoszą cap (Spiżarnia +6 jedz., Magazyn +8 drewna, Filtr/
Studnia +4 wody, Warsztat +6 mat.) — nadwyżka ponad cap przepada (koniec
hoardingu). Szałas -2 obrażeń z chronionych zdarzeń i od potworów, narzędzia +1
do zysku jedzenia/drewna, XP: +1 karta/akcja biomu, +3 budynek, próg
8 + 4×(poziom−1), wygrana w dniu 50. **Budynki: budowane z katalogu w trybie
„Budowanie" (karty + potwierdzenie, nie z talii); po BUM dostępne, ale z dopłatą
+3 energii / +5 drewna / +5 materiałów.** BUM:
dzień 20–26, uszkodzenia budynków **35–80%** z redukcją za obronę rejonu,
zabezpieczony rejon i wysokie max HP (ruina poniżej 50% maks. HP),
naprawa 1 energia + 1 drewno/2 HP, rozbiórka ruiny 1 energia
+ zwrot połowy surowców, Palisada defense 2 (kafel). Zabezpieczenie rejonu:
limit 2 kafli, koszt kamienia/energii/drewna, -30% obrażeń BUM i
60% szans na zużycie HP budynków w Akcie I. Potwory Plagi (po buffie):
Zgnilec 3/3, Zarażony wilk 4/0, Krucza chmara 2/2, Rój szczurów 0/3. Punkt
odniesienia (2026-06-19, po starcie 3/3 + deprywacji Akt I −1): naiwny bot
wygrywa **~80%** (śr. ~29 dni), zgony skupione w Akcie II (~10/50, Akt I ~0).
Świadoma gra ma celować wyżej; trudność świadomie przesunięta w stronę Aktu II.

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
  night_protection). Docelowo do dodania pod aktywną pulę nocnych zdarzeń:
  `weight`, `cooldown_days`, `max_per_run`, `tags` oraz kategoria/ciężar
  (`neutral/weather/biome/omen/monster/disaster`, `minor/medium/major`).
- `DeckData`: lista kart akcji (kopie = wielokrotne wpisy tego samego zasobu);
  budynki NIE są już w talii — buduje się je z katalogu (`SurvivalSystem.
  building_catalog()`)
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

- `MetaState` — działa: złote monety (1 za wygrany run) + odblokowane klasy,
  zapis do `user://meta_state.tres`. Ruletka odblokowuje kolejną zablokowaną
  klasę wg `unlock_order` (najłatwiejsza najpierw; animacja losowania to show). DO ZROBIENIA tu jeszcze: kolekcja kart, odblokowania biomów/
  katastrof i drabinka trudności (README sekcja 8, milestone 2).
- `RunState` jest `Resource` z `@export` (w tym plansza, talia, postęp
  poziomów oraz `disaster`/`bum_day`/`bum_happened`) — gotowy pod
  save/load.
- Fog-of-war planszy: dodać stan odkrycia kafli do `TileState`/`RunState`,
  ukryć dane nieodkrytych kafli w UI, odkrywać kafel po ruchu; dopiero
  odkryte biomy powinny aktywować swoje zdarzenia w nocnej puli.
- Nocne zdarzenia: aktywna pula z wagami/cooldownami/limitami/tagami +
  kategoriami/severity + pacingiem (bez 2× major) + fazami GOTOWA
  (`NightEventPool`). Pozostało: powiększyć pulę kart (obecnie ~14 zdarzeń +
  4 potwory — mało na pełny run), dodać karty kategorii `omen` (są tylko logi),
  doważyć balans (smoke ~74%) i docelowy popup z rozliczeniem po „OK"
  (obecnie efekty liczą się w tle, popup tylko prezentuje kartę).
- `BoardGenerator` używa wstrzykiwanego RNG (`SurvivalSystem` ma własny) —
  gotowe pod seedowane runy.
- Kolejne kroki wg README sekcja 10 (każdy osobną decyzją): uproszczone
  pory roku, drugi typ katastrofy (Pęknięcie/Zaćmienie — szkielet danych
  `DisasterData` już to umożliwia, system losuje z puli), ulepszanie kart
  (wtedy wraca jako nagroda awansu), docelowy run do dnia 50.

### Zabezpieczenie rejonów przed BUM (2026-07-01)

- Keystone: przetrwanie BUM ma wynikać z przygotowania, nie z losowego wipe'u.
  BUM jest teraz później w Akcie I (20–26), a gracz może zabezpieczyć maks. 2
  rejony.
- Zabezpieczenie jest decyzją kafla, nie budynku: przycisk pojawia się w prawym
  dolnym rogu aktualnego rejonu, karta budynku wróciła do klasycznego `Napraw`.
- Koszt jest celowo ciężki: głównie kamień, potem energia i drewno.
  Rejon daje -30% obrażeń BUM dla budynków i tylko 60% szans na zużycie HP
  budynków w Akcie I; przy BUM flaga zabezpieczenia jest zużywana.
- UI: zabezpieczony rejon ma ramkę, tooltip kafla opisuje efekt, tooltip
  przycisku pokazuje koszt, limit i powód blokady. Samouczek i pomoc opisują
  tę decyzję jako przygotowanie do Aktu II.

### Panele popupów jako osobne sceny (confirm / talia / zabezpieczenie) (2026-07-01)

- Ręcznie malowane drewniane panele (rustykalne drewno + pergamin + lina +
  nity + pieczęć woskowa, wariant Akt I i skażony Akt II) zostały wycięte
  chroma-keyem do alfy (zieleń → alfa na 6 panelach; niebieski placeholder →
  alfa na 2 panelach `secure`; surowe oryginały w
  `assets/_reference/panels_raw_greenkey/`, tool `tools/chroma_key_panels.gd`).
- Zamiast wbudowanych `ConfirmationDialog`/`AcceptDialog` powstały **3 nowe,
  reużywalne sceny UI** (pełnoekranowe overlaye z przyciemnionym tłem +
  wyśrodkowany panel 720×540; kliknięcie tła = anuluj, Esc = zamknij):
  - `ui/confirm_popup.tscn` (`ConfirmPopupView`): potwierdzenia ruch/odkrycie/
    rozbiórka. Sygnały `confirmed`/`cancelled`, `open(title, body, ok_text)`.
  - `ui/deck_popup.tscn` (`DeckPopupView`): podgląd talii (`RichTextLabel`
    z przewijaniem), `open(list_text)`.
  - `ui/secure_popup.tscn` (`SecurePopupView`): zabezpieczenie rejonu; ma slot
    podglądu (`RegionPreview`) w wyciętej strefie placeholdera, `open(title,
    body, ok_text, preview)`.
- Każda scena ma `set_act2()` — podmienia panel na skażony i re-skinuje
  przyciski (`ButtonSkin`, ozdobny styl gameplay). `run.gd` woła je w
  `_apply_act2_look()` (także przy wznowieniu post-BUM — popupy tworzone przed
  resume). **Layout dzieci (tytuł/treść/przyciski/preview) jest ustawiony
  zgrubnie i przeznaczony do ręcznego strojenia w edytorze.**
- `run.gd`: `_confirm_action` → `_confirm_popup`, nowy `_confirm_secure` →
  `_secure_popup`, `_show_deck_dialog` → `_deck_popup`; Esc zamyka aktywny
  popup (przed menu pauzy). Usunięty martwy kod build-confirm
  (`_build_confirm`/`_on_build_confirmed`/`_on_build_card_pressed` — budowa jest
  drag-only). Weryfikacja: `--import` bez błędów, 3 sceny + `run.tscn`
  `can_instantiate`, `ui_layout`/`load`/`biome_camp` OK, smoke bez crashy.

### Przegląd kart: dominacje, tematyka, duplikaty nocy (2026-07-02)

Audyt wszystkich 220 kart (porównanie surowych liczb, nie opisów) wykrył karty
ściśle zdominowane, tematycznie odwrócone i zduplikowane zdarzenia nocne.
Poprawki w 3 etapach wg decyzji gracza:

- **Zdominowane karty akcji:**
  - „Dołóż do ognia" (stoke_fire) zdjęte z osi ciepła — teraz JEDYNA konwersja
    drewno→energia (2 drewna → +3 energii). „Ogrzej się" (campfire) podbite
    +2→+4 ciepła (było ściśle gorsze od „Otul się"); „Otul się" bez zmian.
  - „Obróbka kamienia" (knapping) kosztuje teraz 3 energii (+2 drewna → 2 kamienie)
    — przestaje dominować sygnaturę Budowlańca; opcja na deficyt kamienia.
  - „Rąb drewno" (gather_wood) tylko jako akcja biomu Lasu (`gather_only`);
    w taliach zastąpione: Kucharz → Naręcze drewna, Strateg → Wiatrołom; talia
    i ręka tutoriala używają Wiatrołomu (tutorial ciągnie karty z puli nagród).
  - „Szukaj kamienia" (scavenge) zostaje TYLKO w 4 taliach startowych
    (`gather_only` = poza pulą nagród); „Wydobycie kamienia" (mine_stone) wyszło
    z puli nagród i jest akcją zbierania biomów kamiennych — zastępuje scavenge
    we WSZYSTKICH listach gather biomów (normalnych i skażonych; jedna podmiana
    ścieżki ExtResource na biom obsłużyła obie listy).
  - „Sidła" (gather Łąk): +1 jedzenia +2 sytości (było +1/+1 = Zbieractwo
    z doliczonym drewnem).
  - Świadomie zostają mniej opłacalne (decyzja gracza — karty „pod presją"):
    Bukłak, Zbieractwo vs Suszone mięso, Ciesielka, Zacisnąć zęby, Bandaż bez
    kosztu kamienia (bandażowanie kamieniem nie miało logiki).
- **Tematyka (koszt zdrowia zamiast energii itp.):**
  - „Forsowny marsz" → **„Bez obiadu"** (efekt bez zmian +3 energii/−2 sytości;
    nazwa pasuje do pominięcia posiłku zamiast odwróconej logiki marszu).
  - „Nadludzki wysiłek" (overexert) → **„Daj z siebie więcej"**: +3 energii dziś,
    **−3 energii jutro** (pożyczka tempa zamiast −2 zdrowia). NOWE POLE
    `ActionCardData.next_day_energy_delta` (reużywa `RunState.next_day_energy_
    delta`), wpięte w `_resolve_action`, log akcji i linię efektów `card_view`.
  - „Mętna woda" (skażona): dodane −1 zdrowia (spójnie z resztą skażonego
    zbierania). „Wybielone kości" (Pustkowie): −1 zdrowia → −2 energii
    następnego dnia (widok nie daje zasnąć), severity minor→medium.
- **Duplikaty zdarzeń nocnych:**
  - „Gęsta mgła" ≠ „Rozmokła ziemia": mgła ma NOWĄ mechanikę — jutro każdy ruch
    kosztuje +1 energii. Pole `EventCardData.next_day_move_penalty` →
    `RunState.next_day_move_penalty` (persystowane) → o świcie do
    `_move_penalty_today` doliczanego w `move_energy_cost()` (wzorzec 1:1 jak
    `next_day_energy_delta`; darmowy ruch z „Biegu" pozostaje darmowy).
  - NOWE POLE `EventCardData.disaster_id` ("" = zawsze): zdarzenie wchodzi do
    puli nocy tylko po BUM pod pasującą katastrofą (filtr `_event_matches_
    disaster` w `_event_pool()`, obejmuje pulę bazową i biomową). Użyte:
    „Lodowy szept" (skażone Góry) → tylko Zaćmienie, efekt −2 ciepła/−1 energii
    jutro; „Czarna piana" (skażone Wybrzeże) → tylko Powódź, efekt −1 jedzenia/
    −1 nawodnienia/−1 zdrowia — koniec bliźniaków z „Wyciem w szczelinach"
    i „Słonym szkwałem" w tych samych biomach.
  - „Otwarte rany" (Plaga): −2 zdrowia/−1 ciepła (było identyczne z „Gorączką").
  - Pęknięcie: druga karta o nazwie „Wstrząs wtórny" (rift_tremor) przemianowana
    na **„Osuwisko"** (efekt bez zmian).
  - Deduplikacja atmo w biomie: „Szum nurtu" (Rzeka) → +1 energii jutro
    („Zimorodek" zostaje +1 zdrowia); „Rozlewisko" (Wybrzeże) → +1 kamienia
    („Krzyk mew" zostaje +1 jedzenia).
- `biome_camp_test.GATHER_ONLY_IDS` rozszerzone do 7 kart; pula nagród 50→47.
- Testy: cała czternastka zielona. Smoke **22/50** (śr. 37,7 dnia; zgony Akt I 8,
  śr. dzień 10,3 / Akt II 20) — wyraźnie lepiej niż 0/50 z 2026-07-01 (bot ginął
  na drogim zabezpieczaniu rejonów); Akt I nadal powyżej ideału ~0–2 zgonów, do
  obserwacji. Klasy: Zielarka 28/30 … Wojskowy 7/30, Budowlaniec 3/30,
  Informatyk 0/30 (Budowlaniec mocno w dół — droższa Obróbka kamienia; kandydat
  do przyjrzenia się przy następnym strojeniu).
- ZNANE/niezrobione z audytu (świadomie): reskiny „-1/+1 energii jutro" w atmo
  różnych biomów zostają (flavor per biom); „Dziwne jagody" — opcja ryzykowna
  wciąż ledwo lepsza od bezpiecznej; dwie karty o nazwie „Głęboki sen"
  (deep_sleep i rest_up „Odpoczynek: Głęboki sen").

### Bezpieczny format zapisów: JSON zamiast .tres (2026-07-03)

- **Powód (security).** `ResourceLoader.load()` na `.tres` z `user://` potrafi
  wykonać GDScript osadzony w spreparowanym pliku (znane ryzyko z dokumentacji
  Godota — „never load .tres from untrusted sources"). Podmieniony/udostępniony
  save = wykonanie dowolnego kodu. Oba zapisy przeszły na JSON.
- **Run:** `user://run_save.json`. `RunState.to_dict()` serializuje skalary
  wprost, a zasoby autorskie po **id** (klasa, talia, biomy, budynki,
  katastrofa); `RunState.from_dict(data, catalog)` waliduje typy każdego pola
  (`_read_int`/`_read_bool`), clampuje zakresy i odtwarza referencje z katalogu
  `res://` (`GameManager._save_catalog()`); zwraca `null` dla uszkodzonych
  danych (wtedy zapis jest kasowany). Nieznane id kart/budynków są pomijane
  z warningiem; zasoby NIE są clampowane do bazowych `MAX_*` (magazyny
  podnoszą capy). `CardLibrary.DECK_CARD_DIRS`/`load_deck_card_lookup()` —
  wspólna lista katalogów kart, jakie może zawierać talia (akcje + signature/
  upgrades/corrupted + budynki).
- **Meta:** `user://meta_state.json` (te same pola co dotąd). Stary
  `meta_state.tres` jest migrowany jednorazowo przy starcie (jedyny pozostały
  odczyt ResourceLoaderem z `user://` — własny plik gry, kasowany zaraz po
  odczycie). Stary `run_save.tres` nie jest migrowany (run w toku przepada
  przy aktualizacji) — `delete_saved_run()` sprząta też legacy plik.
- Testy `save_load_test` / `meta_progression_test` przepisane na nowy format;
  cała czternastka zielona.

### Porządki: nieużywane assety i martwy kod (2026-07-03)

- Usunięte z repo: `assets/_reference/` (121 MB konceptów/źródeł), śledzony
  `tmp/` (32 MB raw z imagegen; katalog dodany do `.gitignore`), ~60 MB
  nieużywanej grafiki (stare ilustracje kart sprzed `*_candidates`, stare
  9-slice'y, `card_backs`, duble FX, `assets/placeholders/`), martwe wpisy
  `web/` w `.gitignore`, `.gitkeep`-y w niepustych katalogach.
- UWAGA: pliki `.wav` w `assets/audio/` NIE są dublami `.ogg` — katalog
  AudioManagera pisze ścieżki `.ogg`, ale `_resolve()` dobiera rozszerzenie
  i większość efektów istnieje tylko jako `.wav`. Zostają.
- Martwy kod: `ui/night_card_view.gd/.tscn` (stary flip nocnej karty,
  zastąpiony panelami 2026-07-01; wycięty też z `ui_layout_test`),
  w `scenes/run.gd` funkcje `_add_building_interaction`, `_deck_summary`,
  `_make_building_cost_label`, `_make_icon_action_button`,
  `_make_text_action_button`, `_card_cost_summary` + stałe `LOG_PANEL_ACT1`,
  `LOG_TEXT_ACT2`, `REPAIR_ICON`, `RUIN_ICON`; w `ui/help_overlay.gd` stary
  `PAGES` (używany jest `TUTORIAL_PAGES`).
- Narzędzia one-off w `tools/` i `docs/asset_plan/` celowo zostają. Cała
  czternastka testów zielona po reimporcie.

### Przygotowanie do wydania: wersja zapisu, CI, metadane exe, licencje, repo (2026-07-03)

- **Wersjonowanie zapisu runu.** `RunState.SAVE_VERSION` (= 1); `to_dict()`
  zapisuje ją, a `from_dict()` ODRZUCA zapis z inną wersją (zwraca `null` →
  GameManager kasuje plik). Patch zmieniający schemat już nigdy nie wczyta
  połowicznie starego zapisu; przy niekompatybilnej zmianie bump SAVE_VERSION.
  `save_load_test` sprawdza odrzucenie zapisu z przyszłą wersją.
- **CI:** dopisany brakujący `bum_preparation_test.gd` do listy w
  `godot-ci.yml` (workflow miał 13 z 14 testów).
- **Metadane exe** (`export_presets.cfg`): file/product_version 1.0.0.0,
  company_name/copyright AradinX. Codesign świadomie wyłączony — dystrybucja
  przez Steam.
- **Licencje Suno zweryfikowane** (oficjalna baza wiedzy, 2026-07-03; wyniki
  i checklista właściciela konta w `assets/audio/LICENSES.txt`): Pro w momencie
  generacji = własność + prawa komercyjne (gry wideo wprost dozwolone),
  prawa zostają po zakończeniu subskrypcji, NIE działają wstecz na plan
  darmowy. Do zrobienia ręcznie: dowód subskrypcji z dat generacji.
- **Repo spakowane:** `git gc --aggressive --prune=now` na 1,22 GiB luźnych
  obiektów (5287 plików, zero packów). Duże usunięte assety wciąż są w
  HISTORII — jeśli potrzebny lekki klon, osobna decyzja o `git filter-repo`.

### Refactor: noc/BUM/FX wydzielone z dwóch molochów (2026-07-03)

Realizacja zalecenia z README („wydzielić obsługę nocy/BUM oraz prezentację
efektów") przed wydaniem. Cztery kroki, każdy osobnym commitem z zielonymi
testami; publiczne API `SurvivalSystem` i sygnały BEZ ZMIAN (delegaty),
więc run.gd/testy/bot nie wymagały przepisania.

- **`systems/bum_resolver.gd`** (BumResolver): uderzenie BUM, zabezpieczanie
  rejonów, omeny. Wzorzec: klasa ze STATYCZNYMI funkcjami przyjmującymi
  `sys: SurvivalSystem` — cały stan, stałe (testy/run.gd czytają
  `SurvivalSystem.BUM_*`) i sygnały zostają na systemie; zero cykli
  referencji RefCounted, zero zmian lifecycle. `bum_preparation_test`
  przepięty z `survival.call("_trigger_bum")` na `BumResolver.trigger()`.
- **`systems/night_resolver.gd`** (NightResolver, ten sam wzorzec): pula
  nocna (rebuild/kandydaci/faza), rozliczenie karty (zdarzenie / wybór z
  ryzykiem / atak potwora), pasywy i zużycie budynków, paliwo ogniska,
  psucie i bilans potrzeb. `survival_system.gd`: 3068 → **2224 linii**.
- **`ui/night_overlay_view.gd`** (NightOverlayView): skrypt zawieszony na
  węźle `NightEventOverlay` w `run.tscn` — swap panelu per typ karty,
  przyciski wyborów, hover/blokady, reveal FX + pazur potwora, rozliczenie
  przez `_survival`. run.gd trzyma tylko hook tutoriala i SFX potwora
  (konwencja: ui/ bez odwołań do autoloadów, żeby skrypty ładowały się w
  testach `-s`; stąd `AudioManager.play_sfx("monster")` został w run.gd).
  Sygnał `log_line` → log runu. Zweryfikowane headless: instancjacja +
  show_card dla zdarzenia/decyzji (2 przyciski wyboru)/potwora.
- **`scenes/run_fx.gd`** (RunFx, RefCounted na węzłach sceny): sekwencja BUM
  (`play_bum_fx(look, on_flash_peak)` — callback podmienia wygląd Aktu II
  w szczycie błysku), pogoda sezonowa, world/card FX, winiety krytycznych
  statów. `run.gd`: 2875 → **1817 linii**.
- Weryfikacja: `--import` czysty, cała czternastka testów zielona po każdym
  kroku, smoke po krokach 20/50 i 25/50 (baseline 22/50 — szum RNG, rozkład
  zgonów Akt I/II zgodny). Wymagany RĘCZNY playtest popupu nocy i animacji
  BUM w edytorze (UI-only zmiany niewidoczne dla headless).

### Przebudowa klas: uczciwe modyfikatory + drabinka trudności (2026-07-04)

- Audyt klas symulacją (smoke, 30 runów/klasa) wykazał, że `unlock_order` nie
  odpowiadał realnej trudności (Zielarka 93% wygranych na slocie 2, Wojskowy
  33% na 6), a `food_hunger_multiplier` 0.9/1.2 był MARTWY — mnoży tylko
  `FOOD_HUNGER_VALUE = 2`, a `round(2×0.9) = round(2×1.2) = 2` — tooltipy
  Zielarki i Łowcy obiecywały nieistniejące efekty (działa tylko 1.5 Kucharza).
- Przebudowa modyfikatorów: Skaut bez rabatu budowy i bez +1 HP (czysty
  baseline: −1 pragnienia, +2 kamienia); Zielarka bez martwego −10% sytości;
  Strateg bez XP ×1.25 (mnożnik XP zostaje wyłącznie tożsamością Informatyka);
  Budowlaniec rabat 1→2 (przejął tożsamość taniej budowy), bez +1 HP; Łowca
  bez martwego +20% sytości, w zamian realna wada +1 pragnienia/dzień (mięsna
  dieta); Kucharz/Wojskowy/Wędrowiec/Informatyk — wartości bez zmian.
- Nowy `unlock_order` wg ZMIERZONEJ trudności (winrate bota): Skaut 0 (70%),
  Zielarka 1 (30/30 — celowo najłatwiejsza, „na pierwsze przejście"),
  Budowlaniec 2 (77%), Strateg 3 (73%), Wędrowiec 4 (70%), Łowca 5 (63%),
  Kucharz 6 (47%), Wojskowy 7 (23%), Informatyk 8 (10%).
- Ruletka NIE losuje już klasy: `spin_roulette()` odblokowuje najłatwiejszą
  z pozostałych (sort po `unlock_order`) — animacja losowania zostaje, ale
  progresja trudności jest deterministyczna run po runie.
- Bias nagród Stratega → [SYNERGY, WATER, CONVERT] (był identycznym zbiorem
  co Informatyk).
- Lokalizacja: 5 zmienionych opisów klas zaktualizowane w `strings.csv`
  (PL + EN). Testy: smoke + meta_progression + load zielone.

### Dokręcenie ekonomii jedzenia/wody + Zielarka jako klasa startowa (2026-07-04)

- **Problem:** jedzenie i woda praktycznie nie stanowiły presji — bartery
  (`barter_food/water/materials/wood`, `windfall_trade`, `trade_caravan`) i
  `trail_snack` kosztowały **0 energii**, `find_water` (1E → 2 wody) był też
  darmową akcją zbierania w 5/8 biomów, a psucie zapasów zaczynało się dopiero
  przy stanie ≥4 i tylko -1/dzień. Realny drenaż istniał wyłącznie na froncie
  ciepła, stąd zgony bota to prawie same Mróz/Choroba.
- **Karty akcji:** `barter_food/water/materials/wood`, `windfall_trade`,
  `trade_caravan`, `trail_snack` — dodane `energy_cost = 1` (logistyka przestaje
  być darmowa). `find_water`: 1E→**2E** za 2 wody (upgrade `find_water_up`
  zostaje 1E/3 wody — nadal realna nagroda). `dried_meat`: zysk 2→**1** jedzenia
  (zostaje +1 sytości natychmiast).
- **Psucie zapasów** (`survival_system.gd`, `night_resolver.gd`): próg
  `SPOILAGE_MIN_FOOD` 4→**3**; nowy próg `HIGH_SPOILAGE_FOOD = 6` — powyżej
  niego psuje się **2** zamiast 1. Hoarding przestaje być bezpiecznym domyślnym
  wyborem.
- **Budynek:** Cysterna 2→**1** wody/dzień (jedyny "wieczny kran" wody w grze).
- **2 nowe zdarzenia nocne** (Akt I, zawsze aktywne — `data/cards/events/`):
  `leaky_waterskin` (Nieszczelny bukłak, -2 wody) i `gnawed_supplies`
  (Nadgryzione zapasy, -1 jedzenia/-1 wody); pula bazowa 34→36. Kontrują
  wcześniejszą przewagę dodatnich zdarzeń zapasowych (10 dodatnich vs 2
  ujemne w puli Aktu I).
- **Zielarka jako klasa startowa:** `MetaState.STARTING_CLASS_ID`
  `"scout"`→`"herbalist"`; `unlock_order` zamienione (Zielarka 0, Skaut 1) —
  tutorial i nowy gracz zaczynają teraz od najłatwiejszej, najbardziej
  wybaczającej klasy zamiast generalisty.
- Lokalizacja: opis Cysterny + 2 nowe zdarzenia dodane do `strings.csv`
  (PL + EN).
- **Kalibracja klas do docelowej krzywej trudności** (cel gracza:
  80/70/50/45/40/30/25/20/10 dla Zielarka/Skaut/Budowlaniec/Strateg/Wędrowiec/
  Łowca/Kucharz/Wojskowy/Informatyk). 3 rundy pomiar→korekta→pomiar (smoke,
  30 runów/klasa):
  - R1 (sama ekonomia): rozjazd ogromny — Wędrowiec wystrzelił do 73% (wolny
    ruch + start z zapasami staje się NIEPROPORCJONALNIE cenny w deflacyjnej
    ekonomii), Kucharz/Strateg za łatwi (53–63%), Budowlaniec zawalił się do
    33% (jedyna klasa bez żadnego moda przeżycia, gołe budowanie bota prawie
    nie obchodzi).
  - R2: Zielarka bez `hunger_rate_delta` (czysta klasa na start), Skaut
    odzyskuje `health_bonus=1`, Budowlaniec dostaje jednorazowy
    `start_food/water=1` (**zero efektu** — jednorazowy zapas nie leczy
    chronicznego niedoboru na 40 dni), Strateg dostaje `hunger_rate_delta=+1`
    (**zły trop** — jego zgony to Mróz, nie Głód), Wędrowiec/Łowca dostają
    `hunger_rate_delta=+1`/`thirst_rate_delta=+2`.
  - R3: Budowlaniec: zamiast zapasu jednorazowego → **recurring**
    `hunger_rate_delta=-1` + `health_bonus=1`; Kucharz: `thirst_rate_delta`
    1→**2** (trafienie niemal idealne, 47%→23%, cel 25%); Strateg: nerf
    przeniesiony na właściwą oś, `warmth_rate_delta=+1` zamiast głodu.
  - **Wniosek o szumie pomiaru:** Wędrowiec i Wojskowy wahały się o 10–20pp
    między rundami BEZ żadnej zmiany configu (czysty szum RNG przy n=30;
    SE ≈ 8–9pp dla p≈0.3–0.5). Precyzyjne trafienie w konkretny procent na
    tej próbce nie jest możliwe — kierunek i rząd wielkości tak.
  - Stan końcowy (orientacyjny, ±10pp szumu): Zielarka ~70–75%, Skaut ~55–60%,
    Budowlaniec ~35–45%, Strateg ~45–55%, Wędrowiec ~35–45%, Łowca ~20–30%,
    Kucharz ~20–25% (blisko celu), Wojskowy ~20–27% (w celu), Informatyk 0–7%
    (cel 10%, wciąż twardszy niż zamierzone, ale w granicach szumu).
  - DO ZROBIENIA: jeśli potrzebna precyzyjniejsza kalibracja, podnieść
    `CLASS_SAMPLE` w `smoke_test.gd` (30→100+) na czas strojenia, żeby SE
    spadło poniżej progu decyzyjnego; Budowlaniec i Skaut zostają
    najbardziej niepewne (wciąż mogą być zbyt trudne względem celu 50/70).
  - Weryfikacja: reimport + smoke ×3 rundy + pełna czternastka po każdej
    rundzie (poza jednym udokumentowanym flakiem `hand_draw_test` — segfault
    silnika PRZY WYJŚCIU po wypisaniu "OK"; potwierdzone jako pre-istniejące
    przez `git stash` na czysty `a2c1747`, niezwiązane z tą zmianą).

### Regresja ekonomii jedzenia/wody + domknięcie assetów Aktu II (2026-07-05)

- **Diagnoza regresji:** commit „karty drewna/kamienia" zbity smoke testem do
  6/50 (był ~42-46/50). Root cause NIE był w tym commicie (rewert dał tylko
  10/50) — winowajca to skumulowane zaciśnięcie ekonomii z wcześniejszych
  commitów tego samego dnia (barter +1 energii, potwory mocniejsze/częstsze,
  `FOOD_HUNGER_VALUE`/`WATER_THIRST_VALUE` 1). **Naprawa:** obie stałe 1→**2**
  (`systems/survival_system.gd`) — 1 jedzenie/woda = 2 sytości/nawodnienia
  znowu, tak jak przed dokręceniem. Kucharz (`food_hunger_multiplier=2.0`)
  skaluje się z bazą automatycznie (2×2=4 sytości/jedzenie), bez osobnej
  zmiany. Po naprawie: 24/50 (48%), klasy w okolicach docelowej krzywej
  (Kucharz wyszedł wyraźnie mocniejszy niż cel 25% — do rozważenia osobno).
- **Post-BUM surcharge — luka domknięta:** `_has_post_bum_surcharge`
  zwalniała z dopłaty tylko Ognisko/Szałas, mimo że Studnia/Spiżarnia/
  Palisada miały zostać w tej samej taniej warstwie (ustalone 2026-07-01).
  Dodano `POST_BUM_SURCHARGE_EXEMPT_IDS` z tymi 3 budynkami.
- **Audyt assetów:** wszystkie karty (89 akcji, 20 budynków, 15 potworów, 148
  zdarzeń) sprawdzone pod kątem unikalnych obrazków i braków. Znaleziono i
  naprawiono: `building_stone_storage` pożyczał art Kamieniołomu przez
  `BUILDING_ART_ALIASES` (usunięty alias, budynek dostał własny obrazek —
  jedyna faktyczna luka, reszta budynków/potworów już unikalna); 2 zdarzenia
  (`gnawed_supplies`, `leaky_waterskin`) bez ilustracji w ogóle. Wszystkie 3
  dograne (`docs/asset_plan/ASSET_PROMPTS_MISSING_ART_2026_07_04.md`).
- **Spójność opisów skażonych kart z katastrofą:** 15 kart Aktu II (8 gather +
  4 wodne + 3 dzielone) miało jeden opis dla 4 ilustracji katastrof — kilka
  zakładało konkretną pogodę (np. "mięso ciepłe" przy zamarzniętych zwłokach
  w Zaćmieniu). Poprawiono neutralnie, a potem dodano właściwy mechanizm:
  `ActionCardData.plague_description`/`eclipse_description`/
  `flood_description`/`rift_description` (opcjonalne, puste = fallback do
  `description`), wybierane w `card_view._description_for_display()` po tym
  samym `_disaster_id`, który już wybiera ilustrację. `tools/extract_strings.gd`
  rozszerzony o te 4 pola. +120 wpisów w `strings.csv` (60 PL + 60 EN).
- Weryfikacja: reimport + pełna czternastka zielona (poza znanymi flakami
  silnika przy wyjściu na Windows — `hand_draw_test`/`season_test` drukują
  "OK" przed segfaultem, CI liniowy na Linuksie tego nie widzi).

### Ujednolicenie popupów: „X", tytuły, dolne przyciski (2026-07-06)

- Wszystkie 5 „X" zamknięcia ma teraz jeden spec: **56×56 px, font 24,
  czerwień #BC0F00** (normal/hover/pressed jak dotąd). Pozycje NIE zostały
  przesunięte — środek każdego „X" zmierzony centroidem czerwonej pieczęci
  woskowej na arcie panelu (Akt I i II mają pieczęć w tym samym miejscu,
  różnice ≤5 px) i zapisany jako czysty punkt kotwicy + offsety ±28
  (koniec ułamkowych anchorów z ręcznego przeciągania). „X" popupu „Budynki"
  w `run.tscn` dostał brakujące czerwone kolory (był domyślny szary, font 28).
- Tytuły: secure 24→26 (jak confirm/deck); settings 24→26 + złoty kolor
  (1, 0.84, 0.4) jak help/credits. Building popup celowo bez zmian
  (mniejszy panel 640×480, własny styl z cieniem).
- Dolne przyciski: settings „OK" 260×88/18 → **„Zamknij" 260×60/16**
  (spójnie z help/credits; klucz „Zamknij" już był w `strings.csv`).
- Treść confirm 18→16 (jak secure). Popupy nocne nietknięte (fonty pod
  okna tekstu na arcie karty).
- Weryfikacja: `--import` + `ui_layout_test` zielone, headless instancjacja
  5 edytowanych scen popupów OK. Do rzutu oka w edytorze przy okazji.

### Review grafiki popupów cz. 2: geometria vs art + kontrast Act II (2026-07-06)

- Metoda jak przy „X": prostokąty node'ów naniesione programowo (PIL) na
  panele act1/act2 + pomiar kontrastu WCAG (kolor fontu vs średni kolor artu
  pod rectem). Geometria we wszystkich 4 popupach z artem siedzi (treść
  confirm trafia w linijki, region secure w niebieskie okno, OK w szyldy,
  building w tabliczki) — sceny bez zmian.
- **Bug**: `ButtonSkin.apply_panel_close()` ustawiał font 20 i w `_ready()`
  nadpisywał ujednolicone 24 ze scen confirm/secure/deck → naprawione u
  źródła (20→24 w `button_skin.gd`).
- **Kontrast Act II**: na act1 tekst ma 5.9–9.5, na ciemnych panelach act2
  brąz spadał do 1.5–2.8. Fix: `apply_panel_action(button, act)` — act2 daje
  jasny krem; `set_act2()` w secure (tytuł/koszt/efekt) i deck (tytuł) →
  krem (0.93, 0.88, 0.72); confirm act2 jest szarobury, więc tam odwrotnie —
  tytuł/treść przyciemnione do (0.07, 0.05, 0.03) (kontrast ~4–5.5);
  building `set_content()` skinuje 3 dolne przyciski przez
  `apply_panel_action` z aktem. „X" bez zmian (czerwień na pieczęci/sęku to
  świadomy spec z cz. 1).
- Weryfikacja: `--import` + `ui_layout_test` zielone + nowy test
  `popup_act2_test.gd` (set_act2/set_content na 4 popupach, asserty na
  font 24 po re-skinie i kolory per akt) — dopisany do listy w CI.

### Fix: badge'e preview przy zasobach + „zawieszone" podświetlenie przycisku (2026-07-06)

- **Badge'e hover-preview nie pokazywały się przy zasobach** (jedzenie/woda/
  drewno/kamień), tylko przy statystykach. Przyczyna (potwierdzona wizualną
  sondą headless→render): `Label.clip_text = true` PRZYCINA TEŻ DZIECI do
  prostokąta etykiety — badge zakotwiczony poza wąską (108 px, wyśrodkowaną)
  etykietą zasobu był ucinany w całości; przy szerokich etykietach statystyk
  badge mieścił się w środku, więc działał. Fix: badge'e zasobów są dziećmi
  `Rows` (zwykły Control bez clipa), pozycjonowane przy show w przerwę
  separacji HBoxa za etykietą. Gracz wrzucił już 12 ikon statów — HUD/karty
  renderują je poprawnie (zweryfikowane sondą).
- **Przycisk „Budowanie" zostawał podświetlony** po kliknięciu (i po powrocie
  do „Akcje"). Przyczyna: `ButtonSkin.apply_primary` ustawiał stylebox `focus`
  na teksturę HOVER, a Godot rysuje focus NA WIERZCHU aktualnego stanu — po
  kliknięciu przycisk trzyma fokus, więc wyglądał jak wiecznie podświetlony
  (z nowym, wyraźnie jaśniejszym hoverem stało się to widoczne). Fix:
  `focus = StyleBoxEmpty` (jak w apply_minimal).

### Nowe przyciski runu + pasek HUD Act II: post-processing i 9-slice (2026-07-06)

- Gracz wygenerował nowy zestaw (8 przycisków bez kwiatów + pasek act2 wg
  `ASSET_PROMPTS_UI_BUTTONS_TOPBAR_2026_07_06.md`), ale: tła były OPAQUE
  czarne (generator nie dał przezroczystości), a stany hover/pressed/disabled
  miały ZUPEŁNIE inne ramki niż baza (animacja klikania by „morfowała").
- Post-processing (PIL, one-off w tmp): stany WYPROWADZONE programowo z bazy
  `button_primary` (hover = jaśniej, pressed = ciemniej, disabled =
  odbarwienie) — identyczna geometria wszystkich stanów; czarne rogi wycięte
  flood-fillem od narożników (act1), act2 dostał PRZESZCZEP alphy z act1
  (jego wypełnienie jest zbyt czarne na flood — przeciekał przez ciemną
  ramkę). Pasek act2: przeszczep kanału alpha z paska act1 (geometria 1:1
  zgodnie z promptem) — koniec ucięcia/rozciągnięcia.
- `button_skin.gd _TEXTURE_MARGINS` 0 → 20 (9-slice): narożniki nie
  deformują się przy żadnym rozmiarze przycisku. UWAGA: przy wymianie artu
  przycisków na inny trzeba dopasować margines do grubości nowej ramki.
- `ui_layout_test` + `popup_act2_test` zielone. Do obejrzenia w edytorze
  (hover/pressed w ruchu).

### Ikony statów/zasobów (plug-and-play) + hover-preview efektów karty (2026-07-06)

- **`ui/stat_icons.gd`** (`StatIcons.texture(key)`): jedno źródło ścieżek ikon
  `assets/art/ui/icons/stats/icon_<key>.png` (health/hunger/thirst/warmth/
  energy/food/water/wood/stone/tools). Ikony to OPCJONALNE assety — brak pliku
  = obecny wygląd tekstowy (wzorzec `ResourceLoader.exists`, jak art kart).
  Prompty + pipeline (green-key 1024 → 64): `docs/asset_plan/
  ASSET_PROMPTS_STAT_ICONS.md`. Stary płaski pack 36 ikon już nie istniał
  (skasowany przy porządkach 2026-07-03), nowy jest do wygenerowania.
- **HUD** (`top_status_bar_view.gd _add_stat_icons()`): ikona w szczelinie po
  lewej każdego boxa statystyki (anchor boxa − 24 px) + ikony wpinane jako
  rodzeństwo etykiet w ResourceRow (HBox sam układa).
- **Karty** (`card_view.gd _apply_cost_icons()`): wiersz kosztów zamienia słowa
  na pary ikona+cyfra (`CostIconRow` w oknie CostLabel), gdy istnieją WSZYSTKIE
  potrzebne ikony; inaczej zostaje tekst. `setup()` dostał opcjonalny
  `cost_values: Dictionary` — run.gd podaje `effective_build_cost()` dla
  budynków (zniżki klasy + dopłata post-BUM w ikonach). Linia EFEKTÓW celowo
  zostaje tekstem (kwalifikatory „nocą"/„jutro" + specjale — ikony zrobiłyby
  hieroglif).
- **Hover-preview (feedback gracza):** najechanie na kartę ręki/okolicy/
  katalogu budowy pokazuje na HUD badge `+X/−Y` (zielony/czerwony) przy każdej
  statystyce i zasobie, który karta zmieni — łącznie z kosztami (energia ujemna
  itd.). `run.gd _setup_hover_preview` + `_card_preview_deltas` (liczone przy
  hoverze — dopłaty post-BUM świeże), `top_status_bar_view.show_effect_preview/
  clear_effect_preview` (badge w prawej części etykiety statu; przy zasobach
  tuż za etykietą, w separacji HBoxa). Preview czyszczone przy każdej
  przebudowie rzędów kart.
- Weryfikacja: `--import` czysty, `ui_layout_test` (125 kart) i `smoke_test`
  (21/50, Akt I 0 zgonów — baseline) zielone. Do obejrzenia w edytorze po
  wygenerowaniu ikon.

### Licencje domknięte + decyzja o wymianie Higgsfield + cięcie 2 dźwięków (2026-07-06)

- **Suno — checklista prawna DOMKNIĘTA:** faktura Apple (Suno Pro, 22.06.2026)
  zarchiwizowana w `docs/licenses/Suno_faktura.png` (celowo poza `assets/` —
  zawiera dane osobowe, `docs/` ma `.gdignore`, nie wchodzi do buildu). Autor
  potwierdził: zakup 22.06 16:05, pierwszy plik 16:07, wszystkie 23 pliki po
  zakupie. Odhaczone w `assets/audio/LICENSES.txt`.
- **OpenAI:** historia faktur ChatGPT (10.2025–07.2026) w
  `docs/licenses/OpenAI_faktury.png`. Generacja grafiki szła z 2 kont cloud
  (adrianpatera2137@gmail.com + przempatpl@gmail.com) — odnotowane w
  `assets/art/LICENSES.txt`; jeśli część powstała na planie płatnym drugiego
  konta, potrzebny analogiczny dowód.
- **Higgsfield — pełna rezygnacja WYKONANA.** Po weryfikacji z autorem
  jedyne produkcyjne pliki Higgsfield to 4 pierwotne bestie Plagi
  (`monster_rotting_one/plague_wolf/crow_swarm/rat_swarm`) — ramki kart
  i jasne zestawy `*_act1_candidates` autor poprawiał/generował w OpenAI.
  Autor zregenerował 4 potwory w pipeline OpenAI wg promptów z
  `docs/asset_plan/ASSET_PROMPTS_HIGGSFIELD_REPLACEMENT.md` (1024x688,
  ta sama skażona paleta, spójne z pozostałymi 11). `--import` czysty,
  `ui_layout_test` zielony. Higgsfield wykreślony z `assets/art/LICENSES.txt`
  i creditsów (`ui/credits_overlay.gd`) — w grze nie ma już żadnych plików
  Higgsfield.
- **Cięcie 2 opcjonalnych dźwięków (decyzja autora):** klucze `coin` (SFX)
  i `act2_plague` (ambient) usunięte z AudioManagera + wywołanie w `result.gd`
  + allowlisty w `audio_test.gd`. Moneta gra bez SFX; Plaga gra generyczny
  `ambience_act2` jako stały wybór.

### Review popupów nocnych + fix ustawień w trakcie runa (2026-07-06)

- Popupy nocne (single/monster/decision/decision_two) przejrzane tą samą
  metodą overlay: wszystkie recty trafiają w art (ilustracja w ramie, tytuł
  w ciemnym szyldzie, opis/efekty na notkach, wybory w slotach notek,
  „Dalej" nachodzi na ostatnią notkę celowo — widoczność przełączana
  naprzemiennie z przyciskami wyboru). Zero zmian w scenach.
- **Bug ustawień w runie**: instancja `SettingsOverlay` w `run.tscn` miała
  nadpisane właściwości sceny źródłowej (`anchors_preset = 0`,
  `anchor_right/bottom = 0.0` itd.), co zwijało pełnoekranowy overlay do
  0×0 w lewym górnym rogu. Fix: usunięte nadpisania, zostało samo
  `visible = false` (jak w działającym `main_menu.tscn`). Do tego overlay
  przegrywał z z_index popupów (300) i zoomu talii (600) — `run.gd` ustawia
  mu teraz `z_index = 700` + `z_as_relative = false`, więc jest zawsze na
  wierzchu po otwarciu z pauzy.
- Weryfikacja: `--import` + `ui_layout_test` + `smoke_test` zielone.

### Wpięcie pakietu graficznego przed premierą (2026-07-07)

- **15 zwietrzałych ilustracji budynków Aktu II** w `assets/art/cards/
  illustrations/buildings_act2/` (id = nazwa pliku, jak Akt I). Po BUM
  podmieniają art w trzech miejscach: karta w katalogu budowy (`card_view`,
  po `_disaster_id`), slot na kaflu (`biome_tile_view`, po `tile.is_corrupted`)
  i popup budynku (`building_popup_view`, po `is_act2`). Wszystko per plik
  pod `ResourceLoader.exists` — brak pliku = jasny art Aktu I zostaje.
- `building_stone_storage` dostał własny art w obu aktach — alias do
  Kamieniołomu (`BUILDING_ART_ALIASES`) usunięty ze wszystkich 3 miejsc.
- **Zregenerowane paski HUD** `top_status_bar_slim_act1/act2.png` (1920×96,
  winieta tylko w strefie x 330–810 zmierzonej z gry) + **ramka kart Aktu II**
  `card_frame_building_act2.png` (podnoszona po BUM, wpięta wcześniej).
- **Malowany panel awansu** `level_up_panel.png`: `LevelUpOverlay/Panel`
  w `run.tscn` przebudowany z PanelContainer na sztywny layout pod strefy
  artu (baza 1024×427); przyciski nagród celowo BEZ drewnianej skórki —
  siedzą na namalowanych pergaminowych notkach (wyjątek w
  `_apply_button_skin`).
- **Logo** `logo_dzien50.png` w menu głównym zastępuje tekstowy tytuł
  i podtytuł (`main_menu.gd _apply_logo`, fallback do etykiet gdy brak pliku).
- Weryfikacja: `--import` czysty, `ui_layout_test` (125 kart),
  `popup_act2_test`, ścieżki panelu awansu w `run.tscn` sprawdzone headless.
  Do rzutu oka w edytorze: panel awansu i HUD na żywo.

### Poprawki po feedbacku: karty awansu w karteczkach + pasek HUD v2 (2026-07-07)

- **Wybór karty po awansie trafia w 3 namalowane karteczki** — karty nagrody
  kotwiczone w rectach przycisków nagród (nie HBox na środku panelu), z linią
  „Masz w talii: N" ciemnym tuszem na pergaminie.
- **Pasek HUD zregenerowany w 2496×128** (19,5:1 — dokładnie proporcja paska
  w grze; prompt: `ASSET_PROMPTS_HUD_POPRAWKA_2026_07_07.md`) z cienkimi
  bocznymi krawędziami. `Frame` w `top_status_bar_view` to teraz
  **NinePatchRect** (marginesy = 16% wysokości pliku) — plecionka trzyma
  grubość przy każdej szerokości okna.
- Winieta w obu nowych paskach wyszła poza strefę (do ~1400 px, wchodziła pod
  statystyki) — ogon wygaszony chirurgicznie klonem tkaniny (przejście 60 px,
  one-off PowerShell w sesji; szew niewidoczny przy 75% skali).
- Weryfikacja: sonda renderująca (`tmp/probe_ui.tscn` — start runu przez
  GameManager + zrzuty HUD/awansu, backup zapisów) — pasek i karty na
  karteczkach OK; `ui_layout_test` zielony. Akt II do rzutu oka po BUM.

### Pasek HUD v3: winieta jako osobna warstwa, pasek 80 px (2026-07-07)

- Feedback (screenshot 2550×1288, proporcja ~1,98): ptak rozciągnięty, ramka
  za cienka i pasek za niski. Przyczyna: winieta siedziała w środkowym patchu
  9-slice — przy oknie szerszym niż 16:9 (`stretch/aspect="expand"`) środek
  się rozciąga; a podniesienie paska skalowało winietę w prawo pod statystyki
  (każdy pasek > ~65 px koliduje).
- Rozwiązanie w `top_status_bar_view.gd`: **winieta (strefa art 400–1100 px)
  wycinana z pliku i rysowana jako osobny `TextureRect`** w stałej skali 0,5,
  zakotwiczony z lewej — nigdy się nie rozciąga i nie wchodzi pod statystyki.
  9-slice dostaje pasek z wyciętą winietą (sama spokojna tkanina — jej
  rozciąganie jest niewidoczne). Pasek podniesiony **64 → 80 px**
  (`custom_minimum_size` w .tscn) — plecionka proporcjonalnie grubsza.
- Weryfikacja: sonda w dwóch oknach (1920×1080 i 2550×1288 jak u gracza) —
  ptak niezniekształcony w obu, brak szwu po wycięciu; `ui_layout_test`
  zielony. Screenshot diagnostyczny przeniesiony z `assets/` do `tmp/`.

### Pasek HUD: powrót do złotej ramki, art robi gracz (2026-07-07)

- Malowane paski (v2/v3) nie przekonały — decyzja: **powrót do płaskiej
  złotej ramki** (StyleBoxFlat fallback). Oba `top_status_bar_slim_*.png`
  usunięte; kod warstwy winiety wycofany do prostego wariantu v2 (pre-skala
  do wysokości paska + 9-slice, marginesy 16%). Plug-and-play zostaje: nowy
  plik pod tą samą ścieżką podnosi się automatycznie.
- Pasek zostaje na **80 px** (feedback: 64 było za nisko). Realne wymiary na
  scenie (z sondy): pozycja (16, 8), **1248×80 px przy 16:9** (canvas
  1280×720), na szerszych oknach rośnie tylko szerokość — u gracza
  (2550×1288) **1393×80 px** (fizycznie ~2492×143 px). Zalecany nowy art:
  **2496×160** (2× od 1248×80); środek 9-slice rozciąga się do ~12%.

### Pasek HUD v4: wycięty z pełnoklatkowych mockupów 1920×1080 (2026-07-07)

- Nowe podejście z `ASSET_PROMPTS_HUD_PELNA_SCENA_2026_07_07.md` ZADZIAŁAŁO:
  gracz wygenerował pasek w kontekście całej klatki gry (wszystko `#0000FF`
  poza paskiem u góry) — generator utrzymał stałą grubość plecionki 18–24 px
  na wszystkich 4 krawędziach i spokojne strefy tekstu/statystyk. Źródła:
  `docs/asset_plan/hud_fullscreen_sources/hud_fullscreen_act1/2.png` (1672×941;
  w `docs/`, bo `.gdignore` trzyma je poza importem i buildem — gra ładuje
  tylko wycięte `top_status_bar_slim_*.png`).
- Post-processing (PIL one-off): crop paska po bounding-boxie nie-niebieskich
  pikseli (oba akty: y 95–229 → 1672×135), chroma-key po odległości od
  `#0000FF` (progi INNER 90 / OUTER 150 + despill, jak `chroma_key_blue.gd`)
  → `top_status_bar_slim_act1/2.png`. Kod HUD (pre-skala do 80 px + 9-slice
  16%) podniósł je plug-and-play, zero zmian w kodzie.
- Weryfikacja sondą `tmp/probe_ui.tscn`: 1920×1080 i 2550×1288 (okno gracza)
  — plecionka trzyma grubość, ptak niezniekształcony, statystyki czytelne na
  spokojnej tkaninie; `ui_layout_test` zielony. Akt II (martwa plecionka,
  kruk-brąz) wycięty czysto — do rzutu oka w grze po BUM.
- **Ramka do krawędzi okna** (feedback: w mockupie plecionka biegnie edge-to-
  edge, w grze pasek siedzi w MarginContainer z odstępem 16 px):
  `top_status_bar_view._bleed_frame_to_window_edges()` rozlewa SAM NinePatch
  poza margines layoutu do krawędzi okna (offsety = zmierzone `global_position`
  vs szerokość viewportu, odświeżane deferowane przy `NOTIFICATION_RESIZED`);
  teksty/statystyki w `Row` zostają w marginesach. Płaski fallback (brak PNG)
  celowo bez rozlania. Wydane jako **v1.0.6** (tag → CI → GitHub Release);
  lokalny tag `v1.0.5` wisiał niewypchnięty na starszym commicie, stąd skok
  numeru.

## Konwencje

- GDScript ze **statycznym typowaniem** (typy parametrów, zwracane, `:=`).
- Pliki: `snake_case.gd` / `.tscn` / `.tres`; klasy: `PascalCase`
  (`class_name`); stałe: `SCREAMING_SNAKE_CASE`; sygnały i metody: `snake_case`.
- Teksty widoczne dla gracza po polsku; kod, nazwy i komentarze po angielsku.
- Logika w `systems/` nie może importować niczego ze `scenes/` ani `ui/`.
- Po każdym większym kroku: aktualizacja changelogu w tym pliku.
- Małe, częste commity z opisowymi komunikatami (po polsku).
