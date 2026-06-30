# DZIEŃ 50 / DAY FIFTY

Karciany roguelike survivalowy 2D dla jednego gracza, tworzony w Godot 4.5.
Każdy dzień to zagrywanie kart, zbieranie zasobów, rozbudowa osady i nocne
zdarzenie. W połowie runu następuje **BUM**: plansza zostaje skażona, budynki
ulegają uszkodzeniu, a do puli nocy trafiają potwory. Celem jest przetrwanie
do dnia 50.

> **Stan projektu: 2026-06-30.** Grywalny, kompletny funkcjonalnie vertical
> slice z pełnym 50-dniowym runem. Główna linia rozwoju to wersja Godot;
> `web/` zawiera starszy, równoległy prototyp przeglądarkowy.

## Co jest w grze

- pełny run do **dnia 50** w dwóch aktach;
- BUM losowane na dzień **11–14**;
- plansza 3×2 losowana z puli **8 biomów**, fog of war i ruch za energię;
- cztery potrzeby: zdrowie, sytość, nawodnienie i ciepło;
- **19 budynków** stawianych z katalogu na slotach biomów;
- naprawy, ruiny, rozbiórka i kosztowna odbudowa po BUM;
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
| Karty akcji w głównej puli nagród | 50 |
| Karty zbierania przypięte do biomu (`gather_only`) | 4 |
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

Akt I służy eksploracji i przygotowaniu osady. BUM odwraca kafle na skażone
wersje i losowo uszkadza budynki. W Akcie II dochodzą reguły katastrofy,
potwory, cięższa ekonomia i odbudowa po zniszczeniach.

## Klasy i meta-progresja

Klasą startową jest **Skaut**. Pozostałe klasy odblokowuje ruletka:

- wygrany run daje 1 złotą monetę;
- losowanie kosztuje 1 monetę;
- ruletka wybiera jedną z jeszcze zablokowanych klas;
- monety i odblokowania zapisują się w `user://meta_state.tres`.

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
  `gather_only` i modyfikatory kafla (camp).

Kontrolne pomiary smoke testu (2026-06-30): główny przebieg **0/50** dla
naiwnego bota — Akt I jest dla niego bezpieczny (zgony ~0–1), a cała śmiertelność
przypada na Akt II (ściana katastrofy, zgodnie z założeniem). Próbka klasowa
rozjeżdża się szeroko (Zielarka ~10/30, Strateg ~5/30, reszta niżej). To sygnał
balansu do strojenia, nie twarda bramka — świadomy gracz celuje wyżej niż bot.

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
web/        starszy, niezależny prototyp przeglądarkowy
```

Największe moduły to `systems/survival_system.gd` i `scenes/run.gd`.
Przed dodawaniem kolejnych dużych systemów warto wydzielić z nich obsługę
nocy/BUM oraz prezentację efektów.

## Aktualne priorytety

1. Balans Aktu II — przy BUM w dniu 11–14 i mecie w dniu 50 to ~36 dni
   katastrofy (bot 0/50); pacing/odbudowa wymagają strojenia.
2. Ręczny playtest skrajnie różnych klas (spread Zielarka↔Informatyk).
3. Uzupełnienie źródeł i licencji audio oraz ekran creditsów.
4. Wersjonowanie/migracja zapisów (zmiana schematu `RunState` psuje stare zapisy).
5. Rozszerzenie meta-progresji (kolekcja, odblokowania) i pełnego podglądu
   nieodkrytych biomów.

CI (testy + build Windows + release) działa już w
[`.github/workflows/godot-ci.yml`](.github/workflows/godot-ci.yml); preset
eksportu `Windows` jest śledzony w `export_presets.cfg`.

## Znane ograniczenia

- balans klas jest szeroki: Zielarka i Skaut są znacznie łatwiejsze od Informatyka;
- Akt II to ściana — przy obecnym oknie BUM (11–14) zajmuje większość runu;
- autozapis działa na granicy dni, bez ręcznych slotów zapisu;
- brak drabinki trudności i kolekcji kart (ulepszanie kart już działa);
- karty zwiadu nie oferują jeszcze pełnego podglądu nieodkrytego kafla;
- brak wersjonowania/migracji starszych zapisów;
- `assets/audio/LICENSES.txt` jest wypełniony (manifest Suno Pro, 23 pliki);
  przed wydaniem zostaje tylko weryfikacja prawna regulaminu Suno.
