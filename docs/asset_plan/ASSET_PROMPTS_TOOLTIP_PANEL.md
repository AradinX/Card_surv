# Brakujący panel tooltipów

Audyt: `panel_tooltip_9slice.png` był zaplanowany jako P0 w
`ASSET_PLAN_DZIEN_50_GODOT.md` („Małe okienko tooltipów kart, ikon i
budynków"), ale nigdy nie trafił do repo i nigdzie w kodzie nie ma
`TooltipPanel`/`TooltipLabel` override. Gra dziś pokazuje wszystkie
`tooltip_text` (kafle biomów, budynki, karty, ikony) domyślnym szarym
tooltipem silnika Godota — zgrzyta z resztą oprawy.

## Parametry techniczne

- Plik: `assets/art/ui/panels/panel_tooltip_9slice.png`
- Canvas: `256x160` PNG, kanał alfa (transparent preferred; fallback: czysty
  chroma-key green `#00FF00`, zgodnie z regułą pipeline'u projektu — nie
  usuwać green-keya przy generowaniu).
- **9-slice**: bezpieczny margines do stretchowania ~28px z każdej strony —
  środek płaski/powtarzalny, róg/krawędź nie mogą mieć unikalnych detali,
  które złamią się przy rozciąganiu (Godot `StyleBoxTexture`, marginesy 28px).
- Jeden wariant, uniwersalny na Akt I i Akt II (tooltip jest neutralnym
  elementem UI, nie sceną biomu — nie potrzebuje osobnej korupcji jak popupy).

## Referencje stylu

- Globalny styl UI: dark wood + muted green + parchment (jak
  `assets/art/ui/panels/confirm_popup_panel_act1.png`), ale
  **znacznie subtelniejszy** — tooltip pojawia się na chwilę pod kursorem
  i nie może konkurować wizualnie z ciężkimi, rzeźbionymi panelami popupów.
  Cienka linia, prawie płaska faktura, minimum ornamentu.
- `assets/art/ui/icons/icon_secure_region.png` — czytelność w małym rozmiarze.

## Prompt

```text
Pixel art UI TOOLTIP PANEL (9-slice background) for a survival card roguelike
with a dark wood + parchment + muted green aesthetic.
Subject: a small, subtle floating tooltip background — aged parchment/vellum
fill with a very thin single-line dark wood or tarnished gold border, faint
worn paper texture, tiny soft corner wear. No ornate carving, no rope, no
nails, no wax seal, no thick frame — this must read as light and quick, not
a decorated popup panel.
Style: crisp visible pixels, hard edges, muted warm parchment tone (soft tan/
cream, slightly aged), thin restrained gold-brown hairline border, very low
visual weight, flat and calm.
Composition: the ENTIRE canvas is a flat, evenly-lit rectangular panel meant
for 9-slice stretching — flat center fill, simple uniform border, no unique
detail in the middle or edges that would break when the panel is resized,
no vignette gradient across the panel, no text, no icons, no characters,
no drop shadow baked in.
Avoid: heavy ornamentation, thick carved wood frame, rope/nail/wax-seal
details, toxic green corruption, horror mood, photorealism, 3D render, blur,
gradients that would look broken when stretched, letters, numbers, glyphs.
Output: 256x160 PNG, transparent background preferred; if transparency is not
available use pure chroma-key green #00FF00 background.
```

## Uwagi implementacyjne

- Gra nie ma jeszcze żadnego `Theme` resource — obecne UI stoi na domyślnym
  motywie edytora. Podpięcie panelu wymaga jednej globalnej zmiany, nie
  osobnej edycji każdego miejsca z `tooltip_text`:
  1. Nowy `Theme` (np. `assets/art/ui/theme_default.tres`) ze `StyleBoxTexture`
     w typie `TooltipPanel` (tekstura = ten plik, marginesy 28px z każdej
     strony) + `TooltipLabel` (kolor fontu dopasowany do parchmentu, np. ciemny
     brąz zamiast białego).
  2. Project Settings → GUI → Theme → Custom Theme = ten zasób.
  Od tej pory KAŻDY istniejący `tooltip_text` w grze (kafle, budynki, karty,
  ikony) dostaje nowy wygląd automatycznie, zero zmian w `.gd`/`.tscn`.
- Po wrzuceniu pliku: `Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.
- Pominięte świadomie: osobny wariant Akt II. Jeden neutralny parchment panel
  powinien czytać się dobrze na obu tłach (jasnym i ciemnym); jeśli po
  wdrożeniu na ciemnym Akcie II będzie zlewał się z tłem, dorobić wtedy
  ciemniejszy wariant `panel_tooltip_9slice_act2.png` tym samym promptem +
  chłodniejszą paletą (jak przy pozostałych panelach popupów).
