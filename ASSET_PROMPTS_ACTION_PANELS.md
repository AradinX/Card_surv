# Prompty paneli popupów — jedna rodzina (format jak building_popup_panel)

Cel: wszystkie popupy mają czytać się jako JEDEN zestaw, jak
`building_popup_panel_act1/act2.png`. Prompty napisane w Twoim oryginalnym
formacie i z tym samym zestawem referencji (`log_panel`, `card_frame_building`,
`card_frame_event`, `building_popup_panel`).

**Ujednolicenie (to naprawia „rozjeżdżanie się"):**
- **Wszystko 1024×768** (jak `building_popup_panel`). `secure_popup_panel` jest
  dziś 1448×1086 i za żółty — regenerujemy go w 1024×768, zachowując tylko układ.
- **Stonowany papier** (ciepły tan/cream), NIE przesycona żółć — to główny dryf
  obecnego panelu secure.
- Ta sama rama, lina, nity, pieczęć i proporcje we wszystkich.

Panele do zrobienia:
1. **confirm** — wspólny dla Napraw / Przejdź / (Rozbiórki), BEZ obrazka.
2. **deck** — talia (rama pod przewijalną siatkę kart).
3. **secure** — poprawa całkowita (zachowujemy tylko układ obecnego panelu).

Wspólne: generuj przez **[$imagegen]**, 1024×768 PNG, przezroczyste poza panelem
(brak alfy → chroma-key green `#00FF00` tylko na zewnątrz ramy). Po wrzuceniu:
`Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

---

## 1a. Panel potwierdzenia — Akt I → `confirm_popup_panel_act1.png`

```text
Output file name: confirm_popup_panel_act1.png

Create a 1024x768 PNG UI background panel for Act 1 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act1.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match building_popup_panel_act1.png exactly for frame, paper tone and proportions
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is a small, tidy CONFIRMATION panel (yes/no) reused for several actions, so it
has NO image placeholder and stays simple and uncluttered.

Visual style:
seasoned dark wood frame, rope-bound corners, brass pins, restrained gold trim,
aged warm parchment in a MUTED tan/cream tone (NOT over-saturated yellow), calm and
readable.

Important layout zones:
- top title strip area, empty, no text
- one central message/description area, empty, with a couple of very faint ruled lines
- bottom area with TWO equal rectangular button plates side by side (left and right,
  for Confirm / Cancel), empty
- generous empty margins, no image box

Important restrictions:
- no readable text, no letters, no numbers
- no icons with semantic meaning, no characters
- no building drawing, no image placeholder
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
assets/art/biomes/backgrounds/normal
```

## 1b. Panel potwierdzenia — Akt II → `confirm_popup_panel_act2.png`

```text
Output file name: confirm_popup_panel_act2.png

Create a 1024x768 PNG UI background panel for Act 2 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act2.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match the corrupted post-cataclysm mood of building_popup_panel_act2.png
- keep the exact same layout and proportions as confirm_popup_panel_act1.png so the
  same Godot text positions can be reused
- keep the same game style, not a new style

This is the Act 2 corrupted version of the small CONFIRMATION panel. NO image placeholder.

Visual style:
rotten dark wood, torn parchment, cracked edges, soot marks, plague/corruption stains,
cold blue-green shadows, damaged brass pins, frayed rope, darker than Act 1 but still
readable.

Important layout zones:
- top title strip area, empty, no text
- one central message/description area, empty, with a couple of very faint ruled lines
- bottom area with TWO equal rectangular button plates side by side (Confirm / Cancel), empty
- generous empty margins, no image box

Important restrictions:
- no readable text, no letters, no numbers
- no icons with semantic meaning, no characters
- no building drawing, no image placeholder
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act2.png
assets/art/ui/panels/log_panel_act2.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
```

---

## 2a. Panel talii — Akt I → `deck_popup_panel_act1.png`

```text
Output file name: deck_popup_panel_act1.png

Create a 1024x768 PNG UI background panel for Act 1 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act1.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match building_popup_panel_act1.png exactly for frame, paper tone and proportions
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is the DECK panel: a frame around a large empty well that will hold a scrollable
grid of cards rendered by the engine.

Visual style:
seasoned dark wood frame, rope-bound corners, brass pins, restrained gold trim,
aged warm parchment in a MUTED tan/cream tone (NOT over-saturated yellow), readable.

Important layout zones:
- top title strip area, empty, no text
- one large recessed inner field spanning most of the panel, empty, meant to hold a
  scrollable grid of cards — leave it completely blank, no cards drawn
- a narrow vertical scrollbar groove along the right inner edge of that field
- a thin bottom strip with one small button plate (for Close), empty

Important restrictions:
- no readable text, no letters, no numbers
- no actual cards, no card illustrations, no building drawing, no characters
- no icons with semantic meaning
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
assets/art/biomes/backgrounds/normal
```

## 2b. Panel talii — Akt II → `deck_popup_panel_act2.png`

```text
Output file name: deck_popup_panel_act2.png

Create a 1024x768 PNG UI background panel for Act 2 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act2.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match the corrupted post-cataclysm mood of building_popup_panel_act2.png
- keep the exact same layout and proportions as deck_popup_panel_act1.png so the same
  Godot positions can be reused
- keep the same game style, not a new style

This is the Act 2 corrupted version of the DECK panel.

Visual style:
rotten dark wood, torn parchment, cracked edges, soot marks, plague/corruption stains,
cold blue-green shadows, damaged brass pins, frayed rope, darker than Act 1 but still
readable.

Important layout zones:
- top title strip area, empty, no text
- one large recessed inner field spanning most of the panel, empty, for a scrollable
  grid of cards — leave it completely blank, no cards drawn
- a narrow vertical scrollbar groove along the right inner edge of that field
- a thin bottom strip with one small button plate (Close), empty

Important restrictions:
- no readable text, no letters, no numbers
- no actual cards, no card illustrations, no building drawing, no characters
- no icons with semantic meaning
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act2.png
assets/art/ui/panels/log_panel_act2.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
```

---

## 3a. Panel zabezpieczenia (poprawa) — Akt I → `secure_popup_panel_act1.png`

Zachowujemy TYLKO układ obecnego panelu (tytuł u góry, obrazek podglądu po lewej,
pole informacji po prawej, szeroki pasek pod spodem, jeden przycisk na dole),
ale w stonowanej palecie i rozmiarze rodziny.

```text
Output file name: secure_popup_panel_act1.png

Create a 1024x768 PNG UI background panel for Act 1 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act1.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match building_popup_panel_act1.png exactly for frame, paper tone and proportions
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is the SECURE-REGION panel. Keep the same layout as the existing secure popup,
but fix the tone: it is currently too saturated/yellow — use a MUTED warm tan/cream
parchment like building_popup_panel_act1.png.

Visual style:
seasoned dark wood frame, rope-bound corners, brass pins, restrained gold trim,
aged warm parchment in a MUTED tan/cream tone (NOT over-saturated yellow), readable.

Important layout zones:
- top title strip area, empty, no text
- upper-left rectangular image placeholder for a region/tile preview
- upper-right information area (for cost and effect), empty
- a wide horizontal information strip across the lower-middle, empty
- bottom-center single large action button plate, empty

The upper-left image placeholder must be filled with a flat bright chroma blue color
so it can be masked later: RGB approximately 0, 80, 255. Do not put any illustration
inside this placeholder.

Important restrictions:
- no readable text, no letters, no numbers
- no icons with semantic meaning, no characters
- no building drawing inside the placeholder
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
assets/art/biomes/backgrounds/normal
```

## 3b. Panel zabezpieczenia (poprawa) — Akt II → `secure_popup_panel_act2.png`

```text
Output file name: secure_popup_panel_act2.png

Create a 1024x768 PNG UI background panel for Act 2 of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match the paper shape and texture from log_panel_act2.png
- match the ornate fantasy framing language from card_frame_building.png and card_frame_event.png
- match the corrupted post-cataclysm mood of building_popup_panel_act2.png
- keep the exact same layout and proportions as secure_popup_panel_act1.png so the same
  Godot positions can be reused
- keep the same game style, not a new style

This is the Act 2 corrupted version of the SECURE-REGION panel.

Visual style:
rotten dark wood, torn parchment, cracked edges, soot marks, plague/corruption stains,
cold blue-green shadows, damaged brass pins, frayed rope, darker than Act 1 but still
readable.

Important layout zones:
- top title strip area, empty, no text
- upper-left rectangular image placeholder for a region/tile preview
- upper-right information area (cost and effect), empty
- a wide horizontal information strip across the lower-middle, empty
- bottom-center single large action button plate, empty

The upper-left image placeholder must be filled with a flat bright chroma blue color
so it can be masked later: RGB approximately 0, 80, 255. Do not put any illustration
inside this placeholder.

Important restrictions:
- no readable text, no letters, no numbers
- no icons with semantic meaning, no characters
- no building drawing inside the placeholder
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible
- do not make the parchment too dark
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act2.png
assets/art/ui/panels/log_panel_act2.png
assets/art/cards/frames/card_frame_building.png
assets/art/cards/frames/card_frame_event.png
```

---

## Uwagi

- Kolejność: `confirm` (obsłuży Napraw + Przejdź + Rozbiórkę) → `deck` → poprawka `secure`.
- Klucz do jednego klimatu: **ten sam rozmiar 1024×768, ten sam zestaw referencji,
  stonowany papier** we wszystkich. Dołączaj do każdej generacji `building_popup_panel_actN.png`
  jako główny wzorzec — to on trzyma rodzinę razem.
- Regeneracja `secure` w 1024×768 zmienia rozmiar pliku; proporcja zostaje ~4:3,
  więc kotwice w Godot skalują się bez psucia układu.
- Wpięcie zrobię jak przy building_popup: stałe `PANEL_ACT1/ACT2` + `ResourceLoader.exists`
  fallback + podmiana na `bum_struck`, więc po wrzuceniu PNG wskoczą bez zmian w kodzie.
```
