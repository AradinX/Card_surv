# Skażone karty biomowe Aktu II — domknięcie wszystkich recyklowanych kart

Audyt (2026-07-04, kontynuacja): po wpięciu 8 unikalnych skażonych kart
zbierania per biom (`ASSET_PROMPTS_DISASTER_TAINTED_GATHER_CARDS.md`) w
`corrupted_gather_cards` biomów zostały jeszcze DWIE kategorie kart bez
wyglądu zależnego od katastrofy:

1. **Resztki starych dzielonych kart** — po podmianie głównych slotów zostały
   4 karty, które nadal są recyklowane (albo są jedynym niewyróżnionym
   drugim/trzecim slotem biomu): `murky_water` (Jaskinie/Las/Bagno/Pustkowie),
   `salvage_scrap` (tylko Wybrzeże), `rotten_forage` (tylko Las, drugi slot
   jedzenia obok `forest_tainted`), `tainted_hunt` (tylko Łąki, drugi slot
   jedzenia obok `meadows_tainted`). Ten dokument nadaje im dedykowaną
   tożsamość per biom — dokładnie ten sam wzorzec co reszta pack'u.
2. **Karty Aktu I reużywane wprost w Akcie II** — `gather_wood` (Rąb drewno,
   Las) i `mine_stone` (Wydobycie kamienia, w 7 z 8 biomów) to TA SAMA karta
   przed i po BUM, więc nie dostają nowej karty danych — tylko 4 warianty
   ilustracji per katastrofa (uniwersalne, nie per biom, bo to jedna karta
   grana wszędzie identycznie).

Liczby (koszt/efekt) wszystkich nowych kart są skopiowane 1:1 ze
starych/dzielonych odpowiedników — zero nowego ryzyka balansu, zmienia się
tylko ilustracja i (dla kategorii 1) opis fabularny.

**Kod NIE wymaga żadnych zmian.** `card_view._illustration_path()` już
próbuje `action_<id>_<disaster_id>.png` dla KAŻDEJ `ActionCardData` (wpięte
przy wcześniejszej turze) — wystarczy dodać kartę `.tres` z nowym `id`, wpiąć
w `corrupted_gather_cards` biomu i wrzucić pliki PNG o pasującej nazwie
(a dla kategorii 2 — nawet i tego nie trzeba, karta już istnieje).

## 1. Nowe karty danych — woda (`data/cards/actions/corrupted/`) — JUŻ WPIĘTE

Utworzone i podłączone w tej turze (zamieniają `murky_water` w
`corrupted_gather_cards` odpowiedniego biomu; `murky_water.tres` zostaje
w repo nieużywany, jak reszta starych dzielonych kart):

| Biom | Plik | `id` | Koszt/efekt (= `murky_water`) | `display_name` | `description` (PL) |
|---|---|---|---|---|---|
| Jaskinie (`caves`) | `caves_tainted_water.tres` | `caves_tainted_water` | 1 energii, +1 wody, −1 zdr. | Kroplący jad | „Woda sączy się ze stalaktytów, zabarwiona trującym minerałem." |
| Las (`forest`) | `forest_tainted_water.tres` | `forest_tainted_water` | 1 energii, +1 wody, −1 zdr. | Czarna rosa | „Krople osiadłe na czarnych liściach mają metaliczny, gorzki zapach." |
| Bagno (`swamp`) | `swamp_tainted_water.tres` | `swamp_tainted_water` | 1 energii, +1 wody, −1 zdr. | Czarna maź | „Zbierasz wodę wprost z kałuży zgnilizny, gęstą niemal jak smoła." |
| Pustkowie (`wasteland`) | `wasteland_tainted_water.tres` | `wasteland_tainted_water` | 1 energii, +1 wody, −1 zdr. | Kwaśna rosa | „Krople osiadłe na spalonym rumowisku są cierpkie i gryzące." |

## 2. Parametry techniczne ilustracji

Identyczne z poprzednim dokumentem:

- Rozmiar: `1024×688`, PNG, **bez kanału alfa** (pełne nieprzezroczyste tło).
- Katalog docelowy: `assets/art/cards/illustrations/actions_act1_candidates/`.
- Nazewnictwo: `action_<id>_<katastrofa>.png`, np.
  `action_caves_tainted_water_plague.png`, `..._eclipse.png`,
  `..._flood.png`, `..._rift.png` (16 plików łącznie, `<id>` z tabeli §1).
- Referencje: `card_back_action.png` (paleta), pasujące skorumpowane tło
  Aktu II danego bioamu+katastrofy (`assets/art/biomes/backgrounds/corrupted/
  biome_<biom>_<katastrofa>_bg.png`), oraz istniejący `action_murky_water.png`
  jako REF-STYLE (kompozycja: pojedyncze naczynie/kałuża wody na pierwszym
  planie, tło biomu rozmyte, bez ludzi).
