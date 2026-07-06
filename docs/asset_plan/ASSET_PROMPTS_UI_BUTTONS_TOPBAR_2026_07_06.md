# Prompty: nowe przyciski runu (bez kwiatków) + pasek HUD Aktu II (2026-07-06)

Feedback autora: ozdobne „kwiatkowe" ramki przycisków w runie do wymiany na
czystszy styl; ramka górnego HUD po BUM wygląda na rozciągniętą.

Diagnoza techniczna (pod którą pisane są prompty):

- `ui/button_skin.gd` rozciąga CAŁY PNG na rect przycisku (texture_margins=0,
  bez 9-slice) — narożne kwiaty/winorośl deformują się przy każdym rozmiarze.
  Nowy art: prosta ramka o STAŁEJ grubości przy samej krawędzi (9-slice-ready);
  po dostarczeniu artu ustawić w `button_skin.gd` `_TEXTURE_MARGINS` ≈ grubość
  ramki w pikselach źródła (ok. 24), wtedy narożniki nigdy się nie deformują.
- Pasek HUD: oba płótna to 2564×238, ale art Aktu II ma UCIĘTĄ górną krawędź
  ramki i grubszą dolną belkę — inna geometria wnętrza niż wieniec Aktu I daje
  efekt „rozciągnięcia". Nowy art Aktu II ma skopiować geometrię ramki Aktu I
  1:1 (ta sama grubość, te same marginesy, ramka W CAŁOŚCI na płótnie).

Zasady: text-free, pixel art spójny z resztą (widoczne piksele, twarde
krawędzie, bez smooth paintingu), zapis pod istniejącymi nazwami (drop-in).

## 1. Przyciski runu — 8 plików, 448×224 każdy

Ścieżki (podmiana in-place):

```text
assets/art/ui/buttons/act1/button_primary.png
assets/art/ui/buttons/act1/button_primary_hover.png
assets/art/ui/buttons/act1/button_primary_pressed.png
assets/art/ui/buttons/act1/button_disabled.png
assets/art/ui/buttons/act2/button_primary.png
assets/art/ui/buttons/act2/button_primary_hover.png
assets/art/ui/buttons/act2/button_primary_pressed.png
assets/art/ui/buttons/act2/button_disabled.png
```

Referencje stylu (dołącz jako obrazy): `assets/art/ui/panels/
confirm_popup_panel_act1.png` (ciemne drewno + złoto Aktu I) oraz
`confirm_popup_panel_act2.png` (wariant skażony dla act2).

Prompt bazowy — ACT 1 `button_primary.png`:

```text
Pixel art UI BUTTON background for the dark survival card roguelike Dzien 50,
matching the attached carved-wood panel style. One single rounded-rectangle
button filling the whole 448x224 image, front view, no perspective.

Style: dark stitched forest-green fabric fill with subtle woven texture,
framed by a simple aged-gold pixel border with a thin inner dark-bronze line.
Clearly visible pixels, hard edges, controlled dithering, no smooth painting.

CRITICAL for 9-slice scaling: the border must be a clean straight band of
CONSTANT thickness (about 22-26 px) running along all four edges, with small
identical rounded corners. NO flowers, NO vines, NO leaves, NO gems, NO
medallions, NO corner ornaments that differ from the edges, NOTHING sticking
out of the border band. The center must be a completely flat, even fill so
text placed on it stays readable.

Text: no text, no letters, no numbers, no icons, no emblem.

Avoid: floral decoration, organic garlands, photorealism, painterly blur,
3D bevel render, drop shadows outside the button, background scene.
```

Warianty stanów ACT 1 (ta sama geometria, tylko delta — wygeneruj z bazą jako
referencją i dopiskiem):

- `button_primary_hover.png`: "same button, the gold border glows slightly
  brighter and warmer, fill lightens a touch (hover state)".
- `button_primary_pressed.png`: "same button, fill darkens and the border
  gold dims to bronze, subtle pressed-in feel via a darker top inner edge".
- `button_disabled.png`: "same button, fully desaturated: gray-green fill,
  dull gray-bronze border (disabled state)".

Warianty ACT 2 (referencja: baza act1 + `confirm_popup_panel_act2.png`):
ta sama geometria ramki co act1, ale "blackened corroded iron-and-bone
border instead of aged gold, charcoal-black fabric fill with a faint sickly
tint, weathered survival-after-catastrophe mood". Stany hover/pressed/
disabled jak wyżej (hover: zimny poblask; pressed: ciemniej; disabled:
wyprane szarości).

Po dostarczeniu: w `ui/button_skin.gd` ustawić `_TEXTURE_MARGINS` na grubość
ramki (≈24 px) — dopiero to włącza 9-slice i kończy deformacje.

## 2. Pasek górnego HUD Aktu II — 1 plik, DOKŁADNIE 2564×238

Ścieżka (podmiana in-place):

```text
assets/art/ui/panels/top_status_bar_panel_act2_withered_candidate.png
```

Referencja OBOWIĄZKOWA (dołącz jako obraz): `assets/art/ui/panels/
top_status_bar_panel_act1_wreath_candidate.png` — wzorzec geometrii.

Prompt:

```text
Pixel art TOP HUD BAR frame for Act II of the dark survival card roguelike
Dzien 50. Use the attached Act I wreath bar as the EXACT layout reference:
same 2564x238 canvas, same border thickness, same inner window size and
position, same corner radius. The full frame must be COMPLETELY INSIDE the
canvas on all four sides — top edge fully visible, nothing cropped, nothing
bleeding past the image border. Top and bottom border bands must have the
SAME thickness as each other and as the Act I reference.

Theme swap only: replace the fresh spring garland with the after-catastrophe
version — blackened withered thorn branches and dry twisted vines woven along
a tarnished dark-gold rail, a few small dead leaves, faint sickly green-gray
tint. Fill the inner window with the same very dark fabric as the reference,
slightly blackened. Keep the ornament calm and evenly distributed so the busy
HUD text stays readable; decoration density similar to the Act I reference,
not heavier.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers. Avoid: cropped edges,
thick bottom band, asymmetric frame, photorealism, painterly blur, glow
effects outside the frame.
```

Weryfikacja po wygenerowaniu (zanim wejdzie do gry): nałożyć oba PNG na
siebie — ramka act2 musi pokrywać się z act1 co do kilku pikseli na wszystkich
czterech krawędziach; żadna krawędź nie może być ucięta.

## Opcjonalnie (spójność)

Jeśli po odchudzeniu przycisków wieniec kwiatowy paska Aktu I zacznie gryźć
się ze stylem, ten sam prompt co w sekcji 2 działa dla Aktu I z motywem
"fresh forest vine rail with sparse leaves, no flowers" — ale to osobna
decyzja autora, domyślnie pasek Aktu I zostaje.
