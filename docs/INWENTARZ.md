# Inwentarz „Dzień 50" — co jest, czego brakuje

Żywy spis treści gry: **dane w grze** vs **art bez danych** vs **braki**.
Aktualizuj przy każdym dodaniu kart/assetów/systemów. Stan: **2026-06-16**.

**Legenda:** ✅ działa w grze (dane + logika) · 🟡 częściowe (np. art bez `.tres`,
albo asset gotowy ale niewpięty) · 🔴 brak.

---

## Klasy postaci
- ✅ **Kucharz** (`data/classes/cook.tres`) — talia startowa 12 kart, modyfikatory.
- 🔴 Pozostałe klasy z README (szkielet `CharacterClassData` gotowy, brak `.tres`).

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

**🟡 Uwaga:** specjale `slow_spoilage` / `unlock_crafting` wciąż NIE wpięte
w logikę — Spiżarnia/Warsztat działają przez zwykłe pasywy (+1 jedzenia / +1
mat.), nie przez efekt specjalny. Bilans do doważenia (smoke ~80% po dodaniu).

## Akcje
- ✅ **22 karty akcji** (`data/cards/actions/`): adrenaline, big_hunt, campfire,
  craft_tools, expedition, explore, feast, find_water, first_aid, fishing, forage,
  gather_sticks, gather_wood, herbs, hunt, murky_water*, rest, scavenge, scout,
  snare_trap, tainted_hunt*, woodcraft. (*skorumpowane akcje zbierania Akt II.)
- 🟡 **Ilustracje akcji: 10 obrazów** (`actions_act1_candidates/`) współdzielone
  przez wszystkie 22 akcje via `ACTION_ART_ALIASES` w `ui/card_view.gd` (np. forage
  obsługuje big_hunt/feast/fishing/hunt/snare_trap). Wszystkie akcje MAJĄ grafikę,
  ale wiele dzieli ten sam obraz — dedykowane ilustracje to kosmetyka, nie blokuje.

## Zdarzenia nocne (aktywna pula — `NightEventPool`)
- ✅ **42 karty zdarzeń**: neutral 9, weather 13, biome 8, omen 6, disaster 6
  (+ 4 potwory). System wag/cooldownów/limitów/severity/faz/pacingu.
- ✅ **omen 6** — pojawiają się tylko w oknie dzień≥7 → BUM (faza OMEN).
- 🟡 Część bazy z `dzien_50_baza_kart_v0_1.md` ZABLOKOWANA (sezony, nowe biomy,
  Pęknięcie/Zaćmienie, obrażenia budynku ze zdarzeń, losowość, mitygacje
  warunkowe) — patrz status w tamtym pliku.
- ✅ **Balans dokręcony (2026-06-16):** decay sytość 3 / nawodnienie 2 / ciepło 2,
  energia 9/dzień → naiwny bot 86% → ~36%, Akt II to ściana. Świadoma gra celuje
  wyżej. Dalsze strojenie opcjonalne.
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
- 🟡 FX pogodowe (deszcz/śnieg/mróz) ISTNIEJĄ, ale NIEWPIĘTE pod sezony.

## Animacje / FX
- ✅ **Odkrycie kafla** (warstwowa mgła, shader dissolve) — wpięte.
- ✅ **BUM** (Akt I→II, warstwowa sekwencja) — wpięte.
- ✅ **Flip nocnej karty** (rewers→front, glow/shine/burst/dust, tint per kategoria).
- 🟡 **ZAPAS FX gotowy, niewpięty:** pogoda (rain/snow/frost), ogień/dym
  (`fx/fire`, `fx/smoke`) pod budynki Akt II, `fx/monster_attack/fx_claw_slash`,
  `fx/cards/fx_heal_spark` + `fx_resource_gain` przy kartach.
- 🔴 **Brak FX (do wygenerowania):** budynek postawienie/naprawa/ruina-zawalenie,
  ekran wyniku (wygrana/przegrana), winieta krytycznego HP, feedback jedzenia/picia.

## UI / ramki
- ✅ HUD górny (Akt I/Akt II), ramki kart, kafle, panel nocy, paski.
- 🟡 Ramki górnego paska (`top_status_bar_panel_act1/act2_*`) — regeneracja pod
  poprawny aspekt (1282×119) w toku przez Codex.

## Systemy / meta (z README, jeszcze nie ma)
- 🔴 **Save/load** runu (`RunState` jest `Resource`, gotowy pod zapis).
- 🔴 **Meta-progresja** (`MetaState` pusty): kolekcja, odblokowania, drabinka.
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
