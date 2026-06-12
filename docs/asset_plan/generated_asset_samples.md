# Generated Asset Samples

Pierwsze dwa assety wygenerowane do zatwierdzenia kierunku wizualnego.

## Current Production Rule

Od teraz assety produkcyjne maja byc text-free: bez wypalonych napisow,
liczb, etykiet, pseudo-liter i dekoracyjnego tekstu. Biomy, karty, UI,
przyciski i inne rysunki maja zostawiac puste plakietki/ramki/panele,
a napisy dodajemy w Godot jako edytowalne warstwy tekstowe.

Update: finalny pipeline jest warstwowy. Pelne ekrany UI generujemy tylko
jako concept/mockup. Finalne biomy generujemy od nowa jako czyste tla terenu:
bez ramek, slotow, title plate'ow, licznikow i napisow. Ramki, sloty, plate'y,
ikony i overlaye sa osobnymi assetami UI. Finalne karty skladamy w Godot z
ramki, ilustracji, ikon/kosztow i tekstu.

Legacy note: wczesniejsze zlozone biomy z ramkami, slotami lub tekstem zostaly
przeniesione do `assets/art/concepts/biomes/` jako reference/mockup, nie jako
finalne tla biomow.

## Building illustrations Act I replacement pass

Status: completed and accepted as the Act I building illustration pack. The
existing 15 building illustrations were judged too dark / too Act II for
default production building cards. They remain untouched in the original
`buildings/` folder for Act II card use, and archived/reference copies also
exist under concepts. The production direction for Act I buildings is now:
brighter, pre-BUM settlement art.

Archived/reference copies:

```text
assets/art/concepts/cards/buildings_act2_reference/*.png
```

Act II production/reference folder, left untouched:

```text
assets/art/cards/illustrations/buildings/*.png
```

Act I production folder:

```text
assets/art/cards/illustrations/buildings_act1_candidates/building_campfire.png
assets/art/cards/illustrations/buildings_act1_candidates/building_farm.png
assets/art/cards/illustrations/buildings_act1_candidates/building_fishing_dock.png
assets/art/cards/illustrations/buildings_act1_candidates/building_herbalist.png
assets/art/cards/illustrations/buildings_act1_candidates/building_hut.png
assets/art/cards/illustrations/buildings_act1_candidates/building_logging_camp.png
assets/art/cards/illustrations/buildings_act1_candidates/building_palisade.png
assets/art/cards/illustrations/buildings_act1_candidates/building_pantry.png
assets/art/cards/illustrations/buildings_act1_candidates/building_quarry.png
assets/art/cards/illustrations/buildings_act1_candidates/building_traps.png
assets/art/cards/illustrations/buildings_act1_candidates/building_watchtower.png
assets/art/cards/illustrations/buildings_act1_candidates/building_water_filter.png
assets/art/cards/illustrations/buildings_act1_candidates/building_well.png
assets/art/cards/illustrations/buildings_act1_candidates/building_wood_storage.png
assets/art/cards/illustrations/buildings_act1_candidates/building_workshop.png
```

Approval samples kept for history:

```text
assets/art/cards/illustrations/buildings_act1_candidates/building_campfire_act1_candidate.png
assets/art/cards/illustrations/buildings_act1_candidates/building_herbalist_act1_candidate.png
docs/asset_plan/previews/preview_buildings_act1.png
```

Updated Act I prompt direction:

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike
Dzien 50, but specifically for ACT I before the catastrophe. Bright, natural,
hopeful survival settlement mood: fresh forest greens, warm earth browns, soft
morning daylight, clear readable shapes, medium visible pixels, crisp hard
edges, controlled dithering, no smooth painting.

Composition: single horizontal 3:2 illustration, subject centered, clean
forest-floor background with daylight and healthy vegetation, moderate gentle
vignette only, important content kept away from extreme edges because it sits
inside a card art window.

Text: absolutely no text, no letters, no numbers, no UI, no card frame, no
border.

