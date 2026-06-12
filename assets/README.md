# Dzien 50 Asset Structure

This directory mirrors `ASSET_PLAN_DZIEN_50_GODOT.md` and is ready for generated
or hand-made assets.

## Main Roots

- `art/ui/` - panels, buttons, bars, overlays, cursors, small UI icons.
- `art/cards/` - card frames, backs, icons, and illustration layers used by Godot card composition.
- `art/biomes/` - clean biome backgrounds plus separate frames, slots, overlays, miniatures, and discovery art.
- `art/concepts/` - full UI mockups and old assembled biome/card references; not production layers.
- `art/buildings/` - building icons, card art, board tokens, damaged states, ruins.
- `art/board/` - board backgrounds, grid pieces, connectors, player markers.
- `art/fx/` - BUM, fire, smoke, corruption, weather, monster, card, discovery FX.
- `art/backgrounds/` - screen backgrounds for menu, run, result, collection, class select.
- `art/fonts/` - bitmap/pixel fonts and font fallback assets.
- `placeholders/` - temporary art used before final assets are generated.
- `audio/` - music and SFX, grouped by gameplay use.

## Import Notes

- Pixel art should use nearest filtering in Godot.
- UI panels intended for scaling should be prepared as 9-slice assets.
- Use `snake_case` filenames without Polish characters.
- Production assets are text-free. Names, costs, counters, descriptions, labels,
  and Polish UI strings are editable Godot text.
- Full UI screens are concept/mockup only.
- Final cards are assembled from `cards/frames/`, `cards/illustrations/`, icons,
  and text in Godot.
- Building illustration split: `art/cards/illustrations/buildings/` is kept as
  the dark Act II/post-BUM set, while the approved bright Act I set is in
  `art/cards/illustrations/buildings_act1_candidates/` (final files omit
  `_candidate`; the two `_candidate` files are approval samples).
- Action illustration split: `art/cards/illustrations/actions/` is kept as the
  dark Act II/post-BUM set, while the approved bright Act I set is in
  `art/cards/illustrations/actions_act1_candidates/`.
- Icon workflow: `art/cards/icons/` currently remains the working flat
  placeholder set. The generated deck-style replacement candidates are in
  `art/cards/icons_deck_style_candidates/` (`64x64`) with larger `source_128/`
  versions; old flat icons are archived in
  `art/concepts/cards/icons_legacy_flat_reference/`.
- Final biomes are clean terrain backgrounds from `biomes/backgrounds/` with
  separate frames, title plates, slots, highlights, and overlays.
- Biome frame/slot workflow: production `biomes/frames/` now follows the
  lighter `biome_neighbor_highlight.png` style, but `biome_tile_frame.png`
  must remain a fully closed continuous frame and `biome_title_plate.png`
  must keep a solid dark filled center for readable one-color Godot text.
  `biomes/slot_markers/` currently needs only `slot_empty.png` and
  `slot_selectable.png`; both should match this closed light ornamental style
  with dark filled centers. Earlier frame copies are kept under
  `art/concepts/biomes/frames_before_neighbor_highlight_style/` and
  `art/concepts/biomes/frames_neighbor_style_open_frame_reference/`.
- Biome overlays in `biomes/overlays/` are raw full-canvas green-key PNGs.
  Do not remove the green background during asset generation; keep `#00FF00`
  intact and let Godot/import tooling key it later so ornate tips are not
  clipped.
- Board backgrounds: `board/backgrounds/bg_biome_board.png` is the current
  default Act I board background; explicit variants are
  `bg_biome_board_act1.png` and `bg_biome_board_act2.png`.
- Board connectors: `board/connectors/neighbor_connector.png` is a raw
  green-key `512x96` ornament connector matching the corrected biome frame
  style.
- FX assets in `fx/` were regenerated as raw green-key pixel-art overlays and
  sprites. Keep `#00FF00` as the transparent/key area during generation; Godot
  or import tooling should handle keying later.
- `biomes/discovery/` is still EMPTY (structure audit 2026-06-12): the
  fog-of-war tile pack (`biome_unknown*`, fog overlay, 9-slice frames, hint
  overlays) is planned in `ASSET_PLAN_DZIEN_50_GODOT.md` but not generated
  yet. Existing discovery-adjacent assets: `art/fx/discovery/`,
  `art/ui/panels/panel_discovery_popup_9slice.png`,
  `art/cards/icons/icon_discovery.png`.
