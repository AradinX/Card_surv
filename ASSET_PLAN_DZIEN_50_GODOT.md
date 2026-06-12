# Dzień 50 / Day Fifty — plan assetów do wersji Godot

Dokument przygotowany jako praktyczna lista produkcyjna dla Codexa / Godot 4.x. Zakłada kierunek z README i CLAUDE: karciany roguelike survivalowy 2D, pixelart UI, plansza 3×2 z biomami, budynki jako karty leżące na kaflach, BUM w połowie runu, potem potwory i skorumpowane biomy.

---

## 1. Założenia wizualne

**Styl:** mroczny survival pixel art, czytelny UI, klimat snu przechodzącego w koszmar. Nie iść w pełny realizm ani kreskówkowość. Najlepiej: ciemne tło, ciepłe złoto/kość na ramkach kart, czytelne ikony zasobów, lekkie animacje i VFX.

**Priorytet czytelności:** gra ma dużo danych, więc assety muszą być proste i rozpoznawalne na małym rozmiarze. Ilustracje kart mogą być bardziej klimatyczne, ale ikony statystyk i zasobów muszą być maksymalnie jednoznaczne.

**Pipeline warstwowy od teraz:** pełne ekrany UI generujemy tylko jako
concept/mockup. Finalne biomy są czystymi tłami terenu bez ramek, slotów,
plakietek, liczników i napisów. Ramki, sloty, panele, przyciski, ikony,
overlaye i plate'y są osobnymi assetami UI. Finalne karty składamy w Godot
z ramki, ilustracji, ikon/kosztów i edytowalnego tekstu. Nie wypalamy tekstu
w grafikach produkcyjnych.

**Proponowane rozdzielczości bazowe:**

| Typ assetu | Rozmiar bazowy | Uwagi |
|---|---:|---|
| Karta pełna | 320×448 px albo 360×512 px | Stały format dla akcji, budynków, zdarzeń i potworów. |
| Ilustracja na karcie | 256×160 px albo 288×180 px | Osobny obraz wkładany w ramkę. |
| Kafelek biomu | 512×320 px | Do planszy 3×2; można skalować w UI. |
| Miniatura biomu / ikonka | 128×128 px | Do kolekcji, tooltipów i wyborów. |
| Ikony zasobów/statystyk | 64×64 px | Eksport PNG z przezroczystością. |
| Ikony małe UI | 32×32 px | W paskach, tooltipach, kosztach kart. |
| Panel UI 9-slice | 64×64 / 128×128 px | Ramki, okna, popupy, log. |
| Efekty BUM / overlay | 1024×576 albo 1920×1080 px | Warstwy z przezroczystością. |
| Tła ekranów | 1920×1080 px | Menu, wynik, kolekcja, klasa. |

**Godot import:** dla pixel art ustaw `Filter: Nearest`, bez wygładzania. Dla paneli UI przygotować wersje 9-slice. Pliki trzymać w `res://assets/`, a dane kart i biomów dalej w `res://data/`.

---

## 2. Co jest zrobione, a czego brakuje według dokumentacji

### Już zrobione / częściowo zrobione

- Istnieje rdzeń pętli dnia: talia, ręka kart, zagrywanie kart, koszty, zdarzenia końca dnia.
- Mapa węzłów została zastąpiona planszą 3×2 z 6 kafli biomów.
- Działają 4 statystyki przetrwania: zdrowie, sytość, nawodnienie, ciepło.
- Działa ruch po sąsiednich kaflach za energię.
- Budynki są kartami: po zbudowaniu schodzą z talii i trafiają na slot kafla.
- Są pola danych pod biomy, budynki, potwory, katastrofy, klasy i runtime state.
- XP i poziomy w runie są już wpięte, z nagrodami 1 z 3.
- Wersja web/Higgsfield jest równoległym prototypem, ale Godot pozostaje główną linią.

### Brakuje / następne logiczne kroki

- Pełnego systemu BUM w Godot: flip kafli, uszkodzenia budynków, ruiny, naprawy.
- Aktu II: potworów w talii zdarzeń, ataków nocą, obrony i uszkadzania budynków.
- Pór roku jako faz talii zdarzeń.
- Pełnego runu do dnia 50; obecnie placeholder kończy run wcześniej.
- Większej puli biomów i skorumpowanych wersji.
- Ekranów meta-progresji: kolekcja, odblokowania, wybór klasy, poziomy trudności.
- Docelowych assetów: aktualnie należy zakładać placeholdery.
- Efektów audio i wizualnych, szczególnie dla momentu BUM.

---

## 3. Docelowa struktura plików assetów

```text
res://
  assets/
    art/
      ui/
        panels/
        buttons/
        bars/
        plates/
        slots/
        overlays/
        cursors/
      cards/
        frames/
        backs/
        icons/
        illustrations/
          actions/
          buildings/
          events/
          monsters/
          disasters/
          classes/
      biomes/
        backgrounds/
          normal/
          corrupted/
        frames/
        miniatures/
        slot_markers/
        overlays/
      concepts/
        ui_screens/
        biomes/
        cards/
      buildings/
        icons/
        card_art/
        board_tokens/
        damaged/
        ruins/
      board/
        backgrounds/
        grid/
        connectors/
        player_marker/
      fx/
        bum/
        fire/
        smoke/
        corruption/
        weather/
        monster_attack/
      backgrounds/
        main_menu/
        run_screen/
        result_screen/
        collection/
      fonts/
    audio/
      music/
      sfx/
        ui/
        cards/
        day_cycle/
        bum/
        monsters/
        weather/
  data/
    cards/
      actions/
      events/
    decks/
    biomes/
    buildings/
    monsters/
    disasters/
    classes/
  docs/
    asset_plan/
```

---

## 4. Konwencja nazw plików

Trzymać `snake_case`, bez polskich znaków w nazwach plików. Teksty widoczne w grze mogą być po polsku, ale assety i ID lepiej po angielsku.

Przykłady:

```text
card_frame_action.png
card_frame_building.png
card_back_action.png
icon_health.png
biome_forest_normal_bg.png
biome_forest_plague_bg.png
building_campfire_illustration.png
building_campfire_token.png
monster_rotting_one_card.png
fx_bum_flash_01.png
ui_panel_log_9slice.png
```

---

## 5. Priorytety produkcji assetów

### P0 — must-have do vertical slice w Godot

To wystarczy, żeby gra wyglądała jak gra, a nie jak debug UI:

