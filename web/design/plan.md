# Dzień 50 — web port — design/plan.md (mode S, §§1–5 merged)

Source of truth for rules: repo README.md (concept) + CLAUDE.md (balance of the
Godot vertical slice). This is a faithful browser port of the slice EXTENDED
with the BUM act (README §5–6), run shortened to 30 days per README §10.

## §1 Profile (one sentence per axis)

- Time: turn-based (a turn = one day; no real-time pressure).
- Space: discrete — a 3×2 board of biome tiles + an abstract card hand.
- Agency: one embodied survivor (a pawn on the board).
- Conflict: versus the system (seasons→catastrophe→monsters; no other players).
- Content: authored cards/biomes + procedural board & deck shuffles.
- Outcome: finite — survive to day 30 = win, health 0 = lose.
- Players: solo (multiplayer.md not opened — axis is solo).
- Session: one run ≈ 20–40 min, replayable.
- Engagement source (primary 1–2): calculation + growth/accumulation.
- Strictness mode: S.

Delivery context:
- Platforms: desktop web + mobile web (responsive, tap-first).
- Input: mouse/touch primary (every verb is a tap); keyboard shortcuts on
  physical codes (Space = end day, Digit1..5 = play hand card). Gamepad:
  DEFERRED — recorded deviation from the web default; a card/board game has
  no continuous input, full focus-navigation UI is out of S scope.
- Languages: Polish (player-facing), strings in one external STRINGS map in
  logic-agnostic UI layer; adding a language = data task.
- Perf budgets (§7.5): see design/thresholds.md.

## §2 Laws

- L2 (action→effect→later): every card pays costs now and shifts stats that
  the night phase re-reads; buildings persist on tiles and feed every later
  night; reward picks permanently alter the deck.
- L3 learnable patterns: (1) needs economy — food/water/warmth decay vs
  gather actions; (2) settlement placement — slots are scarce (2–4/tile),
  passives are global; (3) biome routing — which tile offers which gather,
  movement costs energy; (4) Act II — defense/repair triage after BUM.
- Loops: short = one card decision; medium = one day (spend 10 energy);
  long = the run arc Act I build-up → BUM loss → Act II survival.
- Uncertainty sources (2–3 + carriers): randomness BEFORE decisions (dawn
  hand draw, board layout, event deck); hidden information (event deck
  contents, BUM day rolled 12–15); analytic complexity (energy allocation
  across cards/gathers/moves).
- Comeback: ruins are dismantlable for 50% resources; rewards keep coming;
  hut/palisade mitigate the night — a wounded run can stabilize.

## §3 Concept

- Experience formula: the player feels the pride and dread of a homesteader
  in a dream turning into a nightmare, because the game constantly converts
  their daily card choices into a visible settlement — and then makes them
  defend its remains.
- Pillars: Mechanics load-bearing (cards-as-everything); Story = the two-act
  arc with foreshadowing; Aesthetics = somber pixel-art wilderness;
  Technology = single-page JS, deterministic seeded logic.
- Formal elements: players 1; goal survive day 30; actions = play/build/
  gather/move/end-day/choose-reward/repair/dismantle; rules explicit;
  resources = food, water, wood, materials, energy, HP/hunger/thirst/warmth,
  card slots; conflict = scarcity + night events + monsters; boundary = one
  run; outcome win/lose.
- Interest curve (session): hook = waking alone with 4 cards (3) → first
  buildings (5) → foreshadowing signs (6) → BUM spike (9) → Act II grind
  rising to final nights (8–9) → dawn of day 30 (10).

## §4 System

- Verbs (strong marked *): *play card (objects: action cards, building
  cards, tiles, stats), *gather (biome cards × tile state), *move (6 tiles),
  end day, choose reward (3 options × pool), repair/dismantle (Act II,
  buildings/ruins). Development: gather cards change meaning post-BUM
  (corrupted faces), buildings change from economy to defense targets.
- Feedback loops: building up = positive (more passives) — countered by BUM
  damage + monsters targeting buildings; starvation spiral = negative —
  countered by auto-eat/auto-drink and first-aid/reward heals.
- Information map: open = board, stats, hand, buildings, day counter;
  hidden-known = event deck composition (player saw biome hazards join it),
  deck draw order; hidden-system = BUM exact day (foreshadowed from day 8
  by sign events), monster mix. Player learns hidden facts via foreshadow
  log lines and the visible biome hazard list.

## §5 Prototype (question + evidence)

- Question: "does the daily needs economy create real decisions and is the
  win reachable for a non-expert line of play?"
- Evidence: the rules model ALREADY exists and was measured in the Godot
  vertical slice (CLAUDE.md): naive greedy bot 46/50 wins (~92%, avg level
  6.4) at 15 days without BUM. The web port re-runs the same method: a Node
  headless bot over logic.js (same rules + BUM act), corridor in
  design/thresholds.md. The Node bot run IS this stage's verification run;
  its numbers are quoted in the delivery report.

## Rules data (port contract)

Constants and card list ported 1:1 from CLAUDE.md/Godot data (energy 10,
move 1, hunger/thirst −2/day, warmth −1/day, food +2 (Cook +3), water +2,
deficiency damage −2 each, night-protection −2, tools +1, XP +1/+3,
level cost 8+4×(lvl−1), rewards +1 max energy / +1 max HP (+2 heal) /
new card 1-of-3 from 20-card pool). Extensions for this port (README §5–6):
run 30 days; BUM on a random day 12–15 → every tile flips to corrupted
face, every building rolls 20–80% damage (≥50% = ruin: only dismantle for
50% refund; <50% = damaged: passive off until repaired for proportional
wood/materials); plague monster cards (Zgnilec ×3, Wyjec ×2) join the event
deck (−2 HP / −2 building HP, mitigated by Palisada defense and Szałas);
new Act II cards in pool: Palisada (building, defense), Rozbiórka (action),
Pochodnie (warmth+defense). Foreshadow events from day 8.

## §6-style refusals (mode S)

- Audio: ABSENT — silent jam build; the BUM moment is sold visually
  (screen shake + corrupted palette + splash art). Recorded as future work.
- Meta-progression, classes beyond Kucharz, seasons: out of slice scope
  (same cut as the Godot slice; README milestones 2+).
- Save/load mid-run: absent — a run is one sitting (20–40 min), state kept
  in memory; refresh restarts (recorded as accepted limitation).