Avoid: Act II mood, plague, corruption, toxic green glow, dead trees, heavy
black vignette, horror, photorealism, painterly blur, 3D render, frame or
border, characters, text or icons.
```

## Action illustrations Act I replacement pass

Status: completed and accepted as the Act I action illustration pack. The
existing action illustrations were generated in the darker deck palette and
are now treated as Act II / post-BUM references. They remain untouched in the
original `actions/` folder, with archived copies under concepts.

Archived/reference copies:

```text
assets/art/concepts/cards/actions_act2_reference/*.png
```

Act II production/reference folder, left untouched:

```text
assets/art/cards/illustrations/actions/*.png
```

Act I production folder:

```text
assets/art/cards/illustrations/actions_act1_candidates/action_chop_wood.png
assets/art/cards/illustrations/actions_act1_candidates/action_craft_tools.png
assets/art/cards/illustrations/actions_act1_candidates/action_explore.png
assets/art/cards/illustrations/actions_act1_candidates/action_forage.png
assets/art/cards/illustrations/actions_act1_candidates/action_local_map.png
assets/art/cards/illustrations/actions_act1_candidates/action_mark_trail.png
assets/art/cards/illustrations/actions_act1_candidates/action_rest.png
assets/art/cards/illustrations/actions_act1_candidates/action_scout.png
assets/art/cards/illustrations/actions_act1_candidates/action_spring_source.png
assets/art/cards/illustrations/actions_act1_candidates/action_treat_wounds.png
docs/asset_plan/previews/preview_actions_act1.png
```

Updated Act I prompt direction:

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike
Dzien 50, but specifically for ACT I before the catastrophe. Bright, natural,
hopeful survival mood: fresh forest greens, warm earth browns, soft morning
daylight, clear readable shapes, medium visible pixels, crisp hard edges,
controlled dithering, no smooth painting.

Composition: single horizontal 3:2 illustration, subject centered, clean
forest-floor background with daylight and healthy vegetation, moderate gentle
vignette only, important content kept away from extreme edges because it sits
inside a card art window.

Text: absolutely no text, no letters, no numbers, no UI, no card frame, no
border.

Avoid: Act II mood, plague, corruption, toxic green glow, dead trees, heavy
black vignette, horror, photorealism, painterly blur, 3D render, frame or
border, characters, body parts, text, symbols or icons.
```

## P0/P1 gameplay asset pack

Status: generated as a broad first-pass gameplay pack after the Higgsfield /
Claude card illustration work. AI generation was used for the two atmospheric
background layers; icons, panels, overlays, board markers, and simple FX were
created deterministically as crisp text-free PNGs for reliable Godot use.

AI-generated production layers:

```text
assets/art/backgrounds/run_screen/bg_run_table.png        1920x1080
```

MISSING (structure audit 2026-06-12): the biome discovery tile pack
(`assets/art/biomes/discovery/biome_unknown*.png`, `overlay_fog`,
`frame_*_9slice`, `icon_unknown_terrain`, `icon_discover`, `marker_peeked`,
`overlay_hint_*`) was previously listed here as generated, but the files are
NOT in the repo — `assets/art/biomes/discovery/` contains only `.gitkeep`.
They remain planned in `ASSET_PLAN_DZIEN_50_GODOT.md` (sekcje discovery) and
need to be (re)generated. Discovery-adjacent assets that DO exist:
`assets/art/fx/discovery/*.png` (reveal/fog/flash FX),
`assets/art/ui/panels/panel_discovery_popup_9slice.png`,
`assets/art/cards/icons/icon_discovery.png`.

Deterministic icon pack:

```text
assets/art/cards/icons/*.png  (36 icons, 64x64)
```

Covered icons: health, hunger, thirst, warmth, energy, XP, day, food, water,
wood, materials, stone, ore, herbs, peat, tools, defense, damage, repair, ruin,
move, move_cost, building_slot, discovery, unknown, peek, adjacent, safe_trail,
risky_terrain, plague, rift, eclipse, spring, summer, autumn, winter.

## Deck-style card icon replacement candidates

Status: generated for review. The original deterministic flat icons remain in
`assets/art/cards/icons/` for now and were copied to a legacy/reference folder.
The new candidate pack matches the approved card backs and frames: dark
forest-green stitched texture, aged gold medallion rims, centered pixel-art
symbols, no text, no letters, no numbers.

Legacy/reference copies:

```text
assets/art/concepts/cards/icons_legacy_flat_reference/*.png
```

New candidate pack:

```text
assets/art/cards/icons_deck_style_candidates/*.png              36 icons, 64x64 drop-in size
assets/art/cards/icons_deck_style_candidates/source_128/*.png   36 icons, 128x128 source size
docs/asset_plan/previews/preview_icons_deck_style_64.png
docs/asset_plan/previews/preview_icons_deck_style_128.png
docs/asset_plan/previews/preview_card_backs_frames_reference.png
docs/asset_plan/previews/preview_icons_current.png
```

Covered icons:

```text
adjacent, building_slot, damage, day, defense, disaster_eclipse,
disaster_plague, disaster_rift, discovery, energy, food, health, herbs,
hunger, materials, move, move_cost, ore, peat, peek, repair, risky_terrain,
ruin, safe_trail, season_autumn, season_spring, season_summer,
season_winter, stone, thirst, tools, unknown, warmth, water, wood, xp.
```

UI / board / FX:

```text
assets/art/ui/bars/*.png
assets/art/ui/buttons/*.png
assets/art/ui/panels/*.png
assets/art/ui/icons/icon_map_fragment.png
assets/art/board/**/*.png
assets/art/biomes/overlays/*.png
assets/art/fx/**/*.png
docs/asset_plan/previews/preview_icons_pack.png
docs/asset_plan/previews/preview_fx_bum.png
```

Notes:

- All production assets are text-free; editable labels remain in Godot.
- Panels/buttons are first-pass 9-slice-friendly placeholders, not final
  polished UI art.
- FX are simple overlay sprites intended for quick integration and iteration.

## Board background and connector replacement pass

Status: `imagegen` replacement pass for board art. Board backgrounds now have
separate Act I and Act II versions, and the connector uses the same light
ornamental board UI language as the corrected biome frames/slots.

Production files:

```text
assets/art/board/backgrounds/bg_biome_board.png       1536x1024  default Act I
assets/art/board/backgrounds/bg_biome_board_act1.png  1536x1024  bright healthy forest
assets/art/board/backgrounds/bg_biome_board_act2.png  1536x1024  corrupted post-BUM forest
assets/art/board/connectors/neighbor_connector.png     512x96    raw #00FF00 key
assets/art/concepts/board/backgrounds_before_act_split/bg_biome_board.png
assets/art/concepts/board/connectors_before_imagegen/neighbor_connector.png
```

Connector direction: thin horizontal aged-gold line with leaf/vine accents,
small center diamond, endpoint caps, raw pure green `#00FF00` background, no
text, no alpha removal during generation.

## FX replacement pass

Status: regenerated with `imagegen` using `ASSET_PLAN_DZIEN_50_GODOT.md`
section 16 and the current Dzien 50 pixel-art direction. Files are saved under
their existing production paths and keep the existing dimensions. Transparent
areas are encoded as raw pure green `#00FF00`; do not remove the key during
generation.