- Layout run screen: górny pasek statystyk, plansza 3×2, panel logów, przycisk końca dnia, ręka kart.
- Ramki kart: akcja, budynek, zdarzenie, potwór, nagroda poziomu.
- Rewersy kart: talia akcji, talia zdarzeń, talia potworów.
- Ikony statystyk i zasobów.
- 3 działające biomy normalne jako czyste tła: Las, Łąki, Góry.
- 3 skorumpowane wersje pod Plagę jako czyste tła: Martwy Las, Zgniłe Łąki, Wyjące Góry.
- Ramki kafli, title plate'y i sloty budynków jako osobne UI: pusty, aktywny, zajęty, uszkodzony, ruina.
- Ilustracje i tokeny budynków startowych: Ognisko, Szałas, Studnia. Finalne karty składane w Godot.
- Karty podstawowe: Odpoczynek, Eksploruj, Rąb drewno, Zbieractwo, Opatrz rany, Źródło, Narzędzia.
- 3–4 potwory Plagi.
- Efekt BUM: flash, pęknięcie ekranu, overlay korupcji, płonące budynki.

### P1 — pełniejsza wersja Aktu I i Aktu II

- Wszystkie 8 biomów normalnych i ich wersje skorumpowane.
- Pełny zestaw budynków: Spiżarnia, Farma, Wędzarnia, Warsztat, Palisada, Pułapki, Strażnica, Pochodnie.
- Pory roku: paczka kart zdarzeń Wiosna/Lato/Jesień/Zima.
- Foreshadowing: martwe ptaki, drżenie ziemi, łuna, niespokojny sen.
- Ekran wyboru nagrody poziomu.
- Ekran wyniku runu.
- Portrety klas: Kucharz, Budowlaniec, Wojskowy.

### P2 — polish i rozszerzenia

- Drugi i trzeci typ BUM: Pęknięcie, Zaćmienie.
- Osobne potwory i efekty pod każdy typ katastrofy.
- Kolekcja, meta-progresja, odblokowania.
- Animowane mikropętle: ogień, deszcz, śnieg, mgła, korupcja.
- Pełny sound design.

---

## 6. Lista assetów UI

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Główne tło runu | `assets/art/backgrounds/run_screen/bg_run_table.png` | P0 | Ciemny, leśny lub drewniany stół/board jako baza pod całą rozgrywkę. Ma nie konkurować z kartami. |
| Górny pasek HUD | `assets/art/ui/bars/top_status_bar.png` | P0 | Długi panel na dzień, poziom, XP, zdrowie, sytość, nawodnienie, ciepło, energię. |
| Ramka paska statystyki | `assets/art/ui/bars/stat_bar_frame.png` | P0 | Uniwersalna ramka dla poziomu statystyki. |
| Wypełnienie zdrowia | `assets/art/ui/bars/stat_fill_health.png` | P0 | Czerwone lub krwiste wypełnienie HP. |
| Wypełnienie sytości | `assets/art/ui/bars/stat_fill_hunger.png` | P0 | Pomarańczowe/żółte wypełnienie sytości. |
| Wypełnienie nawodnienia | `assets/art/ui/bars/stat_fill_thirst.png` | P0 | Niebieskie wypełnienie wody. |
| Wypełnienie ciepła | `assets/art/ui/bars/stat_fill_warmth.png` | P0 | Ciepłe, ogniste wypełnienie temperatury. |
| Wypełnienie energii | `assets/art/ui/bars/stat_fill_energy.png` | P0 | Zielone lub jasne wypełnienie energii. |
| Panel logów | `assets/art/ui/panels/panel_log_9slice.png` | P0 | Prawy panel z historią dnia. Ciemny, półprzezroczysty, czytelny. |
| Panel ręki kart | `assets/art/ui/panels/panel_hand_area.png` | P0 | Dolny obszar pod 4–6 kart. Powinien wyglądać jak blat/rowek na karty. |
| Panel kart zdarzeń/potworów | `assets/art/ui/panels/panel_event_deck_area.png` | P0 | Prawy dolny panel na talie wydarzeń i potworów. |
| Przycisk „Zakończ dzień” | `assets/art/ui/buttons/button_end_day.png` | P0 | Duży, brązowo-złoty przycisk, czytelny i ciężki wizualnie. |
| Przycisk zwykły | `assets/art/ui/buttons/button_default_9slice.png` | P0 | Uniwersalny przycisk menu/wyborów. |
| Przycisk aktywny/hover | `assets/art/ui/buttons/button_hover_9slice.png` | P0 | Jaśniejszy wariant przycisku. |
| Przycisk disabled | `assets/art/ui/buttons/button_disabled_9slice.png` | P0 | Wygaszony wariant przycisku. |
| Tooltip panel | `assets/art/ui/panels/panel_tooltip_9slice.png` | P0 | Małe okienko tooltipów kart, ikon i budynków. |
| Popup wyboru nagrody | `assets/art/ui/panels/panel_reward_overlay.png` | P0 | Overlay na awans poziomu: 1 z 3 nagród. |
| Panel kosztów karty | `assets/art/ui/panels/panel_card_cost.png` | P0 | Mały pasek/znacznik kosztów na karcie. |
| Ramka slotu budynku | `assets/art/biomes/slot_markers/slot_empty.png` | P0 | Widoczne miejsce na kartę/budynek w biomie. |
| Slot aktywny | `assets/art/biomes/slot_markers/slot_selectable.png` | P0 | Podświetlenie slotu, kiedy można postawić budynek. |
| Slot zajęty | `assets/art/biomes/slot_markers/slot_occupied.png` | P0 | Delikatna ramka pod token zbudowanego budynku. |
| Slot uszkodzony | `assets/art/biomes/slot_markers/slot_damaged.png` | P0 | Ramka z pęknięciami/ciemnym obramowaniem. |
| Slot ruina | `assets/art/biomes/slot_markers/slot_ruin.png` | P0 | Ramka sugerująca spaleniznę i gruzy. |
| Ikona kursora wyboru | `assets/art/ui/cursors/cursor_select.png` | P1 | Pixelowy kursor wyboru slotu/karty. |
| Tło menu głównego | `assets/art/backgrounds/main_menu/bg_main_menu.png` | P1 | Senna dzicz z ogniskiem i ciemnym horyzontem. |
| Tło wyniku przegranej | `assets/art/backgrounds/result_screen/bg_defeat.png` | P1 | Wygasłe ognisko, zimno, ruiny. |
| Tło wyniku wygranej | `assets/art/backgrounds/result_screen/bg_victory_wakeup.png` | P1 | Pokój po przebudzeniu, subtelny element ze snu. |
| Ekran kolekcji | `assets/art/backgrounds/collection/bg_collection.png` | P2 | Stół z kartami, notatnikiem i zniszczoną mapą. |

---

