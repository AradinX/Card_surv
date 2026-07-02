# Dzień 50 — większa baza kart v0.1

Baza pod `NightEventPool` / `.tres`: kontrolowane losowanie przez `category`, `severity`, `weight`, `cooldown_days`, `max_per_run`, `tags` i warunki aktywacji.

---

## STATUS WDROŻENIA — audyt Claude (2026-06-16)

Świetny roadmap, ale ~⅔ kart zakłada mechaniki, których w kodzie JESZCZE NIE MA.
Wdrożono **bezpieczny podzbiór 28 kart** (warunki „zbakowane" na stałe efekty,
bo silnik nie umie warunkowych mitygacji/losowości/obrażeń budynku ze zdarzeń).

**✅ WDROŻONE (28):**
- NEUTRAL (4): Czyste gwiazdy, Stare ślady, Małe znalezisko, Cicha praca nocą.
- WEATHER (9): Porywisty wiatr, Suchy upał, Długa mżawka, Przymrozek, Rozmokła
  ziemia, Ciepły wiatr, Nocna wilgoć, Biała ściana, Łagodny deszcz.
- OMEN (6): Martwe ptaki, Drżenie ziemi, Łuna na horyzoncie, Niespokojny sen,
  Czarne krople, Cisza zwierząt — kategoria `omen` pojawia się TYLKO w oknie
  dzień≥7 → BUM (faza OMEN ×5, ACT1/ACT2 ×0).
- BIOME (5, wpięte w `extra_event_cards` 3 istniejących biomów): Dzik w
  ciemności + Zgubiony szlak (Las), Ciężki pyłek + Chłód otwartego nieba (Łąki),
  Rzadkie powietrze (Góry).
- DISASTER/Plaga (4, wpięte w `plague.tres`): Zarodniki w powietrzu, Skażona
  studnia, Larwy w drewnie, Gorączka.

**🔴 ZABLOKOWANE — wymaga nowych systemów (zostaje tu jako roadmap):**
- **Karty sezonowe** (`pora roku: …`) — brak gatingu sezonowego w puli (zagrałyby
  w złej porze). Potrzebny warunek aktywacji per `season`.
- **Biomy Wybrzeże/Jezioro/Bagna/Jaskinie/Pustkowie** — nie istnieją (są Las/
  Łąki/Góry). Karty tych biomów czekają na biomy.
- **Katastrofy Pęknięcie i Zaćmienie + ich eventy i potwory** — jest tylko Plaga.
  Trzeba dodać `DisasterData` + potwory, wtedy ich eventy/potwory wejdą.