Production files:

```text
assets/art/fx/bum/fx_bum_flash.png                 1920x1080
assets/art/fx/bum/fx_screen_crack_overlay.png      1920x1080
assets/art/fx/bum/fx_shockwave.png                 1024x1024
assets/art/fx/corruption/fx_plague_cloud.png       1536x1024
assets/art/fx/fire/fx_burn_marks.png               512x512
assets/art/fx/fire/fx_small_fire_loop.png          256x256
assets/art/fx/smoke/fx_smoke_loop.png              256x256
assets/art/fx/weather/fx_rain_overlay.png          1920x1080
assets/art/fx/weather/fx_snow_overlay.png          1920x1080
assets/art/fx/weather/fx_frost_edges.png           1920x1080
assets/art/fx/monster_attack/fx_claw_slash.png     512x512
assets/art/fx/cards/fx_heal_spark.png              256x256
assets/art/fx/cards/fx_resource_gain.png           256x256
assets/art/fx/discovery/fx_tile_reveal_01.png      1536x1024
assets/art/fx/discovery/fx_tile_reveal_02.png      1536x1024
assets/art/fx/discovery/fx_tile_reveal_03.png      1536x1024
assets/art/fx/discovery/fx_fog_loop_01.png         1536x1024
assets/art/fx/discovery/fx_discover_flash_01.png   256x256
assets/art/concepts/fx_before_imagegen_rework/**/*.png
```

Prompt direction: premium pixel art VFX, no text, no letters, no numbers,
readable over cards/biome tiles, Dzien 50 Act I natural palette for healing
and discovery, plague/corruption palette for BUM and Act II effects.

## P1 exploration action illustrations

Status: generated as standalone card illustration layers for the Act I
fog-of-war / map discovery mechanic. All are `1024x688`, text-free, UI-free,
and intended to be clipped into the card art window in Godot.
Current classification after the Act I correction pass: the files in
`assets/art/cards/illustrations/actions/` are kept as darker Act II /
post-BUM action art. Bright Act I replacements live in
`assets/art/cards/illustrations/actions_act1_candidates/`.

Paths:

```text
assets/art/cards/illustrations/actions/action_scout.png
assets/art/cards/illustrations/actions/action_mark_trail.png
assets/art/cards/illustrations/actions/action_local_map.png
```

Shared prompt scaffold:

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike
Dzien 50. Match the deck art style and forest palette of the references: deep
forest greens, warm earth tones, embroidery-like visible pixel texture,
cozy-but-dark survival mood, medium visible pixels, crisp hard edges,
controlled dithering, no smooth painting.

Composition: single horizontal 3:2 illustration, subject centered, calm subtle
dark forest-floor background, gentle vignette so edges are darker, important
content kept away from extreme edges because it sits inside a card art window.

Text: absolutely no text, no letters, no numbers, no UI, no card frame, no
border.
```

Subject notes:

```text
action_scout.png: primitive spyglass/binoculars, compass, folded rough map,
marked twigs, fog-covered unknown terrain beyond a forest ridge.
action_mark_trail.png: safe forest path with branch markers, twine, cloth
ribbons, stones, boot prints, and small travel supplies.
action_local_map.png: parchment map fragment on a mossy stump, abstract 3x2
terrain shapes, compass, charcoal pencil, stones, leaves; no readable labels.
```

## biome_forest_normal.png

Path: `assets/art/biomes/normal/biome_forest_normal.png`
(historical — file not kept; superseded by v3, see legacy note at the top)

Prompt:

```text
Use case: stylized-concept
Asset type: game biome tile for a 2D survival card roguelike
Primary request: Generate asset file candidate `biome_forest_normal.png` for the project "Dzien 50".
Subject: Act I forest biome tile, a lush readable forest panel with pine trees, grass, small rocks, wildflowers, soft blue-green shadows, calm survival mood.
Style/medium: premium pixel art, polished retro strategy game aesthetic, crisp pixel clusters, limited but rich palette, readable at board scale. Dark wood and muted green board-frame influence. No photorealism, no painterly blur, no 3D look.
Composition/framing: wide horizontal rectangular biome panel, board-game tile composition, visible forest identity, clear central terrain, clear empty room for 3 future building slot overlays, subtle integrated dark wood/muted green border, small empty title strip area in the upper left but no words.
Lighting/mood: Act I bright, natural, hopeful, gentle daylight through trees.
Text: no text, no labels, no watermark.
Constraints: rectangular tile only, not puzzle-shaped, no characters, no full UI screen, no giant foreground object blocking slot space. Output should feel ready for a Godot board asset.
```

## P0 card assembly assets

Status: production-ready layered card assets for Godot composition. These are
not final flattened cards. Final cards should be assembled in Godot from:
card frame + clipped illustration + editable labels/text/icons.

Rules:

- No baked-in text, letters, numbers, labels, or fake glyphs.
- Card frame assets reserve blank areas for title, cost, illustration,
  rules text, tags, and status/category sockets.
- Card backs are final standalone bitmap backs, also text-free.
- Illustration slot reference: `card_art_mask.png` is 754x483 and sits at
  offset (135, 307) inside all 1024x1536 card frames (intersection of the
  measured art windows of the v2 generated frame set, 8 px safety margin).

Update 2026-06-12: the original deterministic flat frames were rejected
(no texture, thin misaligned lines) and replaced by the generated frame set
described in the `card_frame_action_v3` section below. The flat originals
are archived in `assets/art/concepts/cards/legacy_flat_frames/`.

Generated / created files:

```text
assets/art/cards/frames/card_frame_action.png    1024x1536
assets/art/cards/frames/card_frame_building.png  1024x1536
assets/art/cards/frames/card_frame_event.png     1024x1536
assets/art/cards/frames/card_frame_monster.png   1024x1536
assets/art/cards/frames/card_frame_reward.png    1024x1536
assets/art/cards/frames/card_art_mask.png        754x483 @ (135, 307)

