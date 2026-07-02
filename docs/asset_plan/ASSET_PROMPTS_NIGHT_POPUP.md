# Prompty nocnego panelu popup — 3 layouty do wyboru

Cel: nowy popup nocnego zdarzenia w TEJ SAMEJ rodzinie co
`building_popup_panel` / `confirm_popup_panel` (1024×768, drewno + lina +
nity + pergamin), ale w **nocnym nastroju** (chłodne światło księżyca,
ciemniejszy pergamin, srebrno-złote akcenty).

Hierarchia (wg decyzji): **karta nocna = bohater panelu** (duża pionowa
wnęka ~2:3 — kartę i tak renderuje silnik, wnęka ma być PUSTA), obok niej
pas na efekty, a **kartka z podsumowaniem mniejsza / na drugim planie**.
Dolny pas musi pomieścić od 1 („Dalej") do 3 przycisków (zdarzenia z wyborami).

Wspólne: generuj przez **[$imagegen]**, 1024×768 PNG, przezroczyste poza
panelem (brak alfy → chroma-key green `#00FF00` tylko na zewnątrz ramy).
Po wyborze layoutu generujemy finalne `night_popup_panel_act1/act2.png`
(ten sam układ, akt II w wersji skażonej). Po wrzuceniu:
`Godot_v4.5.1-stable_win64_console.exe --headless --path . --import`.

---

## Layout A — „Ołtarz karty" (karta na środku) → `night_popup_panel_layout_a.png`

Karta wyśrodkowana jak relikwia w snopie księżycowego światła, efekty pod
nią, podsumowanie jako mała ukośna karteczka z boku.

```text
Output file name: night_popup_panel_layout_a.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match building_popup_panel_act1.png exactly for frame construction, wood, rope and proportions
- match the ornate fantasy framing language from card_frame_event.png and card_frame_monster.png
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is the NIGHT version of the panel family: same seasoned dark wood frame,
rope-bound corners and brass pins, but the parchment is darker and cooler
(deep desaturated blue-grey night parchment), lit by soft silvery moonlight,
with restrained gold trim. Calm, mysterious, still readable.

Important layout zones:
- top title strip area, empty, no text
- CENTER: one large empty recessed vertical card well, portrait 2:3 ratio,
  about one third of the panel width, the clear hero of the layout, with a
  faint soft moonlight halo around it — leave the well completely BLANK
  and dark inside, no card drawn
- directly below the card well: a wide horizontal effects strip, empty,
  with a couple of very faint ruled lines
- lower-left corner: a clearly SMALLER slightly tilted pinned paper note
  (second plane, for the night summary), visibly less important than the card
- bottom strip: one wide horizontal button plate area that can hold one to
  three buttons side by side, empty

Important restrictions:
- no readable text, no letters, no numbers
- no card artwork inside the card well, no characters, no monsters
- a small decorative moon or stars in the frame ornament are allowed,
  but no icons with semantic meaning
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_event.png
assets/art/cards/frames/card_frame_monster.png
assets/art/ui/overlay_night_spotlight.png
```

## Layout B — „Karta po lewej, zwój po prawej" → `night_popup_panel_layout_b.png`

Klasyczny dwukolumnowy: wielka karta w lewej kolumnie, prawa kolumna =
efekty u góry + mniejsza przypięta kartka podsumowania pod spodem.

```text
Output file name: night_popup_panel_layout_b.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match building_popup_panel_act1.png exactly for frame construction, wood, rope and proportions
- match the ornate fantasy framing language from card_frame_event.png and card_frame_monster.png
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is the NIGHT version of the panel family: same seasoned dark wood frame,
rope-bound corners and brass pins, but the parchment is darker and cooler
(deep desaturated blue-grey night parchment), lit by soft silvery moonlight,
with restrained gold trim. Calm, mysterious, still readable.

Important layout zones:
- top title strip area, empty, no text
- LEFT HALF: one large empty recessed vertical card well, portrait 2:3 ratio,
  taking most of the left column height, the dominant element, with a faint
  moonlight glow around its edges — leave the well completely BLANK and dark
  inside, no card drawn
- RIGHT COLUMN, upper part: a tall effects/description area, empty, with a few
  very faint ruled lines
- RIGHT COLUMN, lower part: a clearly SMALLER pinned paper note (second plane,
  for the night summary), slightly overlapping the effects area from below,
  visibly less important than the card
- bottom strip across the full width: one wide horizontal button plate area
  that can hold one to three buttons side by side, empty

Important restrictions:
- no readable text, no letters, no numbers
- no card artwork inside the card well, no characters, no monsters
- a small decorative moon or stars in the frame ornament are allowed,
  but no icons with semantic meaning
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_event.png
assets/art/cards/frames/card_frame_monster.png
assets/art/ui/overlay_night_spotlight.png
```

## Layout C — „Scena księżycowa" (karta z lewej-środka + nachodząca kartka) → `night_popup_panel_layout_c.png`

Najbardziej „filmowy": karta lekko z lewej w snopie światła, podsumowanie
jako mniejsza, przekrzywiona kartka częściowo SCHOWANA za kartą (wyraźny
drugi plan), efekty na wąskiej banderoli pod kartą.

```text
Output file name: night_popup_panel_layout_c.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match building_popup_panel_act1.png exactly for frame construction, wood, rope and proportions
- match the ornate fantasy framing language from card_frame_event.png and card_frame_monster.png
- this popup MUST belong to the same panel family as building_popup_panel_act1.png
- keep the same game style, not a new style

This is the NIGHT version of the panel family: same seasoned dark wood frame,
rope-bound corners and brass pins, but the parchment is darker and cooler
(deep desaturated blue-grey night parchment), lit by soft silvery moonlight,
with restrained gold trim. Calm, mysterious, still readable.

Important layout zones:
- top title strip area, empty, no text
- LEFT-OF-CENTER: one large empty recessed vertical card well, portrait 2:3
  ratio, the clear hero, with a soft vertical moonbeam falling on it from the
  top of the panel — leave the well completely BLANK and dark inside, no card
  drawn
- RIGHT of the card: a clearly SMALLER slightly tilted parchment sheet pinned
  with a brass pin, its left edge partially tucked BEHIND the card well
  (obvious second plane, for the night summary); a few very faint ruled lines
- a narrow horizontal banner strip directly under the card well, empty
  (for the effects line)
- bottom strip across the full width: one wide horizontal button plate area
  that can hold one to three buttons side by side, empty

Important restrictions:
- no readable text, no letters, no numbers
- no card artwork inside the card well, no characters, no monsters
- a small decorative moon or stars in the frame ornament are allowed,
  but no icons with semantic meaning
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
assets/art/cards/frames/card_frame_event.png
assets/art/cards/frames/card_frame_monster.png
assets/art/ui/overlay_night_spotlight.png
```

---

# Rewizja po wyborze layoutu B — problem „ramki w ramce"

Layout B wygrał (`tmp/imagegen/night_popup/night_popup_panel_layout_b_raw.png`),
ale ozdobna złota rama wnęki + własna ramka karty nocnej dublują się.
Dwie wersje rozwiązania — obie używają wygenerowanego layoutu B jako GŁÓWNEJ
referencji (ten sam mrok, drewno, księżycowy medalion, papiery po prawej,
dolny pas):

- **B-v1**: panel ODDAJE ramkę — miejsce na kartę jest płaskie i bez ornamentu,
  jedyną ramką jest ramka samej karty nocnej (silnik kładzie CAŁĄ kartę jak
  dotychczas). Papiery przechodzą na lewo, karta na prawo: górna kartka =
  efekt karty, dolna karteczka = podsumowanie nocy (+/−), na dole „Dalej".
- **B-v2**: karta ODDAJE ramkę — ozdobna rama panelu staje się ramą karty,
  do środka wchodzi TYLKO ilustracja zdarzenia (placeholder chroma blue jak
  w `secure_popup_panel`), pod nią przypięta karteczka (opis LUB efekty),
  duża kartka po prawej na opis/efekty (to, czego nie ma karteczka).

## B-v1 — płaskie miejsce na całą kartę → `night_popup_panel_layout_b_v1.png`

```text
Output file name: night_popup_panel_layout_b_v1.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match night_popup_panel_layout_b_raw.png as the MAIN reference: same night
  mood, same dark wood frame with rope and brass pins, same moon medallion at
  the top, same dark blue-grey night parchment, same bottom button strip
- match building_popup_panel_act1.png for frame construction and proportions
- keep the same game style, not a new style

This is a REVISION of that layout. The previous version had an ornate golden
card frame on the left — REMOVE it completely. The game engine will place a
fully framed playing card on this panel, so the panel itself must NOT draw
any frame around the card area, otherwise there would be a frame inside a
frame. Also MIRROR the layout: papers go LEFT, card area goes RIGHT.

Important layout zones:
- top title strip area with the moon medallion, empty, no text
- LEFT COLUMN, upper part: a large pinned parchment sheet with a few very
  faint ruled lines (for the card effect text), empty
- LEFT COLUMN, lower part: a clearly SMALLER pinned paper note slightly
  overlapping from below (for the night summary), empty
- RIGHT SIDE: a plain FLAT open area in portrait 2:3 ratio, about one third
  of the panel width — just slightly darker recessed parchment with a very
  soft moonlight glow, absolutely NO ornamental frame, NO border, NO golden
  trim around it; it must read as empty table surface where a card will be
  laid down
- bottom strip across the full width: one wide horizontal button plate area
  that can hold one to three buttons side by side, empty

Important restrictions:
- no readable text, no letters, no numbers
- no card drawn in the card area, no characters, no monsters
- absolutely no decorative frame around the right card area
- no modern UI, no sci-fi, no neon
- transparent outside the panel if possible (chroma green outside only)
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: tmp/imagegen/night_popup/night_popup_panel_layout_b_raw.png
assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
```

## B-v2 — rama panelu jako rama karty (sama ilustracja) → `night_popup_panel_layout_b_v2.png`

```text
Output file name: night_popup_panel_layout_b_v2.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference images very closely for style consistency:
- match night_popup_panel_layout_b_raw.png as the MAIN reference: same night
  mood, same dark wood frame with rope and brass pins, same moon medallion at
  the top, same ornate golden inner frame style, same papers on the right,
  same bottom button strip
- match building_popup_panel_act1.png for frame construction and proportions
- keep the same game style, not a new style

This is a REVISION of that layout. The ornate golden frame on the left STAYS,
but it now frames ONLY an illustration (not a whole card), and it gets a small
pinned note underneath.

Important layout zones:
- top title strip area with the moon medallion, empty, no text
- LEFT COLUMN, upper part: the ornate golden/silver moonlit frame from the
  reference, but in LANDSCAPE orientation (about 3:2 ratio, image wider than
  tall), holding a flat bright chroma blue placeholder (RGB approximately
  0, 80, 255) so the event illustration can be masked in later — no
  illustration drawn inside
- LEFT COLUMN, directly under the framed image: a small pinned paper note
  (for the card description or effects), empty, with a couple of very faint
  ruled lines
- RIGHT COLUMN, upper part: a large pinned parchment sheet with faint ruled
  lines (for description/effects), empty
- RIGHT COLUMN, lower part: a clearly SMALLER pinned paper note slightly
  overlapping from below (for the night summary), empty
- bottom strip across the full width: one wide horizontal button plate area
  that can hold one to three buttons side by side, empty

Important restrictions:
- no readable text, no letters, no numbers
- no illustration inside the blue placeholder, no characters, no monsters
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible (chroma green outside only)
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: tmp/imagegen/night_popup/night_popup_panel_layout_b_raw.png
assets/art/ui/panels/building_popup_panel_act1.png
assets/art/ui/panels/log_panel_act1.png
```

---

# Finał v4: obrazek poziomy, „Dalej"/wybory PRZYKLEJONE do dołu dużej kartki

Poprawka po feedbacku do v3: kartka(i) „Dalej"/wyboru NIE są osobnymi
notatkami leżącymi POD kolumnami — wracają na dużą kartkę opisu (prawa
kolumna), ale przyklejone u jej DOŁU (nie u góry jak w v2). Rozmiar:

- **F1/F3 — jedna kartka „Dalej"**: przyklejona na dole dużej kartki opisu,
  zajmuje ok. **DOLNĄ 1/3 wysokości** tej kartki. Górne 2/3 kartki zostają
  czyste na tekst opisu fabularnego.
- **F2 — trzy kartki wyboru**: przyklejone na dole dużej kartki opisu,
  razem zajmują ok. **DOLNE 2/3 wysokości** tej kartki (mogą być ułożone
  w stos trzech poziomych pasków, lekko nierówno/asymetrycznie). Górna
  1/3 kartki zostaje czysta na tekst dylematu.

Reszta bez zmian względem v3: obrazek POZIOMY ~3:2 w oryginalnym rozmiarze
z `night_popup_panel_layout_b_v2_raw.png`, kartka pod obrazkiem (efekty/co
dzieje się w nocy) bez zmian, nocny klimat (gwiazdy/poświaty/promienie
księżyca) zostaje. Nie ma żadnego drewnianego pasa na dole panelu.

**Rozmieszczenie treści (mapping do Godot):**

| Strefa | Zwykłe zdarzenie (F1) | Z wyborem (F2) | Potwór (F3) |
|---|---|---|---|
| Tytuł (góra, wyśrodkowany) | nazwa karty | nazwa karty | nazwa potwora |
| Obrazek poziomy ~3:2 (lewo-góra) | ilustracja zdarzenia | ilustracja | ilustracja potwora |
| Kartka pod obrazkiem (lewo, do dołu) | co dzieje się w nocy / efekty | efekty/flavor | atak (obrażenia gracz/budynek) |
| Duża kartka (prawo), górna część | opis fabularny | opis/dylemat | opis potwora |
| Duża kartka (prawo), dolna 1/3 | kartka „Dalej" przyklejona | — | kartka „Dalej" przyklejona |
| Duża kartka (prawo), dolne 2/3 | — | **3 kartki wyboru przyklejone** | — |

## F1. Zwykłe zdarzenie nocne → `night_popup_panel_event.png`

```text
Output file name: night_popup_panel_event.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT popup of a dark fantasy survival card game.

Use the provided reference image very closely — keep almost everything from it:
- match night_popup_panel_layout_b_v2_raw.png closely: same dark wood frame,
  rope, brass pins, same LANDSCAPE golden/silver moonlit picture frame in the
  upper-left, at the SAME size and proportions (about 3:2, image wider than
  tall) holding the blue placeholder, same pinned note directly under the
  picture frame, same large pinned parchment sheet on the upper-right for
  description, spanning almost the full height of the panel
- match building_popup_panel_act1.png for frame construction quality
- keep the same game style, not a new style

Make only these changes to the reference:
1. ADD a clear, empty, centered rectangular title plate at the very top of
   the panel (a small nameplate, not spanning the full width). The small moon
   medallion stays on the wooden beam above it but must not overlap it, and
   the golden picture frame below has no crest colliding with it.
2. REMOVE the solid wooden button strip that ran along the very bottom of the
   panel in the reference — there is no separate strip at the bottom of the
   panel at all.
3. On the large right-hand parchment sheet, pin ONE smaller parchment note
   (torn edges, brass pin) directly ONTO the sheet near ITS OWN bottom edge,
   covering roughly the bottom ONE THIRD of the sheet's height, spanning
   most of its width. This note sits on top of the big sheet like a
   separate piece of paper pinned over it. The top two thirds of the big
   sheet, above this note, must stay completely clear and flat for
   description text.

Important layout zones:
- top: empty rectangular title plate, centered, no text; small moon medallion
  on the wooden beam above it
- upper-left: ornate golden landscape picture frame (about 3:2 ratio, same
  size/position as the reference) holding a flat bright chroma blue
  placeholder (RGB approximately 0, 80, 255) — no illustration inside, no
  crest on top of this frame
- directly under the picture frame, filling the rest of the left column down
  to near the bottom edge of the panel: a pinned parchment note with a few
  very faint ruled lines (for "what happens tonight" text), empty
- upper-right: one large pinned parchment sheet spanning almost the full
  height of the panel (for the card's flavor description), empty, with faint
  ruled lines in its upper two thirds
- pinned onto the BOTTOM THIRD of that large sheet: one smaller parchment
  note (torn edges, brass pin), empty, clearly a separate layered note lying
  over the bottom of the big sheet — this will hold a "Next" button
- there is NO wooden strip and NO separate button plate anywhere at the very
  bottom of the panel outside of this pinned note

Night atmosphere: add subtle scattered stars in the dark washes of the wood
and background, soft silvery glows and highlights along metal edges, one or
two faint moonbeam rays crossing the panel diagonally — more than the
reference, still subtle and tasteful.

Important restrictions:
- no readable text, no letters, no numbers
- no illustration inside the blue placeholder, no characters, no monsters
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible (chroma green outside only)
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: tmp/imagegen/night_popup/night_popup_panel_layout_b_v2_raw.png
assets/art/ui/panels/building_popup_panel_act1.png
```

## F2. Zdarzenie z wyborem → `night_popup_panel_event_choice.png`

```text
Output file name: night_popup_panel_event_choice.png

Create a 1024x768 PNG UI background panel for the NIGHT EVENT CHOICE popup of a dark fantasy survival card game.

Use the provided reference image very closely — keep almost everything from it:
- match night_popup_panel_layout_b_v2_raw.png closely: same dark wood frame,
  rope, brass pins, same LANDSCAPE golden picture frame in the upper-left at
  the SAME size and proportions (about 3:2) holding the blue placeholder,
  same pinned note directly under the picture frame, same large pinned
  parchment sheet on the upper-right for description, spanning almost the
  full height of the panel
- match building_popup_panel_act1.png for frame construction quality
- keep the same game style, not a new style

This is the CHOICE variant. It shares the same top/left zones and the same
large right-hand sheet as the plain event panel of this family, but the
bottom of that sheet holds THREE pinned choice notes instead of one.

Make only these changes to the reference:
1. ADD a clear, empty, centered rectangular title plate at the very top,
   same as the plain event panel of this family. Moon medallion above it,
   not overlapping; no crest on the picture frame.
2. REMOVE the solid wooden button strip from the bottom of the panel — there
   is no separate strip at the bottom of the panel at all.
3. On the large right-hand parchment sheet, pin THREE smaller parchment
   notes directly ONTO the sheet, together covering roughly the bottom TWO
   THIRDS of the sheet's height. Stack them like three horizontal paper
   slats layered one below another (or slightly overlapping), each with its
   own tilt and pin, filling that lower two-thirds region generously so each
   one is big enough for a full sentence of text. The top ONE THIRD of the
   big sheet, above these three notes, must stay completely clear and flat,
   reserved purely for the dilemma description text.

Important layout zones:
- top: empty rectangular title plate, centered, no text; small moon medallion
  above it
- upper-left: ornate golden landscape picture frame (about 3:2 ratio) holding
  a flat bright chroma blue placeholder (RGB approximately 0, 80, 255) — no
  illustration inside
- directly under the picture frame, down to near the bottom edge of the
  panel: a pinned parchment note with faint ruled lines (for flavor/effects
  text), empty
- upper-right: one large pinned parchment sheet spanning almost the full
  height of the panel, its TOP THIRD clear with faint ruled lines (for the
  dilemma description)
- pinned onto the BOTTOM TWO THIRDS of that same large sheet: THREE stacked
  parchment notes, each generously sized for a full sentence of text,
  slightly irregular tilt/overlap, empty

Night atmosphere: add subtle scattered stars in the dark washes of the wood
and background, soft silvery glows and highlights along metal edges, one or
two faint moonbeam rays crossing the panel diagonally — more than the
reference, still subtle and tasteful.

Important restrictions:
- no readable text, no letters, no numbers
- no illustration inside the blue placeholder, no characters, no monsters
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible (chroma green outside only)
- do not make the parchment so dark that text would be unreadable on it
- the title plate, picture frame, under-picture note and the outer edges of
  the big right-hand sheet must be in the same positions as the plain event
  version of this panel
- 1024x768 resolution

ref: tmp/imagegen/night_popup/night_popup_panel_layout_b_v2_raw.png
assets/art/ui/panels/building_popup_panel_act1.png
```

## F3. Potwór → `night_popup_panel_monster.png`

Układ IDENTYCZNY jak F1 (obrazek poziomy w oryginalnym rozmiarze, kartka pod
obrazkiem, duża kartka opisu po prawej z przyklejoną do DOŁU kartką „Dalej"
na dolnej 1/3, bez drewnianego pasa). Zachowany zostaje motyw grozy z
poprzedniej wersji promptu potwora (krwawy księżyc, poczerniałe żelazo,
zadrapania pazurów, karmazynowe akcenty).

```text
Output file name: night_popup_panel_monster.png

Create a 1024x768 PNG UI background panel for the NIGHT MONSTER ATTACK popup of a dark fantasy survival card game.

Use the provided reference image very closely for LAYOUT AND MATERIALS —
this is a sinister variant of it:
- match night_popup_panel_layout_b_v2_raw.png closely: same dark wood frame,
  rope, brass pins, same LANDSCAPE picture frame in the upper-left at the
  SAME size/proportions (about 3:2) holding the blue placeholder, same pinned
  note under the picture frame, same large pinned sheet on the upper-right
  spanning almost the full height of the panel
- match building_popup_panel_act1.png for frame construction quality
- keep the same game style, not a new style

Make the same structural changes as the plain event panel of this family:
1. ADD a clear, empty, centered rectangular title plate at the very top
   (reserved for the monster name), with no medallion or crest colliding
   with it.
2. REMOVE the solid wooden button strip from the bottom of the panel — there
   is no separate strip at the bottom of the panel at all.
3. On the large right-hand parchment sheet, pin ONE smaller torn parchment
   note directly ONTO the sheet near ITS OWN bottom edge, covering roughly
   the bottom ONE THIRD of the sheet's height. The top two thirds of the big
   sheet, above this note, must stay completely clear for description text.

Important layout zones (identical structure to the plain event panel):
- top: empty rectangular title plate, centered, no text
- upper-left: landscape picture frame (about 3:2) holding a flat bright
  chroma blue placeholder (RGB approximately 0, 80, 255) — no illustration inside
- directly under the picture frame, down to near the bottom edge of the
  panel: a pinned, slightly torn parchment note with faint ruled lines (for
  attack numbers), empty
- upper-right: one large pinned parchment sheet spanning almost the full
  height of the panel (for the monster description), its top two thirds
  clear with faint ruled lines
- pinned onto the BOTTOM THIRD of that large sheet: one smaller torn
  parchment note, empty, clearly layered over the bottom of the big sheet

MOOD SHIFT — this is the MONSTER version of the same panel family: keep the
same layout and materials, but make it read as danger:
- the moon medallion on the top beam becomes a BLOOD MOON (dim red)
- the picture frame becomes darker blackened iron with claw-scratched gold
  remnants and small fang/claw motifs in the corners
- the wood of the outer frame shows a few deep claw scratch marks
- parchment sheets are more torn and stained, with a faint dark red tint
- overall palette: the same night blue-grey, but with deep crimson accents
  instead of warm gold — menacing, still readable
- keep a few scattered stars and faint moonbeam rays for the night mood, but
  duller and colder than the plain event version, more ominous

Important restrictions:
- no readable text, no letters, no numbers
- no illustration inside the blue placeholder, NO monster drawn anywhere,
  no characters — the menace comes only from materials, scratches and color
- no modern UI, no sci-fi, no neon except the flat blue placeholder
- transparent outside the panel if possible (chroma green outside only)
- do not make the parchment so dark that text would be unreadable on it
- 1024x768 resolution

ref: tmp/imagegen/night_popup/night_popup_panel_layout_b_v2_raw.png
assets/art/ui/panels/building_popup_panel_act1.png
assets/art/cards/frames/card_frame_monster.png
```

---

## Uwagi

- Wnęka na kartę jest zawsze PUSTA i ciemna — kartę (rewers → flip → front,
  `NightCardView`, obecnie slot 190×280) i przyciski renderuje silnik na
  wierzchu; panel daje tylko kompozycję i światło.
- Podsumowanie/„kartka informacyjna" celowo mniejsza i na drugim planie we
  wszystkich trzech layoutach — różni się tylko miejscem (A: lewy dół,
  B: prawa kolumna dół, C: nachodząca zza karty).
- Dolny pas przycisków wspólny dla obu wariantów popupu: 1 przycisk „Dalej"
  (karta bez wyboru) albo 2–3 przyciski decyzji (karta z wyborem) — dlatego
  wszędzie jest to jeden szeroki pas, nie osobne płytki.
- W repo leży już `night_event_popup_panel_variant_03.png` (root, niewpięty) —
  to wcześniejsza próba; po wyborze layoutu warto go sprzątnąć albo podmienić.
- Po wyborze zwycięzcy: regeneracja jako `night_popup_panel_act1.png` +
  `night_popup_panel_act2.png` (ten sam układ, mrok/korupcja jak w parach
  act1/act2 pozostałych paneli) i wpięcie w `run.tscn` `NightEventOverlay`.

### Uwagi do rewizji B-v1 / B-v2

- **B-v1 jest lustrzane** (papiery LEWO, karta PRAWO) — tak czytam „po lewej
  na kartce u góry efekt karty"; jeśli karta miała zostać po lewej jak w B,
  wystarczy w promptcie usunąć zdanie o mirrorze.
- **B-v1 = zero zmian w kodzie karty**: silnik kładzie całą `NightCardView`
  (flip, ramka event/monster) na płaskim polu; przenosi się tylko pozycja
  slotu i etykiety tekstów.
- **B-v2 = panel przejmuje rolę karty**: w placeholder chroma blue wchodzi
  sama ilustracja (`illustrations/events/<id>.png`, 1024×688 — dlatego
  placeholder jest POZIOMY ~3:2, nie pionowy), a nazwa/opis/efekty są
  tekstem na papierach. Wymaga przeróbki `run.gd`: zamiast `NightCardView`
  ładowanie ilustracji + rozpisanie tekstów; animację rewers→flip trzeba
  przerobić (np. flip samej ilustracji w ramie) albo odpuścić; rozróżnienie
  potwór/zdarzenie robić tintem/FX zamiast ramką karty.
- Karteczka pod obrazkiem w B-v2 jest neutralna („opis LUB efekty") — decyzja,
  co gdzie trafia, zapada przy wpinaniu, panel tego nie wymusza.

### Uwagi do finału v4 (kartki przyklejone do dołu dużej kartki)

- **Obrazek zostaje poziomy ~3:2**, więc pasuje wprost do istniejących
  ilustracji zdarzeń (`assets/art/cards/illustrations/events/*.png`,
  1024×688) bez przycinania proporcji.
- `EventChoiceData` w `data/cards/events/` potwierdza: zawsze 2 lub 3 opcje,
  nigdy więcej — 3 kartki w dolnych 2/3 F2 wystarczą, silnik chowa trzecią,
  gdy opcji jest 2.
- **Proporcje 1/3 (F1/F3) vs 2/3 (F2)** liczone są względem wysokości dużej
  kartki opisu (prawa kolumna), nie całego panelu — duża kartka zostaje
  jedna i ta sama we wszystkich trzech, zmienia się tylko to, co jest do
  niej przyklejone u dołu.
- Kartka(i) leżą NA dużej kartce (warstwa nad nią, przypięta pinezką), nie
  są osobnym elementem obok — stąd „przyklejona", nie „dołożona".
- Nadal NIE MA drewnianego pasa na dole panelu — to został odrzucony
  wcześniej i pozostaje odrzucony; teraz to po prostu dolna część dużej
  kartki opisu.
- Po wyborze finalnych 3 grafik: wpięcie w `run.gd`/`NightCardView` wymaga
  przeprojektowania układu tekstów (tytuł na środku góry, opis w górnej
  części prawej kartki, przycisk/wybory w jej dolnej części, efekty pod
  obrazkiem) — patrz tabela mapowania wyżej.
