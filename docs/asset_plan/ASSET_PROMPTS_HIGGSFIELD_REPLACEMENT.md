# Wymiana assetów Higgsfield (decyzja autora, 2026-07-06) — WYKONANA 2026-07-06

Autor rezygnuje ze wszystkich plików wygenerowanych przez Higgsfield.
Po weryfikacji z autorem (2026-07-06) dotyczy to WYŁĄCZNIE 4 pierwotnych
bestii Plagi — ramki kart i jasne zestawy ilustracji Aktu I autor
poprawiał/generował w OpenAI i zostają. Kontekst: `assets/art/LICENSES.txt`.

## Zasady wspólne (WAŻNE)

- **Nie podawać plików Higgsfield jako obrazów referencyjnych** — zamiennik ma
  być czysty od źródła, które usuwamy. Referencje stylu tylko z assetów
  OpenAI (pozostałe 11 potworów, tła biomów).
- Zapis pod TĄ SAMĄ nazwą pliku (drop-in; kod ładuje po id karty).
- 1024x688, text-free: bez liter, cyfr, pseudo-glifów, watermarków.
- Po wrzuceniu: `--import` + `ui_layout_test` + rzut oka w edytorze.

## Cztery pierwotne bestie Plagi (ilustracje 1024x688)

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

## Po wymianie (checklista) — domknięta 2026-07-06

- [x] `--import` czysty + `ui_layout_test` zielony (125 kart); wymiary 4×1024x688 zweryfikowane.
- [x] „Higgsfield" usunięty z `assets/art/LICENSES.txt` (sekcja narzędzi + sekcja wymiany).
- [x] „Higgsfield" usunięty z creditsów w grze (`ui/credits_overlay.gd`).
- [x] `docs/asset_plan/generated_asset_samples.md` zaktualizowany (sekcja potworów Plagi).
- [ ] Ręczny rzut oka na 4 karty potworów w edytorze (Akt II) — przy okazji playtestu.
