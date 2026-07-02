# Brakujące assety — ilustracje kart akcji (Fale 1–4, walka z monotonią)

Spec do wklejenia dla Codeksa / pipeline'u obrazów. Dotyczy 27 nowych kart akcji
dodanych w falach „walka z monotonią kart" (changelog 2026-06-28). Karty są w pełni
grywalne — renderują się teraz tylko ramką + tekstem, bo `ui/card_view.gd` szuka
pliku `action_<id>.png` i go nie znajduje.

## Parametry techniczne

- **Katalog docelowy:** `assets/art/cards/illustrations/actions_act1_candidates/`
- **Format:** `1024×688` PNG, poziom 3:2, pełne nieprzezroczyste tło
  (**bez kanału alfa** — ilustracja idzie POD maskę ramki, NIE jest chroma-keyowana,
  inaczej niż assety biomów).
- **Auto-wpięcie:** zero zmian w kodzie — `card_view` ładuje `action_<id>.png` po nazwie.
- **Po wrzuceniu plików:** `Godot --headless --path . --import` (PNG dostaną `.import`).

## Referencje (te same dla wszystkich; podać do każdej generacji)

- **REF-PALETTE** → `assets/art/cards/backs/card_back_action.png`
  (paleta talii: złoto + haftowana zieleń)
- **REF-BG** → `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png`
  (jasny dzień Aktu I, runo lasu)
- **REF-STYLE** → `assets/art/cards/illustrations/actions_act1_candidates/action_forage.png`,
  `action_chop_wood.png`, `action_rest.png` (styl pixel-art, kadr, poziom detalu)

## Wspólny scaffold promptu (wklej, podmień `[SUBJECT]`)

```text
Standalone pixel art CARD ILLUSTRATION for the survival card roguelike Dzien 50,
ACT I before the catastrophe. Bright, natural, hopeful survival-settlement mood:
fresh forest greens, warm earth browns, soft morning daylight, clear readable
shapes, medium visible pixels, crisp hard edges, controlled dithering.
Subject: [SUBJECT]
Composition: single horizontal 3:2 still-life of objects (NO people, NO characters),
clean forest-floor / camp-ground background, daylight, gentle vignette only,
content kept away from edges (sits inside a card art window).
Text: absolutely no text, letters, numbers, UI, card frame or border.
Avoid: Act II mood, plague, corruption, toxic green glow, dead trees, heavy black
vignette, horror, photorealism, painterly blur, 3D render, frame, any human or
creature, text or icons.
Output: 1024x688, solid background, no transparency.
```

## Tabela kart

