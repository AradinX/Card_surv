# Inwentarz „Dzień 50" — co jest, czego brakuje

Żywy spis treści gry: **dane w grze** vs **art bez danych** vs **braki**.
Aktualizuj przy każdym dodaniu kart/assetów/systemów. Stan: **2026-06-16**.

**Legenda:** ✅ działa w grze (dane + logika) · 🟡 częściowe (np. art bez `.tres`,
albo asset gotowy ale niewpięty) · 🔴 brak.

---

## Klasy postaci
- ✅ **9 klas**, każda z WŁASNĄ talią (`data/decks/*_deck.tres`) i modyfikatorami.
  **Skaut** to klasa domyślna (start); reszta z ruletki (**losowo**, za 3 monety).
  - **Skaut** (start) — wytrzymały (+1 HP), tańsza budowa, +2 mat. start, −1 pragnienia.
  - **Kucharz** — generalista/jedzenie.
  - **Budowlaniec** — drewno→materiały→narzędzia, +1 HP (+tańsze/wytrzymalsze budowle).
  - **Zielarka** — regen +1 HP/świt, talia leków (apetyt +1).
  - **Łowca** — zwiad/eksploracja + leczenie (głód −1/dzień, jedzenie +20%).
  - **Strateg** — +1 karta/świt, XP +25% (budowa +1 energii).
  - **Wędrowiec** — darmowy ruch, start +2 jedz./+2 wody (+1 utraty ciepła).
  - **Wojskowy** — twardziel (+3 HP), −1 obrażeń potworów (większy apetyt).
  - **Informatyk** — challenge: same debuffy (−2 energii, +1 głodu, +1 obrażeń,
    budowa +1 energii, −1 HP, −1 jedz./wody na start); jedyny atut XP +25%.
- Pola HP/energii klasy: `health_bonus`, `max_energy_bonus` (w `CharacterClassData`).
- Balans (smoke 30 runów/klasa, ±szum): Zielarka ~100% → Skaut ~93% → Wędrowiec/
  Strateg ~83% → Kucharz/Łowca ~77% → Budowlaniec ~70% → Wojskowy ~50–65% →
  Informatyk ~37% (najtrudniejszy).

## Biomy (plansza)
- ✅ **Las**, **Łąki**, **Góry** (`data/biomes/`) — awers + skorumpowany rewers, akcje
  zbierania, zagrożenia, sloty. Każdy ma tło Akt I/Akt II.
- 🔴 Więcej biomów (bagno, pustkowie itp.) — pod większą różnorodność plansz.

## Budynki
**✅ W grze (15, dane `.tres` + ilustracja Akt I + Akt II, w puli nagród):**
- Bazowe / startowe: Ognisko (`campfire`, +2 ciepła), Szałas (`hut`, ochrona
  nocna), Studnia (`well`, +2 wody), Palisada (`palisade`, obrona 2).
- Produkcja jedzenia: Farma (+2), Port rybacki (+2), Spiżarnia (+1),
  Pułapki (+1 jedzenia + obrona 1).
- Surowce: Drwalnia (+2 drewna), Magazyn drewna (+1 drewna), Kamieniołom
  (+2 mat.), Warsztat (+1 mat.).
- Woda/zdrowie/obrona: Filtr wodny (+1 wody), Zielarnia (+1 zdrowia/dzień),
  Wieża obserwacyjna (obrona 2).

**✅ Budowane z KATALOGU** w trybie **„Budowanie"** (toggle przy „Koniec dnia"
podmienia rząd kart okolicy/ręki na przewijalny katalog budynków-kart; klik karty
→ potwierdzenie), nie z talii ani nagród. Boczny popup kafla = już tylko naprawa/
rozbiórka. **Budowa po BUM dostępna, ale z dopłatą** (+3 energii / +5 drewna /
+5 mat. — `POST_BUM_BUILD_*_SURCHARGE`). Budynki magazynowe podnoszą cap zasobów
(Spiżarnia/Magazyn/Filtr/Warsztat/Studnia).
**🟡 Uwaga:** specjale `slow_spoilage` / `unlock_crafting` wciąż NIE wpięte
(Spiżarnia/Warsztat działają przez pasyw + cap, nie efekt specjalny). Przy
progu BUM 60% budynki Aktu I giną doszczętnie — odbudowa w Akcie II jest możliwa,
ale droga (świadomy koszt katastrofy). Karta budynku w katalogu pokazuje koszt
bazowy; dopłatę po BUM widać w oknie potwierdzenia.

## Akcje
- ✅ **29 kart akcji** (`data/cards/actions/`): bazowe (adrenaline, big_hunt,
  campfire, craft_tools, expedition, explore, feast, find_water, first_aid,
  fishing, forage, gather_sticks, gather_wood, herbs, hunt, murky_water*, rest,
  scavenge, scout, snare_trap, tainted_hunt*, woodcraft) + 7 nowych (waterskin,
  dried_meat, bandage, huddle, trail_snack, survey, deep_sleep).
  (*skorumpowane akcje zbierania Akt II.)
- 🟡 **Ilustracje akcji: 10 obrazów** (`actions_act1_candidates/`) współdzielone
  via `ACTION_ART_ALIASES` w `ui/card_view.gd`. Nowe karty bez aliasu spadają na
  fallback `action_<id>.png` (brak) → render bez ilustracji (tylko ramka+tekst);
  ilustracje dla nich i dla skażonych akcji to kosmetyka (patrz prompt Codex).

