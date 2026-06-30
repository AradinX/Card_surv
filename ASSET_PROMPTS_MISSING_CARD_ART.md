# Missing Card Illustration Prompts (unique art for aliased / frame-only cards)

These 22 action cards currently have **no dedicated illustration** — 20 reuse a
shared alias image (`action_chop_wood` / `action_forage` / `action_explore` /
`action_rest` / `action_treat_wounds`) and 2 render frame-only. Generating the
files below gives every card its own art.

**Wpięcie (już skonfigurowane — plug-and-play):** `ui/card_view.gd`
`_illustration_path()` teraz dla kart akcji najpierw szuka dedykowanego
`actions_act1_candidates/action_<id>.png`, a dopiero gdy go nie ma, spada do
współdzielonego aliasu. Wystarczy zapisać plik pod ścieżką z kolumny `Plik` —
karta automatycznie podmieni grafikę przy następnym uruchomieniu, bez zmian w
kodzie i bez ruszania mapy `ACTION_ART_ALIASES` (która zostaje jako fallback).
Wszystkie pliki trafiają do `assets/art/cards/illustrations/actions_act1_candidates/`.

Use only the built-in imagegen tool (GPT Image), quality medium. Do NOT use Nano-Banana / Gemini. This is pixel art matching the existing card illustrations, full-bleed scene, 1024x688 px, text-free (no letters/UI/frames/borders). No solid-color background, NOT transparent: a real painted scene. Attach the listed references and copy their deck-art style: deep palette, embroidery-like visible pixel texture, medium visible pixels, crisp hard edges, controlled dithering, no smooth painting. Save at the exact path in `Plik`, one by one.

Scaffold for every row:
Standalone pixel-art CARD ILLUSTRATION for the dark survival roguelike "Dzien 50". Subject: {SUBJECT}. Centered, strong readable silhouette, hero of the card, no people/faces. Single horizontal 3:2 scene, calm dark background, gentle vignette, content away from edges. {PALETTE} Avoid: photorealism, painterly blur, 3D render, frame/border, text/icons.

## Akcje drewna (Act I)

References: `assets/art/cards/backs/card_back_action.png` + `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_chop_wood.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_forage.png`.

Palette: deep forest greens and warm bark browns, muted amber light, dark moss shadows.

| Plik | Subject (EN) |
|---|---|
| `assets/art/cards/illustrations/actions_act1_candidates/action_gather_wood.png` | An axe buried in a chopping block beside a freshly split stack of firewood logs, woodcutting scene, no person. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_haul_wood.png` | A heavy bundle of cut logs bound with rope and propped ready to carry, sturdy stacked timber, hard work mood. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_deadfall_wood.png` | A tangle of storm-snapped branches and fallen deadwood gathered into a loose bundle on the forest floor, easy fuel. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_gather_sticks.png` | A small neat bundle of dry twigs and kindling tied with cord, resting on dark forest ground. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_gather_sticks_up.png` | A large overflowing armful of dry sticks and kindling, a generous gathered pile of branches, abundance. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_woodcraft.png` | A carpenter's workbench with cut planks, wooden pegs and shaped parts, hand tools resting, no person. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_barter_wood.png` | A roadside barter: a heap of gray stones on one side traded for a tidy stack of firewood logs on the other. |

## Akcje jedzenia i polowania (Act I)

References: `assets/art/cards/backs/card_back_action.png` + `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_forage.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_treat_wounds.png`.

Palette: natural Act I survival tones, forest greens and ambers, river blue-greens, warm firelight on food.

| Plik | Subject (EN) |
|---|---|
| `assets/art/cards/illustrations/actions_act1_candidates/action_hunt.png` | A hunter's bow and a set snare with fresh small game hanging in a forest setting, no person, no gore. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_big_hunt.png` | A large game carcass on a wooden carrying frame brought back to camp, abundant meat, non-graphic, no faces. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_snare_trap.png` | A rope and wire snare trap set among undergrowth with a small caught animal, careful trapping mood, no gore. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_fishing.png` | A fishing rod and net leaning by a riverbank with two fresh fish on wet stones, calm water. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_feast.png` | A hearty cooked meal spread by a campfire: roasted meat, bread and full bowls, warm and abundant. |

## Akcje kamienia i wypraw (Act I)

References: `assets/art/cards/backs/card_back_action.png` + `assets/art/biomes/backgrounds/normal/biome_mountains_normal_bg.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_explore.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_chop_wood.png`.

Palette: cold mountain grays and dusty stone, muted slate blues, pale daylight, hard rock shadows.

| Plik | Subject (EN) |
|---|---|
| `assets/art/cards/illustrations/actions_act1_candidates/action_mine_stone.png` | A pickaxe striking a rock face with broken chunks of hard gray stone falling, mining scene, no person. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_scavenge.png` | Loose stones and useful scrap scattered in rubble being searched through, salvaging scene, no person. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_barter_materials.png` | A barter scene: a basket of provisions exchanged for a heap of cut stone blocks at a roadside. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_expedition.png` | A traveler's pack, rolled map and walking staff set at the edge of an unknown wilderness path at dawn, no person. |

## Akcje wytchnienia i leczenia (Act I)

References: `assets/art/cards/backs/card_back_action.png` + `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_rest.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_treat_wounds.png`.

Palette: warm firelight ambers against cold dark, soft healing greens, gentle restful glow.

| Plik | Subject (EN) |
|---|---|
| `assets/art/cards/illustrations/actions_act1_candidates/action_campfire.png` | A small crackling campfire with a warm orange glow and a bedroll beside it, cozy warmth in cold darkness. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_adrenaline.png` | A raw burst of motion across dark ground, scattering leaves and a blurred rush of speed, surging vigor, no person. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_first_aid.png` | A simple field dressing: rolled cloth bandage strips, a needle and a small first-aid kit laid out on cloth. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_herbs.png` | Fresh medicinal herbs with a mortar and pestle and a green poultice being prepared, healing remedy. |

## Skażone akcje zbierania (Act II)

References: `assets/art/cards/backs/card_back_monster.png` + `assets/art/biomes/backgrounds/corrupted/biome_forest_plague_bg.png` + `assets/art/cards/illustrations/actions_act1_candidates/action_forage.png` + existing corrupted event art from `assets/art/cards/illustrations/events/`.

Palette: Act II corruption — sickly greens, violets, black rot, bruised shadows, toxic highlights.

| Plik | Subject (EN) |
|---|---|
| `assets/art/cards/illustrations/actions_act1_candidates/action_rotten_forage.png` | A handful of overripe rotting berries with sickly mold and slime, tempting but spoiled fruit, corruption glow, no gore. |
| `assets/art/cards/illustrations/actions_act1_candidates/action_salvage_scrap.png` | Sharp contaminated metal scrap in toxic rubble, slick poisoned debris with a faint green sheen, dangerous salvage, no person. |