assets/art/cards/backs/card_back_action.png      1024x1536
assets/art/cards/backs/card_back_event.png       1024x1536
assets/art/cards/backs/card_back_monster.png     1024x1536
```

Card back prompt direction:

```text
Premium detailed pixel art vertical fantasy card backs, portrait 2:3,
decorative border, centered symbolic emblem, no title, no letters, no numbers,
no readable text, no UI labels, no watermark.
```

## Generated card frame set v2 (APPROVED + completed, 2026-06-12)

Final paths (all 1024x1536, upscaled nearest-neighbor from 688x1024):

```text
assets/art/cards/frames/card_frame_action.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
assets/art/cards/frames/card_frame_monster.png
assets/art/cards/frames/card_frame_reward.png
assets/art/cards/frames/card_art_mask.png        754x483 @ (135, 307)
```

Pipeline: Higgsfield GPT Image 2, quality medium (2 credits each),
reference-image driven. The ACTION frame was approved first (prompt below,
with `card_back_action.png` as style reference). The other four frames were
generated with the approved action frame as the FIRST reference (layout
anchor: identical zone layout and pixel density) plus thematic references:

- building: + `card_back_action.png` + `biome_forest_normal_bg.png`;
  delta: carved timber beams, log-cabin corner joints, rope/nail details.
- event: + `card_back_event.png`; delta: midnight blue + aged silver trim,
  moon/star motifs instead of leaf garlands.
- monster: + `card_back_monster.png` + `biome_forest_plague_bg.png`;
  delta: blackened thorns, tarnished gold/olive, claw scratches, toxic glow.
- reward: + `card_back_action.png`; delta: richer gold, laurel garlands,
  sunburst corner accents, warm golden inner glow.

Each variant prompt = the action prompt scaffold with the theming paragraph
swapped; every prompt repeats: identical zone layout, all zones EMPTY,
no text/letters/numbers/pseudo-glyphs, nothing inside the art window.

Measured art windows (1024x1536, before 8 px inset): action 122-899 x
294-800, building 119-907 x 297-823, event 127-908 x 299-827, monster
112-904 x 290-839, reward 116-896 x 299-797. Mask = intersection - 8 px.

Feedback history: v1 deterministic flat frames rejected (no texture);
v2 carved wood + parchment (quality high, 4 credits) rejected as not
pixelated enough and detached from the approved card backs; v3 direction
(reference-driven, embroidery pixel texture) approved and extended to the
whole set.

Prompt (v3, with `card_back_action.png` attached as reference image):

```text
Using the attached pixel art card back as the exact style reference, design the matching FRONT card frame template for the same card game (dark survival roguelike Dzien 50). Copy from the reference: the deep forest-green color palette, the visibly pixelated cross-stitch / embroidery-like dithering texture, the golden pixel border language with diamond corner accents, and the leaf and fern ornament motifs. The front frame must look like it belongs to the same physical deck as this back.

IMPORTANT: keep the same pixel density and chunkiness as the reference — clearly visible individual pixels, hard edges, no smooth painting, no anti-aliased gradients.

It is an EMPTY front template, one single card filling the whole image, portrait 2:3, with these blank zones: 1) top horizontal title banner as an empty dark-green plaque with thin golden pixel trim, 2) one square cost socket embedded in the top-left corner, empty, 3) large rectangular illustration window below the title, about 80 percent of card width and roughly 1/3 of card height, filled with flat very dark green-black, framed with golden pixel trim, nothing inside, 4) wide empty rules-text panel in the lower third, slightly lighter muted green with subtle stitch texture so future text stays readable, framed in gold, 5) bottom strip with three small empty square sockets on the left and one small empty rectangular tag plate on the right. Decorate remaining frame surfaces with the leaf/fern embroidery pattern from the reference, kept subtle so it never competes with the content zones.

Text: absolutely no text, no letters, no numbers, no runes, no pseudo-glyphs, no emblem in the illustration window. All plaques and sockets stay blank.

Avoid: photorealism, painterly blur, smooth vector shapes, 3D render, the campfire emblem from the reference, any illustration content inside the art window, multiple cards, background scene around the card.
```

Rejected prompt v2 (kept for history):

```text
Premium pixel art vertical trading card frame template for a dark survival card roguelike game called Dzien 50. One single card frame filling the whole image, portrait 2:3, front of card, EMPTY template with no illustration content.

Style: refined SNES-era premium indie pixel art, medium-size visible pixels, crisp hard edges, readable pixel clusters, controlled dithering. Hand-crafted carved dark wood border with visible wood grain pixels, muted forest-green fabric inlay panels, warm aged gold and bone trim lines, weathered parchment texture panel. Cozy but dark survival mood, polished retro strategy deckbuilder UI. Absolutely not flat vector art: the frame must have pixel texture, carved corner ornaments (small leaf and rope motifs), subtle wear, highlights and shadows on the wood.

