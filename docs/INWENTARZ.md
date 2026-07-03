# Inwentarz „Dzień 50” — co jest, czego brakuje

Żywy spis zawartości gry. Stan: **2026-07-02**.

**Legenda:** ✅ działa w grze · 🟡 działa częściowo lub wymaga polishu · 🔴 brak.

## Podsumowanie

| Obszar | Stan |
|---|---|
| Pełny run do dnia 50 | ✅ |
| BUM i cztery katastrofy | ✅ |
| Plansza 6 kafli z fog of war | ✅ |
| 9 klas i osobne talie | ✅ |
| Save/load oraz kontynuacja | ✅ |
| Meta-progresja klas | ✅ |
| Grafiki kart, biomów i potworów | ✅ |
| Muzyka, ambient i podstawowe SFX | ✅ |
| Automatyczne testy Godot | ✅ 14 testów |
| Balans klas i aktów | 🟡 |
| Eksport/CI | ✅ |
| Dokumentacja licencji audio | 🟡 (manifest + regulamin Suno zweryfikowany 2026-07-03; zostaje dowód subskrypcji) |

## Klasy postaci

✅ **9 klas**, każda z osobną talią i kartą sygnaturową:

- Skaut — klasa startowa, wytrzymałość, tańsza budowa i mniejsze pragnienie;
- Kucharz — mocniejsze jedzenie i wolniejsze psucie;
- Budowlaniec — tańsze oraz wytrzymalsze budynki;
- Zielarka — regeneracja zdrowia;
- Łowca — eksploracja, leczenie i ekonomia jedzenia;
- Strateg — większa ręka i szybsze zdobywanie XP;
- Wędrowiec — darmowy ruch i dodatkowe zapasy;
- Wojskowy — więcej HP i redukcja obrażeń potworów;
- Informatyk — klasa challenge z mocnymi karami i premią XP.

✅ Karty sygnaturowe są poza główną pulą nagród i występują tylko w
odpowiednich taliach startowych.

✅ Skaut jest zawsze odblokowany. Wygrany run daje 1 monetę, ruletka kosztuje
1 monetę i losuje jedną z zablokowanych klas.

🟡 Aktualny sygnał balansowy z 30 runów bota na klasę (2026-07-04, po passie
balansu przed wydaniem — Budowlaniec dostał Bukłak i Suszone mięso w talii):

| Klasa | Wygrane |
|---|---:|
| Zielarka | 26/30 |
| Skaut | 24/30 |
| Wędrowiec | 22/30 |
| Strateg | 22/30 |
| Łowca | 20/30 |
| Budowlaniec | 19/30 |
| Kucharz | 17/30 |
| Wojskowy | 8/30 |
| Informatyk | 4/30 |

Informatyk ma być trudny (challenge). Wojskowy ginie z głodu (malus +1/dzień) —
kandydat do przyjrzenia się po ręcznym playteście.

## Biomy i plansza

✅ Plansza 3×2 losuje 6 kafli z puli **8 biomów**:

- Las
- Łąki
- Góry
- Bagno
- Rzeka
- Pustkowie
- Jaskinie
- Wybrzeże

✅ Każdy biom ma dane, sloty budynków, akcje zbierania, zdarzenia oraz
normalne i skażone tło.

✅ Modyfikatory kafla (`BiomeData.camp_*`) — kafel, na którym KOŃCZYSz dzień,
narzuca nocną presję, więc „gdzie obozować" to realna decyzja: Góry/Jaskinie
(−1 ciepła nocą), Pustkowie (−1 nawodnienia), Bagno (30% ryzyka choroby = −2
zdrowia); biomy bezpieczne (Las/Łąki/Rzeka/Wybrzeże) neutralne. Schron na danym
kaflu łagodzi utratę ciepła i ryzyko choroby. Prognoza nocy uwzględnia te spadki.

✅ Fog of war: run zaczyna się z jednym odkrytym kaflem, a wejście na sąsiada
odsłania jego zawartość.

🟡 Karty eksploracji działają, ale nie istnieje jeszcze pełny interfejs
podglądu/oznaczania nieodkrytych kafli przed ruchem.

## Budynki

✅ **19 budynków**:

- Akt I / ogólne: Ognisko, Szałas, Studnia, Farma, Port rybacki, Spiżarnia,
  Pułapki, Drwalnia, Magazyn drewna, Kamieniołom, Warsztat, Filtr wodny,
  Zielarnia, Palisada i Wieża obserwacyjna;
