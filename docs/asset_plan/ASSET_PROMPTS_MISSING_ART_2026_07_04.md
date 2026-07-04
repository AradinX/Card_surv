# Brakujące assety — audyt 2026-07-04

Trzy karty w pełni grywalne, ale bez własnej ilustracji — renderują się tylko
ramką + tekstem, bo `ui/card_view.gd` (`_illustration_path()`) nie znajduje
pliku o oczekiwanej nazwie:

- `leaky_waterskin` i `gnawed_supplies` — 2 nowe zdarzenia nocne Aktu I
  (dodane w rundzie "Dokręcenie ekonomii jedzenia/wody", zawsze aktywne,
  `category = "neutral"`), nigdy nie trafiły do żadnego planu artu.
- `building_stone_storage` (Magazyn kamienia) — od dawna po cichu POŻYCZA
  obrazek Kamieniołomu przez alias w kodzie (`card_view.gd:26`,
  `BUILDING_ART_ALIASES`). Analogiczna para drewna (Drwalnia/Magazyn drewna)
  ma dwa osobne obrazki — to jest luka, nie zamierzony wybór.

## 1. Zdarzenia nocne (`assets/art/cards/illustrations/events/`)

- Format: `1024×688` PNG, poziom 3:2, **bez kanału alfa**.
- Nazewnictwo: dokładnie `<id>.png` (bez prefiksu `action_`/sufiksu
  katastrofy — te 2 zdarzenia są aktywne w KAŻDYM akcie, nie mają
  wariantu per katastrofa).
- Referencje: `card_back_event.png` (paleta), `biome_forest_normal_bg.png`
  (nastrój Aktu I, jasny, nie-skorumpowany), oraz istniejące `rats.png` /
  `rotting_supplies.png` z tego samego folderu jako REF-STYLE (kompozycja:
  pojedynczy przedmiot/scena obozowa w centrum, bez ludzi).
- Po wrzuceniu plików: `Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

Wspólny szkielet promptu:

```text
Standalone pixel-art CARD ILLUSTRATION for the survival card roguelike "Dzien 50",
a quiet nighttime camp scene, Act I mood (not yet corrupted): natural browns and
muted campfire-lit colors, medium visible pixels, crisp hard edges, controlled
dithering, embroidery-like deck palette.
Subject: {SUBJECT}
Composition: single horizontal 3:2 still-life, no people, no faces, no hands,
gentle vignette, content kept away from edges (sits inside a card art window).
Text constraints: text-free image. No letters, numbers, words, UI, frame, border,
or icons.
Avoid: photorealism, painterly blur, 3D render, gore, horror, Act II corruption
mood (toxic green, ice, dust).
Output: 1024x688, solid background, no transparency.
```

| Plik | Karta | `{SUBJECT}` |
|---|---|---|
| `assets/art/cards/illustrations/events/leaky_waterskin.png` | Nieszczelny bukłak (-2 wody) | A leather waterskin lying on its side at the edge of a sleeping camp, a dark wet stain spreading on the ground beneath a small puncture, water still dripping out |
| `assets/art/cards/illustrations/events/gnawed_supplies.png` | Nadgryzione zapasy (-1 jedzenia, -1 wody) | A camp supply sack knocked over and torn open at night, food scraps and a punctured waterskin spilled around it, small gnaw marks visible, no animal shown |

## 2. Budynek (`assets/art/cards/illustrations/buildings_act1_candidates/`)

- Format: `1024×688` PNG, bez alfy, "centered hero structure" (pojedyncza
  budowla, nie martwa natura z przedmiotami) — ta sama konwencja co reszta
  `buildings_act1_candidates/`.
- Nazewnictwo: `building_stone_storage.png`.
- Referencje: `card_back_action.png` (paleta), `biome_forest_normal_bg.png`
  (tło), oraz `building_wood_storage.png` jako REF-STYLE bezpośredni —
  to jest ten sam typ budynku (zadaszony magazyn surowca podnoszący limit),
  tylko dla kamienia zamiast drewna; `building_quarry.png` pokazuje AKTYWNE
  kopanie, tego efektu tu unikamy (to magazyn, nie kopalnia).

```text
Standalone pixel-art CARD ILLUSTRATION for the survival card roguelike "Dzien 50",
Act I mood, bright natural hopeful survival-settlement palette: fresh forest
greens, warm earth browns, soft daylight, medium visible pixels, crisp hard
edges, controlled dithering.
Subject: A small roofed stone storage shed/lean-to, neatly stacked quarried
stone blocks and rubble piled inside and beside it under the shelter, sturdy
timber-framed roof keeping the stone dry, settled and orderly (a depot, not an
active dig site).
Composition: centered hero structure, single horizontal 3:2 scene, forest-camp
background blurred softly behind it, daylight, gentle vignette, content kept
away from edges (sits inside a card art window), no people.
Text constraints: text-free image. No letters, numbers, words, UI, frame,
border, or icons.
Avoid: an open quarry pit or active mining (that's a different building),
photorealism, painterly blur, 3D render, human or creature figures.
Output: 1024x688, solid background, no transparency.
```

## 3. Stan wdrożenia

- ✅ 3 pliki PNG wygenerowane i zaimportowane: `leaky_waterskin`,
  `gnawed_supplies` (§1) + `building_stone_storage` (§2).
- ✅ `BUILDING_ART_ALIASES` (alias `stone_storage`→`quarry`) usunięty z
  `ui/card_view.gd` — budynki ładują teraz obrazek wprost po `id`, Magazyn
  kamienia ma własną ilustrację zamiast pożyczonej.
- Kod nie wymagał żadnych innych zmian.
