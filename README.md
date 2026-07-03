# DZIEŃ 50 / DAY FIFTY

Karciany roguelike survivalowy 2D dla jednego gracza, tworzony w Godot 4.5.
Każdy dzień to zagrywanie kart, zbieranie zasobów, rozbudowa osady i nocne
zdarzenie. W połowie runu następuje **BUM**: plansza zostaje skażona, budynki
ulegają uszkodzeniu, a do puli nocy trafiają potwory. Celem jest przetrwanie
do dnia 50.

> **Stan projektu: 2026-07-01.** Grywalny, kompletny funkcjonalnie vertical
> slice z pełnym 50-dniowym runem. Główna linia rozwoju to wersja Godot.

## Co jest w grze

- pełny run do **dnia 50** w dwóch aktach;
- BUM losowane na dzień **20–26**;
- plansza 3×2 losowana z puli **8 biomów**, fog of war i ruch za energię;
- cztery potrzeby: zdrowie, sytość, nawodnienie i ciepło;
- **19 budynków** stawianych z katalogu na slotach biomów;
- naprawy, ruiny, rozbiórka i kosztowna odbudowa po BUM;
- zabezpieczanie maksymalnie **2 rejonów** przed BUM: głównie koszt kamienia,
  potem energii i drewna, za mniejsze obrażenia BUM oraz mniejsze zużycie HP
  budynków w Akcie I;
- **4 katastrofy**: Plaga, Zaćmienie, Powódź i Pęknięcie;
- **15 potworów** przypisanych do katastrof;
- cztery pory roku z osobnymi modyfikatorami i pogodą;
- ważona pula nocnych zdarzeń z cooldownami, limitami i omenami;
- XP oraz wybór nagrody przy awansie: energia, zdrowie albo nowa karta;
- **9 klas**, każda z własną talią i kartą sygnaturową;
- meta-progresja: moneta za wygrany run i ruletka klasy za 1 monetę;
- autozapis na początku dnia oraz opcja „Kontynuuj”;
- samouczek, ustawienia obrazu i dźwięku, muzyka, ambient, SFX i rozbudowane FX.

Aktualne zasoby danych:

| Rodzaj | Liczba |
|---|---:|
| Biomy | 8 |
| Budynki | 19 |
| Klasy i talie startowe | 9 |
| Katastrofy | 4 |
| Potwory | 15 |
| Karty akcji (łącznie) | 74 |
| Karty akcji w głównej puli nagród | 47 |
| Karty poza pulą nagród (`gather_only`: akcje biomów + fallbacki talii) | 7 |
| Skażone akcje biomów | 4 |
| Karty sygnaturowe klas | 9 |
| Warianty ulepszeń kart | 7 |
| Zasoby zdarzeń nocnych | 146 |

Szczegółowy spis zawartości i aktualnych braków znajduje się w
[`docs/INWENTARZ.md`](docs/INWENTARZ.md). Historia prac jest prowadzona w
[`CLAUDE.md`](CLAUDE.md).

## Pętla rozgrywki

1. O świcie odnawia się energia, dobierana jest ręka i uruchamiają się
   pasywy budynków.
2. Gracz zagrywa karty, korzysta z akcji bieżącego biomu, podróżuje i buduje.
3. Po zakończeniu dnia odkrywana jest duża karta nocnego zdarzenia.
4. Efekt nocy jest rozliczany dopiero po potwierdzeniu przez gracza.
5. Potrzeby spadają, zapasy są automatycznie zużywane i zaczyna się kolejny dzień.

Akt I służy eksploracji i przygotowaniu osady. Gracz może zabezpieczyć wybrane
rejony przyciskiem na aktualnym kaflu; zabezpieczenie jest drogie i limitowane,
ale zmniejsza obrażenia BUM oraz sprawia, że budynki w tym rejonie mają tylko
60% szans na utratę HP przy zużyciu w Akcie I. BUM odwraca kafle na skażone
wersje, uszkadza budynki i zużywa zabezpieczenia. W Akcie II dochodzą reguły
katastrofy, potwory, cięższa ekonomia i odbudowa po zniszczeniach.

## Klasy i meta-progresja

Klasą startową jest **Skaut**. Pozostałe klasy odblokowuje ruletka:

- wygrany run daje 1 złotą monetę;
- losowanie kosztuje 1 monetę;
- ruletka wybiera jedną z jeszcze zablokowanych klas;
- monety i odblokowania zapisują się w `user://meta_state.json`.

Dostępne klasy: Skaut, Kucharz, Budowlaniec, Zielarka, Łowca, Strateg,
Wędrowiec, Wojskowy i Informatyk.

Meta-progresja odblokowuje różnorodność, a nie stałe bonusy statystyk.
Kolekcja kart, odblokowania biomów/katastrof i drabinka trudności nie są
jeszcze zaimplementowane.