## 7. Ikony statystyk, zasobów i mechanik

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Zdrowie | `assets/art/cards/icons/icon_health.png` | P0 | Serce, kropla krwi lub bandaż. Najczytelniej: serce + mała rysa. |
| Sytość | `assets/art/cards/icons/icon_hunger.png` | P0 | Mięso/chleb/miska. Używać konsekwentnie jako sytość/głód. |
| Nawodnienie | `assets/art/cards/icons/icon_thirst.png` | P0 | Kropla wody. |
| Ciepło | `assets/art/cards/icons/icon_warmth.png` | P0 | Płomień/ognisko. |
| Energia | `assets/art/cards/icons/icon_energy.png` | P0 | Błyskawica. |
| XP | `assets/art/cards/icons/icon_xp.png` | P0 | Mała gwiazda/runa. |
| Dzień | `assets/art/cards/icons/icon_day.png` | P0 | Słońce nad kreską horyzontu. |
| Jedzenie | `assets/art/cards/icons/icon_food.png` | P0 | Paczka jedzenia/suszone mięso. |
| Woda | `assets/art/cards/icons/icon_water.png` | P0 | Bukłak lub niebieska kropla. |
| Drewno | `assets/art/cards/icons/icon_wood.png` | P0 | Dwie kłody. |
| Materiały | `assets/art/cards/icons/icon_materials.png` | P0 | Skrzynka z deskami i metalem. |
| Kamień | `assets/art/cards/icons/icon_stone.png` | P1 | Odłamek skały. |
| Ruda | `assets/art/cards/icons/icon_ore.png` | P1 | Ciemna bryła z jasną żyłą. |
| Zioła | `assets/art/cards/icons/icon_herbs.png` | P1 | Zielony pęczek liści. |
| Torf | `assets/art/cards/icons/icon_peat.png` | P1 | Ciemny blok ziemi. |
| Narzędzia | `assets/art/cards/icons/icon_tools.png` | P0 | Młotek i nóż/siekiera. |
| Obrona | `assets/art/cards/icons/icon_defense.png` | P0 | Tarcza/palisada. |
| Obrażenia | `assets/art/cards/icons/icon_damage.png` | P0 | Pęknięcie/cios. |
| Naprawa | `assets/art/cards/icons/icon_repair.png` | P0 | Młotek z plusem. |
| Ruina | `assets/art/cards/icons/icon_ruin.png` | P0 | Spalone belki. |
| Ruch | `assets/art/cards/icons/icon_move.png` | P0 | But/strzałka. |
| Slot budynku | `assets/art/cards/icons/icon_building_slot.png` | P0 | Mały fundament. |
| Plaga | `assets/art/cards/icons/icon_disaster_plague.png` | P0 | Zielona czaszka/mucha. |
| Pęknięcie | `assets/art/cards/icons/icon_disaster_rift.png` | P2 | Fioletowa szczelina. |
| Zaćmienie | `assets/art/cards/icons/icon_disaster_eclipse.png` | P2 | Czarne słońce. |
| Wiosna | `assets/art/cards/icons/icon_season_spring.png` | P1 | Pąk. |
| Lato | `assets/art/cards/icons/icon_season_summer.png` | P1 | Ostre słońce. |
| Jesień | `assets/art/cards/icons/icon_season_autumn.png` | P1 | Liść. |
| Zima | `assets/art/cards/icons/icon_season_winter.png` | P1 | Płatek śniegu. |

---

## 8. Ramki i rewersy kart

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Ramka karty akcji | `assets/art/cards/frames/card_frame_action.png` | P0 | Metalowo-drewniana ramka, neutralna. Miejsce na koszt, nazwę, ilustrację, opis. |
| Ramka karty budynku | `assets/art/cards/frames/card_frame_building.png` | P0 | Cięższa, architektoniczna ramka, z miejscem na HP i koszt budowy. |
| Ramka karty zdarzenia | `assets/art/cards/frames/card_frame_event.png` | P0 | Ciemna ramka z pergaminowym/księżycowym akcentem. |
| Ramka karty potwora | `assets/art/cards/frames/card_frame_monster.png` | P0 | Agresywna ramka z pazurami, kością lub zgniłą zielenią. |
| Ramka karty biomu | `assets/art/cards/frames/card_frame_biome.png` | P1 | Używana w kolekcji/tooltipach biomów. |
| Ramka karty katastrofy | `assets/art/cards/frames/card_frame_disaster.png` | P1 | Duża, dramatyczna ramka dla BUM/typu katastrofy. |
| Ramka nagrody poziomu | `assets/art/cards/frames/card_frame_reward.png` | P0 | Czytelna karta wyboru 1 z 3. |
| Rewers akcji | `assets/art/cards/backs/card_back_action.png` | P0 | Motyw dłoni/ogniska/ekwipunku. |
| Rewers zdarzeń | `assets/art/cards/backs/card_back_event.png` | P0 | Motyw nocy, gwiazd, lasu. |
| Rewers potworów | `assets/art/cards/backs/card_back_monster.png` | P0 | Motyw plagi, pazurów, zębów. |
| Rewers budynków | `assets/art/cards/backs/card_back_building.png` | P1 | Motyw fundamentów i młotka. |
| Rewers biomów | `assets/art/cards/backs/card_back_biome.png` | P1 | Motyw mapy/kafli. |
| Maska ilustracji karty | `assets/art/cards/frames/card_art_mask.png` | P0 | Window/maska dla ilustracji kart, żeby każda karta miała spójny układ. |

---

## 9. Biomy — assety normalne i skorumpowane

Każdy biom powinien mieć: czyste tło terenu, miniaturę, overlaye stanu i
wersję skorumpowaną. Kafel widoczny w grze jest składany w Godot z tła biomu,
osobnej ramki kafla, osobnego title plate'a, osobnych slot markerów i
edytowalnego tekstu. Tło biomu nie zawiera nagłówka, ramek, slotów ani napisów.

