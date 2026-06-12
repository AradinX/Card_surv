# Dzień 50 — port przeglądarkowy (Higgsfield)

Grywalny web-port konceptu z głównego README repo (vertical slice + akt BUM),
zbudowany pipeline'em game-generation Higgsfield.ai (mode S).

**Graj:** https://simple-warbler-784.higgsfield.gg/
(game_id do aktualizacji: `1b6e68ea-a228-463a-9e2f-631072055416`;
pierwszy, martwy deploy: `c9230c77-db21-470c-9f2d-a157691d746b` /
bold-poppy-279 — ścieżka UPDATE platformy padała, szczegóły w
design/gates.md)

- `public/` — źródła gry (logic.js = czysty moduł reguł; assets/rules.js
  to jego dosłowna kopia importowana przez klienta, bo platforma nie
  serwuje root logic.js; index.html = klient canvas; strings.js = wszystkie
  teksty PL).
- `design/` — artefakty pipeline'u: plan, progi, manifest assetów, bramki
  (w tym STYLE FORMULA i historia iteracji balansu).
- `tools/` — weryfikacja headless: sim.mjs (boty + determinizm),
  diag.mjs (diagnoza źródeł obrażeń), smoke.mjs (Chrome: FPS/draw ops/
  zrzuty layoutu).
- `_tools/`, `dzien50.zip` — lokalne narzędzia i paczka deployu (poza git).

Różnice reguł względem slice'a w Godot (decyzje balansu web — patrz
design/gates.md): run 30 dni, BUM dnia 12–15 (flip kafli, 20–80% obrażeń
budynków, próg ruiny 50%, potwory w talii zdarzeń), rozbiórka ruiny zwraca
kartę budynku do talii, Wilki chronione schronieniem, pula nagród Aktu II
+ Palisada/Pochodnie, skażone źródła wody w skorumpowanych biomach.

Aktualizacja gry: spakuj `public/*` (zip, wpisy z `/`), `media_upload` →
PUT → `media_confirm` → `deploy_game` z powyższym game_id.
