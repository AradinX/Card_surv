# Inwentarz „Dzień 50” — co jest, czego brakuje

Żywy spis zawartości gry. Stan: **2026-06-22**.

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
| Automatyczne testy Godot | ✅ 10 testów |
| Balans klas i aktów | 🟡 |
| Eksport/CI | 🔴 |
| Kompletna dokumentacja licencji | 🔴 |

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
3 monety i losuje jedną z zablokowanych klas.

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

✅ **27 kart** w głównej puli nagród.

✅ **2 skażone akcje biomów** używane po BUM.

✅ **9 kart sygnaturowych** klas.

✅ Wszystkie używane akcje mają ilustracje albo jawnie zdefiniowany alias artu.

🔴 Nie ma systemu ulepszania istniejących kart. Nagroda awansu dodaje nową
kartę, zwiększa maksymalne HP albo maksymalną energię.

## Zdarzenia nocne

✅ **70 zasobów zdarzeń**:

- 39 kart bazowych, pogodowych i omenów;
- 15 zdarzeń biomowych;
- 6 zdarzeń Plagi;
- 4 zdarzenia Zaćmienia;
- 3 zdarzenia Powodzi;
- 3 zdarzenia Pęknięcia.

✅ `NightEventPool` obsługuje wagi, cooldowny, limity wystąpień, fazy runu,
sezony, odkryte biomy, katastrofę i potwory.

✅ Omeny zaczynają się przed możliwym BUM.

✅ Nocna karta ma animowany rewers, reveal i front. Efekt jest rozliczany
dopiero po potwierdzeniu przez gracza.

✅ Zdarzenia z wyborami prezentują wynik decyzji przed przejściem dalej.

✅ Ilustracje zdarzeń biomowych i katastroficznych są obecne oraz zaimportowane.

## Katastrofy i potwory

✅ BUM następuje losowo o świcie dnia **22–27**.

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

🟡 Kontrolne smoke testy z 2026-06-22: **31–33/50 wygranych**. Wszystkie
porażki wydarzyły się po BUM. Akt I jest dla bota bardzo bezpieczny, a Akt II
odpowiada za całą śmiertelność.

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

🔴 `assets/audio/LICENSES.txt` nadal jest szablonem. Przed publicznym wydaniem
trzeba wpisać źródło, autora, licencję i datę dla każdego pliku oraz dodać
creditsy w grze.

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

✅ Dziesięć testów headless:

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

Pokrywają pełne runy, wszystkie klasy, 200 plansz, dane `.tres`, 100 wariantów
kart UI, pory roku, fog of war, pulę nocy, oba rodzaje zapisu i konfigurację audio.

🔴 Brak CI uruchamiającego testy po każdym pushu.

## Najbliższe priorytety

1. Ręczne playtesty i balans klas oraz obu aktów.
2. Presety eksportu Windows/Web i automatyczne testy CI.
3. Uzupełnienie licencji audio i creditsów.
4. Kompresja audio oraz ograniczenie rozmiaru repozytorium.
5. Wersjonowanie zapisów.
6. Dalsza meta-progresja i pełny zwiad nieodkrytych biomów.
