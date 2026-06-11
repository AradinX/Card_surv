# DZIEŃ 50 / DAY FIFTY (tytuł roboczy)

Karciany roguelike survivalowy 2D (pixelart UI), singleplayer.
Run trwa ~60-90 minut i ma dwuaktową strukturę: budowanie osady w walce
z naturą, przerwane katastrofą **BUM**, po której świat — i plansza —
zmieniają się na oczach gracza.

> **Status dokumentu:** koncept po pierwszej rundzie decyzji projektowych.
> Alternatywne tytuły: „Długi Sen / The Long Dream", „Deck of Days",
> „Przebudzenie / Wake".

---

## 1. Wizja i haczyk (elevator pitch)

Budzisz się w dziczy. Każda tura to dzień: grasz kartami akcji, stawiasz
budynki (które stają się kartami na stole) i przeżywasz pory roku na
planszy złożonej z losowych biomów. Gdy osada w końcu kwitnie — następuje
**BUM**: kafle mapy odwracają się na skorumpowane wersje, twoje budynki
płoną w sekundę, a do talii zdarzeń wtasowują się potwory. Przetrwaj do
dnia 50. Obudź się.

**Wyróżniki na tle innych karcianych roguelike'ów:**
1. Survival zamiast walki — przeciwnikiem są pory roku, głód i zimno,
   nie rzędy wrogów.
2. Osada jako karty fizycznie leżące na stole — widzisz, jak rośnie
   (i jak ginie).
3. Katastrofa w połowie runu, która przemeblowuje planszę, talię
   i zasady. Moment stworzony pod klipy/streamy.

## 2. Filary projektu

1. **Dwa akty, jeden run** — ta sama plansza, dramatycznie inna gra.
2. **Wszystko jest kartą** — akcje, budynki, zdarzenia, potwory, biomy
   (kafle). Zero animowanych postaci i mapy świata — zakres pod solo deva.
3. **Strata napędza emocje** — BUM niszczy to, co gracz zbudował,
   ale run jest na tyle krótki, że porażka zaprasza do kolejnej próby.
4. **Każdy run inny** — losowa plansza biomów, losowy typ katastrofy,
   odblokowywana różnorodność zamiast permanentnych ułatwień.

## 3. Plansza biomów (mapa runu)

- Plansza składa się z **6 kafli biomów** losowanych i układanych na
  starcie runu (siatka 3×2) z większej puli.
- Pula biomów (startowo ~8, do rozszerzania): Wybrzeże, Góry, Bagna,
  Las, Łąki, Jezioro, Jaskinie, Wzgórza.
- Każdy biom definiuje:
  - **dostępne karty zasobów** (Wybrzeże: ryby i woda; Góry: ruda
    i kamień; Bagna: zioła i torf...),
  - **modyfikatory zdarzeń** (Góry: ostrzejsza zima; Bagna: choroby;
    Wybrzeże: sztormy),
  - **sloty pod budynki: bazowo 3, zakres 2-4** (Łąki: 4, Góry: 2...).
    Przy 6 kaflach ~18 miejsc łącznie — celowy niedobór wymuszający
    decyzje o lokalizacji osady.
- **Pozycja i ruch gracza:** gracz stoi na jednym kaflu; przejście na
  sąsiedni kafel kosztuje **1 energię**. Karty zbierania zasobów działają
  tylko w bieżącym biomie; **pasywne efekty budynków są globalne**
  (Ognisko grzeje niezależnie od pozycji).
- **Po BUM kafle odwracają się** na skorumpowane wersje (Martwe
  Wybrzeże, Wyjące Góry...) z innymi zasobami i zagrożeniami.
- Synergia układu: sąsiedztwo kafli ma znaczenie (np. Farma na Łące
  obok Jeziora daje bonus) — głębia z prostych zasad.

## 4. Akt I — Narodziny (dni 1 - ~25-30)

- **Cel aktu:** rozwijać osadę i przygotować się na zimę / na to,
  co nadchodzi.
- Statystyki gracza: **HP, Głód, Pragnienie, Ciepło** — spadek któregoś
  do zera = obrażenia / śmierć.
- **Energia: 10 dziennie (bazowo).** Pętla dnia: dobierz rękę z talii
  akcji → graj karty za energię → efekty budynków → karta zdarzenia →
  koniec dnia (głód/pragnienie/ciepło tykają).