| Fala | Plik (`…/actions_act1_candidates/`) | Karta — efekt | `[SUBJECT]` (EN) | Reference |
|---|---|---|---|---|
| 1 | `action_forced_march.png` | Forsowny marsz — +3 energii/−2 sytości | worn forest trail rushing by, a sturdy walking staff and half-open travel satchel dropped mid-stride, dust and wind-bent grass, fast urgent motion | REF-PALETTE+BG+STYLE |
| 1 | `action_overexert.png` | Nadludzki wysiłek — +4 energii/−2 zdrowia | a heavy log levered up with a thick wooden pole and taut straining ropes over a wedge stone, sweat-shine, pushing past the limit | REF-PALETTE+BG+STYLE |
| 1 | `action_barter_food.png` | Wymiana: jedzenie — −2 drewna/+3 jedz. | a neat stack of chopped firewood traded for a woven basket of bread, roots and dried provisions on a cloth | REF-PALETTE+BG+STYLE |
| 1 | `action_barter_water.png` | Filtracja zapasów — −1 jedz./+3 wody | a cloth-and-charcoal filter funnel dripping clear water into a clay jug, a small portion of food set aside as the price | REF-PALETTE+BG+STYLE |
| 1 | `action_knapping.png` | Obróbka kamienia — −2 drewna/+2 kamienia | flint shaped with a wooden mallet and antler tool, fresh stone flakes and a pile of dressed building stone, wood offcuts | REF-PALETTE+BG+STYLE |
| 1 | `action_trade_caravan.png` | Objuczony kram — surowiec→jedz.+woda | a small roadside barter stall: crate of raw wood and stone on a plank table beside baskets of food and a row of full waterskins | REF-PALETTE+BG+STYLE |
| 1 | `action_stoke_fire.png` | Dołóż do ognia — −2 drewna/+5 ciepła | a campfire fed with fresh logs, bright lively warm flames and glowing embers, stacked woodpile beside a stone fire ring | REF-PALETTE+BG+STYLE |
| 1 | `action_toughen.png` | Hartowanie — −1 zdrowia/+3 ciepła | thick rolled furs and a wool blanket warming by glowing coals, a steaming kettle, rising steam and heat shimmer | REF-PALETTE+BG+STYLE |
| 1 | `action_push_through.png` | Zacisnąć zęby — −2 zdrowia/+3 kamienia | a pickaxe driven hard into broken rock, chunks of fresh quarried stone and rubble, a blood-spotted cloth wrap on the handle, gritty effort | REF-PALETTE+BG+STYLE |
| 1 | `action_windfall_trade.png` | Handel okazyjny — −2 kamienia/+jedz.+woda | a spread of ore and cut stone traded for a lucky haul of food baskets and waterskins laid on a tarp in morning light | REF-PALETTE+BG+STYLE |
| 2 | `action_dash.png` | Bieg — następny ruch za darmo | a forest path opening ahead with light footprints, swirling leaves and motion lines, swift free running, no person | REF-PALETTE+BG+STYLE |
| 2 | `action_field_repair.png` | Doraźna naprawa — łata budynek | a wooden hut wall patched with fresh planks, a hammer and nails, sawdust, repair half-done | REF-PALETTE+BG+STYLE |
| 2 | `action_keep_watch.png` | Warta — łagodzi noc | a lit lantern and a spear leaning at a camp watch post overlooking the settlement at golden dusk, a signal horn | REF-PALETTE+BG+STYLE |
| 2 | `action_dig_in.png` | Okopanie się — warta + ciepło | a low earth-and-branch rampart of packed stones built around a small campfire, defensive berm | REF-PALETTE+BG+STYLE |
| 2 | `action_set_snare.png` | Wnyki — blokują atak potwora | a rope snare loop rigged among roots with a bent-sapling trigger, camouflaged trail trap | REF-PALETTE+BG+STYLE |
| 2 | `action_bait_trap.png` | Zwabienie zwierzyny — pułapka + jedzenie | bait laid on a trail beside a baited deadfall/cage trap, a couple of caught small game nearby | REF-PALETTE+BG+STYLE |
| 3 | `action_momentum.png` | Zapał — silnik energii | a spinning whetstone wheel and tools mid-work throwing small sparks, sense of building work-rhythm and flow | REF-PALETTE+BG+STYLE |
| 3 | `action_relentless.png` | Nieustępliwość — silnik, −sytość | a workbench worked hard into dusk with an empty bowl set aside (skipped meal), determined relentless toil | REF-PALETTE+BG+STYLE |
| 3 | `action_rhythm.png` | Rytm dnia — +energia za zagrania | a tidy end-of-day row of finished tools and a tally of completed chores, steady orderly cadence | REF-PALETTE+BG+STYLE |
| 3 | `action_cadence.png` | Kadencja — rytm + leczenie | a calm steady work scene with a cup of herbal tea steaming beside neatly arranged tools, restorative pace | REF-PALETTE+BG+STYLE |
| 3 | `action_second_breakfast.png` | Drugie śniadanie — combo jedzenia | a hearty refilled meal laid out — a brimming bowl, doubled bread and berries, abundant second helping | REF-PALETTE+BG+STYLE |
| 4 | `action_forage_up.png` | Zbieractwo: Spiżarka (ulepszenie) | a rich foraging haul overflowing a basket — berries, roots, mushrooms, herbs — more bountiful refined version | REF-PALETTE + base `action_forage.png` |
| 4 | `action_find_water_up.png` | Źródło: Bystry strumień (ulepszenie) | a clear fast spring stream filling several waterskins at a well-made stone catch, generous refined version | REF-PALETTE + base `action_spring_source.png` |
| 4 | `action_first_aid_up.png` | Opatrunek: Szwy (ulepszenie) | a proper field surgery kit — needle and thread, clean linen bandages, salves — skilled refined version | REF-PALETTE + base `action_treat_wounds.png` |
| 4 | `action_rest_up.png` | Odpoczynek: Głęboki sen (ulepszenie) | a cozy well-made bedroll under a lean-to with soft morning light, deep restful sleep, refined version | REF-PALETTE + base `action_rest.png` |
| 4 | `action_scout_up.png` | Zwiad: Rekonesans (ulepszenie) | a spyglass, a marked local map and a small pouch of scavenged scrap on a plank, thorough recon, refined version | REF-PALETTE + base `action_scout.png` |
| 4 | `action_herbs_up.png` | Zioła: Mocny wywar (ulepszenie) | a steaming potent herbal brew in a cup with bundled medicinal herbs and a mortar, stronger refined version | REF-PALETTE + base `action_treat_wounds.png` |

## Uwagi

- Wszystkie 27 plików → `assets/art/cards/illustrations/actions_act1_candidates/`,
  `1024×688`, bez alfy, nazwy dokładnie jak w kolumnie „Plik".
- **Fala 4 (6 ulepszeń)** — trzymać ciągłość wizualną z kartą bazową (kolumna
  Reference): to ta sama akcja w mocniejszej wersji. **Opcjonalnie** zamiast
  generować te 6 można dodać aliasy w `ui/card_view.gd` → `ACTION_ART_ALIASES`
  (`"forage_up": "action_forage"`, `"find_water_up": "action_spring_source"`,
  `"first_aid_up": "action_treat_wounds"`, `"rest_up": "action_rest"`,
  `"scout_up": "action_scout"`, `"herbs_up": "action_treat_wounds"`) i reużyć art
  bazowy — wtedy te 6 plików nie jest potrzebne.
- Mapowanie aliasów istniejących baz (skąd „base" w Reference): `find_water` →
  `action_spring_source`, `first_aid`/`herbs` → `action_treat_wounds`,
  `forage` → `action_forage`, `rest` → `action_rest`, `scout` → `action_scout`.