| Biom | Assety | Priorytet | Opis |
|---|---|---:|---|
| Las | `assets/art/biomes/backgrounds/normal/biome_forest_normal_bg.png`, `biome_forest_mini.png` | P0 | Czyste tło: gęsty, ciemnozielony las; zasoby: drewno, jedzenie, źródło/woda. Klimat startowy. |
| Martwy Las / Plaga | `assets/art/biomes/backgrounds/corrupted/biome_forest_plague_bg.png` | P0 | Czyste tło: te same drzewa, ale zgniłe, szare, zielona mgła, martwe ptaki. |
| Łąki | `assets/art/biomes/backgrounds/normal/biome_meadow_normal_bg.png`, `biome_meadow_mini.png` | P0 | Czyste tło: jasna trawa, kwiaty, przestrzeń; dobre pod farmę. |
| Zgniłe Łąki / Plaga | `assets/art/biomes/backgrounds/corrupted/biome_meadow_plague_bg.png` | P0 | Czyste tło: żółto-brązowa trawa, plamy choroby, owady, kości małych zwierząt. |
| Góry | `assets/art/biomes/backgrounds/normal/biome_mountains_normal_bg.png`, `biome_mountains_mini.png` | P0 | Czyste tło: skały, zimny wiatr, śnieżne szczyty; mniej slotów w danych, ale nie wypalone w tle. |
| Wyjące Góry / Plaga | `assets/art/biomes/backgrounds/corrupted/biome_mountains_plague_bg.png` | P0 | Czyste tło: pęknięte skały, zielone szczeliny, toksyczna mgła i ostre kontury. |
| Wybrzeże | `biome_coast_normal.png`, `biome_coast_mini.png` | P1 | Piasek, skały, woda, sieci; zasoby ryby/woda; zdarzenia: sztorm. |
| Martwe Wybrzeże | `biome_coast_plague.png` | P1 | Czarne fale, martwe ryby, zgniła piana, wraki. |
| Bagna | `biome_swamp_normal.png`, `biome_swamp_mini.png` | P1 | Mętna woda, trzciny, zioła, torf; choroby jako ryzyko. |
| Zatrute Bagna | `biome_swamp_plague.png` | P1 | Gęsta zielona mgła, bąble, larwy, gnijące pnie. |
| Jezioro | `biome_lake_normal.png`, `biome_lake_mini.png` | P1 | Spokojna tafla wody, brzegi, trzciny; silna synergia z farmą. |
| Zgniłe Jezioro | `biome_lake_plague.png` | P1 | Zielona tafla, martwe ryby, czarne brzegi. |
| Jaskinie | `biome_caves_normal.png`, `biome_caves_mini.png` | P1 | Ciemne wejścia, kryształy/kamień, mało ciepła. |
| Zainfekowane Jaskinie | `biome_caves_plague.png` | P1 | Zielone narośla, ślepia w ciemności, toksyczne wycieki. |
| Wzgórza | `biome_hills_normal.png`, `biome_hills_mini.png` | P1 | Falujące trawy, kamienie, widok na horyzont. Uniwersalny biom. |
| Skażone Wzgórza | `biome_hills_plague.png` | P1 | Spękana ziemia, chore trawy, zielonkawy horyzont. |
| Overlay sąsiedztwa | `assets/art/biomes/overlays/biome_neighbor_highlight.png` | P0 | Podświetla kafle, na które można przejść. |
| Overlay obecnej pozycji | `assets/art/biomes/overlays/biome_current_player.png` | P0 | Znacznik aktualnego kafla gracza. |
| Overlay skorumpowania | `assets/art/biomes/overlays/biome_corruption_overlay.png` | P0 | Uniwersalna warstwa plagi, gdy nie ma jeszcze pełnego artu. |

---

## 10. Budynki jako karty i tokeny na planszy

Każdy budynek potrzebuje dwóch wersji: **pełna ilustracja karty** oraz **mały token/mini karta na slocie biomu**. Dodatkowo dla BUM potrzebne są warianty uszkodzone i ruiny.

| Budynek | Ścieżki | Priorytet | Opis |
|---|---|---:|---|
| Ognisko | `building_campfire_card.png`, `building_campfire_token.png`, `building_campfire_damaged.png`, `building_campfire_ruin.png` | P0 | Małe ognisko z kamieniami. Symbolizuje ciepło globalne. Uszkodzone: przygaszone; ruina: popiół. |
| Szałas | `building_hut_card.png`, `building_hut_token.png`, `building_hut_damaged.png`, `building_hut_ruin.png` | P0 | Prymitywne schronienie z gałęzi/skór. Symbol ochrony nocą. |
| Studnia | `building_well_card.png`, `building_well_token.png`, `building_well_damaged.png`, `building_well_ruin.png` | P0 | Drewniana studnia z wiadrem. Symbol wody. |
| Spiżarnia | `building_pantry_card.png`, `building_pantry_token.png`, `building_pantry_damaged.png`, `building_pantry_ruin.png` | P1 | Mały magazyn/skrzynia, beczki, suszone jedzenie. Spowalnia psucie. |
| Farma | `building_farm_card.png`, `building_farm_token.png`, `building_farm_damaged.png`, `building_farm_ruin.png` | P1 | Grządki, płotek, małe pole. Najlepiej wygląda na Łąkach. |
| Wędzarnia | `building_smokehouse_card.png`, `building_smokehouse_token.png`, `building_smokehouse_damaged.png`, `building_smokehouse_ruin.png` | P1 | Mała drewniana budka z dymem. Przetwarzanie jedzenia. |
| Warsztat | `building_workshop_card.png`, `building_workshop_token.png`, `building_workshop_damaged.png`, `building_workshop_ruin.png` | P1 | Stół, narzędzia, daszek. Odblokowuje/craftuje lepsze karty. |
| Palisada | `building_palisade_card.png`, `building_palisade_token.png`, `building_palisade_damaged.png`, `building_palisade_ruin.png` | P0/P1 | Obrona po BUM. Rząd ostrych pali, mocny symbol ochrony. |
| Pułapki | `building_traps_card.png`, `building_traps_token.png`, `building_traps_damaged.png`, `building_traps_ruin.png` | P0/P1 | Wilcze doły, linki, kolce. Lepsze jako „obrona aktywna”. |
| Strażnica | `building_watchtower_card.png`, `building_watchtower_token.png`, `building_watchtower_damaged.png`, `building_watchtower_ruin.png` | P1 | Drewniana wieża. Daje wykrywanie/zmniejsza obrażenia od potworów. |
| Pochodnie | `building_torches_card.png`, `building_torches_token.png`, `building_torches_damaged.png`, `building_torches_ruin.png` | P1 | Krąg pochodni, obrona przed ciemnością/zaślepieniem. |
| Ruiny ogólne | `building_generic_ruin_token.png` | P0 | Uniwersalny placeholder ruiny, jeśli nie ma indywidualnych ruin. |
| Ikona HP budynku | `icon_building_hp.png` | P0 | Małe serce/tarcza budynku. |
| Pasek HP budynku | `ui_building_hp_bar.png` | P0 | Mini pasek na tokenie budynku. |

---

## 11. Karty akcji — ilustracje

| Karta | Ścieżka | Priorytet | Opis ilustracji |
|---|---|---:|---|
| Odpoczynek | `assets/art/cards/actions/action_rest.png` | P0 | Postać/sylwetka przy ognisku, ciepły blask, bez pełnej animowanej postaci. |
| Eksploruj | `assets/art/cards/actions/action_explore.png` | P0 | Ścieżka w lesie, mapa, ślady stóp, mgła. |
| Rąb drewno | `assets/art/cards/actions/action_chop_wood.png` | P0 | Siekiera wbita w pień, lecące drzazgi. |
| Zbieractwo | `assets/art/cards/actions/action_forage.png` | P0 | Ręka/koszyk z jagodami, grzybami, ziołami. |
| Opatrz rany | `assets/art/cards/actions/action_treat_wounds.png` | P0 | Bandaż, zioła, kropla krwi. |
| Źródło | `assets/art/cards/actions/action_spring_source.png` | P0 | Małe źródełko między kamieniami, błękitny akcent. |
| Narzędzia | `assets/art/cards/actions/action_craft_tools.png` | P0 | Młotek, sznurek, kamienny nóż/siekiera. |
| Zwiad | `assets/art/cards/actions/action_scout.png` | P1 | Widok ze wzgórza, lornetka prymitywna lub ślady. |
| Adrenalina | `assets/art/cards/actions/action_adrenaline.png` | P1 | Dynamiczny czerwony błysk, ręka zaciskająca pięść. |
| Podwójna eksploracja | `assets/art/cards/actions/action_double_explore.png` | P1 | Rozchodzące się dwie ścieżki. |
| Napraw | `assets/art/cards/actions/action_repair.png` | P0/P1 | Młotek naprawiający pękniętą belkę. Ważne po BUM. |
| Rozbierz ruiny | `assets/art/cards/actions/action_salvage_ruins.png` | P0/P1 | Wyciąganie desek z ruin, odzysk materiałów. |
| Uciekaj | `assets/art/cards/actions/action_flee.png` | P1 | Szybkie ślady i ciemne sylwetki w tle. |
| Wzmocnij budynek | `assets/art/cards/actions/action_reinforce.png` | P1 | Belki, liny i gwoździe wzmacniające ścianę. |
| Rozpal większy ogień | `assets/art/cards/actions/action_stoke_fire.png` | P1 | Silniejsze ognisko, iskry, ciepły glow. |

