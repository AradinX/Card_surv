# Inwentarz „Dzień 50” — co jest, czego brakuje

Żywy spis zawartości gry. Stan: **2026-06-30**.

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
| Automatyczne testy Godot | ✅ 13 testów |
| Balans klas i aktów | 🟡 |
| Eksport/CI | ✅ |
| Dokumentacja licencji audio | 🟡 (manifest gotowy, weryfikacja prawna przed wydaniem) |

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

🟡 Aktualny sygnał balansowy z 30 runów bota na klasę:

| Klasa | Wygrane |
|---|---:|
| Zielarka | 27/30 |
| Skaut | 27/30 |
| Wojskowy | 20/30 |
| Wędrowiec | 20/30 |
| Budowlaniec | 18/30 |
| Łowca | 17/30 |
| Kucharz | 15/30 |
| Strateg | 12/30 |
| Informatyk | 4/30 |

To nie jest finalny balans. Informatyk ma być trudny, ale rozrzut wymaga
playtestów człowieka.

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
- dopłata za zwykłą budowę po BUM;
- tańsze warianty odbudowy dostępne tylko w Akcie II.

## Karty akcji

✅ **74 karty akcji** łącznie (54 top-level, 9 sygnaturowych, 7 ulepszeń,
4 skażone).

✅ **50 kart** w głównej puli nagród (top-level minus 4 karty `gather_only`
przypięte do biomu — Poluj/Wędkowanie/Sidła/Suchy chrust nie wpadają już do
nagród awansu).

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

✅ BUM następuje losowo o świcie dnia **11–14** (omeny od dnia 8). Uwaga: przy
mecie w dniu 50 Akt II zajmuje większość runu — to oś balansu do strojenia.

✅ BUM odwraca planszę, uruchamia sekwencję FX i uszkadza budynki o 35–80%.

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

🟡 Kontrolne smoke testy (2026-06-30): główny przebieg **0/50** dla naiwnego bota.
Akt I jest dla niego bezpieczny (zgony ~0–1), całą śmiertelność bierze Akt II.
Próbka klasowa rozjeżdża się szeroko (Zielarka ~10/30, Strateg ~5/30, reszta
niżej). Świadomy gracz celuje wyżej niż bot.

## UI, animacje i FX

✅ Główne ekrany: menu, run i wynik.

✅ HUD Aktu I/Aktu II, paski statystyk, dziennik, katalog budowy, popup kafla,
panel awansu, samouczek, ustawienia i galeria klas.

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

🟡 Brak ręcznego zapisu, wielu slotów i wersjonowania/migracji starych zapisów.

🔴 Brak kolekcji kart, odblokowań biomów/katastrof i drabinki trudności.

## Testy

✅ Trzynaście testów headless:

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

Pokrywają pełne runy, wszystkie klasy, 200 plansz, dane `.tres`, 100 wariantów
kart UI, pory roku, fog of war, pulę nocy, oba rodzaje zapisu, konfigurację audio,
ulepszenia kart, owned-only dobór ręki oraz flagę `gather_only` i modyfikatory kafla.

✅ CI uruchamia wszystkie 13 testów + build Windows + release na tagach
(`.github/workflows/godot-ci.yml`).

## Najbliższe priorytety

1. Balans Aktu II (BUM 11–14, meta 50 → długi Akt II; bot 0/50) i strojenie klas.
2. Uzupełnienie licencji audio i creditsów.
3. Wersjonowanie/migracja zapisów.
4. Ograniczenie rozmiaru repozytorium.
5. Dalsza meta-progresja (kolekcja, odblokowania) i pełny zwiad nieodkrytych biomów.
