# Skażone karty zbierania — unikalne per biom, wygląd zależny od katastrofy

Audyt (2026-07-04): każdy biom ma już swój unikalny skorumpowany LOOK
(`corrupted_display_name`/`corrupted_description` w `data/biomes/*.tres`, np.
Bagno → „Trujące Mokradła"), ale karty AKCJI zbierania, które faktycznie grasz
po BUM, nie są unikalne — 4 karty (`murky_water`, `tainted_hunt`,
`rotten_forage`, `salvage_scrap` w `data/cards/actions/corrupted/`) są
recyklowane w 6–4 biomach naraz z jednym wspólnym artem (np. `tainted_hunt`
gra jednocześnie w Lesie, Bagnie, Łąkach i na Wybrzeżu). To jest luka, o którą
pyta gracz: „żeby podczas katastrofy wszystkie karty biomów miały swój
odpowiednik skażony" — czyli 1 unikalna skażona karta zbierania NA BIOM,
zamiast 4 recyklowanych na 8 biomów. Dodatkowo, tak jak tła kafli (wpis
2026-07-03), wygląd tej karty ma zależeć od tego, KTÓRA z 4 katastrof
(`plague`/`eclipse`/`flood`/`rift`) wylosowała się w danym runie.

Ten dokument to kompletna specyfikacja: 8 nowych kart danych (`.tres`) + 32
prompty ilustracji (8 biomów × 4 katastrofy), gotowe do wklejenia do
pipeline'u obrazów. Świadomie NIE tworzymy 32 osobnych kart danych — mechanika
(koszt/efekt) zostaje jedna na biom, zmienia się tylko ilustracja i opis
fabularny wg katastrofy (dokładnie ten sam wzorzec co tła kafli).

## 1. Nowe karty danych (`data/cards/actions/corrupted/`)

Liczby są SKOPIOWANE 1:1 z istniejących, już wybalansowanych kart (zero
nowego ryzyka balansu) — zmienia się tylko `id`/`display_name`/`description`,
żeby każdy biom miał własną tożsamość zamiast dzielonej. Wzorzec liczbowy
w nawiasie mówi, z której dzisiejszej karty pożyczono wartości.

| Biom | Nowy plik | `id` | Zasób (wzorzec) | Koszt/efekt | `display_name` | `description` (PL) |
|---|---|---|---|---|---|---|
| Las (`forest`) | `forest_tainted.tres` | `forest_tainted` | jedzenie (`tainted_hunt`) | 2 energii, +3 jedz., −1 zdr. | Padlina spod korzeni | „Coś leży pod czarnymi korzeniami. Mięso jest ciepłe, choć nie powinno." |
| Bagno (`swamp`) | `swamp_tainted.tres` | `swamp_tainted` | jedzenie (`tainted_hunt`) | 2 energii, +3 jedz., −1 zdr. | Wzdęta zdobycz | „Wyciągasz coś z mułu. Wzdęte, ale jeszcze jadalne — mówisz sobie." |
| Góry (`mountains`) | `mountains_tainted.tres` | `mountains_tainted` | woda (`murky_water`) | 1 energii, +1 wody, −1 zdr. | Skażony roztop | „Woda ścieka po skale w nienaturalnym kolorze." |
| Łąki (`meadows`) | `meadows_tainted.tres` | `meadows_tainted` | jedzenie (`rotten_forage`) | 1 energii, +2 jedz., −1 zdr. | Zgniłe kłosy | „Kłosy poczerniały, ale ziarno w środku jeszcze się trzyma." |
| Rzeka (`river`) | `river_tainted.tres` | `river_tainted` | woda (`murky_water`) | 1 energii, +1 wody, −1 zdr. | Czarna toń | „Nurt zgęstniał, prawie nie płynie. Smak jest metaliczny." |
| Pustkowie (`wasteland`) | `wasteland_tainted.tres` | `wasteland_tainted` | materiały (`salvage_scrap`) | 2 energii, +1 mat., −1 zdr. | Spopielony złom | „Przepalony metal kruszy się w palcach, tnie jak brzytwa." |
| Jaskinie (`caves`) | `caves_tainted.tres` | `caves_tainted` | materiały (`salvage_scrap`) | 2 energii, +1 mat., −1 zdr. | Jaskiniowy rumosz | „Odłamki ze ściany jaskini pokryte są śliskim, cierpkim nalotem." |
| Wybrzeże (`coast`) | `coast_tainted.tres` | `coast_tainted` | jedzenie (`tainted_hunt`) | 2 energii, +3 jedz., −1 zdr. | Skażone połowy | „Ryby wyławiasz martwe na brzuchu, łuski poplamione czarną smugą." |

Implementacja (poza zakresem tego dokumentu — to plan artu/danych, nie kod):
podmienić w każdym `data/biomes/<biom>.tres` odpowiedni wpis w
`corrupted_gather_cards` z dzielonej karty (`tainted_hunt`/`murky_water`/
`rotten_forage`/`salvage_scrap`) na nową dedykowaną. Stare 4 dzielone karty
mogą zostać w repo nieużywane albo zostać usunięte — decyzja przy wdrożeniu.

## 2. Parametry techniczne ilustracji

- Rozmiar: `1024×688` (jak cały istniejący komplet
  `actions_act1_candidates/`), PNG, **bez kanału alfa** (pełne nieprzezroczyste
  tło — ilustracja idzie pod maskę ramki karty, tak jak reszta akcji).
- Katalog docelowy: `assets/art/cards/illustrations/actions_act1_candidates/`.
- Nazewnictwo: `action_<biom>_tainted_<katastrofa>.png`, np.
  `action_forest_tainted_plague.png`, `action_forest_tainted_eclipse.png`,
  `action_forest_tainted_flood.png`, `action_forest_tainted_rift.png`.
- Referencje do podania w każdej generacji: `card_back_action.png` (paleta),
  odpowiednie skorumpowane tło Aktu II danego bioamu+katastrofy z
  `assets/art/biomes/backgrounds/corrupted/biome_<biom>_<katastrofa>_bg.png`
  (już wygenerowane, wpis 2026-07-03 — spójność kolorystyczna kafla i karty),
  oraz istniejąca skażona karta jako REF-STYLE:
  `assets/art/cards/illustrations/actions_act1_candidates/action_tainted_hunt.png`
  (kompozycja: pojedynczy skażony przedmiot/zdobycz na pierwszym planie,
  bagienne/leśne tło rozmyte, bez ludzi).
- Po wrzuceniu plików: `Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

## 3. Wspólny szkielet promptu

```text
Standalone pixel-art CARD ILLUSTRATION for the dark survival roguelike "Dzien 50",
ACT II after the catastrophe. Subject: {SUBJECT}. Centered, strong readable
silhouette as the hero of the card (a single tainted/corrupted food, water or
scrap item being gathered), no people, no faces, no hands. Single horizontal
3:2 still-life scene, background is the corrupted biome environment blurred
softly behind the subject, gentle vignette, content kept away from edges
(sits inside a card art window). Same rendering style as the existing corrupted
gather cards: refined pixel art, medium visible pixels, crisp hard edges,
controlled dithering, embroidery-like deck palette.
Mood/palette: {DISASTER_MOOD}
Text constraints: text-free image. No letters, numbers, words, UI, frame,
border, or icons.
Avoid: photorealism, painterly blur, 3D render, gore, visible corpses/bodies,
human or animal faces in distress.
Output: 1024x688, solid background, no transparency.
```

Wypełnij `{SUBJECT}` z tabeli niżej (kolumna per katastrofa) i
`{DISASTER_MOOD}` z sekcji 4.

## 4. Nastrój per katastrofa (spójny z tłami kafli)

- **Plague** (bazowy, już istniejący ton): sickly green rot, spores, decay,
  dim swamp-green light.
- **Eclipse**: frozen solid, pale blue-violet ice crust, frost crystals, cold
  moonlight glare.
- **Flood**: waterlogged and bloated, murky teal-grey water sheen, dripping,
  drowned look.
- **Rift**: dust-dried and cracked, sandy orange-brown haze, brittle jerky-like
  desiccation.

## 5. Tabela promptów — 8 biomów × 4 katastrofy (32 pliki)

| Biom | Plague `{SUBJECT}` | Eclipse `{SUBJECT}` | Flood `{SUBJECT}` | Rift `{SUBJECT}` |
|---|---|---|---|---|
| `forest` | A skinned carcass half-buried under black twisted roots, sickly green sheen on the flesh, dark forest floor | The same carcass frozen solid under hoarfrost, ice crystals on stiff fur, pale frost-blackened roots | The carcass waterlogged and bloated, lying in murky ankle-deep floodwater among drowned roots | The carcass mummified and dust-dry, cracked leathery hide, torn roots in a dusty fissure |
| `swamp` | A bloated dead fish/creature pulled from black mud, mossy purple-spotted fungus growth, boggy roots (matches existing `action_tainted_hunt.png` — reuse as Plague variant, zero-cost) | The same catch frozen into the ice-locked bog surface, frost rime on scales, stiff reeds | The catch floating in flooded black swamp water, waterlogged and swollen, heavy rain ripples | The catch shriveled on cracked dry mud where the bog drained away, dust settling on the reeds |
| `mountains` | A trickle of sickly green meltwater pooling in a stone hollow, mossy toxic sheen on rock | Jagged icicles dripping pale blue-white water into a frost-rimed stone catch basin | Rain-swollen grey runoff pouring off wet slick rock into a stone hollow | A thin trickle of dusty orange water seeping through a cracked, rubble-strewn rock fissure |
| `meadows` | A handful of blackened, sickly-green grain stalks with fungal spores, rotten meadow ground | Frost-blackened grain stalks poking through wind-blown snow, ice-crusted heads | Flattened waterlogged grain stalks half-submerged in muddy floodwater | Dry brittle grain stalks in dust-cracked meadow soil, hazy amber light |
| `river` | Thick black-green river water pooling in a cupped vessel, oily sheen, dead reeds nearby | Jagged pack ice chunks in a vessel of near-frozen dark water, frost on the rim | Fast murky brown-teal floodwater filling a vessel, debris swirling | Muddy, near-dry water pooling in a cracked exposed riverbed stone |
| `wasteland` | Charred, sickly green-tinged scrap metal shards in ashen rubble | Ice-crusted scrap metal shards rimed with frost in cold wasteland dust | Scrap metal shards half-submerged in flat standing floodwater and mud | Charred scrap metal shards half-buried in a dust-choked fissure, orange haze |
| `caves` | Slick, sickly green-glowing mineral rubble on a poisoned cave floor | Ice-crusted cave rubble hanging with small frozen drip formations, pale blue glow | Wet reflective cave rubble sitting in shallow flooded cave-floor water | Fresh dusty rockfall rubble settling on a fissured cave floor, unstable loose stone |
| `coast` | Dead fish with sickly green-black discoloration on wet dark shore rocks | Ice-crusted dead fish on a frost-rimed rocky shore, pale frigid water behind | Dead fish tangled in storm-driven floodwater and dark driftwood on the shore | Sun-dried, salt-crusted dead fish on a cracked, dust-hazed rocky shelf |

## 6. Uwagi implementacyjne (do zrobienia PO wygenerowaniu artu)

- **Kod dziś wybiera ilustrację akcji wyłącznie po `id`** (`card_view.gd`
  `_illustration_path()` → `action_<id>.png`), bez pojęcia o wylosowanej
  katastrofie — dokładnie ten sam dług, co miały tła kafli przed poprawką
  2026-07-03. Do zmiany: `_illustration_path()` (albo `CardView.setup()`)
  musi przyjąć `disaster_id` (dostępne w `run.gd` jako
  `state.disaster.id`) i próbować `action_<id>_<disaster_id>.png` PRZED
  fallbackiem do samego `action_<id>.png`. Dzięki fallbackowi wdrożenie może
  być stopniowe: wygenerowany tylko wariant `plague` już działa jako
  domyślny wygląd dla wszystkich katastrof, reszta dogenerowywana bez
  ryzyka regresji (identyczny wzorzec co `biome_tile_view._background_path()`).
- `swamp` może zaoszczędzić jedną generację: istniejący
  `action_tainted_hunt.png` już wizualnie pasuje (bagno, mech, zgnilizna) —
  można go po prostu przenieść/skopiować jako
  `action_swamp_tainted_plague.png` zamiast generować od zera.
- Reszta 31 plików wymaga generacji; kolejność sugerowana: najpierw komplet
  `plague` (8 plików = fallback dla wszystkich katastrof), potem
  `eclipse`/`flood`/`rift` biom po biomie.
