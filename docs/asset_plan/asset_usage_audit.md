# Audyt użycia assetów — „Dzień 50" (2026-06-13)

Mapa: który plik graficzny jest realnie wpięty w grę (scena/skrypt), a który
leży „w zapasie". Po segregacji assety nieużywane i referencyjne wyjechały do
`assets/_reference/` (katalog ma `.gdignore`, więc Godot ich nie importuje).

Legenda: **[WPIĘTE]** = ładowane przez scenę lub skrypt w czasie gry ·
**[ZAPAS]** = w `assets/art/`, gotowe, jeszcze nieładowane ·
**[_reference]** = przeniesione poza import Godota.

---

## backgrounds/
- `run_screen/bg_run_table.png` — **[WPIĘTE]** tło `main_menu.tscn`
  (TextureRect + scrim).

## board/
- `backgrounds/bg_biome_board_act1.png` — **[WPIĘTE]** tło `run.tscn` (Akt I).
- `backgrounds/bg_biome_board_act2.png` — **[WPIĘTE]** podmieniane w
  `run.gd::_on_bum_struck` po BUM (Akt II).
- `bg_biome_board.png` (duplikat act1, MD5 identyczny) — **[_reference/unused]**.
- `markers/`, `player_marker/` (move_arrow itp.) — **[ZAPAS]**, brak referencji
  w kodzie (ruch i pozycja rysowane są dziś przez `biome_tile_view`).

## biomes/
- `backgrounds/normal/biome_{forest,meadow,mountains}_normal_bg.png` —
  **[WPIĘTE]** `biome_tile_view.gd` (tło kafla Akt I).
- `backgrounds/corrupted/biome_{...}_plague_bg.png` — **[WPIĘTE]** tło kafla
  po BUM.
- `frames/biome_tile_frame.png` — **[WPIĘTE]** ramka kafla Akt I (chroma-key →
  alpha, NinePatch/TextureRect w kaflu).
- `frames/biome_title_plate.png` — **[WPIĘTE]** nameplate nagłówka kafla
  (NinePatchRect; nazwa biomu + liczba slotów).
- `overlays/biome_corruption_overlay.png` — **[WPIĘTE]** ramka kafla Akt II
  (podmiana za `tile_frame` gdy `is_corrupted`).
- `overlays/biome_current_player.png` — **[WPIĘTE]** marker „tu jesteś" na
  bieżącym kaflu.
- `slot_markers/slot_empty.png`, `slot_selectable.png` — **[ZAPAS]**.
  Chroma-key zrobiony, ale to pionowe panele-sloty (2:3) i nie pasują do
  poziomego miniaturowego kafla (3:2). Czekają na powierzchnię „rozkład
  slotów budynków" (osobny panel kafla), wtedy wejdą.

## cards/
- `frames/card_frame_action.png` — **[WPIĘTE]** domyślna ramka (akcje/budynki
  używają jej przez `_frame_path`; uwaga: kod stałą nazywa `FRAME_BUILDING`).
- `frames/card_frame_event.png` — **[WPIĘTE]** ramka kart zdarzeń (`card_view`).
- `frames/card_frame_monster.png` — **[WPIĘTE]** ramka kart potworów.
- `frames/card_frame_reward.png` — **[_reference/unused]** (brak osobnego
  widoku nagrody-karty; nagroda używa zwykłej ramki).
- `illustrations/actions_act1_candidates/*` — **[WPIĘTE]** ilustracje akcji
  (jasny zestaw Akt I) przez `ACTION_ART_DIR` + aliasy.
- `illustrations/buildings_act1_candidates/*` — **[WPIĘTE]** ilustracje
  budynków (jasny zestaw Akt I).
- `illustrations/monsters/*` — **[WPIĘTE]** ilustracje potworów (aliasy).
- `illustrations/actions/`, `illustrations/buildings/` (ciemne zestawy
  Akt II) — **[ZAPAS]**. Docelowo podmiana po BUM; dziś `card_view` ciągle
  ładuje zestawy `_act1_candidates`. (Follow-up: swap zestawu po `bum_struck`.)
- `illustrations/events/` — **[ZAPAS]** pusty/placeholder (brak ilustracji
  per-event; karta zdarzenia pokazuje samą ramkę).
- `icons/*` (36 płaskich ikon) — **[ZAPAS]**, brak referencji w kodzie
  (placeholder paska kosztów to dziś tekst „E/J/D/M").

## fx/
- całość (`bum/`, `weather/`, `discovery/`, `card/`) — **[ZAPAS]**, brak
  referencji w kodzie. Do podpięcia przy animacjach BUM/pogody/odkrywania.

## ui/
- `bars/`, `buttons/`, `panels/`, `icons/` (19 plików) — **[ZAPAS]**, **żaden
  nie jest wpięty**. Jedyne trafienia w repo to auto-generowane `.import`
  i plany w `docs/`. UI gry stoi dziś na domyślnym theme Godota; to pierwsze
  produkcyjne placeholdery do wymiany skórki (9-slice buttony/panele, paski
  statystyk, top bar). Wymagają złożenia własnego `Theme`/StyleBox w Godot.

## fonts/
- pusty — brak własnych fontów (domyślny font silnika).

---

## Przeniesione poza import: `assets/_reference/`
- `unused/` — `bg_biome_board.png` (dup), `biome_neighbor_highlight.png`,
  `neighbor_connector.png`, `card_frame_reward.png` (odrzucone kierunki).
- `concepts/` — historia zatwierdzeń (rewersy, koncepty ramek, legacy).
- `icons_deck_style_candidates/` — **odpowiedź na pytanie #19**: ten
  deck-style pack ikon (złote medaliony) **nie jest nigdzie referowany** —
  to kandydat, który nie zastąpił płaskich `cards/icons/`. Trzymany jako
  materiał do decyzji, poza importem.
- `biomes_greenkey_src/` — surowe (zielone) źródła 6 assetów biomów sprzed
  chroma-key, gdyby trzeba było przerobić próg keyowania.

## Pipeline chroma-key (biomes)
6 assetów biomów dostarczono na surowym tle `#00FF00`. Wycięcie do alpha:
próg `G>150 ∧ R<120 ∧ B<120 ∧ (G−R)>80 ∧ (G−B)>80` (oszczędza złote ornamenty,
liście i szmaragdowe klejnoty) + tłumienie green-spillu na krawędziach.
Źródła w `assets/_reference/biomes_greenkey_src/`. Powtórka: keyować tylko
czysty chroma-zielony, nie ruszać ciemnej zieleni paneli ani szmaragdów.