---

## 12. Karty zdarzeń i pory roku

| Karta / grupa | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Zimna noc | `assets/art/cards/events/event_cold_night.png` | P0 | Namiot/szałas pod mroźnym niebem, niebieskie cienie. |
| Ulewa | `assets/art/cards/events/event_heavy_rain.png` | P0 | Deszcz na lesie i błoto, ciemne chmury. |
| Słoneczny poranek | `assets/art/cards/events/event_sunny_morning.png` | P0 | Ciepłe słońce przez drzewa. Daje bonus energii. |
| Dziki zwierz | `assets/art/cards/events/event_wild_animal.png` | P1 | Ślepia w ciemności, ślady pazurów. |
| Zepsute jedzenie | `assets/art/cards/events/event_spoiled_food.png` | P1 | Zgniłe zapasy, muchy. |
| Susza | `assets/art/cards/events/event_drought.png` | P1 | Popękana ziemia, puste naczynie. |
| Obfity dzień | `assets/art/cards/events/event_abundant_day.png` | P1 | Kosz zasobów, spokojna pogoda. |
| Śnieżyca | `assets/art/cards/events/event_blizzard.png` | P1 | Biały wiatr, zasypane ognisko. Zima. |
| Upalny dzień | `assets/art/cards/events/event_heatwave.png` | P1 | Ostre słońce, wyschnięta trawa. Lato. |
| Wiosenny deszcz | `assets/art/cards/events/event_spring_rain.png` | P1 | Lżejszy deszcz i świeże rośliny. Wiosna. |
| Jesienne zbiory | `assets/art/cards/events/event_autumn_harvest.png` | P1 | Liście, kosze, przygotowania do zimy. |
| Martwe ptaki | `assets/art/cards/events/event_dead_birds.png` | P1 | Foreshadowing BUM: kilka martwych ptaków na ziemi. |
| Drżenie ziemi | `assets/art/cards/events/event_ground_tremor.png` | P1 | Pęknięcie w ziemi, poruszone drzewa. |
| Łuna na horyzoncie | `assets/art/cards/events/event_distant_glow.png` | P1 | Nienaturalne światło za lasem. |
| Niespokojny sen | `assets/art/cards/events/event_bad_dream.png` | P1 | Senna, rozmazana sylwetka nad łóżkiem/ogniskiem. |
| Karta BUM: Plaga | `assets/art/cards/disasters/disaster_plague_card.png` | P0 | Wielka karta katastrofy: zielona eksplozja/zaraza na horyzoncie. |
| Karta BUM: Pęknięcie | `assets/art/cards/disasters/disaster_rift_card.png` | P2 | Fioletowa szczelina w niebie/ziemi. |
| Karta BUM: Zaćmienie | `assets/art/cards/disasters/disaster_eclipse_card.png` | P2 | Czarne słońce, wieczna noc. |

---

## 13. Potwory Aktu II

Dla vertical slice wystarczy 3–4 potwory Plagi. Każdy potwór potrzebuje pełnej ilustracji karty oraz małej ikonki/miniatury do logu i talii.

| Potwór | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Zgnilec | `assets/art/cards/monsters/monster_rotting_one.png` | P0 | Podstawowy zombie/zgniły człowiek, wolny, zielona zaraza. |
| Zarażony wilk | `assets/art/cards/monsters/monster_plague_wolf.png` | P0 | Chudy wilk z zielonymi oczami, szybki atak. |
| Krucza chmara | `assets/art/cards/monsters/monster_crow_swarm.png` | P0 | Stado czarnych ptaków, atak na zapasy/budynki. |
| Rój szczurów | `assets/art/cards/monsters/monster_rat_swarm.png` | P0 | Szczury przy ruinach, niszczą spiżarnię/jedzenie. |
| Zarażony olbrzym | `assets/art/cards/monsters/monster_plague_brute.png` | P1 | Większy, rzadki wróg, duże obrażenia budynków. |
| Widmo | `assets/art/cards/monsters/monster_ghost.png` | P2 | Potwór pod Pęknięcie. Przezroczysta zjawa. |
| Cień | `assets/art/cards/monsters/monster_shadow.png` | P2 | Potwór pod Zaćmienie. Ciemna sylwetka z oczami. |
| Mroczna ćma | `assets/art/cards/monsters/monster_eclipse_moth.png` | P2 | Potwór zaćmienia, atakuje ciepło/pochodnie. |

---

## 14. Klasy postaci

Klasy nie muszą mieć pełnej animacji postaci. Wystarczy portret/karta klasy i mała ikonka klasy.

| Klasa | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Kucharz | `assets/art/cards/classes/class_cook_portrait.png`, `icon_class_cook.png` | P1 | Postać przy garnku/ognisku, ciepło, jedzenie, bezpieczny start. |
| Budowlaniec | `assets/art/cards/classes/class_builder_portrait.png`, `icon_class_builder.png` | P1 | Młotek, belki, mocne schronienie. |
| Wojskowy | `assets/art/cards/classes/class_soldier_portrait.png`, `icon_class_soldier.png` | P1 | Latarka, nóż, improwizowana obrona, surowszy klimat. |
| Karta wyboru klasy | `assets/art/ui/panels/panel_class_select.png` | P1 | Panel przed runem z opisem atutów i słabości. |

---

## 15. Mapa główna / plansza runu

