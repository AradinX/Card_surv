# Dzień 50 (tytuł roboczy; wcześniej „Karcianka: Przetrwanie")

Karciany roguelike survivalowy 2D (desktop, Godot 4.5), singleplayer.
**Pełny koncept gry jest w [README.md](README.md)** — to on wyznacza kierunek:
run ~60–90 min w dwóch aktach (budowa osady na planszy 6 kafli biomów →
katastrofa **BUM** → przetrwanie do dnia 50), wszystko jest kartą (akcje,
budynki, zdarzenia, potwory, kafle biomów), klasy postaci, meta-progresja
„różnorodność zamiast siły".

Stan obecny: gra toczy się na planszy 6 kafli biomów (kroki 1–3 vertical
slice'a z README sekcja 10) — mapa węzłów z etapu 2 została zastąpiona
i usunięta (historia w gicie). Run = przetrwaj do dnia 30 w dwóch aktach:
Akt I (budowa), BUM w dniu 13–16 (Plaga: flip kafli, uszkodzenia budynków),
Akt II (potwory nocą, naprawy, ruiny, obrona). 4 statystyki, budynki jako
karty, akcje biomu, ruch za energię, XP i poziomy z nagrodami 1 z 3
(deckbuilding w runie, w puli nagród też budynki).

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

### Port przeglądarkowy (Higgsfield) — równoległy artefakt (2026-06-12)

- Grywalny web-port konceptu (slice + akt BUM, run 30 dni) zbudowany
  pipeline'em Higgsfield.ai: https://simple-warbler-784.higgsfield.gg/
- Źródła i artefakty projektowe w `web/` (katalog ma `.gdignore` — Godot
  go nie skanuje); szczegóły w `web/README.md` i `web/design/`.
- To prototyp równoległy do gry w Godot — wersja Godot pozostaje główną
  linią rozwoju; rozbieżności balansu opisane w `web/README.md`.

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
- `docs/` dostał `.gdignore` (jak `web/`) — Godot nie importuje już
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
```

- `smoke_test` — naiwny bot rozgrywa 50 pełnych runów na planszy (karty
  z ręki + akcje biomu + wędrówka), sprawdza że każdy kończy się
  wygraną/przegraną.
- `board_test` — niezmienniki 200 wygenerowanych plansz + sąsiedztwo kafli.
- `load_test` — poprawność typów ręcznie pisanych zasobów `.tres`.
- `season_test` — harmonogram pór roku w 30-dniowym vertical slice.
- `ui_layout_test` — headless instancjonowanie kart i kafli, łapie błędy
  w UI-only kodzie typu auto-fit tekstu i dobór ramek.

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
                        BUM (flip planszy, uszkodzenia), potwory nocą,
                        naprawy/ruiny/rozbiórka, warunki końca
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
3. Noc (obecnie): pasywy budynków (globalne, ruiny pomijane) → karta
   z talii zdarzeń: zwykłe zdarzenie (Szałas łagodzi chronione) ALBO po BUM
   potwór (rani gracza i losowy budynek; Szałas/defense łagodzą) →
   sytość/nawodnienie spadają i automatyczne jedzenie/picie →
   głód/odwodnienie/zamarzanie biją w zdrowie → śmierć (przegrana) /
   dzień 30 przeżyty (wygrana) / kolejny dzień.
   O świcie dnia BUM (13–16): flip planszy, uszkodzenia budynków,
   przebudowa talii zdarzeń.
4. Noc (docelowo): po kliknięciu `Zakończ dzień` pojawia się duża karta
   zdarzenia z aktywnej, wagowanej puli; gracz klika `OK`, dopiero wtedy
   efekt i podsumowanie nocy są rozliczane oraz logowane.

Balans (stałe w `run_state.gd`, `survival_system.gd`): startowe maks.
statystyki 10 (zdrowie/energia rosną nagrodami awansu), energia 10/dzień
(cap maks.+1 ze Słonecznym porankiem), ruch 1 energii, sytość i nawodnienie
-2 dziennie, ciepło -1 dziennie, 1 jedzenie = +2 sytości (Kucharz: +3),
1 woda = +2 nawodnienia, głód/odwodnienie/mróz -2 zdrowia dziennie, Szałas
-2 obrażeń z chronionych zdarzeń, narzędzia +1 do zysku jedzenia/drewna,
XP: +1 karta/akcja biomu, +3 budynek, próg 8 + 4×(poziom−1), wygrana
w dniu 30. BUM: dzień 13–16, uszkodzenia budynków 10–80%, ruina poniżej
50% maks. HP, naprawa 1 energia + 1 drewno/2 HP, rozbiórka ruiny 1 energia
+ zwrot połowy surowców, Szałas -2 obrażeń także od potworów, Palisada
defense 2 (kafel). Punkt odniesienia: naiwny bot ze smoke testu wygrywa
~56–62% runów (śr. ~27 dni, śr. poziom ~9); sam Akt I wygrywał ~90%.

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
- `RunState` jest `Resource` z `@export` (w tym plansza, talia, postęp
  poziomów oraz `disaster`/`bum_day`/`bum_happened`) — gotowy pod
  save/load.
- Fog-of-war planszy: dodać stan odkrycia kafli do `TileState`/`RunState`,
  ukryć dane nieodkrytych kafli w UI, odkrywać kafel po ruchu; dopiero
  odkryte biomy powinny aktywować swoje zdarzenia w nocnej puli.
- Nocne zdarzenia: zastąpić prostą talię zdarzeń aktywną pulą z wagami,
  cooldownami, limitami i tagami; dodać popup dużej karty przed rozliczeniem.
- `BoardGenerator` używa wstrzykiwanego RNG (`SurvivalSystem` ma własny) —
  gotowe pod seedowane runy.
- Kolejne kroki wg README sekcja 10 (każdy osobną decyzją): uproszczone
  pory roku, drugi typ katastrofy (Pęknięcie/Zaćmienie — szkielet danych
  `DisasterData` już to umożliwia, system losuje z puli), ulepszanie kart
  (wtedy wraca jako nagroda awansu), docelowy run do dnia 50.

## Konwencje

- GDScript ze **statycznym typowaniem** (typy parametrów, zwracane, `:=`).
- Pliki: `snake_case.gd` / `.tscn` / `.tres`; klasy: `PascalCase`
  (`class_name`); stałe: `SCREAMING_SNAKE_CASE`; sygnały i metody: `snake_case`.
- Teksty widoczne dla gracza po polsku; kod, nazwy i komentarze po angielsku.
- Logika w `systems/` nie może importować niczego ze `scenes/` ani `ui/`.
- Po każdym większym kroku: aktualizacja changelogu w tym pliku.
- Małe, częste commity z opisowymi komunikatami (po polsku).
