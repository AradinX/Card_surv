# Brakujące tła skorumpowanych biomów — Zaćmienie / Powódź / Pęknięcie

Audyt (2026-07-03): sprawdzone `assets/art/biomes/backgrounds/corrupted/` i cały
`docs/asset_plan/` — istnieje komplet 8 teł Aktu II wyłącznie dla **Plagi**
(`biome_<biom>_plague_bg.png`). Nigdzie w repo (dokumenty, historia, konspekty)
nie ma gotowych promptów dla pozostałych 3 katastrof — ten plik jest pierwszym
zestawem, nic wcześniej nie duplikuje.

Gra ma 4 katastrofy (`data/disasters/*.tres`: `plague`, `eclipse`, `flood`,
`rift`), każda z własną mechaniką i kolorem ekranu Aktu II (`run.gd ACT2_LOOK`),
ale **wygląd kafli planszy jest współdzielony i zawsze zielony jak Plaga** — to
świadomie odnotowany dług w changelogu (`docs/CLAUDE.md`, wpis
2026-06-19 „Wygląd Aktu II zależny od katastrofy"). Ten dokument to prompty pod
brakujące 24 tła (3 katastrofy × 8 biomów), żeby domknąć tę lukę wizualnie.

## Parametry techniczne

- Rozmiar: `1536x1024` (`landscape_hd`), tak jak istniejący komplet Plagi.
- Format: PNG, `quality: high`, `num_images: 1`.
- Katalog docelowy: `assets/art/biomes/backgrounds/corrupted/`.
- Czyste tło terenu — bez ramki, bez plakietki nazwy, bez slotów budowli, bez
  liczników, bez tekstu. Godot dokłada ramkę/plakietkę/sloty/overlay osobno
  (dokładnie jak przy istniejących tłach Plagi).
- Nazewnictwo plików: `biome_<art_id>_<disaster_id>_bg.png`, gdzie `art_id` to
  wartość z `BIOME_ART_IDS` w `ui/biome_tile_view.gd` (uwaga: `meadows` → art_id
  `meadow`, liczba pojedyncza; reszta identyczna z `id` biomu).
- Po wrzuceniu plików: `Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

## Referencje stylu

- Cały istniejący komplet `assets/art/biomes/backgrounds/corrupted/biome_*_plague_bg.png`
  — ta sama kompozycja/skala/gęstość detalu, inna paleta.
- Odpowiadające czyste tła Aktu I `assets/art/biomes/backgrounds/normal/biome_*_normal_bg.png`
  — geografia biomu (co widać na tle) ma zostać rozpoznawalna, tylko skorumpowana.
- Kolor katastrofy już wpięty w `scenes/run.gd ACT2_LOOK` (tint ekranu Aktu II,
  ma się zgadzać z tłem kafli):
  - **Zaćmienie**: `fx_tint (0.55, 0.7, 1.05)`, `scrim (0.04, 0.05, 0.11)` — lodowy
    błękit/fiolet na niemal czarnym granacie.
  - **Powódź**: `fx_tint (0.5, 0.85, 0.85)`, `scrim (0.03, 0.08, 0.09)` — mętny
    turkus/cyjan na ciemnej zieleni-czerni.
  - **Pęknięcie**: `fx_tint (1.05, 0.66, 0.4)`, `scrim (0.10, 0.05, 0.03)` — piaskowy
    pomarańcz/brąz na ciemnej rdzy.

## Wspólny szkielet promptu

```text
Use case: stylized-concept
Asset type: clean corrupted biome terrain background layer for a 2D survival card roguelike
Primary request: Generate the named `*_bg.png` asset for "Dzien 50" (Act II, post-catastrophe) as a clean production background for layered Godot composition.
Composition/framing: one wide horizontal rectangular terrain background. Pure terrain only: no border, no card frame, no title plaque, no slot cards, no UI panels. Keep calm readable areas where Godot can overlay building slot markers later, without drawing slots.
Style/medium: refined SNES-era / premium indie pixel art, medium-size visible pixels, crisp hard edges, readable clusters, controlled dithering, clean retro strategy-game environment art. Same rendering style and detail density as the existing `biome_*_plague_bg.png` set, different palette/mood only.
Lighting/mood: {DISASTER_MOOD}
Text constraints: text-free image. NEVER include letters, numbers, words, symbols, labels, watermark, pseudo-text, fake glyphs, UI captions, decorative writing, title areas, or signs.
Production constraints: pure terrain/background layer only. MUST contain no UI elements of any kind. MUST stay readable as the same underlying biome as its Act I counterpart, just corrupted. Compatible with separate Godot overlays for frame, title plate, slot markers, hover/selected state, current player marker, and text. Avoid photorealism, painterly blur, 3D render, characters, gore.
Subject: {SUBJECT}
```

Wypełnij `{DISASTER_MOOD}` i `{SUBJECT}` z tabel niżej.

---

## Zaćmienie (`eclipse`) — mróz i ciemność

`{DISASTER_MOOD}`: Endless frozen night, no sun, pale cold moonlight, drifting
ice fog, blue-violet shadows, hoarfrost on every surface. Same locations as Act I,
now frozen and dark rather than rotten.

| Plik | Subject |
|---|---|
| `biome_forest_eclipse_bg.png` | Frozen pine forest at night, bare frost-blackened branches, ice-crusted undergrowth, pale blue moonlight through fog, space for 2 slots. |
| `biome_meadow_eclipse_bg.png` | Open meadow buried in wind-blown snow and dead frozen grass stalks poking through ice, faint aurora-cold sky glow, space for 2 slots. |
| `biome_mountains_eclipse_bg.png` | Alpine rocks sheathed in thick ice, frozen dead pines, driving blizzard haze, jagged icicles, space for 2 slots. |
| `biome_swamp_eclipse_bg.png` | Frozen bog with ice-locked black water, frost-rimed reeds standing stiff, cracked ice sheet over mud, space for 2 slots. |
| `biome_river_eclipse_bg.png` | River choked with jagged pack ice and frozen spray, ice-coated stones on the banks, pale cold light, space for 3 slots. |
| `biome_wasteland_eclipse_bg.png` | Cracked wasteland ground under a hard frost, dead brush rimed with ice crystals, cold dust haze, space for 3 slots. |
| `biome_caves_eclipse_bg.png` | Cave mouth choked with hanging icicles and frozen drip formations, pale blue interior glow, frost on stone, space for 2 slots. |
| `biome_coast_eclipse_bg.png` | Rocky shore with frozen sea spray and ice-crusted driftwood, dark frigid water, pale moon on the horizon, space for 3 slots. |

---

## Powódź (`flood`) — woda i gnicie

`{DISASTER_MOOD}`: Endless grey rain and standing floodwater, waterlogged ground,
murky teal-green water, drowned vegetation, damp mist. Same locations as Act I,
now submerged/soaked rather than dry-rotten.

| Plik | Subject |
|---|---|
| `biome_forest_flood_bg.png` | Flooded pine forest, tree trunks standing in murky ankle-deep water, waterlogged mossy roots, grey drizzle, space for 2 slots. |
| `biome_meadow_flood_bg.png` | Meadow turned to shallow marsh, flattened waterlogged grass poking from muddy floodwater, overcast grey sky, space for 2 slots. |
| `biome_mountains_flood_bg.png` | Mountain slope with rain-swollen runoff streams cutting through mud, slick wet rock, low grey rainclouds, space for 2 slots. |
| `biome_swamp_flood_bg.png` | Swamp fully submerged, black-teal water covering the ground, reeds barely breaking the surface, heavy rain ripples, space for 2 slots. |
| `biome_river_flood_bg.png` | River burst its banks, fast murky brown-teal floodwater carrying debris, half-submerged rocks, space for 3 slots. |
| `biome_wasteland_flood_bg.png` | Cracked wasteland ground turned to flat standing floodwater and mud, dead brush half-submerged, grey haze, space for 3 slots. |
| `biome_caves_flood_bg.png` | Cave mouth with water pouring/dripping heavily inside, flooded entrance floor, damp reflective stone, space for 2 slots. |
| `biome_coast_flood_bg.png` | Coast under storm surge, waves pushed far inland over rocks, driftwood tangled in murky floodwater, grey rain, space for 3 slots. |

---

## Pęknięcie (`rift`) — pęknięta ziemia i pył

`{DISASTER_MOOD}`: Dry choking dust haze, warm sandy-orange light through cracked
sky, deep fissures splitting the ground, loose rubble. Same locations as Act I,
now torn open and dust-covered rather than rotten.

| Plik | Subject |
|---|---|
| `biome_forest_rift_bg.png` | Forest floor split by a deep jagged fissure, uprooted and leaning scorched trees, dust haze, orange-brown light, space for 2 slots. |
| `biome_meadow_rift_bg.png` | Meadow ground cracked into dry dusty plates, small chasms between clumps of dead grass, hazy amber sky, space for 2 slots. |
| `biome_mountains_rift_bg.png` | Mountain rock shattered by tremors, loose rubble and scree fields, a wide crack splitting the ridge, dust cloud, space for 2 slots. |
| `biome_swamp_rift_bg.png` | Swamp drained and cracked into dry mud plates over a black fissure, dead reeds, dust drifting over stagnant puddles, space for 2 slots. |
| `biome_river_rift_bg.png` | Riverbed torn open by a fissure, water diverted into a churning crack, exposed cracked stones, dust haze, space for 3 slots. |
| `biome_wasteland_rift_bg.png` | Wasteland ground split by a wide chasm, loose rubble and rockfall, thick dust haze, dim orange light, space for 3 slots. |
| `biome_caves_rift_bg.png` | Cave interior with a fresh rockfall and a fissure splitting the floor, dust still settling, unstable loose stone, space for 2 slots. |
| `biome_coast_rift_bg.png` | Coastal rock shelf cracked and partly collapsed into the sea, rubble on the shoreline, dust haze over dark water, space for 3 slots. |

---

## Uwagi implementacyjne

- **Kod dziś ZAWSZE ładuje sufiks `plague` dla skorumpowanego kafla**, niezależnie
  od wylosowanej katastrofy — to dwa miejsca do poprawy PO wygenerowaniu plików:
  - `ui/biome_tile_view.gd` — `_background_path()` (linia ~397): buduje nazwę
    pliku z twardym `"plague" if tile.is_corrupted else "normal"`.
  - `scenes/run.gd` — `_tile_background_path` (okolice linii 1306): ta sama
    literówka logiczna, osobna kopia tego samego wzorca.
  Obie funkcje trzeba przełączyć na `state.disaster.id` zamiast stałego
  `"plague"`, z fallbackiem do `plague`, gdy plik dla danej katastrofy nie
  istnieje (tak jak dziś działa fallback do `biome_forest_normal_bg.png`).
- Do czasu tej zmiany kodu nowe pliki będą leżeć gotowe, ale nieużywane w grze
  (bezpieczne — zero ryzyka regresji, czysto addytywne).
- Warto wygenerować od razu całą trójkę per biom (żeby paleta/tint od razu było
  spójne), ale bez przeszkód można też iść katastrofa po katastrofie.
