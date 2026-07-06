# Wymiana assetów Higgsfield (decyzja autora, 2026-07-06)

Autor rezygnuje ze wszystkich plików wygenerowanych przez Higgsfield.
Ten dokument zawiera gotowe prompty do regeneracji zamienników w bieżącym
pipelinie (GPT Image / imagegen). Kontekst i lista plików: `assets/art/LICENSES.txt`.

## Zasady wspólne (WAŻNE)

- **Nie podawać plików Higgsfield jako obrazów referencyjnych** — zamiennik ma
  być czysty od źródła, które usuwamy. Referencje stylu tylko z assetów
  OpenAI: tła biomów, ilustracje zdarzeń, 11 późniejszych potworów.
- Zapis pod TĄ SAMĄ nazwą pliku (drop-in; kod ładuje po ścieżce/id).
- Wszystko text-free: bez liter, cyfr, pseudo-glifów, watermarków.
- Po wrzuceniu: `--import` + `ui_layout_test` + rzut oka w edytorze.

## 1. Cztery pierwotne bestie Plagi (ilustracje 1024x688)

Ścieżki (podmiana in-place):

```text
assets/art/cards/illustrations/monsters/monster_rotting_one.png   (Zgnilec)
assets/art/cards/illustrations/monsters/monster_plague_wolf.png   (Zarażony wilk)
assets/art/cards/illustrations/monsters/monster_crow_swarm.png    (Krucza chmara)
assets/art/cards/illustrations/monsters/monster_rat_swarm.png     (Rój szczurów)
```

Obrazy referencyjne (styl/paleta — pipeline OpenAI): `leech_plague.png`
+ `shadow_crawler.png` (spójność z pozostałymi 11 potworami) oraz
`assets/art/biomes/backgrounds/corrupted/biome_forest_plague_bg.png`
(kotwica skażonej palety Plagi).

Wspólny scaffold (podmieniaj tylko akapit Subject):

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike
Dzien 50, Act II plague monster. Match the art style and palette of the
attached reference monster illustrations and corrupted forest background:
dark teal, charcoal gray, muted violet, sickly toxic-green glow, blackened
dead vegetation, medium visible pixels, crisp hard edges, controlled
dithering, no smooth painting. Ominous but readable, NO gore.

Subject: {SUBJECT}. Single creature (a swarm reads as one threatening mass),
centered, strong readable silhouette, hero of the card.

Composition: single horizontal 3:2 illustration, subject centered, calm dark
corrupted-forest background, gentle vignette so edges are darker, important
content kept away from extreme edges (it sits inside a card art window).

Text: absolutely no text, no letters, no numbers, no UI, no card frame,
no border.

Avoid: photorealism, painterly blur, 3D render, frame or border, human
figures, blood splatter gore, zombie-photo look, text or icons.
```

Subjects:

- `monster_rotting_one` — a shambling rotting humanoid mass of moss, fungus
  and blackened branches, faint toxic-green glow in its chest, dripping decay.
- `monster_plague_wolf` — a gaunt infected wolf, patchy fur, glowing sickly
  green eyes, fungal growths along the spine, snarling stance.
- `monster_crow_swarm` — a dense swarm of plague crows forming one dark
  swirling mass, a few glowing green eyes inside, feathers scattering.
- `monster_rat_swarm` — a surging wave of infected rats reading as one mass,
  matted fur, toxic-green sheen, many small glinting eyes.

## 2. Trzy ramki kart (1024x1536)

Ścieżki (podmiana in-place):

```text
assets/art/cards/frames/card_frame_building.png   (wspólna: akcje/budynki/nagrody)
assets/art/cards/frames/card_frame_event.png      (zdarzenia nocne)
assets/art/cards/frames/card_frame_monster.png    (potwory)
```

UWAGA TECHNICZNA: `card_view.gd` ma na sztywno zmierzone okna tekstu, a okno
ilustracji to ~754x483 @ (135, 307) w 1024x1536. Nowa ramka MUSI powtórzyć
ten sam układ stref. Po generacji zmierzyć okno artu; jeśli odjeżdża o więcej
niż ~8 px, poprawić stałe okien w `card_view.gd` (i przetestować
`ui_layout_test` + auto-fit tekstów na 100+ kartach).

Referencje palety (OpenAI): `biome_forest_normal_bg.png` (zieleń Aktu I),
dowolna ilustracja zdarzenia z `illustrations/events/` (paleta nocna),
`biome_forest_plague_bg.png` (paleta potworów).

Prompt bazowy (wariant BUILDING; dla event/monster podmień akapit tematyczny):

```text
Premium pixel art vertical trading card FRONT FRAME template for the dark
survival card roguelike Dzien 50. One single empty card frame filling the
whole image, portrait 2:3, EMPTY template with no illustration content.