- Po wrzuceniu plików: `Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

## 3. Wspólny szkielet promptu

```text
Standalone pixel-art CARD ILLUSTRATION for the dark survival roguelike "Dzien 50",
ACT II after the catastrophe. Subject: {SUBJECT}. Centered, strong readable
silhouette as the hero of the card (a single tainted/corrupted pool or vessel
of water being gathered), no people, no faces, no hands. Single horizontal
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

## 4. Nastrój per katastrofa (spójny z resztą pack'u)

- **Plague**: sickly green rot, spores, decay, dim swamp-green light.
- **Eclipse**: frozen solid, pale blue-violet ice crust, frost crystals, cold
  moonlight glare.
- **Flood**: waterlogged and bloated, murky teal-grey water sheen, dripping,
  drowned look.
- **Rift**: dust-dried and cracked, sandy orange-brown haze, brittle,
  scarce-water look (trickle, not a full pool).

## 5. Tabela promptów — 4 biomy × 4 katastrofy (16 plików)

| Biom | Plague `{SUBJECT}` | Eclipse `{SUBJECT}` | Flood `{SUBJECT}` | Rift `{SUBJECT}` |
|---|---|---|---|---|
| `caves` | Sickly green-glowing water dripping from stalactites into a shallow stone hollow, mineral sheen on wet cave rock | Frozen stalactite drips locked in pale blue ice, frost-rimed stone hollow, faint glow through the ice | Cave floor pool flooded ankle-deep with murky dark water, ripples under a dripping ceiling | A thin trickle seeping from a cracked stalactite into a dust-choked stone hollow, mineral dust settling on the surface |
| `forest` | Sickly green-black puddle collecting among twisted black roots, oily sheen, dead leaves floating | Puddle frozen solid among frost-blackened roots, ice crust glinting under pale light | Rain-flooded root hollow brimming with murky brown floodwater, drowned leaves swirling | A shrunken, near-dry puddle cracking at the edges among dust-dry roots, hazy amber light |
| `swamp` | Thick black-green bog water pooling in a hollowed gourd, oily sheen, moss and dead reeds around | Ice-locked bog surface with a cracked hole revealing near-frozen dark water beneath, frost rime | Overflowing bog water rising over a half-submerged mossy log, heavy rain ripples | A shrunken muddy puddle in a drained, cracked bog bed, dust settling over dead reeds |
| `wasteland` | Sickly green-tinged water pooling in a rusted metal hollow amid ashen rubble | Ice-crusted water frozen inside a dented metal hollow, frost rime on cold wasteland dust | Standing floodwater pooling murky and still in a half-buried metal hollow, debris floating | A thin trickle of dusty orange water seeping into a cracked metal hollow, orange haze settling |

Wypełnij `{SUBJECT}` z tabeli i `{DISASTER_MOOD}` z sekcji 4, tak jak w
poprzednim dokumencie.

## 6. Nowe karty danych — ostatnie 3 dzielone karty — JUŻ WPIĘTE

`salvage_scrap`/`rotten_forage`/`tainted_hunt` są dziś używane już tylko
przez JEDEN biom każda (reszta biomów dostała swoje zamienniki wcześniej),
ale wciąż mają generyczną nazwę/opis niepasujące do biomu. Utworzone i
podłączone w tej turze (liczby skopiowane 1:1 ze starej karty):

| Biom | Plik | `id` | Koszt/efekt (= stara karta) | `display_name` | `description` (PL) |
|---|---|---|---|---|---|
| Wybrzeże (`coast`) | `coast_tainted_scrap.tres` | `coast_tainted_scrap` | 2 energii, +1 mat., −1 zdr. (= `salvage_scrap`) | Wyrzucony złom | „Fale wyrzucają na brzeg poszarpane, zardzewiałe szczątki rozbitych łodzi." |
| Las (`forest`) | `forest_tainted_berries.tres` | `forest_tainted_berries` | 1 energii, +2 jedz., −1 zdr. (= `rotten_forage`) | Czarne jagody | „Krzewy owocują nawet w Martwym Lesie, ale jagody mają gorzki, chemiczny posmak." |
| Łąki (`meadows`) | `meadows_tainted_game.tres` | `meadows_tainted_game` | 2 energii, +3 jedz., −1 zdr. (= `tainted_hunt`) | Ochwacone zwierzę | „Dogonić chore zwierzę jest łatwo — mięso jednak cuchnie zgnilizną." |

`salvage_scrap.tres`/`rotten_forage.tres`/`tainted_hunt.tres` zostają w repo
nieużywane (jak `murky_water.tres`).

## 7. Prompty — 3 nowe karty × 4 katastrofy (12 plików)