Layout zones, all completely EMPTY and blank: 1) top horizontal title banner as an empty carved wood plaque with parchment center, 2) one square cost socket embedded in the top-left corner of the banner, empty, 3) large rectangular illustration window below the title, about 80 percent of card width and roughly 1/3 of card height, filled with flat very dark neutral green-black color, framed by a gold pixel trim, no picture inside, 4) wide empty parchment rules-text panel in the lower third with slightly torn pixel edges, 5) bottom strip with three small empty square sockets on the left and one small empty rectangular tag plate on the right.

Text: absolutely no text, no letters, no numbers, no runes, no pseudo-glyphs, no fake writing, no watermark. All plaques and sockets stay blank.

Avoid: photorealism, painterly blur, 3D render, glossy modern mobile UI, flat untextured vector shapes, thin misaligned hairlines, illustration content inside the art window, multiple cards, background scene around the card.
```

## Starter card illustrations (completed, 2026-06-12)

Status: clean standalone card illustrations (the art layer that sits inside
the new card frames' art window). All 1024x688 (≈3:2 to match the 754x483
window aspect), text-free, no frame/border, centered hero subject, dark
forest survival palette. Composed in Godot under the frame + mask.

Current classification: the building files in
`assets/art/cards/illustrations/buildings/` are now kept as dark Act II /
post-BUM building art. The approved brighter Act I replacements live in
`assets/art/cards/illustrations/buildings_act1_candidates/`.
Current classification: the action files in
`assets/art/cards/illustrations/actions/` are now kept as dark Act II /
post-BUM action art. The approved brighter Act I replacements live in
`assets/art/cards/illustrations/actions_act1_candidates/`.

Pipeline: Higgsfield GPT Image 2, quality medium (2 credits each), shared
style references `card_back_action.png` + `biome_forest_normal_bg.png` for
palette/pixel-density consistency. One shared prompt scaffold, only the
subject paragraph swapped. Campfire was the style-lock test, approved, then
the rest batched.

Paths:

```text
assets/art/cards/illustrations/buildings/building_campfire.png
assets/art/cards/illustrations/buildings/building_hut.png
assets/art/cards/illustrations/buildings/building_well.png
assets/art/cards/illustrations/actions/action_rest.png
assets/art/cards/illustrations/actions/action_explore.png
assets/art/cards/illustrations/actions/action_chop_wood.png
assets/art/cards/illustrations/actions/action_forage.png
assets/art/cards/illustrations/actions/action_treat_wounds.png
assets/art/cards/illustrations/actions/action_spring_source.png
assets/art/cards/illustrations/actions/action_craft_tools.png
```

Shared prompt scaffold (subject swapped per card):

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike Dzien 50. Match the deck art style and forest palette of the references: deep forest greens, warm earth tones, embroidery-like visible pixel texture, cozy-but-dark survival mood, medium visible pixels, crisp hard edges, controlled dithering, no smooth painting.

Subject: {SUBJECT}. Centered, strong readable silhouette, hero of the card. No people.

Composition: single horizontal 3:2 illustration, subject centered, calm subtle dark forest-floor background, gentle vignette so edges are darker, important content kept away from extreme edges (it sits inside a card art window).

Text: absolutely no text, no letters, no numbers, no UI, no card frame, no border.

Avoid: photorealism, painterly blur, 3D render, frame or border, characters or human figures, text or icons.
```

Subjects used: campfire (stone ring + flame), lean-to hut (branches +
hides), stone/wood well (roof + bucket + water glint), rest (bedroll + fur
+ embers), explore (forest trail into mist + footprints), chop wood (axe in
stump + split logs), forage (wicker basket of berries/mushrooms/herbs),
treat wounds (bandage + herb bowl + drop), spring source (spring between
mossy stones), craft tools (stone axe + flint knife + cordage).

## Plague monster illustrations (completed, 2026-06-12)

Status: Act II monster card illustrations, same illustration pipeline but
corrupted palette. 1024x688, text-free, centered single creature/swarm,
ominous but no gore. References: `card_back_monster.png` +
`biome_forest_plague_bg.png` (corrupted palette anchor). GPT Image 2 medium.

Paths:

```text
assets/art/cards/illustrations/monsters/monster_rotting_one.png   (Zgnilec)
assets/art/cards/illustrations/monsters/monster_plague_wolf.png   (Zarazony wilk)
assets/art/cards/illustrations/monsters/monster_crow_swarm.png    (Krucza chmara)
assets/art/cards/illustrations/monsters/monster_rat_swarm.png     (Roj szczurow)
```

Scaffold = the starter-illustration scaffold with the palette line swapped
to "dark teal, charcoal gray, muted violet, sickly toxic-green glow,
blackened dead vegetation, ominous but readable, NO gore" and explicit
avoids for zombie-photo look / blood splatter gore. Single creature per
card (swarms read as one threatening mass).

## Additional building illustrations (completed, 2026-06-12)

