# Karty akcji — podział, kategorie i audyt (stan 2026-06-30)

Wygenerowane audytem (skrypt ładuje wszystkie karty i liczy kanały dostępności —
talie startowe / pula nagród / zbieranie biomu / ulepszenia). **Audyt kart widmo:
0** (każda karta jest osiągalna jakimś kanałem).

**Legenda kosztów/efektów:** E = energia, J = jedzenie, D = drewno, M = materiały
(kamień), W = woda, zdr = zdrowie, syt = sytość, naw = nawodnienie, cie = ciepło.

---

## 1. Skąd biorą się zasoby (karty produkujące dany surowiec)

### 🪵 DREWNO  — gałąź WYRÓWNANA (2026-06-30): 7 producentów przez różne kanały
| Karta | Kanał | Zysk |
|---|---|---|
| Naręcze drewna (`haul_wood`) | pula | +3 D (−2 E) |
| Wymiana: drewno (`barter_wood`) | pula — *wymiana* | +3 D (−2 M) |
| Rąb drewno (`gather_wood`) | pula + zbieranie (Las, skażony Las) | +2 D |
| Wiatrołom (`deadfall_wood`) | pula | +2 D (−1 E, najtaniej/E) |
| Chrust: Naręcze (`gather_sticks_up`) | ulepszenie (Chrustu) | +2 D |
| Chrust (`gather_sticks`) | starter Budowlańca + pula + zbieranie (skażone Góry) | +1 D |
| Suchy chrust (`wasteland_scrapwood`) | pula + zbieranie (Pustkowie) | +1 D (−1 naw) |

> Wcześniej drewno miało tylko 3 karty produkcyjne i zero przez wymianę/ulepszenie.
> Dorzucono raw (`haul_wood`, `deadfall_wood`), konwersję kamień→drewno
> (`barter_wood`) i ulepszenie Chrustu (`gather_sticks_up`). Jedyne czego wciąż nie
> ma to dedykowana sygnaturka drwala (świadomie — Budowlaniec ma już Chrust ×2).

### 💧 WODA
| Karta | Kanał | Zysk |
|---|---|---|
| Źródło (`find_water`) | starter (wszystkie klasy) + zbieranie (Góry/Bagno/Rzeka/Jaskinie) | +2 W |
| Bukłak (`waterskin`) | pula | +2 W (+1 naw) |
| Wędkowanie (`fishing`) | zbieranie (Rzeka/Wybrzeże) | +1 W (+1 J) |
| Filtracja zapasów (`barter_water`) | pula — *wymiana* | +3 W (−1 J) |
| Objuczony kram (`trade_caravan`) | pula — *wymiana* | +2 W (+2 J, −1 D, −1 M) |
| Handel okazyjny (`windfall_trade`) | pula — *wymiana* | +2 W (+2 J, −2 M) |
| Skrytka wędrowca (`nomad_signature`) | starter Wędrowca | +2 W (+2 J) |
| Mętna woda (`murky_water`) | zbieranie skażone | +1 W |
| Źródło: Bystry strumień (`find_water_up`) | ulepszenie | +3 W |

### 🍖 JEDZENIE
| Karta | Kanał | Zysk |
|---|---|---|
| Zbieractwo (`forage`) | starter (większość) + zbieranie (Łąki/Pustkowie/Bagno) | +1 J (+1 syt) |
| Poluj (`hunt`) | zbieranie (Las) | +3 J |
| Wielkie polowanie (`big_hunt`) | pula | +5 J (−4 E) |
| Sidła (`snare_trap`) | zbieranie (Łąki) | +1 J (+1 syt, −1 D) |
| Wędkowanie (`fishing`) | zbieranie (Rzeka/Wybrzeże) | +1 J (+1 W) |
| Suszone mięso (`dried_meat`) | starter (Zielarka/Skaut/Wędrowiec) + pula | +2 J (+1 syt) |
| Przekąska (`trail_snack`) | pula | +1 J |
| Zwabienie zwierzyny (`bait_trap`) | pula | +2 J (+ pułapka) |
| Wymiana: jedzenie (`barter_food`) | pula — *wymiana* | +3 J (−2 D) |
| Objuczony kram / Handel okazyjny | pula — *wymiana* | +2 J |
| Drugie śniadanie (`second_breakfast`) | pula — *synergia* | +2 J (+2 jeśli grałeś jedzenie) |
| Skrytka wędrowca (`nomad_signature`) | starter Wędrowca | +2 J (+2 W) |
| Skażona zwierzyna (`tainted_hunt`) | zbieranie skażone | +3 J (−1 zdr) |
| Zgniłe jagody (`rotten_forage`) | zbieranie skażone | +2 J (−1 zdr) |
| Zbieractwo: Spiżarka (`forage_up`) | ulepszenie | +2 J (+ combo) |