Ten sam szkielet promptu i te same nastroje katastrof co w sekcjach 3–4,
tylko `{SUBJECT}` inny (materiały/jedzenie zamiast wody) i nazewnictwo wg
`id` z tabeli §6 (np. `action_coast_tainted_scrap_plague.png`).

| Karta | Plague `{SUBJECT}` | Eclipse `{SUBJECT}` | Flood `{SUBJECT}` | Rift `{SUBJECT}` |
|---|---|---|---|---|
| `coast_tainted_scrap` | Rusted, sickly green-tinged scrap metal washed up among dark wet shore rocks | Ice-crusted rusted scrap metal rimed with frost on a frigid rocky shore | Storm-driven scrap metal tangled in floodwater and dark driftwood on the shore | Sun-bleached, salt-crusted rusted scrap half-buried in cracked, dust-hazed shore rubble |
| `forest_tainted_berries` | A handful of blackened, sickly green-glistening berries on a wilted dark bush, dark forest floor | Frost-crusted berries frozen solid on a hoarfrost-blackened bush, ice crystals glinting | Waterlogged, bloated berries on a half-submerged bush in murky floodwater | Shriveled, dust-dry berries clinging to a brittle dead bush in a cracked dusty clearing |
| `meadows_tainted_game` | A skinned carcass of a small game animal lying in sickly green-tinged rotten meadow grass | The same carcass frozen solid under hoarfrost, ice crystals on stiff fur, snow-dusted grass | The carcass waterlogged and bloated, half-submerged in flooded meadow grass | The carcass mummified and dust-dry, cracked leathery hide, brittle dead grass around it |

## 8. Prompty — karty Aktu I reużywane w Akcie II (uniwersalne, nie per biom)

`gather_wood` i `mine_stone` NIE dostają nowej karty danych — to ta sama
karta w Akcie I i II, więc potrzebują tylko 4 wariantów ilustracji KAŻDA
(nazwane wg ISTNIEJĄCEGO `id` karty, bez zmian w `data/`/biomach):
`action_gather_wood_<katastrofa>.png`, `action_mine_stone_<katastrofa>.png`.
`mine_stone` jest reużywany identycznie w 7 biomach (wszystkie poza Górami),
więc jego art jest celowo biomowo-neutralny (rozmyte rumowisko, nie
konkretny biom) — dokładnie tak jak wygląda już jego istniejący art Aktu I.

| Karta | Plague `{SUBJECT}` | Eclipse `{SUBJECT}` | Flood `{SUBJECT}` | Rift `{SUBJECT}` |
|---|---|---|---|---|
| `gather_wood` | A bundle of black, sickly green-mossed logs stacked at the base of rotten dead trees, dark forest floor | A bundle of frost-rimed logs stacked among ice-blackened trunks, hoarfrost crystals on the bark | A bundle of waterlogged logs half-submerged in murky floodwater among drowned dead trees | A bundle of sun-bleached, cracked dry logs stacked in a dust-cracked forest clearing, hazy amber light |
| `mine_stone` | A pile of freshly broken stone chunks with a sickly green mossy sheen, dim rubble surroundings | A pile of broken stone chunks rimed with frost and ice crystals, pale cold light | A pile of broken stone chunks sitting in shallow murky floodwater, wet reflective surfaces | A pile of freshly broken, dust-coated stone chunks in a cracked, rubble-strewn fissure, orange haze |

## 9. Stan wdrożenia

- ✅ 7 kart danych utworzonych i wpiętych (4 wodne §1 + 3 dzielone §6);
  `corrupted_gather_cards` 7 biomów zaktualizowane (Mountains/River już
  miały dedykowane karty z poprzedniej tury i nie były ruszane).
- ✅ `--import` + `load_test`/`ui_layout_test`/`biome_camp_test` zielone po
  obu turach zmian.
- ⬜ **36 plików PNG do wygenerowania łącznie**: 16 (§5, woda) + 12 (§7,
  dzielone) + 8 (§8, uniwersalne) — po wrzuceniu i `--import` zadziałają
  automatycznie, zero dalszych zmian w kodzie (fallback do `action_<id>.png`
  bez sufiksu katastrofy, gdyby brakowało wariantu, identyczny mechanizm co
  reszta pack'u).
- ⬜ Do rozważenia przy okazji (nie blokuje): 7 nowych `display_name`/
  `description` (§1 + §6) nie są jeszcze w `localization/strings.csv` — bez
  wpisu gracz z `locale=en` zobaczy polski oryginał (fallback), nic się nie
  wyłoży błędem; `tools/extract_strings.gd` je domiecie przy najbliższym
  przebiegu ekstrakcji lokalizacji. `gather_wood`/`mine_stone` (§8) nie
  potrzebują nowych wpisów — to istniejące karty.
