# design/thresholds.md — fixed before implementation (mode S)

Performance (web, weakest platform = mid mobile):
- target_fps: 60 (frame budget 16 ms); smoke red line: avg < 45 fps.
- draw_call_budget: 80 (mobile). This is a DOM/canvas-free card game: the
  equivalent measured numbers are (a) FPS from a rAF counter, (b) DOM node
  count of the worst-case scene ≤ 400, (c) zero per-frame allocations — no
  rAF game loop at all outside transient animations (turn-based, event-driven).
- worst_case_scene: day in Act II — full board (6 tiles, 12 building chips,
  corruption overlays), hand of 7 cards, 4 gather cards, level-up overlay
  with 3 card choices open, log at 300 lines, BUM shake animation running.

Logic verification (Node bot, fixed seeds):
- termination: 100% of 200 simulated runs end in win/lose ≤ 200 days guard.
- naive-bot win-rate corridor: 35–75% with BUM act enabled (BUM must hurt:
  clearly below the 92% no-BUM Godot baseline, clearly above hopeless).
- contrast route: a deliberately-bad bot (never builds, never gathers water)
  must win < 5% of runs (decisions matter, L2).
- avg run length of losses ≥ 8 days (no instant unfair deaths).
- determinism: same seed → identical end-state hash on 2 reruns.

Game entry:
- launch → first meaningful action (playing a card) ≤ 3 steps
  (load page → click "Nowy run" → click a card).