### ⛏️ MATERIAŁY (kamień)
| Karta | Kanał | Zysk |
|---|---|---|
| Szukaj kamienia (`scavenge`) | starter Skauta + zbieranie (Góry/Pustkowie/Jaskinie/Wybrzeże) | +1 M |
| Ciesielka (`woodcraft`) | starter Budowlańca + pula — *wymiana* | +1 M (−1 D) |
| Obróbka kamienia (`knapping`) | pula — *wymiana* | +2 M (−2 D) |
| Zacisnąć zęby (`push_through`) | pula — *wymiana* | +3 M (−2 zdr) |
| Prefabrykaty (`builder_signature`) | starter Budowlańca | +2 M (−2 D) |
| Rozpoznanie (`scout_signature`) | starter Skauta | +1 M (+ explore) |
| Skażony złom (`salvage_scrap`) | zbieranie skażone | +1 M (−1 zdr) |
| Zwiad: Rekonesans (`scout_up`) | ulepszenie | +1 M (+ draw 2) |

---

## 2. Karty SYNERGICZNE (reagują na resztę tury / wzmacniają inne karty)

| Karta | Kanał | Działanie |
|---|---|---|
| Zapał (`momentum`) | pula | każda KOLEJNA karta dziś zwraca +1 E |
| Nieustępliwość (`relentless`) | pula | jak Zapał, taniej (−1 syt zamiast −1 E) |
| Rytm dnia (`rhythm`) | pula | +1 E za każdą kartę zagraną wcześniej dziś |
| Kadencja (`cadence`) | pula | jak Rytm + 1 zdr |
| Drugie śniadanie (`second_breakfast`) | pula | +2 J, a +2 więcej jeśli grałeś już jedzenie |
| Zbieractwo: Spiżarka (`forage_up`) | ulepszenie | +2 J + ten sam combo jedzenia |
| Wytwórz narzędzia (`craft_tools`) | starter (Kucharz/Budowlaniec) + pula | trwałe +1 do zysku J/D z kart (narzędzia) |

## 3. Karty „COŚ ZA COŚ" (wymiany / poświęcenie zasobu lub statu)

**Konwersje surowca → surowiec/stat (pula):** Wymiana: jedzenie (`barter_food`),
Filtracja zapasów (`barter_water`), Obróbka kamienia (`knapping`), Objuczony kram
(`trade_caravan`), Handel okazyjny (`windfall_trade`), Ciesielka (`woodcraft`),
Dołóż do ognia (`stoke_fire`), Ogrzej się (`campfire`), Okopanie się (`dig_in`),
Wytwórz narzędzia (`craft_tools`).

**Poświęcenie statu → tempo/surowiec (pula):** Nadludzki wysiłek (`overexert`,
−2 zdr→+4 E), Zacisnąć zęby (`push_through`, −2 zdr→+3 M), Hartowanie (`toughen`,
−1 zdr→+3 cie), Forsowny marsz (`forced_march`, −2 syt→+3 E), Nieustępliwość
(`relentless`, −1 syt), Adrenalina (`adrenaline`, −1 zdr→+3 E), Uczta (`feast`,
−3 J→+5 syt/+1 zdr), Sidła (`snare_trap`), Suchy chrust (`wasteland_scrapwood`).

**Sygnaturki/skażone w tym duchu:** Prefabrykaty (`builder_signature`), Sycący
gulasz (`cook_signature`), Skażona zwierzyna (`tainted_hunt`), Zgniłe jagody
(`rotten_forage`), Skażony złom (`salvage_scrap`).

---

## 4. Podstawowe (na starcie w talii) vs dodatkowe (odblokowywane)