- **Poziomy postaci w obrębie runu:** XP za działania; awans = wybór
  1 z 3 nagród (+1 max energii / +max HP / ulepszenie karty z talii).
  Poziomy NIE przenoszą się między runami. Karty zdarzeń mogą dawać
  dodatkowe jednorazowe bonusy energii/statystyk.
- **Budynki = karty na stole**, przypisane do slotów kafli: Ognisko
  (+ciepło), Szałas (ochrona nocą), Spiżarnia (spowalnia psucie),
  Studnia (woda), Farma, Wędzarnia, Warsztat (odblokowuje lepsze karty).
- **Pory roku jako fazy talii zdarzeń:** wiosna → lato (upał, psucie
  jedzenia) → jesień (obfitość, przygotowania) → zima (mróz, śnieżyce,
  zamarznięta woda).
- **Foreshadowing** (zapowiedzi twista): od ~dnia 15 w talii zdarzeń
  pojawiają się sygnały — martwe ptaki, drżenie ziemi, łuna na
  horyzoncie, niespokojne sny. Gracz wie, że COŚ nadchodzi; nie wie
  kiedy ani co.

## 5. BUM (losowy moment, dzień ~25-30)

- **Fabularnie:** sen zamienia się w koszmar. Gracz nigdy nie widzi
  źródła — tylko eksplozję na niebie / upadek czegoś za horyzontem.
  Każdy typ katastrofy to inna twarz koszmaru.
- Mechanicznie: animacja na całej planszy — kafle odwracają się,
  a **każdy budynek losuje procent uszkodzeń**:
  - **< 50% uszkodzeń** → budynek uszkodzony: działa słabiej lub wcale,
    można go **naprawić** (koszt surowców proporcjonalny do uszkodzeń);
  - **≥ 50% uszkodzeń** → **ruina**: można tylko rozebrać, odzyskując
    ~50% surowców.
- **Typ katastrofy losowany z puli** (startowo 2-3, kolejne
  odblokowywane):
  - *Plaga* — zombie, gnijące biomy, choroby;
  - *Pęknięcie* — duchy i zjawy, kafle "wyciekają" mrokiem;
  - *Zaćmienie* — wieczna noc, mróz, stwory ciemności;
  - (pomysły na później: powódź, rój, "cisza").
- Każdy typ ma własne potwory, skorumpowane wersje kafli i własną
  strategię przetrwania → drugi run z innym BUM to inna gra.

## 6. Akt II — Po katastrofie (do dnia 50)

- Talia zdarzeń zostaje zainfekowana **kartami potworów**, które
  atakują nocą i **zadają obrażenia kartom budynków** (budynki mają HP;
  uszkodzenia naprawialne wg progu 50% jak przy BUM).
- Nowe karty: Palisada, Pułapki, Strażnica, Pochodnie (obrona),
  plus karty rozbiórki ruin (odzysk surowców z własnych zgliszcz).
- Statystyki przetrwania działają nadal — zima + fala potworów
  to szczyt trudności.
- **Cel: dotrwać do dnia 50.** Finał: budzisz się w domu. To był sen.
  *(Scena po napisach z elementem ze snu — do przemyślenia.)*

## 7. Klasy postaci

Start: tylko Kucharz. Kolejne klasy odblokowywane **przez wydarzenia
w runach** (spotykasz postać jako kartę zdarzenia, pomagasz jej —
dołącza do kolekcji jako grywalna klasa).

| Klasa | Atuty | Słabości | Profil |
|---|---|---|---|
| **Kucharz** | jedzenie odnawia +50% głodu; wolniejsze psucie zapasów | budowanie kosztuje +1 energii | bezpieczny start, ekonomia jedzenia |
| **Budowlaniec** | budynki tańsze w surowcach i z większym HP | jedzenie odnawia mniej głodu | osada-forteca, mocny po BUM |
| **Wojskowy** | karty obrony/pułapek silniejsze; mniejsze obrażenia od potworów | szybszy wzrost głodu; droższe budowanie | słabszy Akt I, dominuje w Akcie II |

Każda klasa = własna talia startowa (~10 kart) + 1-2 karty unikalne.

## 8. Meta-progresja między runami