## Zdarzenia nocne (aktywna pula — `NightEventPool`)
- 🟡 **Ilustracje zdarzeń: 37/42** w `assets/art/cards/illustrations/events/`
  (`<id>.png`, auto-ładowane przez `card_view`). Brak artu: 5 zdarzeń Plagi
  (plague_fever/infected_well/larvae/spores, rotting_supplies) — renderują się
  z samą ramką. Skażone akcje (murky_water, tainted_hunt) też jeszcze bez artu.
- ✅ **42 karty zdarzeń**: neutral 9, weather 13, biome 8, omen 6, disaster 6
  (+ 4 potwory). System wag/cooldownów/limitów/severity/faz/pacingu.
- ✅ **omen 6** — pojawiają się tylko w oknie dzień≥7 → BUM (faza OMEN).
- 🟡 Część bazy z `dzien_50_baza_kart_v0_1.md` ZABLOKOWANA (sezony, nowe biomy,
  Pęknięcie/Zaćmienie, obrażenia budynku ze zdarzeń, losowość, mitygacje
  warunkowe) — patrz status w tamtym pliku.
- ✅ **Balans (2026-06-19):** capy zasobów + zasoby per biom + budowanie z katalogu
  (tryb „Budowanie") + decay 3/3/3 + energia 8 + BUM rujnuje 60–80% + budowa po BUM
  za karę (+3E/+5D/+5M). Naiwny bot ~66% (33/50), zgony skupione w Akcie II (15).
  Świadoma gra celuje wyżej.
- 🔴 Popup nocy z rozliczeniem dopiero po „OK" (teraz efekty liczą się w tle).

## Potwory (Akt II)
- ✅ **4** (`data/monsters/`): Zgnilec, Zarażony wilk, Krucza chmara, Rój szczurów —
  komplet z artem, wpięte w pulę po BUM.
- 🔴 Więcej potworów + warianty pod inne katastrofy.

## Katastrofy (BUM)
- ✅ **Plaga** (`data/disasters/plague.tres`) — flip planszy, uszkodzenia, potwory,
  zdarzenia Aktu II.
- 🔴 **Pęknięcie / Zaćmienie** — szkielet `DisasterData` to umożliwia (system losuje
  z puli), brak `.tres` + dedykowanych potworów/efektów.

## Pory roku
- ✅ Wiosna/Lato/Jesień/Zima z modyfikatorami + HUD (`season`).
- ✅ FX pogodowe wpięte: deszcz (wiosna/jesień), śnieg (zima), czysto (lato) —
  subtelna warstwa pod UI (`run.gd _update_weather`).

## Animacje / FX
- ✅ **Odkrycie kafla** (warstwowa mgła, shader dissolve) — wpięte.
- ✅ **BUM** (Akt I→II, warstwowa sekwencja) — wpięte.
- ✅ **Flip nocnej karty** (rewers→front, glow/shine/burst/dust, tint per kategoria).
- ✅ **Wpięte FX:** pogoda sezonowa (deszcz/śnieg), **pazur** przy ataku potwora
  (`fx_claw_slash` nad nocną kartą), **iskry** lecz./zasobów przy zagraniu karty
  (`fx_heal_spark`/`fx_resource_gain`), **dym** nad zruinowanymi budynkami
  (`fx_smoke_loop` w slocie kafla). Wszystkie pod `ResourceLoader.exists` →
  działają na obecnych i na zregenerowanych assetach.
- 🟡 **Zostaje niewpięte:** `fx/fire/fx_small_fire_loop` (ogień na ruinach —
  można dołożyć obok dymu), `fx_frost_edges` (mróz zimą jako winieta).
- 🔴 **Brak FX (do wygenerowania):** budynek postawienie/naprawa/ruina-zawalenie,
  ekran wyniku (wygrana/przegrana), winieta krytycznego HP, feedback jedzenia/picia.

## UI / ramki
- ✅ HUD górny (Akt I/Akt II), ramki kart, kafle, panel nocy, paski.
- 🟡 Ramki górnego paska (`top_status_bar_panel_act1/act2_*`) — regeneracja pod
  poprawny aspekt (1282×119) w toku przez Codex.

## Systemy / meta (z README, jeszcze nie ma)
- ✅ **Save/load** runu — autozapis na każdym świcie do `user://run_save.tres`,
  „Kontynuuj" w menu, `SurvivalSystem.resume`. Granulacja per dzień (postęp w
  trakcie dnia nie jest zapisywany). 🔴 jeszcze: ręczny zapis/wiele slotów.
- 🟡 **Meta-progresja:** ✅ złote monety (1/wygrany run) + ruletka (3 monety →
  kolejna klasa wg drabinki easiest→hardest), zapis do `user://meta_state.tres`;
  **7 klas** (Kucharz + Budowlaniec/Zielarka/Łowca/Strateg/Wędrowiec/Wojskowy).
  🔴 jeszcze: kolekcja kart, odblokowania biomów/katastrof, drabinka trudności.
- 🔴 **Ulepszanie kart** (dziś nagroda = nowa karta, nie ulepszenie).
- 🔴 **Docelowy run do dnia 50** (teraz 30 — vertical slice).
- 🔴 Karty zwiadu realnie podglądające/oznaczające kafle przed ruchem
  (ilustracje scout/mapa są, efekt fog-of-war ograniczony).

---

## Najbliższe „darmowe" zwycięstwa (bez generowania nowego artu)
1. ~~Odblokować 11 budynków~~ ✅ ZROBIONE (2026-06-16) — 15 budynków w puli.
2. **Wpiąć ZAPAS FX** — pogoda pod sezony, ogień/dym na ruinach, claw przy ataku.
3. **Dosypać zdarzenia** (zwł. omeny) — system puli już to udźwignie.
4. **Doważyć balans** — smoke ~80% po budynkach; rozważyć koszty/HP/pasywy
   nowych budynków albo mocniejszy BUM/Akt II.
