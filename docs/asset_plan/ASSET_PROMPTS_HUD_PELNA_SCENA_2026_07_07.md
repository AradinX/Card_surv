# Pasek HUD generowany w pełnej klatce ekranu (2026-07-07)

Plik SAMODZIELNY do podania czatowi generującego.

Nowe podejście: zamiast wąskiego paska 2496×128 (generator gubił proporcje)
generujemy **cały ekran gry 1920×1080** — wszystko czysto niebieskie
`#0000FF`, a u góry namalowany pasek HUD dokładnie w miejscu i rozmiarze,
w jakim siedzi w grze. Generator widzi pasek w kontekście całej klatki,
więc grubość ramki i proporcje wychodzą naturalnie.

Geometria (zmierzona w grze, canvas 1280×720 × 1,5):

```text
Obraz:  1920×1080
Pasek:  x 24–1896, y 12–132  (1872×120 px, proporcja 15,6:1)
Ramka:  stała grubość 18–24 px na WSZYSTKICH 4 krawędziach
Strefy paska (x w obrazie): 24–550 tekst | 560–830 dozwolony motyw
                            | 840–1896 statystyki — SPOKOJNE tło
```

Po wygenerowaniu NIC nie musisz mierzyć — wytnę pasek automatycznie po
krawędziach niebieskiego, przeskaluję i podłączę (chroma-key jak zwykle).
Lekkie odchyłki położenia są OK.

Referencje (dołącz jako obrazy): `assets/art/ui/panels/log_panel_act1.png`
i `log_panel_act2.png` (styl plecionki/haftu).

Prompt — ACT 1:

```text
Pixel art UI mockup frame for the dark survival card roguelike Dzien 50,
full game screen 1920x1080, front view.

The ENTIRE image is SOLID PURE BLUE #0000FF placeholder background — except
ONE element: a slim horizontal top HUD bar panel near the top edge, from
x=24 to x=1896, from y=12 to y=132 (1872x120 pixels). Nothing else exists
on the screen: no other panels, no cards, no icons, no decorations in the
blue area.

The top bar panel: a braided wicker/vine plait border along all four edges
of the bar with CONSTANT thickness 18-24 px everywhere — the short left and
right edges exactly as thin as the long top and bottom edges, no thick
decorative end caps. Small identical rounded corners. Muted aged-gold and
living green tones. Fill inside the border: very dark forest-green woven
fabric with a subtle tight cross-weave texture, flat and even — game text
and icons are drawn on top at runtime, so the fill must stay calm,
especially from x=24 to x=550 (day/level text) and from x=840 to x=1896
(stat icons and numbers).

Optional decorative motif: ONE modest accent only between x=560 and x=830,
vertically centered inside the bar, at most 80 px tall — a leafy vine sprig
with a small bird silhouette in muted greens and golds, slightly brighter
than the fill but still background-dark, fading smoothly into the plain
fill on both sides.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers.
Avoid: anything drawn in the blue area, border thicker than 24 px, thick
side caps, bright highlights, busy pattern in the text and stats zones,
black background, photorealism, painterly blur, glow.
```

Prompt — ACT 2 (referencja: gotowy nowy act1 + `log_panel_act2.png`;
geometria skopiowana 1:1):

```text
Same 1920x1080 layout as the attached Act I mockup: solid pure blue #0000FF
everywhere except the same slim top HUD bar from x=24 to x=1896, y=12 to
y=132, same constant 18-24 px border on all four edges, same small rounded
corners, same calm fill zones (x=24-550 and x=840-1896), same single motif
zone x=560-830.

Theme swap only — the world after the catastrophe: the braided border is
now DEAD — dry blackened twisted twigs and withered thorny vines, tarnished
bronze instead of gold, faint sickly gray-green tint. The motif is the dead
mirror of Act I: a bare cracked branch, a few dry curled leaves, a tiny
crow silhouette. Fill: charcoal-dark fabric with a faint cold tint, still
flat and calm in the text and stats zones.

Style: clearly visible pixels, hard edges, no smooth painting. Text: none.
Avoid: anything in the blue area, border thicker than 24 px, thick side
caps, bright highlights, black background, glow, photorealism.
```

Po wrzuceniu plików (dowolna nazwa, np. `hud_fullscreen_act1.png` w
`assets/`): wycięcie paska po krawędziach niebieskiego, skala do paska,
chroma-key i podmiana pod `top_status_bar_slim_act1/2.png` — kod podnosi
je automatycznie (plug-and-play).