Zasada projektowa: **odblokowujemy różnorodność, nie siłę.**
Permanentne ułatwienia psują roguelike'i. Zamiast tego:

- **Odblokowania (różnorodność):** nowe karty akcji i budynków
  (trafiają do puli losowań), nowe kafle biomów, nowe typy katastrof,
  klasy postaci (przez wydarzenia w runach — patrz sekcja 7).
- **Drabinka trudności (dobrowolna):** po wygranej odblokowuje się
  wyższy poziom z utrudnieniami (krótsze lato, szybszy głód,
  wcześniejszy BUM...) — wzorzec Ascension/Stake.
- **Waluta meta:** punkty za przebieg runu (dni przeżyte, poziom osady)
  wydawane na odblokowania — postęp jest nawet po przegranej.
- Śmierć = koniec runu, zawsze. Run trwa 60-90 min, więc to gatunkowa
  norma, nie kara.

## 9. Pozycjonowanie rynkowe

- Karciane roguelike'i to zatłoczony rynek, ale niemal w całości
  **bojowy** (klony Slay the Spire). Nisza survivalowa w tym gatunku
  jest płytko zagospodarowana.
- Sprzedaje grę: moment BUM (trailer!), osada z kart, plansza biomów.
- Grupa docelowa: gracze StS/Balatro szukający świeżego twista +
  fani survivali bez czasu na 60-godzinne sandboxy.
- Format idealny pod streamerów: pełny run w jednym materiale.

## 10. Plan produkcji (na bazie istniejącego prototypu!)

Prototyp z etapów 1-2 (pętla dnia, statystyki, karty akcji, talia
zdarzeń, mapa węzłów) to fundament — nie zaczynamy od zera.

### Vertical slice (cel nr 1)
- Przeróbka mapy węzłów na **planszę 6 kafli** (3-4 biomy w puli),
  ruch za 1 energię, sloty budynków 2-4.
- Budynki jako karty na stole z przypisaniem do slotów i HP.
- Statystyki: HP, Głód, Pragnienie, Ciepło; energia 10/dzień;
  uproszczone pory roku (po kilka kart na porę).
- Poziomy w runie: XP + wybór 1 z 3 przy awansie.
- **Jeden typ BUM** (Plaga): flip kafli, procentowe uszkodzenia
  budynków (próg 50%), 3-4 typy potworów, podstawowa obrona.
- Jedna klasa (Kucharz). Run skrócony do ~30 dni na czas testów.
- Cel testowy: czy Akt I wciąga sam w sobie i czy BUM robi wrażenie.

### Milestone'y dalsze
1. Pełna długość runu (50 dni), balans, synergie kafli.
2. Meta-progresja: waluta, odblokowania, ekran kolekcji;
   klasy Budowlaniec i Wojskowy + wydarzenia odblokowujące.
3. Drugi i trzeci typ katastrofy, kolejne biomy.
4. Drabinka trudności, polish, dźwięk, juice na moment BUM.

## 11. Technologia

- **Silnik:** Godot 4.x, GDScript ze statycznym typowaniem.
- **Workflow:** VS Code + Claude Code; CLAUDE.md jako żywa dokumentacja
  i changelog.
- Wszystkie dane (karty, kafle, klasy, katastrofy, potwory,
  odblokowania) jako zasoby/JSON oddzielone od logiki.
- RunState (stan runu, w tym poziomy postaci) oddzielony od MetaState
  (kolekcja, odblokowane klasy, drabinka) — MetaState wchodzi
  w milestone 2.
- Grafika: placeholder → pakiety pixelart (itch.io) → docelowo własne.

## 12. Otwarte pytania (pozostałe)

- [ ] Wielkość ręki kart i koszty energii poszczególnych akcji
      (do ustalenia w praktyce podczas balansu vertical slice'a).
- [ ] Ile XP za co i co dokładnie daje "poziom osady" w punktacji meta.
- [ ] Szczegóły wydarzeń odblokowujących Budowlańca i Wojskowego.
- [ ] Scena po napisach — czy element ze snu pojawia się w "realnym"
      pokoju?
- [ ] Ostateczny wybór tytułu: Dzień 50 / Day Fifty (faworyt),
      Długi Sen / The Long Dream, Deck of Days, Przebudzenie / Wake.