- dedykowana odbudowa Aktu II: Bastion, Cysterna, Szpital polowy i
  Wzmocnione schronienie.

✅ Budynki są wybierane z katalogu, umieszczane w slotach biomu i mają HP.

✅ Działają:

- limity magazynowe zasobów;
- produkcja dzienna;
- ochrona nocna;
- spowolnienie psucia;
- przeróbka drewna na materiały;
- naprawa, ruina i rozbiórka;
- zabezpieczenie rejonu przed BUM: limit 2 kafli, wysoki koszt kamienia,
  energii i drewna, obrys na planszy oraz tooltip z efektem;
- dopłata za zwykłą budowę po BUM;
- tańsze warianty odbudowy dostępne tylko w Akcie II.

## Karty akcji

✅ **74 karty akcji** łącznie (54 top-level, 9 sygnaturowych, 7 ulepszeń,
4 skażone).

✅ **47 kart** w głównej puli nagród (top-level minus 7 kart `gather_only`:
akcje biomów Poluj/Wędkowanie/Sidła/Suchy chrust/Rąb drewno/Wydobycie kamienia
oraz Szukaj kamienia — fallback wyłącznie talii startowych).

✅ **4 skażone akcje biomów** używane po BUM.

✅ **9 kart sygnaturowych** klas.

✅ Każda karta akcji ma własną, unikalną ilustrację (74/74); jedyny alias artu
to `find_water → action_spring_source`.

✅ System ulepszania kart (`upgrade_id`): nagroda awansu może PODMIENIĆ posiadaną
kartę na mocniejszy wariant (7 wariantów w `data/cards/actions/upgrades/`), zamiast
tylko dorzucać nową — talia ewoluuje. Pozostałe nagrody: nowa karta, +max HP, +max
energii.

## Zdarzenia nocne

✅ **146 zasobów zdarzeń**:

- 34 karty bazowe, pogodowe i omeny (`data/cards/events/`);
- 76 zdarzeń biomowych (`events/biome/` — atmosferyczne + skażone, gated fog of war);
- 11 zdarzeń Plagi;
- 9 zdarzeń Zaćmienia;
- 8 zdarzeń Powodzi;
- 8 zdarzeń Pęknięcia.

✅ `NightEventPool` obsługuje wagi, cooldowny, limity wystąpień, fazy runu,
sezony, odkryte biomy, katastrofę i potwory.

✅ Omeny zaczynają się przed możliwym BUM.

✅ Nocna karta ma animowany rewers, reveal i front. Efekt jest rozliczany
dopiero po potwierdzeniu przez gracza.

✅ Zdarzenia z wyborami prezentują wynik decyzji przed przejściem dalej.

✅ Ilustracje zdarzeń biomowych i katastroficznych są obecne oraz zaimportowane.

## Katastrofy i potwory

✅ BUM następuje losowo o świcie dnia **20–26** (omeny 6 dni wcześniej). Dłuższy
Akt I daje czas na zbudowanie bazy i świadome zabezpieczenie wybranych rejonów.

✅ BUM odwraca planszę, uruchamia sekwencję FX i uszkadza budynki o 35–80%.
Zabezpieczony rejon obniża rzut obrażeń o 30%, po czym zabezpieczenie znika.

✅ Cztery katastrofy:

- Plaga — większy głód i szybsze psucie;
- Zaćmienie — większa utrata ciepła i mniej energii;
- Powódź — zimno oraz psucie zapasów;
- Pęknięcie — większe pragnienie i mniej energii.

✅ **15 potworów**, wszystkie przypisane do odpowiednich katastrof i posiadające
ilustracje.

✅ Akt II ma osobną paletę, muzykę i ambient zależny od katastrofy.

## Pory roku i balans runu

✅ Wiosna, lato, jesień i zima mają własne modyfikatory oraz HUD.

✅ Pogoda wizualna: deszcz, śnieg i zimowa winieta.

✅ Docelowy warunek zwycięstwa to przetrwanie do dnia 50.

🟡 Kontrolne smoke testy (2026-07-02, po przeglądzie kart): główny przebieg
**22/50** dla naiwnego bota, średnio 37,7 dnia; zgony: Akt I 8 (śr. dzień 10,3),
Akt II 20. Wyraźna poprawa względem 0/50 z 2026-07-01; Akt I wciąż powyżej
historycznego ideału ~0–2 zgonów — do obserwacji przy kolejnym strojeniu.

