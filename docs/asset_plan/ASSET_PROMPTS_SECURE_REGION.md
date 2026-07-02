# Brakujące assety — zabezpieczenie rejonu przed BUM

Spec do wygenerowania brakujących grafik dla mechaniki zabezpieczania rejonu.
Mechanika działa już w kodzie z fallbackami UI; te assety są potrzebne do finalnego
polishu wizualnego.

## Parametry techniczne

- **Ikona UI:** `assets/art/ui/icons/icon_secure_region.png`
  - format: `256x256` PNG
  - preferowany kanał alfa; jeśli generator nie umie alfy, użyj czystego
    chroma-key green `#00FF00` jako tła
  - bez tekstu, cyfr i ramek przycisku
- **Ramka rejonu:** `assets/art/biomes/overlays/biome_secure_region_frame.png`
  - format: `1024x650` PNG, proporcja zgodna z kaflem planszy
  - preferowany kanał alfa; fallback: chroma-key green `#00FF00`
  - sama ramka/obrys, bez tła biomu
- **Opcjonalny FX:** `assets/art/fx/buildings/fx_secure_region.png`
  - format: `512x512` PNG, przezroczyste lub chroma-key green tło
  - statyczny błysk/pył do krótkiego feedbacku po kliknięciu
- **Po wrzuceniu plików:** uruchom import Godota:

```text
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
```

## Referencje stylu

- `assets/art/biomes/frames/biome_tile_frame.png` — ornament i grubość obrysu kafla
- `assets/art/ui/icons/icon_repair_round.png` — czytelność ikony w małym rozmiarze
- `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png` — jasny Akt I
- `assets/art/biomes/overlays/biome_corruption_overlay.png` — format overlayu kafla

## Prompt 1 — ikona przycisku

Docelowy plik: `assets/art/ui/icons/icon_secure_region.png`

```text
Pixel art UI ICON for a survival card roguelike, readable at small button size.
Subject: fortified region action icon, a compact stone shield combined with a
low palisade arc and two fitted stone blocks, symbolizing "secure this area".
Style: warm Act I survival UI, crisp visible pixels, hard edges, slight engraved
gold highlight, earthy stone gray, muted wood brown, small green survival accent.
Composition: centered single object, strong silhouette, no background scenery,
no text, no letters, no numbers, no button frame.
Avoid: modern metal shield, fantasy magic rune, skulls, horror corruption,
photorealism, blur, 3D render, excessive detail, red warning icon.
Output: 256x256 PNG, transparent background preferred; if transparency is not
available use pure chroma-key green #00FF00 background.
```

## Prompt 2 — ramka zabezpieczonego rejonu

Docelowy plik: `assets/art/biomes/overlays/biome_secure_region_frame.png`

```text
Pixel art transparent TILE OVERLAY FRAME for a 2D survival card roguelike board.
Subject: secured region frame, an irregular reinforced stone-and-wood perimeter
that wraps around the rectangular biome tile, with small rope bindings, wedge
stones, subtle golden repair marks and a calm prepared-before-the-storm mood.
Style: compatible with ornate biome tile frames, readable on bright forest,
meadow, mountain and river backgrounds, crisp pixels, controlled dithering,
warm stone gray, weathered wood brown, restrained gold highlights.
Composition: frame only around the outer edge, center fully empty/transparent,
corners slightly heavier, no filled background, no UI text, no icons.
Avoid: dark corruption, toxic green glow, heavy black vignette, flames, horror,
photorealism, 3D render, card border, letters, numbers.
Output: 1024x650 PNG, transparent background preferred; if transparency is not
available use pure chroma-key green #00FF00 background.
```

## Prompt 3 — opcjonalny FX zabezpieczenia

Docelowy plik: `assets/art/fx/buildings/fx_secure_region.png`

```text
Pixel art one-shot FEEDBACK EFFECT sprite for securing a region in a survival
card roguelike.
Subject: small burst of stone dust, rope tension marks and warm golden hammer
sparks radiating from the center, suggesting a region has been fortified.
Style: bright Act I, clear readable pixels, short UI feedback effect, warm gold,
stone gray, soft dust tan, no dark catastrophe mood.
Composition: centered burst with empty transparent outer area, works over a biome
tile, no text, no symbols, no characters.
Avoid: explosion, fireball, magic spell, skulls, red danger, horror corruption,
photorealism, blur, 3D render, letters, numbers.
Output: 512x512 PNG, transparent background preferred; if transparency is not
available use pure chroma-key green #00FF00 background.
```

## Uwagi implementacyjne

- Kod aktualnie szuka `icon_secure_region.png`; jeśli pliku nie ma, używa
  `icon_repair_round.png` jako fallbacku.
- Ramka działa już jako stylowany border w Godot. Po dodaniu PNG można ją
  podmienić w `ui/biome_tile_view.tscn` / `ui/biome_tile_view.gd` na teksturę.
- FX jest opcjonalny; obecnie kliknięcie używa istniejącego feedbacku budowy.