Style: deep forest-green palette with visible cross-stitch / embroidery-like
pixel dithering texture, warm aged-gold pixel trim with diamond corner
accents, leaf and fern ornament motifs, carved timber beams and log-cabin
corner joints with rope and nail details. Clearly visible individual pixels,
hard edges, no smooth painting, no anti-aliased gradients. Cozy but dark
survival mood, polished retro deckbuilder look.

Layout zones, all completely EMPTY and blank, copied exactly: 1) top
horizontal title banner as an empty dark-green plaque with thin golden pixel
trim, 2) one square cost socket embedded in the top-left corner, empty,
3) large rectangular illustration window below the title, about 80 percent
of card width and roughly 1/3 of card height, filled with flat very dark
green-black, framed with golden pixel trim, nothing inside, 4) wide empty
rules-text panel in the lower third, slightly lighter muted green with subtle
stitch texture so future text stays readable, framed in gold, 5) bottom strip
with three small empty square sockets on the left and one small empty
rectangular tag plate on the right.

Text: absolutely no text, no letters, no numbers, no runes, no pseudo-glyphs,
no emblem in the illustration window. All plaques and sockets stay blank.

Avoid: photorealism, painterly blur, smooth vector shapes, 3D render, any
illustration content inside the art window, multiple cards, background scene
around the card.
```

Akapity tematyczne zamienników:

- **event** (`card_frame_event.png`): zamiast akapitu o drewnie/zieleni —
  "midnight-blue and deep indigo palette with aged-silver pixel trim,
  moon and star motifs instead of leaf garlands, faint night-sky sparkle
  in the border fabric".
- **monster** (`card_frame_monster.png`): "blackened thorn branches, tarnished
  gold and olive trim, claw scratches across the border wood, faint sickly
  toxic-green glow seeping from the corners".

## 3. WARUNKOWO: jasne zestawy Akt I (jeśli autor potwierdzi Higgsfield)

Dokumentacja nie zapisała narzędzia dla `actions_act1_candidates/` (10 plików)
i `buildings_act1_candidates/` (15 plików). Jeśli powstały w Higgsfield,
zregenerować tym scaffoldem (udokumentowany kierunek Act I):

```text
Standalone pixel art CARD ILLUSTRATION for the dark survival card roguelike
Dzien 50, specifically for ACT I before the catastrophe. Bright, natural,
hopeful survival mood: fresh forest greens, warm earth browns, soft morning
daylight, clear readable shapes, medium visible pixels, crisp hard edges,
controlled dithering, no smooth painting.

Subject: {SUBJECT}. Centered, strong readable silhouette, hero of the card.
No people.

Composition: single horizontal 3:2 illustration, subject centered, clean
forest-floor background with daylight and healthy vegetation, moderate gentle
vignette only, important content kept away from extreme edges because it sits
inside a card art window.

Text: absolutely no text, no letters, no numbers, no UI, no card frame,
no border.

Avoid: Act II mood, plague, corruption, toxic green glow, dead trees, heavy
black vignette, horror, photorealism, painterly blur, 3D render, frame or
border, characters, body parts, text, symbols or icons.
```

Subjects — akcje (10): rest (bedroll + fur + embers), explore (forest trail
into mist + footprints), chop_wood (axe in stump + split logs), forage
(wicker basket of berries/mushrooms/herbs), treat_wounds (bandage + herb bowl),
spring_source (spring between mossy stones), craft_tools (stone axe + flint
knife + cordage), scout (lookout rock over treetops), mark_trail (carved
trail blaze + rope marker), local_map (parchment map + charcoal stick).

Subjects — budynki (15): campfire (stone ring + flame), hut (lean-to of
branches + hides), well (stone/wood well + bucket), pantry (stocked cellar
shelves), workshop (workbench + tools), palisade (sharpened log wall),
traps (snares + pit trap), wood_storage (stacked log shed), fishing_dock
(wooden pier + rod), water_filter (barrel + charcoal/sand layers),
watchtower (tall wooden tower), logging_camp (sawhorse + stacked timber),
farm (small tilled plots + fence), quarry (stone pit + tools), herbalist
(drying herbs hut).

## Po wymianie (checklista)

- [ ] `--import` + `ui_layout_test` + ręczny rzut oka na karty w edytorze.
- [ ] Zmierzone okno artu nowych ramek == stare (albo poprawione stałe w `card_view.gd`).
- [ ] Usunąć „Higgsfield" z `assets/art/LICENSES.txt` (sekcja narzędzi + decyzja o wymianie).
- [ ] Usunąć „Higgsfield" z creditsów w grze (`ui/credits_overlay.gd`).
- [ ] Zaktualizować `docs/asset_plan/generated_asset_samples.md` (sekcje ramek/potworów).