Tutaj nie chodzi o klasyczną mapę świata, tylko o centralny ekran rozgrywki z 6 kaflami. Układ powinien być podobny do załączonego szkicu: góra = statystyki, centrum = biomy, dół = ręka, prawa strona = koniec dnia/log/talie.

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Tło pod planszę biomów | `assets/art/board/backgrounds/bg_biome_board.png` | P0 | Ciemny blat/las pod kaflami 3×2. |
| Ramka kafla biomu | `assets/art/board/grid/biome_tile_frame.png` | P0 | Ramka dla każdego kafla, z miejscem na nagłówek. |
| Nagłówek kafla biomu | `assets/art/board/grid/biome_tile_header.png` | P0 | Pasek z nazwą biomu i liczbą slotów. |
| Siatka planszy 3×2 | `assets/art/board/grid/board_grid_3x2.png` | P0 | Opcjonalna bazowa siatka, jeśli kafle nie mają własnych ramek. |
| Połączenia sąsiedztwa | `assets/art/board/connectors/neighbor_connector.png` | P1 | Subtelne ścieżki między kaflami. |
| Znacznik gracza | `assets/art/board/player_marker/player_marker.png` | P0 | Mały pionek/ognik/sylwetka pokazująca aktualny biom. |
| Znacznik ruchu | `assets/art/board/player_marker/move_arrow.png` | P0 | Strzałka pokazująca możliwy ruch za 1 energię. |
| Ciemny overlay niedostępnego kafla | `assets/art/board/grid/tile_unavailable_overlay.png` | P0 | Przygasza kafle, do których nie można przejść. |
| Overlay aktywnego biomu | `assets/art/board/grid/tile_active_overlay.png` | P0 | Podświetlenie obecnego biomu. |

---

## 16. Efekty BUM, uszkodzeń i pogody

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| BUM flash | `assets/art/fx/bum/fx_bum_flash.png` | P0 | Biało-zielony lub czerwony błysk na cały ekran. |
| Pęknięcie ekranu | `assets/art/fx/bum/fx_screen_crack_overlay.png` | P0 | Transparentne pęknięcia, do nałożenia na cały ekran. |
| Fala uderzeniowa | `assets/art/fx/bum/fx_shockwave.png` | P0 | Krąg/fala, może być animowana przez skalowanie w Godot. |
| Chmura plagi | `assets/art/fx/corruption/fx_plague_cloud.png` | P0 | Zielonkawa mgła na biomy po BUM. |
| Spalenizna budynku | `assets/art/fx/fire/fx_burn_marks.png` | P0 | Overlay na budynki i sloty. |
| Mały ogień | `assets/art/fx/fire/fx_small_fire_loop.png` | P0/P1 | 3–6 klatek animacji ognia. |
| Dym | `assets/art/fx/smoke/fx_smoke_loop.png` | P0/P1 | 4–8 klatek dymu z ruin. |
| Deszcz | `assets/art/fx/weather/fx_rain_overlay.png` | P1 | Warstwa deszczu do wydarzeń. |
| Śnieg | `assets/art/fx/weather/fx_snow_overlay.png` | P1 | Warstwa śniegu do zimy. |
| Mróz na krawędziach | `assets/art/fx/weather/fx_frost_edges.png` | P1 | Overlay, gdy ciepło jest niskie. |
| Atak potwora | `assets/art/fx/monster_attack/fx_claw_slash.png` | P0/P1 | Cięcie/pazury na kartę budynku. |
| Leczenie | `assets/art/fx/cards/fx_heal_spark.png` | P1 | Mały zielony/ciepły błysk. |
| Zysk zasobu | `assets/art/fx/cards/fx_resource_gain.png` | P1 | Mały plus/iskra przy ikonie zasobu. |

---

## 17. Audio

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Muzyka menu | `assets/audio/music/music_main_menu.ogg` | P1 | Spokojna, senna, mroczna. |
| Muzyka Akt I | `assets/audio/music/music_act1_survival.ogg` | P1 | Cichy ambient lasu, napięcie, ale bez horroru. |
| Muzyka Akt II | `assets/audio/music/music_act2_nightmare.ogg` | P1 | Bardziej niepokojąca, po BUM. |
| Klik UI | `assets/audio/sfx/ui/sfx_ui_click.wav` | P0 | Krótki, miękki klik. |
| Hover UI | `assets/audio/sfx/ui/sfx_ui_hover.wav` | P1 | Delikatny dźwięk najechania. |
| Dobranie karty | `assets/audio/sfx/cards/sfx_card_draw.wav` | P0 | Papier/karta. |
| Zagranie karty | `assets/audio/sfx/cards/sfx_card_play.wav` | P0 | Mocniejszy ruch karty. |
| Budowa | `assets/audio/sfx/cards/sfx_building_place.wav` | P0 | Drewno/młotek. |
| Ruch po biomie | `assets/audio/sfx/day_cycle/sfx_move_tile.wav` | P0 | Kroki/gałązki. |
| Koniec dnia | `assets/audio/sfx/day_cycle/sfx_end_day.wav` | P0 | Przygasanie ogniska/dzwon. |
| Nocne zdarzenie | `assets/audio/sfx/day_cycle/sfx_night_event.wav` | P0/P1 | Krótki niepokojący akcent. |
| BUM | `assets/audio/sfx/bum/sfx_bum_impact.wav` | P0 | Najważniejszy dźwięk: ciężki, zapamiętywalny. |
| Flip biomu | `assets/audio/sfx/bum/sfx_tile_corrupt.wav` | P0 | Odwrócenie/pęknięcie/magia. |
| Pożar | `assets/audio/sfx/bum/sfx_building_burn.wav` | P0 | Krótki ogień/trzask. |
| Atak potwora | `assets/audio/sfx/monsters/sfx_monster_attack.wav` | P0/P1 | Pazury/warczenie. |
| Deszcz | `assets/audio/sfx/weather/sfx_rain_loop.ogg` | P1 | Loop do ulewy. |
| Śnieżyca | `assets/audio/sfx/weather/sfx_blizzard_loop.ogg` | P1 | Loop do zimy. |

---

## 18. Minimalny backlog assetów dla Codexa

Poniższa lista jest dobra jako pierwsze zadanie dla Codexa, zanim zaczniesz masową generację grafik.

```text
1. Utwórz foldery w res://assets zgodnie ze strukturą z tego dokumentu.
2. Dodaj klasy/zasoby do mapowania art_path w danych kart/biomów/budynków, jeśli jeszcze ich nie ma.
3. W UI kart dodaj obsługę:
   - frame_path,
   - art_path,
   - icon_path,
   - card_back_path.
4. W UI biomu dodaj obsługę:
   - normal_art_path,
   - corrupted_art_path,
   - slot markerów,
   - overlay aktualnej pozycji i możliwego ruchu.
5. Przygotuj fallback placeholdery:
   - card_frame_placeholder.png,
   - icon_placeholder.png,
   - biome_placeholder.png,
   - building_placeholder.png.
6. Dopiero potem podmieniaj placeholdery na wygenerowane assety.
```

---

## 19. Assety startowe — absolutne minimum do wygenerowania najpierw

W tej kolejności:

