# Poprawka paska HUD — proporcje + boki ramki (2026-07-07)

Plik SAMODZIELNY do podania czatowi generującego.

Diagnoza: dotychczasowy plik 1920×96 (proporcja 20:1) jest w grze wyświetlany
w pasku o proporcji 19,5:1 i przy szerszych oknach dodatkowo rozciągany —
ramka się deformuje. Do tego BOCZNE (lewa/prawa) krawędzie ramki są za grube
— szerokie ozdobne zakończenia czytają się jak kluchy. Do REGENERACJI oba
pliki w NOWYM, szerszym rozmiarze o proporcji zgodnej z grą:

```text
assets/art/ui/panels/top_status_bar_slim_act1.png   (2496×128)
assets/art/ui/panels/top_status_bar_slim_act2.png   (2496×128)
```

2496×128 = 19,5:1 — dokładnie proporcja paska w grze, więc art wyświetla się
1:1 bez rozciągania. Kod dodatkowo tnie pasek jako 9-slice (narożniki i
krawędzie nie deformują się przy żadnej szerokości okna) — dlatego ramka
musi mieć STAŁĄ grubość ≤ 20 px na wszystkich 4 krawędziach.

Zasady wspólne (jak w całym pakiecie):
- Pixel art spójny z grą: widoczne piksele, twarde krawędzie, kontrolowany
  dithering, bez smooth paintingu. Zero tekstu.
- Wszystko POZA panelem: solid blue `#0000FF` — nigdy czarne, nigdy
  „przezroczyste". Niebieski jest wycinany później (`tools/chroma_key_blue.gd`).

Strefy (2496 szer.): tekst lewy zajmuje x 0–400, statystyki zaczynają się od
x=1150 — obie strefy mają zostać spokojne. Winieta TYLKO w x 430–1050,
maks. 84 px wysokości.

Referencje (dołącz jako obrazy): `assets/art/ui/panels/log_panel_act1.png`
i `log_panel_act2.png` (styl plecionki/haftu). Obecny pasek dołącz jako
ANTY-referencję: „tak NIE — za grube boki ramki".

Prompt — ACT 1:

```text
Pixel art SLIM TOP HUD STRIP for the dark survival card roguelike Dzien 50,
2496x128, front view. One long thin horizontal panel filling the whole canvas.

FIX vs the attached previous attempt (anti-reference): the LEFT and RIGHT
ends of the frame were too thick — wide decorative caps that read as blobs.

Border: a braided wicker/vine plait along all four edges with CONSTANT
thickness 16-20 px EVERYWHERE — the left and right edges exactly as thin as
the top and bottom, NO wide gathered caps, NO thick end ornaments. Small
identical rounded corners. Muted aged-gold and living green tones. The braid
stays calm and even — nothing sticking outside the border band.

Fill: very dark forest-green woven fabric with a subtle tight cross-weave
texture, flat and even — game icons and numbers are drawn on top at runtime.
Text zones that MUST stay plain calm fill: x=0 to x=400 and x=1150 to x=2496.

Decorative motif: ONE lively vignette ONLY inside the zone from x=430 to
x=1050, vertically centered, at most 84 px tall and clearly narrower than
its zone — a modest accent, never overwhelming: fresh leafy vine sprigs with
a few spring leaves and tiny buds and a small bird silhouette, growing
sideways out of the border braid, muted greens and golds, slightly brighter
than the fill but still background-dark. The motif fades out smoothly into
the plain fill on both sides well before x=430 and x=1050.

Background OUTSIDE the panel (the tiny cut corners past the rounded border):
SOLID PURE BLUE #0000FF, not black, not transparent.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers, no icons.
Avoid: thick side caps, border thicker than 20 px anywhere, bright
highlights, busy pattern in the text zones, corner ornaments, black
background, photorealism, painterly blur, glow.
```

Prompt — ACT 2 (referencja: gotowy nowy act1 + `log_panel_act2.png`;
geometria plecionki skopiowana 1:1):

```text
Same 2496x128 slim HUD strip layout as the attached Act I strip: same border
thickness 16-20 px constant on ALL four edges (left and right exactly as
thin as top and bottom, no thick end caps), same small rounded corners, same
single vignette zone from x=430 to x=1050 (at most 84 px tall, modest
accent), same plain calm fill everywhere else, especially x=0-400 and
x=1150-2496.

Theme swap only — the world after the catastrophe: the braided border is now
DEAD — dry blackened twisted twigs and withered thorny vines, tarnished
bronze instead of gold, faint sickly gray-green tint. The vignette is the
dead mirror of Act I: bare cracked branches, a few dry curled leaves
falling, a tiny crow silhouette. Fill: charcoal-dark fabric with a faint
cold tint, still flat and calm under the text zones.

Background OUTSIDE the panel (cut corners past the rounded border):
SOLID PURE BLUE #0000FF, not black, not transparent.

Style: clearly visible pixels, hard edges, no smooth painting. Text: none.
Avoid: thick side caps, border thicker than 20 px, bright highlights, busy
pattern in text zones, black background, glow, photorealism.
```

Po wrzuceniu plików: podmiana w miejscu (te same ścieżki), gra podnosi je
bez zmian w kodzie (9-slice liczy marginesy z wysokości pliku). Weryfikacja:
boki ramki tak samo cienkie jak góra/dół, brak deformacji przy zmianie
szerokości okna.
