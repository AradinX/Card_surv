# Prompty: zestaw ikon statystyk i zasobów (2026-07-06)

12 małych ikon: 10 do górnego HUD i wiersza kosztów na kartach + 2 do
efektów kart (losowe znalezisko, dobór karty). Kod jest już
wpięty (plug-and-play): wrzucenie plików do `assets/art/ui/icons/stats/`
automatycznie włącza ikony na pasku HUD i zamienia słowne koszty na kartach
na ikona+cyfra. Brak plików = obecny wygląd tekstowy, zero regresji.

## Pliki docelowe (64×64, przezroczyste tło)

```text
assets/art/ui/icons/stats/icon_health.png   (zdrowie)
assets/art/ui/icons/stats/icon_hunger.png   (sytość)
assets/art/ui/icons/stats/icon_thirst.png   (nawodnienie)
assets/art/ui/icons/stats/icon_warmth.png   (ciepło)
assets/art/ui/icons/stats/icon_energy.png   (energia)
assets/art/ui/icons/stats/icon_food.png     (zapas jedzenia)
assets/art/ui/icons/stats/icon_water.png    (zapas wody)
assets/art/ui/icons/stats/icon_wood.png     (drewno)
assets/art/ui/icons/stats/icon_stone.png    (kamień)
assets/art/ui/icons/stats/icon_tools.png    (narzędzia)
assets/art/ui/icons/stats/icon_random.png   (losowe znalezisko — „?")
assets/art/ui/icons/stats/icon_card.png     (dobierz/dodaj kartę)
```

Uwaga: `icon_random` i `icon_card` dotyczą efektów kart („+1 losowe
znalezisko", „+2 karty do ręki"). Linia efektów jest dziś zwykłym Labelem
(tekst) — te 2 ikony generujemy razem z zestawem, a ich wpięcie w linię
efektów to osobny krok (RichTextLabel), do decyzji gdy assety będą gotowe.

## Pipeline

Generuj w 1024×1024 na JEDNOLITYM zielonym tle `#00FF00` (jak FX/panele —
NIE prosić generatora o przezroczystość, wycinamy sami). Po wrzuceniu surowych
plików (np. do `tmp/icons_raw/`) chroma-key + downscale do 64×64 robi Claude
istniejącym pipeline'em (`tools/chroma_key_fx.gd` + skalowanie).

WAŻNE dla czytelności w 20 px: jeden gruby, wypełniony symbol na ikonę,
zajmujący ~85% kadru, bez tła, bez ramki, bez drobnych detali — detal
mniejszy niż 1/10 kadru zniknie po zmniejszeniu.

## Wspólny scaffold (podmieniaj tylko {SUBJECT} i {COLOR})

```text
Single pixel art GAME ICON for the dark survival card roguelike Dzien 50.
One bold centered symbol filling about 85 percent of the frame, on a SOLID
pure green #00FF00 background (chroma key), nothing else in the image.

Subject: {SUBJECT}.

Style: chunky readable pixel art with a thick dark-brown outline (like aged
ink), warm hand-painted fill in {COLOR}, one soft highlight, medium visible
pixels, hard edges, no smooth gradients. The symbol must stay clearly
readable when scaled down to 20x20 pixels: simple silhouette, no small
details, no inner text.

Avoid: background scenery, frame, border, medallion, drop shadow, glow,
letters, numbers, multiple objects, photorealism, painterly blur, 3D render.
```

## Subjects i kolory

| Plik | {SUBJECT} | {COLOR} |
|---|---|---|
| icon_health | a rounded heart | deep warm red with a lighter top |
| icon_hunger | a wooden bowl of steaming stew with a spoon | warm brown broth, cream steam |
| icon_thirst | a fat water droplet | clear blue with a white shine |
| icon_warmth | a small campfire flame | orange-yellow flame core |
| icon_energy | a thick lightning bolt | bright golden yellow |
| icon_food | a small wicker basket filled with red berries and a mushroom | straw beige basket, red berries |
| icon_water | a leather waterskin with a wooden stopper | earthy brown leather, blue drop accent |
| icon_wood | two stacked cut logs seen from the side, visible rings | warm timber brown, cream rings |
| icon_stone | a rough gray stone chunk with a flint edge | cool gray with lighter facets |
| icon_tools | a crossed stone axe and flint knife | wooden handles, gray stone heads |
| icon_random | a bold question mark carved like weathered wood | aged gold with dark grain |
| icon_card | a single playing card seen slightly tilted, blank dark-green face with a thin gold border | forest green face, aged gold trim |

Uwaga na pary „stat vs zapas": sytość (miska gulaszu) ≠ jedzenie (koszyk),
nawodnienie (kropla) ≠ woda (bukłak) — symbole muszą się wyraźnie różnić,
bo występują obok siebie na tym samym pasku.

## Po dostarczeniu (checklista)

- [ ] chroma-key #00FF00 → alpha + downscale 1024→64 (robi Claude).
- [ ] `--import` + `ui_layout_test` + rzut oka: HUD (ikony przy statach
      i zasobach) i karty (koszt jako ikona+cyfra) w edytorze.
- [ ] Jeśli któraś ikona nieczytelna w 20 px — regeneracja pojedynczej
      z prostszym subjectem.