1. `bg_run_table.png` — tło run screen.
2. `top_status_bar.png`, `panel_log_9slice.png`, `panel_hand_area.png`, `button_end_day.png`.
3. `card_frame_action.png`, `card_frame_building.png`, `card_frame_event.png`, `card_frame_monster.png`.
4. Ikony: zdrowie, sytość, nawodnienie, ciepło, energia, XP, jedzenie, woda, drewno, materiały, obrona, naprawa, ruina.
5. Biomy: Las, Łąki, Góry + wersje Plagi.
6. Sloty: empty, selectable, occupied, damaged, ruin.
7. Budynki: Ognisko, Szałas, Studnia — karta + token + damaged + ruin.
8. Akcje: Odpoczynek, Eksploruj, Rąb drewno, Zbieractwo, Opatrz rany, Źródło, Narzędzia.
9. Potwory Plagi: Zgnilec, Zarażony wilk, Krucza chmara, Rój szczurów.
10. BUM: flash, screen crack, plague cloud, burn marks, shockwave.

---

## 20. Prompt bazowy do generowania spójnych assetów

Używaj jednego wspólnego promptu bazowego i zmieniaj tylko temat:

```text
Pixel art asset for a dark survival card roguelike game, 2D, readable at small size, moody forest nightmare atmosphere, hand-painted pixel art look, limited color palette, high contrast silhouette, no text, no watermark, transparent background where applicable, consistent with a survival card game UI.
```

Dla kart:

```text
Vertical card illustration, dark survival pixel art, central object clearly visible, no text, no UI, no card frame, transparent or simple dark background, designed to be placed inside a card frame.
```

Dla biomów:

```text
Wide isometric/top-down inspired biome tile for a 2D card survival roguelike, pixel art, clear space for 2-4 building slots, readable terrain identity, no text, no UI, no characters.
```

Dla budynków:

```text
Small survival settlement building, pixel art, readable silhouette, centered object, no text, no UI, transparent background, suitable as both card illustration and board token.
```

---

## 21. Uwaga projektowa

Najważniejsze, żeby nie wygenerować jedynie „ładnych obrazków”. Ta gra opiera się na czytelności mechanik: gracz musi natychmiast widzieć, gdzie jest, który biom ma wolne sloty, który budynek jest uszkodzony, co kosztuje energia i co stanie się nocą. Dlatego assety UI, ikony i sloty są ważniejsze niż duże ilustracje kart.

---

## 22. Assety dla mechaniki odkrywania mapy w Akcie I

Mechanika odkrywania mapy zakłada, że na początku runu gracz widzi tylko kafel startowy, a pozostałe kafle planszy są ukryte jako `Nieznany teren`. Po wejściu na sąsiedni kafel zostaje on odkryty i dopiero wtedy pokazuje biom, sloty budynków, akcje zbierania oraz ewentualne zagrożenia.

Ta mechanika wymaga osobnego pakietu assetów UI/board, ponieważ zakryte kafle nie powinny wyglądać jak puste placeholdery — mają budować klimat eksploracji, niepewności i „wchodzenia w dzicz”.

### 22.1. Zasada wizualna

Zakryty kafel powinien wyglądać jak:

- pixel-artowa karta/mapa terenu przykryta mgłą,
- ciemnozielony lub niebiesko-zielony panel,
- zarys lasu, gór albo ścieżki w tle,
- napis `Nieznany teren` albo `???`,
- brak widocznych slotów budynków,
- brak widocznych akcji biomu,
- delikatna animacja mgły / połysku na krawędzi.

Po odkryciu kafel powinien płynnie przejść do właściwego biomu.

### 22.2. Assety P0 — niezbędne do pierwszej wersji odkrywania

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Zakryty kafel — neutralny | `assets/art/biomes/discovery/biome_unknown.png` | P0 | Podstawowy wygląd nieodkrytego kafla. Ciemna zieleń, mgła, zarys drzew/gór, napis `Nieznany teren`. |
| Zakryty kafel — sąsiedni dostępny | `assets/art/biomes/discovery/biome_unknown_reachable.png` | P0 | Wariant kafla, na który można wejść. Powinien mieć delikatne podświetlenie krawędzi. |
| Zakryty kafel — niedostępny | `assets/art/biomes/discovery/biome_unknown_locked.png` | P0 | Wariant kafla poza zasięgiem ruchu. Ciemniejszy, mniej kontrastowy. |
| Hover zakrytego kafla | `assets/art/biomes/discovery/biome_unknown_hover.png` | P0 | Podświetlenie po najechaniu myszką. Może mieć jaśniejszą ramkę i ikonę kompasu. |
| Ikona nieznanego terenu | `assets/art/biomes/discovery/icon_unknown_terrain.png` | P0 | Mała ikona `?`, kompasu albo mapy. Do kafla i tooltipów. |
| Ikona odkrycia | `assets/art/biomes/discovery/icon_discover.png` | P0 | Ikona używana w logu i komunikacie: `Odkryto nowy biom`. |
| Overlay mgły | `assets/art/biomes/discovery/overlay_fog.png` | P0 | Półprzezroczysta warstwa mgły na zakryte kafle. |
| Ramka odkrywalnego kafla | `assets/art/biomes/discovery/frame_reachable_9slice.png` | P0 | 9-slice / ramka dla kafla, na który można wejść. |
| Ramka zakrytego kafla | `assets/art/biomes/discovery/frame_unknown_9slice.png` | P0 | Standardowa ramka dla ukrytego kafla. |
| Marker startowego kafla | `assets/art/board/markers/marker_start_tile.png` | P0 | Ikona/znacznik miejsca startowego gracza. |

### 22.3. Assety P1 — lepsze feedbacki i animacje

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Animacja odkrycia kafla | `assets/art/fx/discovery/fx_tile_reveal_*.png` | P1 | Krótka animacja: mgła schodzi z kafla, pojawia się biom. 6–12 klatek. |
| Pixelowa mgła ruchoma | `assets/art/fx/discovery/fx_fog_loop_*.png` | P1 | Subtelna pętla mgły na nieodkrytych kaflach. |
| Błysk odkrycia | `assets/art/fx/discovery/fx_discover_flash_*.png` | P1 | Mały zielono-błękitny błysk przy odkryciu. |
| Komunikat odkrycia | `assets/art/ui/panels/panel_discovery_popup_9slice.png` | P1 | Mały popup: `Odkryto: Las`, `Odkryto: Rzeka`, etc. |
| Mini mapa / pergamin odkrycia | `assets/art/ui/icons/icon_map_fragment.png` | P1 | Ikona fragmentu mapy do kart typu Zwiad/Eksploruj. |
| Znacznik podejrzenia kafla | `assets/art/biomes/discovery/marker_peeked.png` | P1 | Jeśli karta Zwiad pozwala podejrzeć biom bez wejścia. |
| Overlay zarysu biomu — las | `assets/art/biomes/discovery/overlay_hint_forest.png` | P1 | Opcjonalny zarys/poszlaka: las. |
| Overlay zarysu biomu — woda | `assets/art/biomes/discovery/overlay_hint_water.png` | P1 | Opcjonalny zarys/poszlaka: rzeka/jezioro. |
| Overlay zarysu biomu — góry | `assets/art/biomes/discovery/overlay_hint_mountains.png` | P1 | Opcjonalny zarys/poszlaka: góry/wzgórza. |

