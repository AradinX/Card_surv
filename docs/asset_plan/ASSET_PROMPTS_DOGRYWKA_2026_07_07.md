# Dogrywka do pakietu premierowego (2026-07-07)

Plik SAMODZIELNY do podania czatowi generującemu, gdy skończy obecną partię:
(1) poprawione prompty paska HUD (ramki do REGENERACJI — poprzednie wyszły
z czarnym tłem i bez wyznaczonej strefy artu), (2) nowy asset: mroczna ramka
kart Aktu II.

Zasady wspólne (obowiązują oba punkty):
- Pixel art spójny z grą: widoczne piksele, twarde krawędzie, kontrolowany
  dithering, bez smooth paintingu. Zero tekstu.
- Wszystko POZA artem: solid blue `#0000FF` — nigdy czarne, nigdy
  „przezroczyste" (generator i tak robi z tego czerń). Niebieski jest
  wycinany później (`tools/chroma_key_blue.gd`).

## 1. Pasek HUD — 2 pliki do REGENERACJI, 1920×96

```text
assets/art/ui/panels/top_status_bar_slim_act1.png
assets/art/ui/panels/top_status_bar_slim_act2.png
```

Strefy zmierzone z gry (1920 szer.): tekst lewy kończy się na x=274,
statystyki zaczynają na x=874. Art = mała winieta TYLKO w x 330–810,
maks. 60 px wysokości — akcent, nie dominanta.

Referencje stylu (dołącz jako obrazy): `assets/art/ui/panels/
log_panel_act1.png` (Akt I) i `log_panel_act2.png` (Akt II).

Prompt — ACT 1:

```text
Pixel art SLIM TOP HUD STRIP for the dark survival card roguelike Dzien 50,
1920x96, front view. One long thin horizontal panel filling the whole canvas.

Fill: very dark forest-green woven fabric, flat and even — game icons and
numbers are drawn on top at runtime, so keep it low-contrast and uniform.
Text zones that MUST stay plain flat fill: x=0 to x=320 and x=820 to x=1920.

Border: a VERY SUBTLE thin braided wicker/vine plait running along all four
edges, constant thickness about 8-10 px, muted aged-gold and living green
tones, small identical rounded corners. The braid must stay calm and even —
no flowers bursting out, no medallions, nothing sticking outside the border
band.

Decorative motif: ONE SMALL lively vignette ONLY inside the zone from x=330
to x=810, vertically centered, at most 60 px tall and clearly narrower than
its zone — it must feel like a modest accent, never overwhelming: fresh leafy
vine sprigs with a few spring leaves and tiny buds, maybe a small bird
silhouette, growing sideways out of the braid, muted greens and golds,
slightly brighter than the fill but still background-dark. The motif fades
out smoothly into the plain fill on both sides well before x=330 and x=810.

Background OUTSIDE the panel (the tiny cut corners past the rounded border):
SOLID PURE BLUE #0000FF, not black, not transparent.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers, no icons.
Avoid: bright highlights, busy pattern in the text zones, corner ornaments,
black background, photorealism, painterly blur, glow.
```

Prompt — ACT 2 (referencja: gotowy act1 + `log_panel_act2.png`; geometria
plecionki skopiowana 1:1):

```text
Same 1920x96 slim HUD strip layout as the attached Act I strip: same braid
thickness, same corners, same single small decorative vignette zone from
x=330 to x=810 (at most 60 px tall, modest accent), same plain dark fill
everywhere else, especially x=0-320 and x=820-1920.

Theme swap only — the world after the catastrophe: the braided border is now
DEAD — dry blackened twisted twigs and withered thorny vines, tarnished
bronze instead of gold, faint sickly gray-green tint. The vignette is the
dead mirror of Act I: bare cracked branches, a few dry curled leaves falling,
maybe a tiny crow silhouette. Fill: charcoal-dark fabric with a faint cold
tint, still flat and even under the text zones.

Background OUTSIDE the panel (cut corners past the rounded border):
SOLID PURE BLUE #0000FF, not black, not transparent.

Style: clearly visible pixels, hard edges, no smooth painting. Text: none.
Avoid: bright highlights, busy pattern in text zones, black background,
glow, photorealism.
```

## 2. NOWY asset: ramka kart Aktu II — 1 plik, 1024×1536

Jeden plik zmienia nastrój WSZYSTKICH kart w ręce po katastrofie (akcje,
budynki, zbieranie, nagrody). Kod już wpięty — plik jest plug-and-play.

```text
assets/art/cards/frames/card_frame_building_act2.png
```

Referencja OBOWIĄZKOWA (dołącz jako obraz): `assets/art/cards/frames/
card_frame_building.png` — wzorzec geometrii; okna tekstu/ilustracji muszą
się pokrywać co do kilku pikseli.

Prompt:

```text
Pixel art CARD FRAME for Act II of the dark survival card roguelike Dzien 50,
1024x1536. Use the attached Act I card frame as the EXACT geometry reference:
same canvas, same border thickness, same title band position and size, same
illustration window position and size, same description and cost areas —
every window must overlap the reference within a few pixels, because card
text and art are placed by those exact rectangles at runtime.

Theme swap only — the same frame AFTER THE CATASTROPHE: the living green
embroidery and aged gold turn into blackened corroded bronze, dry cracked
thorn tendrils instead of fresh vines, faint sickly gray-green tint, a few
subtle scratches on the border band. Keep all text/illustration windows as
clean and readable as the reference — decay lives ON THE BORDER, not in the
windows.

Background outside the frame edges: SOLID PURE BLUE #0000FF, not black,
not transparent.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers.
Avoid: moving or resizing any window, heavy damage over text areas, black
background, photorealism, painterly blur.
```

Weryfikacja: nałożyć na ramkę Aktu I — okna pokrywają się co do kilku
pikseli. Po wrzuceniu pliku gra sama używa go po BUM (fallback: ramka Aktu I).