## UI, animacje i FX

✅ Główne ekrany: menu, run i wynik.

✅ HUD Aktu I/Aktu II, paski statystyk, dziennik, katalog budowy, popup kafla,
panel awansu, samouczek, ustawienia i galeria klas.

✅ Kafel zabezpieczonego rejonu ma ramkę na planszy, przycisk zabezpieczenia
pojawia się w prawym dolnym rogu aktualnego kafla, a tooltipy opisują koszt,
blokady i efekt.

✅ Wpięte FX:

- odkrywanie kafla;
- wielowarstwowe BUM;
- reveal nocnej karty;
- deszcz, śnieg i mróz;
- pazur potwora;
- leczenie i zdobywanie zasobów;
- postawienie i naprawa budynku;
- dym, ogień, ślady wypalenia i zawalenie ruiny;
- krytyczne HP;
- feedback jedzenia/picia;
- zwycięstwo i porażka.

✅ Ekran wyniku ma osobne tła zwycięstwa i porażki.

🟡 Dalszy polish może objąć czytelność tekstów na mniejszych oknach,
ujednolicenie tempa animacji i testy innych proporcji ekranu.

## Audio

✅ Muzyka menu, Aktu I, zwycięstwa oraz osobne utwory Aktu II dla czterech
katastrof.

✅ Ambient lasu i warianty Aktu II; Plaga korzysta obecnie z generycznego
ambientu Aktu II.

✅ SFX kart, budowy, naprawy, BUM, potwora, awansu, odkrycia, jedzenia,
picia, przycisku i przegranej.

🟡 Brak `coin.wav`; nagroda monety działa bez dźwięku.

🟡 `assets/audio/LICENSES.txt` to wypełniony manifest (23 pliki, źródło Suno Pro,
zweryfikowany 1:1 z dyskiem i kluczami AudioManager); creditsy w grze działają
(Menu → „Twórcy"). Przed publicznym wydaniem zostaje checklista prawna: potwierdzić
aktualny regulamin Suno dla użytego planu i zachować dowód subskrypcji z dat generacji.

✅ Muzyka została przekonwertowana z WAV do OGG Vorbis (`q=6`): 123,46 MB
→ 12,13 MB bez zmiany długości utworów. Ambient i krótkie SFX pozostają w WAV.

## Save/load i meta

✅ Autozapis runu na początku każdego dnia.

✅ „Kontynuuj” w menu i odbudowa systemów runtime przez `SurvivalSystem.resume`.

✅ Osobny zapis meta: monety, odblokowane klasy i informacja o obejrzeniu tutorialu.

✅ Test zapisu runu oraz osobny test kosztu, odblokowania i zapisu meta-progresji.

🟡 Brak ręcznego zapisu i wielu slotów. Zapis ma wersję schematu
(`RunState.SAVE_VERSION`) — niekompatybilny zapis jest odrzucany; migracji brak.

🔴 Brak kolekcji kart, odblokowań biomów/katastrof i drabinki trudności.

## Testy

✅ Czternaście testów headless:

1. `smoke_test.gd`
2. `fog_of_war_test.gd`
3. `season_test.gd`
4. `board_test.gd`
5. `load_test.gd`
6. `ui_layout_test.gd`
7. `night_pool_test.gd`
8. `save_load_test.gd`
9. `meta_progression_test.gd`
10. `audio_test.gd`
11. `card_upgrade_test.gd`
12. `hand_draw_test.gd`
13. `biome_camp_test.gd`
14. `bum_preparation_test.gd`

Pokrywają pełne runy, wszystkie klasy, 200 plansz, dane `.tres`, 100 wariantów
kart UI, pory roku, fog of war, pulę nocy, oba rodzaje zapisu, konfigurację audio,
ulepszenia kart, owned-only dobór ręki, flagę `gather_only`, modyfikatory kafla
oraz przygotowanie rejonów na BUM.

✅ CI uruchamia testy + build Windows + release na tagach
(`.github/workflows/godot-ci.yml`).

## Najbliższe priorytety

1. Balans Aktu II po BUM 20–26, zabezpieczeniach rejonów i droższej decyzji
   przygotowawczej.
2. Dowód subskrypcji Suno z dat generacji (checklista w `assets/audio/LICENSES.txt`).
3. Dalsza meta-progresja (kolekcja, odblokowania) i pełny zwiad nieodkrytych biomów.