### 22.4. Assety P2 — warianty klimatyczne

| Asset | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Zakryty kafel — las | `assets/art/biomes/discovery/biome_unknown_forest_hint.png` | P2 | Nie zdradza dokładnego biomu, ale sugeruje las. |
| Zakryty kafel — woda | `assets/art/biomes/discovery/biome_unknown_water_hint.png` | P2 | Sugeruje wodę, rzekę albo jezioro. |
| Zakryty kafel — góry | `assets/art/biomes/discovery/biome_unknown_mountain_hint.png` | P2 | Sugeruje teren skalisty. |
| Zakryty kafel — bagna | `assets/art/biomes/discovery/biome_unknown_swamp_hint.png` | P2 | Sugeruje ciężki, ryzykowny teren. |
| Zakryty kafel nocny | `assets/art/biomes/discovery/biome_unknown_night.png` | P2 | Wariant dla nocy / zdarzeń specjalnych. |
| Zakryty kafel przed BUM | `assets/art/biomes/discovery/biome_unknown_omen.png` | P2 | Od dnia ~15 może mieć subtelne oznaki katastrofy: łuna, martwe ptaki, zielone iskry. |

---

## 23. Karty i ikony powiązane z eksploracją mapy

Odkrywanie mapy warto powiązać nie tylko z ruchem, ale też z kartami. Dzięki temu eksploracja staje się decyzją strategiczną, a nie tylko kliknięciem sąsiedniego pola.

### 23.1. Karty eksploracji / zwiadu

| Karta | Ścieżka ilustracji | Priorytet | Opis ilustracji |
|---|---|---:|---|
| Eksploruj | `assets/art/cards/actions/action_explore.png` | P0 | Plecak, mapa i leśna ścieżka. Karta może dobierać kartę albo pomagać przy odkrywaniu. |
| Zwiad | `assets/art/cards/actions/action_scout.png` | P1 | Lornetka/kompas/mapa, widok na mglisty teren. Pozwala podejrzeć sąsiedni kafel. |
| Wytycz szlak | `assets/art/cards/actions/action_mark_trail.png` | P1 | Znaki na drzewach, małe chorągiewki, ścieżka przez trawę. Może obniżać koszt ruchu. |
| Mapa okolicy | `assets/art/cards/actions/action_local_map.png` | P1 | Pergamin z fragmentem planszy 3×2. Może odkrywać/oznaczać jeden kafel. |
| Wyprawa | `assets/art/cards/actions/action_expedition.png` | P2 | Dłuższa podróż przez las/wzgórza. Może pozwalać odkryć dalszy kafel. |

### 23.2. Ikony mechaniki eksploracji

| Ikona | Ścieżka | Priorytet | Opis |
|---|---|---:|---|
| Odkrycie | `assets/art/cards/icons/icon_discovery.png` | P0 | Kompas albo odsłonięta mapa. |
| Nieznany teren | `assets/art/cards/icons/icon_unknown.png` | P0 | Znak zapytania na mapie. |
| Podejrzyj kafel | `assets/art/cards/icons/icon_peek.png` | P1 | Oko/kompas/lornetka. |
| Koszt ruchu | `assets/art/cards/icons/icon_move_cost.png` | P0 | But / ślad / strzałka. |
| Sąsiedztwo | `assets/art/cards/icons/icon_adjacent.png` | P1 | Dwa połączone kafle. |
| Bezpieczny szlak | `assets/art/cards/icons/icon_safe_trail.png` | P2 | Ścieżka z małym listkiem. |
| Ryzykowny teren | `assets/art/cards/icons/icon_risky_terrain.png` | P2 | Ścieżka z ostrzeżeniem / czaszką / cierniem. |

---

## 24. Zmiany w strukturze plików pod odkrywanie mapy

Do struktury assetów należy dodać:

```text
res://
  assets/
    art/
      biomes/
        discovery/
          biome_unknown.png
          biome_unknown_reachable.png
          biome_unknown_locked.png
          biome_unknown_hover.png
          biome_unknown_forest_hint.png
          biome_unknown_water_hint.png
          biome_unknown_mountain_hint.png
          frame_unknown_9slice.png
          frame_reachable_9slice.png
          icon_unknown_terrain.png
          icon_discover.png
          marker_peeked.png
          overlay_fog.png
      fx/
        discovery/
          fx_tile_reveal_01.png
          fx_tile_reveal_02.png
          fx_tile_reveal_03.png
          fx_fog_loop_01.png
          fx_discover_flash_01.png
      ui/
        panels/
          panel_discovery_popup_9slice.png
        icons/
          icon_map_fragment.png
```

---

## 25. Krótki brief do generowania zakrytego kafla

### Zakryty kafel Aktu I

> Pixel art game biome tile, unknown terrain, dark green and teal fog, soft forest silhouettes, subtle map/compass icon, rectangular UI panel, clean readable card game board slot, cozy but mysterious Act I exploration mood, no puzzle shape, no visible building slots, premium retro pixel art.

### Kafel dostępny do odkrycia

> Pixel art unknown biome tile, reachable adjacent terrain, subtle glowing green border, misty forest silhouette, small compass icon, rectangular panel for survival card game UI, readable and polished, bright Act I palette with mystery.

### Odkrycie kafla

> Pixel art tile reveal effect, fog lifting from a rectangular biome panel, green-blue magical dust, small compass/map sparkle, clean readable effect for card survival game UI, 8 frame animation style.

---

## 26. Kontrola kompletności przed generowaniem

Lista jest jasna i wystarczająca jako plan produkcyjny, ale przed masowym generowaniem warto dopilnować jeszcze tych drobiazgów:

- **Fonty i bitmap font fallback:** osobny wybór fontu pixel/bitmap dla polskich znaków, cyfr na paskach i małych opisów kart.
- **Stany interakcji kart:** hover, selected, playable, unplayable, insufficient resources, target-required.
- **Popup nocnego zdarzenia:** osobny overlay/panel na dużą kartę po `Zakończ dzień`, przycisk `OK`, rewers karty zdarzenia w dużym rozmiarze i miejsce na podsumowanie efektu.
- **Ikony statusów budynków:** aktywny, uszkodzony, ruina, chroni nocą, produkuje zasób, wymaga naprawy.
- **Atlasy/spritesheety animacji:** dla ognia, dymu, mgły, deszczu, śniegu i flipu karty lepiej planować sekwencje `*_01.png` albo spritesheety z opisem liczby klatek.
- **Import preset Godot:** dla pixel artu spisać regułę `Filter: Nearest`, brak mipmap dla UI, powtarzalne ustawienia dla 9-slice i audio loopów.
- **Placeholder pack:** przygotować od razu minimalne placeholdery dla każdego typu assetu, żeby UI można było podpiąć zanim grafiki będą finalne.