- **Obrażenia budynku ze zdarzenia** (gradobicie, osuwisko, „X obrażeń budynku") —
  dziś tylko potwory ranią budynki. Trzeba pole `building_damage` w `EventCardData`.
- **Losowość** („50% szansy", „losowo +1 X") — efekty są stałe. Trzeba RNG w
  rozliczaniu eventów.
- **Mitygacje warunkowe budynków** („Filtr/Zielarnia/Spiżarnia redukuje") oraz
  blokady pasywów — dziś tylko Szałas (schronienie). Wdrożone karty mają te
  klauzule USUNIĘTE (działa goły efekt).
- **Bonusy wagi między nocami** („+1 wagi katastrofy następnej nocy", omen_boost)
  i **specjale potworów** (traity) — brak.

**⚖️ BALANS:** po dodaniu kart smoke wzrósł do ~86% (cel ~60–66%). Dużo kart
minor/neutral ROZCIEŃCZA rzadkie majory → noce łagodnieją. Do osobnego przejścia
balansowego (podbić wagi/severity kar albo wzmocnić Akt II / BUM).

---

## Podsumowanie

- Event cards: **108**
- Monsters: **24**
- Disaster definitions: **3**
- Kategorie zgodne z obecną logiką: `neutral`, `weather`, `biome`, `omen`, `disaster`; potwory jako osobny typ danych, ale w puli nocnej mogą mieć kategorię `monster`.
- Pory roku są zrobione jako tagi/warunki (`season:spring`, `season:summer`, `season:autumn`, `season:winter`), żeby nie dokładać nowej kategorii do enuma.

## Rekomendowany target do wdrożenia najpierw

1. Dodać wszystkie `omen` — obecnie to największa dziura, a system już ma kategorię.
2. Dodać po 4–6 kart sezonowych na porę roku.
3. Rozszerzyć Plagę o dodatkowe eventy + 4 nowe potwory.
4. Dopiero potem dodać drugą katastrofę: `Pęknięcie` albo `Zaćmienie`.


## NEUTRAL (15)

| Karta | Sev | Faza | Warunek | Efekt | Schronienie | Waga | CD | Max | Tagi |
|---|---|---|---|---|---|---|---|---|---|
| Spokojny wieczór | minor | ACT1 | global | Brak negatywnego efektu. Gracz ma chwilę oddechu. | nie | 24 | 0 | 0 | safe, pacing |
| Czyste gwiazdy | minor | ACT1 | global | +1 ciepła; następnego dnia +1 energii. | nie | 12 | 2 | 3 | rest, warmth |
| Sowa na skraju lasu | minor | ACT1 | odkryty Las lub Łąki | Brak obrażeń. Dziennik dodaje ostrzeżenie; dobra karta do budowania klimatu. | nie | 10 | 2 | 0 | flavor, forest |
| Stare ślady | minor | ACT1 | global | +1 drewna albo +1 materiału losowo; bez kary. | nie | 10 | 3 | 3 | resource |
| Żar pod popiołem | minor | ACT1 | masz Ognisko | +2 ciepła. Jeżeli brak Ogniska: +1 ciepła. | nie | 9 | 3 | 3 | building:campfire, warmth |
| Cicha praca nocą | minor | ACT1 | global | Następnego dnia +1 energia, ale -1 ciepła. | nie | 8 | 3 | 3 | energy, tradeoff |
| Małe znalezisko | minor | ACT1 | global | +1 jedzenia albo +1 wody losowo. | nie | 11 | 2 | 4 | resource |
| Łagodny deszcz | minor | ACT1 | global | +1 woda, -1 ciepła. | nie | 10 | 2 | 0 | water, weather_light |
| Młode pędy | minor | ACT1 | pora roku: Wiosna | +1 jedzenie. | nie | 12 | 2 | 3 | season:spring, food, season |
| Wczesny rozkwit | minor | ACT1 | pora roku: Wiosna | +1 jedzenie, +1 zdrowie. | nie | 8 | 4 | 2 | season:spring, good, season |
| Długi dzień | minor | ACT1 | pora roku: Lato | Następnego dnia +1 energia. | nie | 11 | 3 | 3 | season:summer, energy, season |
| Ciepła noc | minor | ACT1 | pora roku: Lato | +1 ciepła, ale -1 nawodnienia. | nie | 10 | 2 | 0 | season:summer, tradeoff, season |
| Żołędzie pod stopami | minor | ACT1 | pora roku: Jesień | +2 jedzenia. | nie | 11 | 3 | 2 | season:autumn, food, season |
| Grzybowa noc | minor | ACT1 | pora roku: Jesień | +1 jedzenie; 25% ryzyka -1 zdrowia, jeśli dodasz losowość. | nie | 9 | 3 | 2 | season:autumn, food, risk, season |
| Ostatnie przygotowania | minor | ACT1 | pora roku: Jesień | +1 drewno, +1 materiał. | nie | 8 | 4 | 2 | season:autumn, resource, season |

## WEATHER (30)

| Karta | Sev | Faza | Warunek | Efekt | Schronienie | Waga | CD | Max | Tagi |
|---|---|---|---|---|---|---|---|---|---|
| Gęsta mgła | minor | ACT1 | global | -1 energii następnego dnia. | nie | 12 | 2 | 0 | fog |
| Ulewa | medium | ACT1 | global | -1 zdrowia, -1 ciepła, +1 woda. Schronienie redukuje karę zdrowia/ciepła. | tak | 9 | 2 | 0 | rain, water |
| Zimna noc | medium | ACT1 | global | -3 ciepła. Schronienie redukuje stratę. | tak | 9 | 2 | 0 | cold |
| Burza | major | ACT1 | global | -3 zdrowia. Schronienie redukuje obrażenia. | tak | 7 | 3 | 2 | storm |
| Porywisty wiatr | minor | ACT1 | global | -1 ciepła; jeżeli masz Wieżę obserwacyjną, brak efektu. | tak | 11 | 2 | 0 | wind, building:watchtower |
| Gradobicie | medium | ACT1 | global | -1 zdrowia i 1 obrażenie losowego budynku. Schronienie chroni gracza, nie budynek. | tak | 8 | 3 | 2 | hail, building_damage |
| Suchy upał | medium | ACT1 | global | -2 nawodnienia; następnego dnia -1 energia. | nie | 8 | 3 | 2 | heat, summer |
| Długa mżawka | minor | ACT1 | global | +2 wody, -2 ciepła. | tak | 9 | 2 | 2 | rain, water |
| Przymrozek | medium | ACT1 | global | -2 ciepła; Studnia nie daje pasywu wody tej nocy/dnia, jeżeli wprowadzisz blokady budynków. | tak | 8 | 3 | 2 | frost, well |
| Biała ściana | major | ACT1 | global | -2 ciepła i -1 energia następnego dnia; brak ruchu zwiadowczego następnego dnia, jeżeli dodasz taką flagę. | tak | 6 | 4 | 1 | snow, winter, major_weather |
| Ciężkie chmury | minor | ACT1 | global | Brak strat, ale omeny/katastrofy mają +1 wagi następnej nocy. | nie | 8 | 3 | 2 | pacing, omen_boost |
| Rozmokła ziemia | minor | ACT1 | global | Następnego dnia pierwszy ruch kosztuje +1 energii; prostsza wersja: -1 energia następnego dnia. | nie | 10 | 2 | 0 | rain, movement |
| Piorun w oddali | medium | ACT1 | global | 50% szansy: -2 drewna; jeśli brak drewna, -1 zdrowia. | nie | 7 | 4 | 2 | storm, resource_loss |
| Ciepły wiatr | minor | ACT1 | global | +1 ciepła, ale -1 nawodnienia. | nie | 9 | 2 | 0 | warm, tradeoff |
| Marznący deszcz | major | ACT1 | global | -2 ciepła, -1 zdrowia, 1 obrażenie losowego budynku. | tak | 5 | 4 | 1 | rain, frost, building_damage |
| Nocna wilgoć | minor | ACT1 | global | -1 ciepła; jeżeli masz Spiżarnię, -1 jedzenia przez zawilgocenie zapasów. | tak | 9 | 2 | 2 | humidity, pantry |
| Roztopy | medium | ACT1 | pora roku: Wiosna | -1 ciepła, +2 woda. | tak | 9 | 3 | 2 | season:spring, water, season |
| Błotniste ścieżki | minor | ACT1 | pora roku: Wiosna | Następnego dnia -1 energia. | nie | 10 | 2 | 2 | season:spring, movement, season |
| Zimny wiosenny deszcz | medium | ACT1 | pora roku: Wiosna | -2 ciepła, +1 woda. | tak | 8 | 3 | 2 | season:spring, rain, season |
| Psujące się zapasy | medium | ACT1 | pora roku: Lato | -2 jedzenia; Spiżarnia redukuje do -1. | nie | 8 | 3 | 3 | season:summer, food_loss, pantry, season |
| Fala upału | major | ACT1 | pora roku: Lato | -3 nawodnienia; Filtr/Studnia łagodzą o 1, jeśli wprowadzisz synergię. | nie | 6 | 5 | 1 | season:summer, heat, major, season |
| Wyschnięte źródło | medium | ACT1 | pora roku: Lato | -1 woda i -1 nawodnienia. | nie | 8 | 3 | 2 | season:summer, water_loss, season |
| Mokre liście | minor | ACT1 | pora roku: Jesień | Następnego dnia -1 energia. | nie | 10 | 2 | 2 | season:autumn, movement, season |
| Jesienna ulewa | medium | ACT1 | pora roku: Jesień | -1 ciepła, +2 woda. | tak | 9 | 2 | 2 | season:autumn, rain, season |
| Pierwszy chłód | medium | ACT1 | pora roku: Jesień | -2 ciepła. | tak | 9 | 2 | 2 | season:autumn, cold, season |
| Śnieżyca | major | ACT1 | pora roku: Zima | -3 ciepła, -1 energia następnego dnia. Schronienie redukuje ciepło. | tak | 6 | 4 | 2 | season:winter, snow, major, season |
| Zamarznięta studnia | medium | ACT1 | pora roku: Zima | -1 woda; jeśli masz Filtr, brak straty. | nie | 8 | 3 | 2 | season:winter, well, water_loss, season |
| Bezchmurny mróz | medium | ACT1 | pora roku: Zima | -2 ciepła, +1 energia następnego dnia. | tak | 8 | 3 | 2 | season:winter, cold, tradeoff, season |
| Głęboki śnieg | minor | ACT1 | pora roku: Zima | Następnego dnia -1 energia. | nie | 10 | 2 | 0 | season:winter, movement, season |
| Długa noc | major | ACT1 | pora roku: Zima | -2 ciepła, -1 zdrowia. Schronienie redukuje oba efekty. | tak | 6 | 4 | 1 | season:winter, dark, major, season |

## BIOME (27)

| Karta | Sev | Faza | Warunek | Efekt | Schronienie | Waga | CD | Max | Tagi |
|---|---|---|---|---|---|---|---|---|---|
| Trzask gałęzi | minor | ACT1 | odkryty biom: Las | -1 energia następnego dnia; jeśli masz Wieżę obserwacyjną, brak efektu. | nie | 10 | 2 | 0 | forest, warning |
| Dziki w ciemności | medium | ACT1 | odkryty biom: Las | -1 zdrowia i -1 jedzenia. Schronienie redukuje zdrowie. | tak | 8 | 3 | 2 | forest, animal |
| Zgubiony szlak | medium | ACT1 | odkryty biom: Las | Następnego dnia -2 energia. | nie | 7 | 3 | 2 | forest, movement |
| Myszy w trawie | minor | ACT1 | odkryty biom: Łąki | -1 jedzenia, ale +1 materiałów z porzuconych resztek. | nie | 10 | 2 | 0 | meadow, food_loss |
| Ciężki pyłek | medium | ACT1 | odkryty biom: Łąki | -1 zdrowia, -1 energia następnego dnia. | nie | 8 | 3 | 2 | meadow, sickness |
| Chłód otwartego nieba | minor | ACT1 | odkryty biom: Łąki | -2 ciepła. Schronienie redukuje stratę. | tak | 9 | 2 | 0 | meadow, cold |
| Spadające kamienie | medium | ACT1 | odkryty biom: Góry | -1 zdrowia i 2 obrażenia losowego budynku w Górach. | tak | 8 | 3 | 2 | mountains, building_damage |
| Rzadkie powietrze | minor | ACT1 | odkryty biom: Góry | Następnego dnia -1 energia. | nie | 10 | 2 | 0 | mountains, energy |
| Osuwisko | major | ACT1 | odkryty biom: Góry | -2 zdrowia; jeden slot budynku w Górach dostaje +2 obrażeń, jeśli zajęty. | tak | 5 | 5 | 1 | mountains, major, building_damage |
| Słony wiatr | minor | ACT1 | odkryty biom: Wybrzeże | -1 nawodnienia; +1 jedzenia, jeśli masz Port rybacki. | nie | 9 | 2 | 0 | coast, fishing_port |
| Wysoka fala | medium | ACT1 | odkryty biom: Wybrzeże | -1 drewna, -1 ciepła. Schronienie redukuje ciepło. | tak | 8 | 3 | 2 | coast, water |
| Nocny sztorm | major | ACT1 | odkryty biom: Wybrzeże | -2 zdrowia i 2 obrażenia losowego budynku na Wybrzeżu. | tak | 5 | 5 | 1 | coast, storm, building_damage |
| Mgła nad jeziorem | minor | ACT1 | odkryty biom: Jezioro | -1 energia następnego dnia, +1 woda. | nie | 10 | 2 | 0 | lake, fog |
| Cienki lód | medium | ACT1 | odkryty biom: Jezioro | -1 zdrowia, -1 ciepła; tylko zimą major. | tak | 8 | 3 | 2 | lake, winter |
| Chmara komarów | medium | ACT1 | odkryty biom: Jezioro/Bagna | -1 zdrowia; max 3 na run. | nie | 7 | 3 | 3 | lake, swamp, insects |
| Trujące opary | medium | ACT1 | odkryty biom: Bagna | -2 zdrowia; Zielarnia redukuje o 1. | nie | 7 | 4 | 2 | swamp, poison, herbalist |
| Pijawki | minor | ACT1 | odkryty biom: Bagna | -1 zdrowia, +1 jedzenia, jeśli zaryzykujesz zbiór; prosta wersja: -1 zdrowia. | nie | 9 | 2 | 3 | swamp |
| Bagienna choroba | major | ACT1 | odkryty biom: Bagna | -2 zdrowia, -1 energia następnego dnia. Max 2 na run. | nie | 5 | 5 | 2 | swamp, disease, major |
| Echo pod ziemią | minor | ACT1 | odkryty biom: Jaskinie | Brak obrażeń; następne zdarzenie monster/disaster ma +1 wagi. | nie | 9 | 3 | 2 | caves, omen_boost |
| Pęknięcie stropu | medium | ACT1 | odkryty biom: Jaskinie | -1 zdrowia i -1 materiałów. | tak | 8 | 3 | 2 | caves, materials_loss |
| Chłód z głębi | medium | ACT1 | odkryty biom: Jaskinie | -3 ciepła. Schronienie redukuje stratę. | tak | 7 | 3 | 2 | caves, cold |
| Kwaśny pył | medium | ACT1 | odkryty biom: Pustkowie | -1 zdrowia, -1 ciepła, -1 woda. | nie | 7 | 4 | 2 | wasteland, dust |
| Martwy horyzont | minor | ACT1 | odkryty biom: Pustkowie | -1 morale/klimat; prosta wersja: -1 energia następnego dnia. | nie | 9 | 3 | 2 | wasteland, energy |
| Pękająca ziemia | major | ACT1 | odkryty biom: Pustkowie | -2 zdrowia i 2 obrażenia losowego budynku. | tak | 5 | 5 | 1 | wasteland, building_damage, major |
| Wiosenna gorączka | medium | ACT1 | pora roku: Wiosna + Łąki/Bagna | -1 zdrowia. | nie | 7 | 4 | 2 | season:spring, disease, season |
| Rój owadów | medium | ACT1 | pora roku: Lato + Bagna/Jezioro/Łąki | -1 zdrowia, -1 jedzenia. | nie | 7 | 3 | 2 | season:summer, insects, season |
| Zwierzyna zniknęła | medium | ACT1 | pora roku: Zima + Las/Łąki/Góry | -1 jedzenie; akcje polowania następnego dnia mogą dawać -1 mniej. | nie | 7 | 3 | 2 | season:winter, food_loss, season |

## OMEN (12)

| Karta | Sev | Faza | Warunek | Efekt | Schronienie | Waga | CD | Max | Tagi |
|---|---|---|---|---|---|---|---|---|---|
| Martwe ptaki | minor | OMEN | dzień >= 7 / okno omenów | Na ścieżce leżą czarne ptaki. Brak bezpośredniej kary; +1 wagi katastrofy w kolejnej nocy. | nie | 11 | 2 | 1 | omen, plague |
| Drżenie ziemi | minor | OMEN | dzień >= 7 / okno omenów | -1 ciepła; log sugeruje nadchodzący BUM. | nie | 10 | 2 | 1 | omen, fracture |
| Łuna na horyzoncie | minor | OMEN | dzień >= 7 / okno omenów | Następnego dnia -1 energia, ale +1 materiał z popiołu. | nie | 10 | 2 | 1 | omen, eclipse |
| Niespokojny sen | medium | OMEN | dzień >= 7 / okno omenów | -1 zdrowia, -1 energia następnego dnia. | nie | 8 | 3 | 1 | omen, dream |
| Czarne krople | medium | OMEN | dzień >= 7 / okno omenów | -1 ciepła, -1 woda. Schronienie redukuje ciepło. | nie | 8 | 3 | 1 | omen, rain |
| Cisza zwierząt | minor | OMEN | dzień >= 7 / okno omenów | Brak kary; następnej nocy neutralne karty mają mniejszą wagę. | nie | 10 | 2 | 1 | omen, pacing |
| Pęknięte gwiazdy | medium | OMEN | dzień >= 7 / okno omenów | -2 ciepła. Wskazuje Pęknięcie. | nie | 7 | 3 | 1 | omen, fracture |
| Popiół o świcie | minor | OMEN | dzień >= 7 / okno omenów | +1 materiał, -1 nawodnienia. | nie | 9 | 2 | 1 | omen, resource |
| Zapach zgnilizny | medium | OMEN | dzień >= 7 / okno omenów | -1 zdrowia; jeśli masz Zielarnię, brak straty. | nie | 8 | 3 | 1 | omen, plague, herbalist |
| Odwrócony księżyc | medium | OMEN | dzień >= 7 / okno omenów | -1 ciepła, -1 energia następnego dnia. | nie | 7 | 3 | 1 | omen, eclipse |
| Karta bez tekstu | minor | OMEN | dzień >= 7 / okno omenów | Brak efektu, ale bardzo mocny klimat przed BUM. Max 1 na run. | nie | 6 | 0 | 1 | omen, meta |
| Ktoś woła po imieniu | medium | OMEN | dzień >= 7 / okno omenów | -1 zdrowia; w Akcie II zamienia się w kartę potwora zależną od katastrofy. | nie | 6 | 4 | 1 | omen, monster_seed |

## DISASTER (24)

| Karta | Sev | Faza | Warunek | Efekt | Schronienie | Waga | CD | Max | Tagi |
|---|---|---|---|---|---|---|---|---|---|
| Gnijące zapasy | medium | ACT2 | katastrofa: Plaga | -2 jedzenia. Spiżarnia redukuje do -1. | nie | 8 | 2 | 0 | plague, food_loss |
| Koszmary | medium | ACT2 | katastrofa: Plaga | -1 zdrowia, -1 energia następnego dnia. | nie | 8 | 2 | 0 | plague, dream |
| Zarodniki w powietrzu | medium | ACT2 | katastrofa: Plaga | -1 zdrowia, -1 ciepła. | nie | 7 | 3 | 3 | plague, poison |
| Skażona studnia | major | ACT2 | katastrofa: Plaga | -2 wody i -1 zdrowia; Filtr redukuje stratę wody. | nie | 5 | 5 | 2 | plague, water_loss, filter |
| Larwy w drewnie | medium | ACT2 | katastrofa: Plaga | -2 drewna; jeśli brak drewna, 1 obrażenie losowego budynku. | nie | 7 | 3 | 2 | plague, wood_loss, building_damage |
| Gorączka | major | ACT2 | katastrofa: Plaga | -2 zdrowia, -1 energia następnego dnia. Zielarnia redukuje zdrowie o 1. | nie | 5 | 5 | 2 | plague, disease, herbalist |
| Martwe mięso | medium | ACT2 | katastrofa: Plaga | -1 jedzenia, -1 zdrowia jeśli gracz nie ma zapasu wody. | nie | 7 | 3 | 3 | plague, food |
| Czarna pleśń | medium | ACT2 | katastrofa: Plaga | 1 obrażenie wszystkim budynkom produkcji jedzenia albo losowemu budynkowi w prostej wersji. | nie | 6 | 4 | 2 | plague, building_damage |
| Szepty spod ziemi | medium | ACT2 | katastrofa: Pęknięcie | -1 zdrowia, -1 ciepła. | nie | 8 | 2 | 0 | fracture, spirit |
| Zimne światło | medium | ACT2 | katastrofa: Pęknięcie | -2 ciepła; Ognisko redukuje o 1. | tak | 7 | 3 | 3 | fracture, cold |
| Duch w palisadzie | medium | ACT2 | katastrofa: Pęknięcie | 2 obrażenia budynku z obroną; jeśli brak obrony, -1 zdrowia. | nie | 6 | 4 | 2 | fracture, defense_counter, building_damage |
| Poślizg rzeczywistości | major | ACT2 | katastrofa: Pęknięcie | Następnego dnia -2 energia. Max 2 na run. | nie | 5 | 5 | 2 | fracture, energy |
| Otwarta rysa | major | ACT2 | katastrofa: Pęknięcie | -2 zdrowia i 2 obrażenia losowego budynku. | tak | 5 | 5 | 1 | fracture, major, building_damage |
| Zgubiona godzina | minor | ACT2 | katastrofa: Pęknięcie | Następnego dnia -1 energia, ale +1 materiał. | nie | 8 | 3 | 2 | fracture, tradeoff |
| Fałszywe wspomnienia | medium | ACT2 | katastrofa: Pęknięcie | -1 zdrowia; kolejna karta omen/disaster ma +1 wagi. | nie | 7 | 3 | 3 | fracture, mind |
| Ciche zawalenie | major | ACT2 | katastrofa: Pęknięcie | 3 obrażenia losowego budynku; nie rani gracza. | nie | 5 | 5 | 2 | fracture, building_damage |
| Poranek bez słońca | medium | ACT2 | katastrofa: Zaćmienie | -2 ciepła, -1 energia następnego dnia. | tak | 8 | 2 | 0 | eclipse, dark |
| Czarne słońce | major | ACT2 | katastrofa: Zaćmienie | -2 zdrowia, -2 ciepła. Max 1 na run. | tak | 4 | 0 | 1 | eclipse, major |
| Gasnące ognisko | medium | ACT2 | katastrofa: Zaćmienie | Ognisko nie daje ciepła tej nocy; prosta wersja: -2 ciepła. | tak | 7 | 3 | 3 | eclipse, campfire |
| Zamarznięty oddech | medium | ACT2 | katastrofa: Zaćmienie | -1 zdrowia, -1 ciepła. | tak | 8 | 2 | 0 | eclipse, cold |
| Łowy w cieniu | major | ACT2 | katastrofa: Zaćmienie | Dobierz dodatkowego potwora albo prosta wersja: -2 zdrowia. | tak | 5 | 5 | 2 | eclipse, monster_boost |
| Woda pod lodem | medium | ACT2 | katastrofa: Zaćmienie | -2 wody; Filtr redukuje do -1. | nie | 7 | 3 | 3 | eclipse, water_loss |
| Gasnące światła | minor | ACT2 | katastrofa: Zaćmienie | Następnego dnia -1 energia; jeśli masz Wieżę, brak kary. | nie | 8 | 3 | 2 | eclipse, watchtower |
| Głębsza noc | major | ACT2 | katastrofa: Zaćmienie | -3 ciepła. Schronienie redukuje stratę. | tak | 5 | 4 | 2 | eclipse, cold, major |

## MONSTERS / POTWORY

| Potwór | Katastrofa | Sev | DMG gracz | DMG budynek | Kopie/waga | Tagi | Trait/notatka |
|---|---|---|---|---|---|---|---|
| Zgnilec | plague | medium | 2 | 2 | 2 | plague, undead | Bazowy potwór Plagi. |
| Zarażony wilk | plague | major | 3 | 0 | 2 | plague, beast | Rani gracza mocno, nie rusza budynków. |
| Krucza chmara | plague | minor | 1 | 1 | 2 | plague, swarm | Częsty słaby presser. |
| Rój szczurów | plague | medium | 0 | 3 | 2 | plague, swarm, building_damage | Atakuje zapasy/budynki, nie gracza. |
| Spuchły truposz | plague | major | 2 | 4 | 1 | plague, undead, building_damage | Rzadki niszczyciel budynków. |
| Nosiciel | plague | medium | 1 | 1 | 2 | plague, disease | Po ataku może dodać kartę Gorączka do puli. |
| Zgniły niedźwiedź | plague | major | 4 | 3 | 1 | plague, beast, elite | Elitarny potwór, max 1 kopia. |
| Rój much | plague | minor | 1 | 0 | 3 | plague, swarm | Mała kara, ale wysoka częstotliwość. |
| Blady świadek | fracture | minor | 1 | 1 | 2 | fracture, spirit | Klimatyczny potwór presser. |
| Duch drwala | fracture | medium | 1 | 3 | 2 | fracture, spirit, wood | Preferuje budynki z drewnem. |
| Pęknięty cień | fracture | medium | 2 | 1 | 2 | fracture, shadow | Standardowy wróg Pęknięcia. |
| Szepcząca zjawa | fracture | major | 2 | 0 | 2 | fracture, mind | Daje -1 energii następnego dnia jako efekt specjalny. |
| Kamienny upiór | fracture | major | 2 | 4 | 1 | fracture, stone, building_damage | Niszczy budynki obronne. |
| Lustro bez twarzy | fracture | medium | 0 | 2 | 1 | fracture, weird | Kopiuje ostatni efekt obrażeń budynku, jeśli dodasz logikę. |
| Wędrowiec spod ziemi | fracture | major | 3 | 2 | 1 | fracture, elite | Ignoruje część obrony, jeśli dodasz special. |
| Żywa rysa | fracture | medium | 1 | 2 | 2 | fracture, rift | Może aktywować event Otwarta rysa. |
| Czarny wilk | eclipse | major | 3 | 1 | 2 | eclipse, beast | Szybki nocny napastnik. |
| Lodowa mara | eclipse | medium | 1 | 2 | 2 | eclipse, cold, spirit | Po ataku -1 ciepła. |
| Ćma zaćmienia | eclipse | minor | 0 | 1 | 3 | eclipse, swarm | Niszczy światło/ognisko. |
| Bezoki łowca | eclipse | major | 4 | 0 | 1 | eclipse, elite | Wysokie obrażenia gracza. |
| Nocny jeleń | eclipse | medium | 2 | 2 | 2 | eclipse, beast | Równy presser. |
| Zimny pełzacz | eclipse | medium | 1 | 3 | 2 | eclipse, cold, building_damage | Atakuje budynki produkcyjne. |
| Głodny cień | eclipse | major | 2 | 2 | 1 | eclipse, shadow | Po ataku -1 jedzenia. |
| Księżycowy kruk | eclipse | minor | 1 | 0 | 3 | eclipse, bird | Słaby, ale częsty. |

## DISASTERS / KATASTROFY

| Katastrofa | Temat | Efekt BUM | Strategia gracza | Eventy | Potwory |
|---|---|---|---|---|---|
| Plaga | zgnilizna, choroby, skażone zasoby, presja na zdrowie i jedzenie | Flip wszystkich kafli na skażone wersje; budynki 10–80% uszkodzeń; HP poniżej 50% = ruina. | Budować Zielarnię, Filtr wodny, obronę i zapas jedzenia; walczyć z chorobą oraz psuciem zasobów. | plague_rotting_supplies, plague_nightmares, plague_spores, plague_infected_well, plague_larvae_in_wood, plague_fever, plague_dead_meat, plague_black_mold | rotter, infected_wolf, raven_swarm, rat_swarm, bloated_corpse, plague_carrier, rotten_bear, fly_cloud |
| Pęknięcie | duchy, niestabilna rzeczywistość, nagłe obrażenia budynków, utrata czasu/energii | Kafle pękają; część slotów może dostać status 'niestabilny'. Budynki dostają 10–75% uszkodzeń; obronne częściej są celem. | Rozproszyć budynki, mieć materiały na naprawy, budować Wieżę/Palisadę, unikać zbyt dużej zależności od jednego kafla. | fracture_whispers, fracture_cold_light, fracture_ghost_in_wall, fracture_reality_slip, fracture_open_rift, fracture_lost_time, fracture_false_memories, fracture_silent_collapse | pale_witness, woodcutter_ghost, cracked_shadow, whisper_wraith, stone_specter, faceless_mirror, underground_walker, living_rift |
| Zaćmienie | wieczna noc, mróz, brak światła, presja na ciepło i energię | Świat ciemnieje; globalnie +1 nocna strata ciepła. Budynki 10–80% uszkodzeń; Ognisko/Szałas zyskują większe znaczenie. | Priorytet Ognisko, Szałas, drewno i szybka naprawa obrony; przygotować zapas wody przed zimnem. | eclipse_dayless_morning, eclipse_black_sun, eclipse_extinguished_fire, eclipse_frozen_breath, eclipse_shadow_hunt, eclipse_frozen_water, eclipse_lanterns_fail, eclipse_deep_night | black_wolf, ice_mare, eclipse_moth, eyeless_hunter, night_stag, cold_crawler, hungry_shadow, moon_raven |

