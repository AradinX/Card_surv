# Prompty: pakiet graficzny przed premierą (2026-07-07)

Ustalenia z autorem po przeglądzie screenów (`docs/steam_screens/pl/`):

1. Pasek HUD — subtelna plecionka dookoła + art w wolnej strefie między
   „Dzień" a statystykami; wariant żywy (Akt I) i martwy (Akt II).
2. Przyciski runu — wymiana na kartki papieru/pergamin w stylu notek
   z popupów nocnych (obecne drewniano-złote się nie podobają).
3. Logo menu „DZIEŃ 50" (dziś zwykły systemowy font).
4. Malowany panel popupu awansu (jedyny „goły" popup).
5. (Rekomendacja Claude) Mroczne warianty artów budynków na Akt II.

Zasady wspólne: pixel art spójny z resztą (widoczne piksele, twarde krawędzie,
kontrolowany dithering, bez smooth paintingu), zapis pod podanymi ścieżkami.
Text-free WSZĘDZIE poza logo (sekcja 3). Tła: jeśli generator nie da
przezroczystości, dostarczyć na solid blue `#0000FF` — tnie
`tools/chroma_key_blue.gd`.

Wpięcie w kod (po wrzuceniu plików): sekcje 1–2 są plug-and-play (zero zmian
w kodzie; przy przyciskach drobna korekta kolorów fontu — robi Claude).
Sekcje 3–5 wymagają małych zmian w kodzie — robi Claude, wystarczy dać znać,
że pliki są.

## 1. Pasek HUD — 2 pliki, 1920×96

```text
assets/art/ui/panels/top_status_bar_slim_act1.png
assets/art/ui/panels/top_status_bar_slim_act2.png
```

Plug-and-play: `TopStatusBarView` sam podmieni płaski panel, gdy plik istnieje.

Geometria (WAŻNE — tekst gry rysuje się NA panelu):
- Strefa tekstu lewa: x 0–330 („Dzień 5/50", „Poziom", XP).
- Strefa statystyk prawa: x 860–1920 (10 komórek ikona+wartość+podpis).
- **Wolna strefa na art: x ~350–840** — tu wchodzi motyw ozdobny.
- Wypełnienie pod strefami tekstu musi być CIEMNE i JEDNOLITE (kremowe
  cyfry i małe podpisy muszą zostać czytelne; nad wartościami pojawiają się
  też zielone/czerwone badge'e +X/−Y).

Referencje stylu (dołącz jako obrazy): `assets/art/ui/panels/
log_panel_act1.png` (paleta Aktu I) i `log_panel_act2.png` (Akt II).

Prompt — ACT 1:

```text
Pixel art SLIM TOP HUD STRIP for the dark survival card roguelike Dzien 50,
1920x96, front view. One long thin horizontal panel filling the whole canvas.

Fill: very dark forest-green woven fabric, flat and even — game icons and
numbers are drawn on top at runtime, so keep it low-contrast and uniform,
especially in the left third and the right half.

Border: a VERY SUBTLE thin braided wicker/vine plait (delikatna plecionka)
running along all four edges, constant thickness about 8-10 px, muted
aged-gold and living green tones, small identical rounded corners. The braid
must stay calm and even — no flowers bursting out, no medallions, nothing
sticking outside the canvas.

Decorative motif: ONLY in the horizontal zone between x=350 and x=840
(the rest of the strip stays plain fill): a small lively Act I vignette woven
into the strip — fresh leafy vine sprigs, a few spring leaves and tiny buds,
maybe a small bird silhouette, growing sideways out of the braid, in muted
greens and golds, slightly brighter than the fill but still background-dark.
The motif must fade out smoothly into the plain fill on both sides.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers, no icons.
Avoid: bright highlights, busy pattern under the text zones, corner
ornaments, photorealism, painterly blur, glow outside the frame.
```

Prompt — ACT 2 (referencja: gotowy act1 + `log_panel_act2.png`; geometria
plecionki skopiowana 1:1):

```text
Same 1920x96 slim HUD strip layout as the attached Act I strip: same braid
thickness, same corners, same decorative zone between x=350 and x=840,
same plain dark fill everywhere else.

Theme swap only — the world after the catastrophe: the braided border is now
DEAD — dry blackened twisted twigs and withered thorny vines, tarnished
bronze instead of gold, faint sickly gray-green tint. The decorative motif in
the middle zone is the dead mirror of Act I: bare cracked branches, a few
dry curled leaves falling, maybe a tiny crow silhouette. Fill: charcoal-dark
fabric with a faint cold tint, still flat and even under the text zones.

Style: clearly visible pixels, hard edges, no smooth painting. Text: none.
Avoid: bright highlights, busy pattern under text zones, glow, photorealism.
```

Weryfikacja: wrzucić plik, odpalić run — HUD podnosi go sam; sprawdzić
czytelność wartości i badge'y +X/−Y na obu wariantach.

## 2. Przyciski runu jako kartki papieru — 8 plików, 448×224

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
night_popup_panel_event.png` (kartki-notki, do których dążymy) oraz
`night_popup_panel_monster.png` (mroczny wariant pod act2).

UWAGA 9-slice: przyciski są rozciągane (rogi 20 px chronione w kodzie).
Podarte krawędzie kartki MUSZĄ być delikatne i równomierne — pas krawędzi
o stałej grubości, identyczne rogi, żadnych pojedynczych dużych wyrwań,
bo przy rozciąganiu się powielą.

Prompt bazowy — ACT 1 `button_primary.png`:

```text
Pixel art UI BUTTON for the dark survival card roguelike Dzien 50: a single
PINNED PAPER NOTE filling the whole 448x224 image, front view, matching the
parchment notes on the attached night-event panel.

Style: aged cream parchment sheet with subtle fiber texture, gently torn
edges, one small brass tack in each top corner, a very soft drop shadow
baked around the sheet inside the canvas. The center must be flat, even
parchment so dark ink text placed on it at runtime stays readable.

CRITICAL for 9-slice scaling: the torn edge must form a clean band of
CONSTANT thickness (about 18-22 px) along all four sides, with all four
corners looking identical; no single big rip, no element sticking out.

Text: no text, no letters, no numbers, no icons.
Avoid: writing, wax seals, medallions, heavy stains in the center,
photorealism, painterly blur, glow.
```

Warianty stanów ACT 1 (ta sama geometria; generować z bazą jako referencją):
- `button_primary_hover.png`: "same note, parchment brightens slightly warm,
  tacks glint (hover state)".
- `button_primary_pressed.png`: "same note, parchment darkens a touch and
  the shadow tightens, pressed-down feel".
- `button_disabled.png`: "same note, desaturated gray parchment, dull tacks".

Warianty ACT 2 (referencja: baza act1 + panel monster): ta sama geometria,
ale "scorched dirty parchment with darkened edges, blackened iron tacks,
faint claw scratches near the edges (never in the center), cold
after-catastrophe mood". Stany jak wyżej.

Alternatywny pipeline (jak przy obecnym zestawie): wygenerować TYLKO 2 bazy
(act1/act2), a hover/pressed/disabled wyprowadzić programowo (PIL:
jaśniej/ciemniej/odbarwienie) — identyczna geometria stanów gratis.

Po dostarczeniu (Claude): korekta kolorów fontu w `button_skin.gd` —
na jasnym pergaminie act1 tekst ciemny atrament (jak notki nocne,
~`(0.16, 0.1, 0.05)`), na brudnym act2 do zmierzenia kontrast.

## 3. Logo menu „DZIEŃ 50" — 1 plik, 1024×512, przezroczyste tło

```text
assets/art/ui/logo_dzien50.png
```

JEDYNY asset z tekstem. Sprawdzić po wygenerowaniu, czy „Ń" ma poprawny
akcent (generatory często go gubią) — odrzucić i powtórzyć, jeśli nie.

Referencje: `assets/art/backgrounds/bg_run_table.png` (tło menu, na nim
logo będzie leżeć) + dowolna plakietka tytułowa (np. `assets/art/biomes/
frames/biome_title_plate.png`) dla spójności liternictwa ze światem gry.

Prompt:

```text
Pixel art GAME LOGO for the dark survival card roguelike "DZIEN 50",
1024x512, transparent background, front view.

The words "DZIEŃ 50" (Polish, note the accent stroke over the N) in large
hand-carved wooden letters with aged-gold edge trim, arranged on one or two
lines, slightly weathered, with a few small vine sprigs and leaves growing
from the letters. Below or around it NO subtitle, NO other words. The "50"
may be emphasized (larger or warmer gold). Mood: dark forest survival with
a warm campfire accent.

Style: clearly visible pixels, hard edges, controlled dithering, readable
silhouette on a dark background, subtle warm rim light. No background scene,
no frame, transparent around the letters.

Avoid: any other text, watermark, photorealism, painterly blur, neon glow.
```

Wpięcie (Claude): `main_menu.tscn` — TextureRect zamiast Labela tytułu,
fallback do tekstu, gdy pliku brak.

## 4. Panel popupu awansu — 1 plik, 1536×640

```text
assets/art/ui/panels/level_up_panel.png
```

Referencje: `assets/art/ui/panels/confirm_popup_panel_act1.png` (drewno+złoto)
i `night_popup_panel_event.png` (kartki). Panel jest POZIOMY: u góry pas na
tytuł „Awans! Poziom N — wybierz nagrodę", pod nim rząd TRZECH miejsc na
przyciski nagród (kartki jak w sekcji 2 mogą być wmalowane jako sloty).

Prompt:

```text
Pixel art LEVEL-UP POPUP PANEL for the dark survival card roguelike Dzien 50,
1536x640, front view, matching the attached carved-wood confirm panel.

Layout: one wide horizontal panel of dark carved wood with a simple aged-gold
border (constant thickness, calm corners). Across the top: a darker wooden
title plaque band (about 120 px tall, centered, taking ~60% of the width) —
kept EMPTY for runtime text. Below it: THREE identical pinned parchment note
rectangles in a row (each about 420x260), evenly spaced, kept EMPTY for
runtime text — same parchment style as the notes on the attached night panel.
A few subtle celebratory accents in the wood between the notes: small carved
laurel sprigs, tiny gold star studs — calm, not busy.

Style: clearly visible pixels, hard edges, controlled dithering, no smooth
painting. Text: no text, no letters, no numbers.
Avoid: filling the plaque or notes with decoration, wax seals, photorealism,
painterly blur, glow outside the panel.
```

Wpięcie (Claude): `run.tscn` LevelUpOverlay — PanelArt + zakotwiczenie
3 przycisków nagród w namalowane kartki (jak popupy nocne).

## 5. (Rekomendacja) Mroczne arty budynków na Akt II — 16 plików, 1024×688

Opinia Claude: TAK, warto — po BUM jasne, wiosenne miniatury budynków na
kaflach Martwego Lasu odstają (widać to na `04_act2_board.png`). Ale to
16 generacji; tania alternatywa na start: przyciemnienie miniatur kodem
(tint) na skażonych kaflach — zrobi Claude w 10 minut, bez artu. Pełny
efekt daje jednak dedykowany art.

Katalog docelowy (NOWY — stare jasne pliki zostają nietknięte):

```text
assets/art/cards/illustrations/buildings_act2/building_<id>.png
```

Lista (16; pomijamy 4 budynki act2_only — bastion, cistern,
field_infirmary, reinforced_shelter — bo istnieją tylko po BUM i ich
obecny art już jest w nastroju katastrofy):

```text
building_campfire      building_hut           building_well
building_palisade      building_pantry        building_workshop
building_farm          building_fishing_dock  building_herbalist
building_logging_camp  building_quarry        building_stone_storage
building_traps         building_watchtower    building_water_filter
building_wood_storage
```

Scaffold promptu (dla każdego: dołączyć jego jasny odpowiednik z
`buildings_act1_candidates/` jako referencję i podmienić nazwę):

```text
Pixel art building illustration for Act II of the dark survival card
roguelike Dzien 50, 1024x688, text-free. Use the attached Act I illustration
of the same building as the EXACT composition reference: same building, same
camera angle, same placement in frame.

Theme swap only — the same building AFTER THE CATASTROPHE, still standing
and functional but weathered: darkened wood, patched repairs, torn edges,
dead grass and withered vines around the base, cold gray-green sickly light,
overcast dark sky, faint mist. NOT a ruin — the building still works, it just
survived the end of the world. No people, no monsters, no text.

Style: clearly visible pixels, hard edges, controlled dithering, muted
after-catastrophe palette consistent with the attached corrupted biome
backgrounds. Avoid: total destruction, fire, photorealism, painterly blur.
```

(Dodatkowa referencja wspólna: dowolne tło z
`assets/art/biomes/backgrounds/corrupted/` dla palety.)

Wpięcie (Claude): lookup w `biome_tile_view`/`building_popup_view`/
`card_view` — preferuj `buildings_act2/` gdy kafel skażony / po BUM,
fallback do jasnego artu (plug-and-play per plik: można generować partiami).

## Poza tym plikiem (czysto kodowe, bez generowania — robi Claude)

- Medalion postaci nachodzi na plakietkę tytułu kafla (przesunięcie kotwic).
- Wyrównanie rozmiaru fontu opisów kart w obrębie rzędu ręki.
- Skórka dropdownu „Postać:" w menu (surowy szary Godot).