### Talie startowe per klasa (9 kart każda; pierwsza to sygnaturka klasy)
| Klasa | Talia startowa |
|---|---|
| **Kucharz** | cook_signature, forage, find_water, rest, first_aid, scout, craft_tools, herbs, explore |
| **Budowlaniec** | builder_signature, gather_sticks ×2, woodcraft, craft_tools, first_aid, forage, find_water, rest |
| **Zielarka** | herbalist_signature, herbs, huddle, first_aid, forage, dried_meat, find_water, rest, scout |
| **Łowca** | hunter_signature, expedition, explore, scout ×2, herbs ×2, find_water, rest |
| **Wędrowiec** | nomad_signature, explore, scout, forage, dried_meat, find_water, rest, herbs, bandage |
| **Strateg** | planner_signature, scout ×2, explore, forage, find_water, rest, herbs, first_aid |
| **Skaut** | scout_signature, scavenge, forage, dried_meat, find_water, rest, first_aid, herbs, scout |
| **Wojskowy** | soldier_signature, adrenaline, feast, first_aid, herbs, forage, find_water, rest, scout |
| **Informatyk** | informatyk_signature, forage ×2, find_water, rest, first_aid, herbs, scout, explore |

> Wspólny rdzeń niemal każdej klasy: `forage`, `find_water`, `rest`, `first_aid`,
> `herbs`, `scout`. Klasy różnią się sygnaturką + 1–2 kartami profilowymi.

### Dodatkowe — TYLKO z puli nagród awansu (nigdy na starcie)
Te 28 kart nie są w żadnej talii startowej ani w zbieraniu biomu — pojawiają się
wyłącznie jako nagroda awansu (1 z 3):

`bait_trap`, `barter_food`, `barter_water`, `big_hunt`, `cadence`, `campfire`,
`dash`, `deep_sleep`, `dig_in`, `field_repair`, `forced_march`, `keep_watch`,
`knapping`, `momentum`, `overexert`, `push_through`, `relentless`, `rhythm`,
`second_breakfast`, `set_snare`, `stoke_fire`, `survey`, `toughen`,
`trade_caravan`, `trail_snack`, `waterskin`, `windfall_trade`
*(oraz 6 ulepszeń, które nie są dorzucane, tylko podmieniają kartę bazową)*.

> Cała pula nagród = wszystkie karty z `data/cards/actions/` (top-level), więc karty
> startowe też mogą wypaść jako kolejna kopia w nagrodzie. Powyżej tylko te, które
> NIE startują w żadnej talii.

### Ulepszenia (nagroda „1 z 3" podmienia bazę, nie dorzuca)
`forage → forage_up`, `find_water → find_water_up`, `first_aid → first_aid_up`,
`rest → rest_up`, `scout → scout_up`, `herbs → herbs_up`
(warianty leżą w `data/cards/actions/upgrades/`, poza pulą losowania).

---

## 5. Karty zbierania biomu (dostępne tylko na danym kaflu, 1×/dzień)

- **Normalne:** `gather_wood`, `hunt` (Las); `forage`, `snare_trap` (Łąki);
  `scavenge`, `find_water` (Góry/Jaskinie); `fishing` (Rzeka/Wybrzeże);
  `wasteland_scrapwood` (Pustkowie).
- **Skażone (po BUM):** `gather_wood`, `scavenge`, `gather_sticks`, `tainted_hunt`,
  `rotten_forage`, `murky_water`, `salvage_scrap`.

---

## 6. Audyt kart widmo

**0 kart widmo.** Każda karta akcji jest osiągalna co najmniej jednym kanałem:
pula nagród (top-level), talia startowa klasy, zbieranie biomu (gather/corrupted)
albo cel ulepszenia. Karty z podkatalogów `signature/`, `corrupted/`, `upgrades/`
są celowo poza pulą losowania, ale wszystkie są podpięte (sygnaturki w taliach
klas, skażone w biomach, ulepszenia jako cele `upgrade_id`).

*Regeneracja audytu: skrypt jednorazowy ładuje `data/cards/actions/**`,
`data/decks/*`, `data/classes/*` (starter_deck) i `data/biomes/*` (gather), po czym
liczy osiągalność i kategorie.*