## Uruchomienie

Wymagany jest Godot 4.5 lub nowszy; projekt był testowany na 4.5.1.

1. Otwórz Godot Project Manager.
2. Zaimportuj `project.godot`.
3. Uruchom projekt klawiszem **F5**.

Główna scena: `scenes/main_menu.tscn`.

## Testy

Po zmianach w skryptach lub zasobach najpierw odśwież import:

```text
Godot_v4.5.1-stable_win64_console.exe --headless --path . --import
```

Testy headless:

```text
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/smoke_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/fog_of_war_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/season_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/board_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/load_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/ui_layout_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/night_pool_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/save_load_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/meta_progression_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/audio_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/card_upgrade_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/hand_draw_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/biome_camp_test.gd
Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tests/bum_preparation_test.gd
```

Aktualny zestaw obejmuje:

- 50 pełnych runów bota oraz próbkę 30 runów dla każdej klasy;
- walidację 200 proceduralnych plansz;
- import i typy wszystkich ręcznie tworzonych zasobów;
- pory roku, fog of war i ważoną pulę zdarzeń;
- instancjonowanie 100 wariantów kart UI;
- zapis/odczyt runu;
- koszt, odblokowanie i zapis/odczyt meta-progresji;
- katalogi audio, busy oraz start odtwarzaczy muzyki i SFX;
- ulepszenia kart (podmiana w talii), owned-only dobór ręki oraz flagę
  `gather_only`, modyfikatory kafla (camp) i przygotowanie rejonów pod BUM.

Kontrolne pomiary smoke testu (2026-07-02, po przeglądzie kart): główny przebieg
**22/50** dla naiwnego bota, średnio 37,7 dnia; zgony: Akt I 8 (śr. dzień 10,3),
Akt II 20. Wyraźna poprawa względem 0/50 z 2026-07-01 (bot ginął na drogim
zabezpieczaniu rejonów); Akt I wciąż powyżej historycznego ideału ~0–2 zgonów —
sygnał do dalszego strojenia, nie twarda bramka.

## Architektura

Projekt rozdziela dane, logikę i UI:

```text
data/       zasoby .tres: karty, biomy, budynki, klasy, katastrofy, potwory
systems/    logika niezależna od scen: run, plansza, talia, pula nocy
scripts/    stan runu i meta, autoloady, definicje zasobów
scenes/     menu, ekran runu i wynik
ui/         reużywalne widoki kart, biomów, pasków i overlayów
tests/      testy headless uruchamiane przez Godot -s
assets/     grafika, FX i audio
```

Obsługa nocy i BUM jest wydzielona z `survival_system.gd` do
`systems/night_resolver.gd` i `systems/bum_resolver.gd` (statyczne funkcje na
przekazanym systemie; stan i sygnały zostają na `SurvivalSystem`). Po stronie
UI popup nocy żyje w `ui/night_overlay_view.gd` (skrypt węzła `NightEventOverlay`
w `run.tscn`), a FX (sekwencja BUM, pogoda, winiety, world FX) w
`scenes/run_fx.gd`.

## Aktualne priorytety

1. Balans Aktu II po przesunięciu BUM na dzień 20–26 i dodaniu zabezpieczeń
   rejonów; pacing/odbudowa wymagają kolejnych ręcznych playtestów.
2. Ręczny playtest skrajnie różnych klas (spread Zielarka↔Informatyk);
   Budowlaniec 3/30 u bota — kandydat do strojenia.
3. Rozszerzenie meta-progresji (kolekcja, odblokowania) i pełnego podglądu
   nieodkrytych biomów.

CI (testy + build Windows + release) działa już w
[`.github/workflows/godot-ci.yml`](.github/workflows/godot-ci.yml); preset
eksportu `Windows` jest śledzony w `export_presets.cfg`.

## Znane ograniczenia

- balans klas jest szeroki: Zielarka i Skaut są znacznie łatwiejsze od Informatyka;
- Akt II nadal może być ścianą, ale obecne okno BUM (20–26) daje dłuższy Akt I
  na przygotowanie i wybór zabezpieczonych rejonów;
- autozapis działa na granicy dni, bez ręcznych slotów zapisu;
- brak drabinki trudności i kolekcji kart (ulepszanie kart już działa);
- karty zwiadu nie oferują jeszcze pełnego podglądu nieodkrytego kafla;
- zapis runu ma wersję schematu (`RunState.SAVE_VERSION`) — niekompatybilny
  zapis jest czysto odrzucany; migracji między wersjami nadal nie ma;
- `assets/audio/LICENSES.txt` jest wypełniony i regulamin Suno zweryfikowany
  (2026-07-03: Pro = własność + prawa komercyjne, gry wideo dozwolone);
  do zrobienia ręcznie zostaje dowód subskrypcji z dat generacji.