Status: 12 more building cards beyond the starter trio, same building
illustration pipeline (shared starter scaffold, subject paragraph swapped),
1024x688, text-free, centered hero structure, dark forest survival palette.
Current classification: this `buildings/` set is kept for Act II / post-BUM
cards. The approved brighter Act I building set lives separately in
`assets/art/cards/illustrations/buildings_act1_candidates/`.
References: `card_back_action.png` + `biome_forest_normal_bg.png`. GPT Image 2,
quality medium (2 cr each) except `building_wood_storage` at low (0.5 cr) to
fit the remaining budget — it still holds the style. Batched in groups of 4
(the basic plan's concurrent-job limit).

Paths:

```text
assets/art/cards/illustrations/buildings/building_pantry.png        (Spizarnia)
assets/art/cards/illustrations/buildings/building_workshop.png      (Warsztat)
assets/art/cards/illustrations/buildings/building_palisade.png      (Palisada)
assets/art/cards/illustrations/buildings/building_traps.png         (Pulapki)
assets/art/cards/illustrations/buildings/building_wood_storage.png  (Magazyn drewna, low quality)
assets/art/cards/illustrations/buildings/building_fishing_dock.png  (Port rybacki)
assets/art/cards/illustrations/buildings/building_water_filter.png  (Filtr wodny)
assets/art/cards/illustrations/buildings/building_watchtower.png    (Wieza obserwacyjna)
assets/art/cards/illustrations/buildings/building_logging_camp.png  (Drwalnia)
assets/art/cards/illustrations/buildings/building_farm.png          (Farma)
assets/art/cards/illustrations/buildings/building_quarry.png        (Kamieniolom)
assets/art/cards/illustrations/buildings/building_herbalist.png     (Zielarnia)
```

Buildings directory now holds all 15 (starter trio + these 12). No `.tres`
building cards wired to these yet — they are art-ahead of the data/gameplay.

## biome_forest_normal_bg.png

Path: `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png`

Status: new clean biome background baseline. No frame, no title plate, no slots,
no text. Intended for Godot layer composition.

Prompt:

```text
Use case: stylized-concept
Asset type: clean biome terrain background layer for a 2D survival card roguelike
Primary request: Generate `biome_forest_normal_bg.png` for the project "Dzien 50" as a fresh clean production background, starting the asset pipeline over with layered Godot composition.
Subject: Act I forest biome terrain background: lush pine forest clearing, distant treeline, blue sky glimpses, grass, rocks, mushrooms, small wildflowers, calm survival exploration mood. The image should clearly read as a forest biome at board scale.
Composition/framing: one wide horizontal rectangular terrain background. No border, no card frame, no title plaque, no slot cards, no UI panels. Keep the center and lower-middle areas visually calm enough for Godot to overlay 3 building slot markers later, but do not draw the slots. Preserve readable forest depth with foreground grass, midground clearing, and background trees.
Style/medium: refined SNES-era / premium indie pixel art, medium-size visible pixels, crisp hard edges, readable clusters, controlled dithering, clean retro strategy-game environment art. The pixels should be visible but not oversized or chunky.
Lighting/mood: bright Act I daylight, hopeful but still survival-themed, green-blue natural palette with warm sun patches.
Text constraints: text-free image. NEVER include letters, numbers, words, symbols, labels, watermark, pseudo-text, fake glyphs, UI captions, decorative writing, title areas, or signs.
Production constraints: pure terrain/background layer only. MUST contain no UI elements of any kind. MUST be compatible with separate Godot overlays for frame, title plate, slot markers, hover/selected state, current player marker, and text. Avoid smooth digital painting, painterly texture, realistic rendering, 3D style, characters, and full gameplay screen layout.
```

## P0 clean biome backgrounds batch

Status: generated as final layered-production biome backgrounds. All are
`1536x1024`, text-free, UI-free, and intended for Godot composition with
separate frame/title/slot overlays.

Paths:

```text
assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png
assets/art/biomes/backgrounds/normal/biome_meadow_normal_bg.png
assets/art/biomes/backgrounds/normal/biome_mountains_normal_bg.png
assets/art/biomes/backgrounds/corrupted/biome_forest_plague_bg.png
assets/art/biomes/backgrounds/corrupted/biome_meadow_plague_bg.png
assets/art/biomes/backgrounds/corrupted/biome_mountains_plague_bg.png
```

Shared prompt pattern:

```text
Use case: stylized-concept
Asset type: clean biome terrain background layer for a 2D survival card roguelike
Primary request: Generate the named `*_bg.png` asset for "Dzien 50" as a clean production background for layered Godot composition.
Composition/framing: one wide horizontal rectangular terrain background. Pure terrain only: no border, no card frame, no title plaque, no slot cards, no UI panels. Keep calm readable areas where Godot can overlay building slot markers later, without drawing slots.
Style/medium: refined SNES-era / premium indie pixel art, medium-size visible pixels, crisp hard edges, readable clusters, controlled dithering, clean retro strategy-game environment art.
Text constraints: text-free image. NEVER include letters, numbers, words, symbols, labels, watermark, pseudo-text, fake glyphs, UI captions, decorative writing, title areas, or signs.
Production constraints: pure terrain/background layer only. MUST contain no UI elements of any kind. Compatible with separate Godot overlays for frame, title plate, slot markers, hover/selected state, current player marker, and text.
```

Asset-specific subject notes:

```text
biome_meadow_normal_bg.png: Act I open lush grassland, low hills, wildflowers, stones, open center for 4 slots.
biome_mountains_normal_bg.png: Act I rocky alpine clearing, gray stone outcrops, pines, distant snow peaks, space for 2 slots.
biome_forest_plague_bg.png: Act II plague-corrupted pine forest, dead undergrowth, toxic spores, cold shadows, space for 3 slots.
biome_meadow_plague_bg.png: Act II sick yellow-brown meadow, diseased grass, cracked earth, toxic mold patches, space for 4 slots.
biome_mountains_plague_bg.png: Act II cracked alpine rocks, dead pines, toxic green fissures, cold mist, space for 2 slots.
```

## P0 biome UI layer assets

Status: deterministic repaint was rejected as too flat / paint-like. The
accepted direction for production biome frames and slot markers is now raw
green-key AI art. Update: `biomes/frames/` was regenerated again to follow
the lighter `biome_neighbor_highlight.png` style, then corrected once more:
`biome_tile_frame.png` must be a fully closed continuous frame with no breaks,
while `biome_title_plate.png` must have a solid dark green/brown filled center
so one-color Godot text stays readable. Slot markers were simplified to two
active production states: `slot_empty.png` and `slot_selectable.png`, both in
the same closed light ornamental style with dark filled centers. Transparent/key
areas stay as solid pure green `#00FF00`; do not remove the green during
generation.

Current production paths:

```text
assets/art/biomes/frames/biome_tile_frame.png
assets/art/biomes/frames/biome_title_plate.png
assets/art/biomes/slot_markers/slot_empty.png
assets/art/biomes/slot_markers/slot_selectable.png
assets/art/biomes/slot_markers/slot_occupied.png
assets/art/biomes/slot_markers/slot_damaged.png
assets/art/biomes/slot_markers/slot_ruin.png
assets/art/concepts/biomes/frames_before_neighbor_highlight_style/*.png
assets/art/concepts/biomes/frames_neighbor_style_open_frame_reference/*.png
assets/art/concepts/biomes/slot_markers_before_closed_light_style/*.png
docs/asset_plan/previews/preview_biome_frames_neighbor_style_raw_green.png
docs/asset_plan/previews/preview_biome_frames_closed_filled_raw_green.png
docs/asset_plan/previews/preview_biome_frames_closed_filled_on_forest.png
docs/asset_plan/previews/preview_biome_slots_closed_light_raw_green.png
```

Dimensions:

```text
biome_tile_frame.png: 1536x1024
biome_title_plate.png: 1774x887
slot_*.png: 1024x1536
```

Earlier AI review candidates: the `assets/art/biomes/ai_layer_candidates/`
folder no longer exists — the accepted candidates were promoted into the
production paths above and the folder was removed (structure audit
2026-06-12). Their review previews remain:

```text
docs/asset_plan/previews/preview_biome_ai_candidates_greenkey.png
docs/asset_plan/previews/preview_biome_ai_candidates_on_forest.png
```

Prompt direction:

```text
Pixel art UI frame asset for Dzien 50, matching the approved card backs and
card frames. Dark forest-green stitched cloth texture, aged gold/bronze trim,
dark wood accents, leaf/vine ornament, crisp medium pixel clusters, hard
edges, controlled dithering, premium survival card roguelike UI. Frame/plate
or slot marker only, no background scene, no text, no letters, no numbers.
All empty transparent/key areas must be pure solid green #00FF00 only.
```

## P0 biome overlay replacement pass

Status: regenerated and copied into production with `imagegen`. These files
must stay as raw full-canvas PNGs on pure solid green `#00FF00`; do not run
chroma-key removal during asset generation because it can clip ornate frame
tips and glow pixels. Godot/import tooling should handle the green key later.

Production files:

```text
assets/art/biomes/overlays/biome_corruption_overlay.png  1536x1024
assets/art/biomes/overlays/biome_current_player.png      1536x1024
assets/art/biomes/overlays/biome_neighbor_highlight.png  1536x1024
docs/asset_plan/previews/preview_biome_overlays_raw_green.png
```

Prompt direction:

```text
Pixel art biome overlay layer for Dzien 50, matching the approved biome
frames, slot markers, card backs and card frames. Dark forest-green stitched
texture, aged gold/bronze ornament, leaf/vine accents, crisp medium pixel art,
controlled dithering. Full 1536x1024 raw image on perfectly flat #00FF00
background. Overlay art only, no text, no letters, no numbers, no UI copy, no
background scene, no post-process cutout.
```

## building_well_card.png

Path (current): `assets/art/concepts/cards/concept_building_well_card.png`
(originally generated as `assets/art/cards/buildings/building_well_card.png`,
moved to concepts when the layered card pipeline replaced flattened cards)

Prompt:

```text
Use case: stylized-concept
Asset type: vertical building card for a 2D survival card roguelike
Primary request: Generate asset file candidate `building_well_card.png` for the project "Dzien 50".
Subject: Studnia / stone water well with a small wooden roof, rope bucket, subtle blue water glint, instantly recognizable survival settlement building.
Style/medium: premium pixel art, polished retro deckbuilder UI, parchment card body with dark wood and muted green frame, crisp pixel clusters, strong silhouette, clean readable game card design. No photorealism, no painterly blur, no 3D look.
Composition/framing: exactly one vertical card, title area at top left empty with no words, large central illustration of the well fully visible, lower information area kept clean and blank for future UI text, small cost/icon sockets may be present but empty, centered layout, no extra cards, no full gameplay screen.
Lighting/mood: cozy survival craft mood, neutral UI usable in Act I and Act II, warm parchment with dark forest-game trim.
Text: no text, no labels, no watermark.
Constraints: the card must look like part of the same visual system as the forest biome asset, readable when scaled down, no Polish letters rendered, no decorative clutter blocking the text/effect areas.
```

## biome_forest_normal_v2.png

Path: `assets/art/biomes/normal/biome_forest_normal_v2.png`
(historical — file not kept; superseded by v3)

Prompt:

```text
Use case: stylized-concept
Asset type: chunky 16-bit pixel art biome board tile for a 2D survival card roguelike
Primary request: Generate a revised asset candidate named `biome_forest_normal_v2.png` for the project "Dzien 50", closer to the provided reference: visibly pixelated, low-resolution retro game UI, simple readable blocks, not painterly.
Subject: Act I forest biome tile named "LAS", with pine trees, blue sky, distant treeline, rocks, mushrooms, small flowers, bright green grass, and a calm survival exploration mood.
Style/medium: true chunky pixel art, 16-bit strategy game UI, large visible pixel clusters, crisp hard edges, limited color palette, no smooth painting, no soft gradients, no realistic lighting, no 3D render look. The image should feel like old-school hand-placed pixel art scaled up.
Composition/framing: one wide horizontal rectangular board tile, dark green and wood frame, forest landscape background. Place a dark green title plaque in the upper-left corner with pixel-font text exactly "LAS" and below it exactly "Sloty 0/3". Place three large vertical dark green building slot cards across the middle/lower area, each with a thin golden pixel border and a subtle leaf emblem inside. Keep the layout simple and readable like a game board asset, with strong silhouettes and generous spacing.
Lighting/mood: bright Act I daylight, hopeful forest, readable and cozy.
Text: render only "LAS" and "Sloty 0/3" in chunky cream pixel font on the upper-left plaque.
Constraints: MUST be more visibly pixelated than the previous version. MUST include exactly three building slot cards. MUST be a rectangular tile, not a puzzle shape. Do not include characters, full game screen UI, tiny unreadable details, painterly brushwork, smooth illustration texture, or watermark.
```

## biome_forest_normal_v3.png

Path (current):
`assets/art/concepts/biomes/concept_biome_forest_board_slots_v3.png`
(originally `assets/art/biomes/normal/biome_forest_normal_v3.png`; archived
as concept when the layered pipeline replaced composed tiles. A byte-identical
`legacy_biome_forest_normal_v3.png` duplicate was removed in the 2026-06-12
structure audit.)

Prompt:

```text
Use case: stylized-concept
Asset type: medium-density pixel art biome board tile for a 2D survival card roguelike
Primary request: Generate `biome_forest_normal_v3.png` for the project "Dzien 50" as a balanced revision: less chunky than v2, more clearly pixel art than v1. Aim for refined SNES-era / premium indie pixel art, not oversized blocky pixels.
Subject: Act I forest biome tile named "LAS", with pine trees, blue sky, distant treeline, rocks, mushrooms, small flowers, bright green grass, and calm survival exploration mood.
Style/medium: refined premium pixel art with medium-size visible pixels, crisp hard edges, readable clusters, controlled dithering, clean tile-based retro strategy UI. The pixels should be visible but not huge. Use more environmental detail than v2, while keeping the forms simple and readable. Avoid smooth digital painting, soft gradients, realistic lighting, and 3D render style.
Composition/framing: one wide horizontal rectangular board tile, dark green and wood frame, forest landscape background. Put a dark green title plaque in the upper-left corner with pixel-font text exactly "LAS" and below it exactly "Sloty 0/3". Place exactly three large vertical dark green building slot cards across the middle/lower area, each with a thin golden pixel border and a subtle leaf emblem. Keep slot cards readable and evenly spaced, but let the forest behind have finer pixel detail than v2.
Lighting/mood: bright Act I daylight, cozy forest, readable and hopeful.
Text: render only "LAS" and "Sloty 0/3" in cream pixel font on the upper-left plaque.
Constraints: MUST be less chunky/blocky than the previous v2 direction. MUST still be obvious pixel art. MUST include exactly three building slot cards. MUST be a rectangular tile, not a puzzle shape. Do not include characters, full game screen UI, painterly texture, smooth illustration, or watermark.
```

## biome_meadow_normal.png

Path (current):
`assets/art/concepts/biomes/concept_biome_meadow_board_slots.png`
(originally `assets/art/biomes/normal/biome_meadow_normal.png`; archived as
concept when the layered pipeline replaced composed tiles. A byte-identical
`legacy_biome_meadow_normal.png` duplicate was removed in the 2026-06-12
structure audit.)

Status: corrected production direction after approval note. This asset keeps
the approved medium-density pixel-art biome style, but removes all baked-in
text. The title plaque is intentionally empty for Godot text.

Prompt:

```text
Use case: stylized-concept
Asset type: medium-density pixel art biome board tile for a 2D survival card roguelike
Primary request: Regenerate `biome_meadow_normal.png` for the project "Dzien 50" in the approved `biome_forest_normal_v3` direction, but with absolutely no baked-in text. This is a production board art asset where labels will be added later in Godot.
Subject: Act I meadow biome: open lush grassland with wildflowers, low rolling hills, a few small trees, stones, tiny pixel butterflies as decoration, bright but calm survival exploration mood.
Composition/framing: one wide horizontal rectangular board tile, dark green and dark wood frame, meadow landscape background. Put a dark green EMPTY title plaque in the upper-left corner with enough blank space for future Godot text. Place exactly four medium vertical dark green building slot cards across the middle/lower area, each with a thin golden pixel border and a subtle grass/leaf emblem. Keep the slot cards readable and evenly spaced, with enough meadow detail behind them.
Style/medium: refined SNES-era / premium indie pixel art, medium-size visible pixels, crisp hard edges, readable clusters, controlled dithering, clean retro strategy UI. The pixels should be visible but not huge.
Lighting/mood: bright Act I daylight, hopeful and natural, green-blue palette with warm sunlight.
Text constraints: text-free image. The title plaque MUST be blank. NEVER include letters, numbers, words, symbols, labels, watermark, pseudo-text, fake glyphs, UI captions, or decorative writing anywhere in the image.
Constraints: MUST be less chunky than old 16-bit block art but still obvious pixel art. MUST be a rectangular tile, not a puzzle shape. MUST feel visually compatible with `biome_forest_normal_v3`. Do not include characters, full game screen UI, smooth digital painting, painterly texture, realistic rendering, or 3D style.
```
