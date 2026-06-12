# Dzień 50 — ART_PROMPT_TEMPLATES.md

Gotowy zestaw szablonów promptów do generowania assetów graficznych dla projektu **Dzień 50 / Day Fifty**.

Ten plik jest przeznaczony do użycia przez Codexa, Claude’a albo jako stały brief artystyczny w repo. Cel: utrzymać jeden spójny styl generowanych grafik.

---

## 1. Asset generation defaults for Dzień 50

Always follow these rules when generating art assets:

- Style: **premium pixel art**
- Never use photorealistic, cinematic, painterly, glossy, or 3D render style.
- Full gameplay screens are **concept/mockup only**. They can show the whole
  assembled interface for direction, but they are not production UI assets.
- Final biome assets are **clean terrain backgrounds only**: no baked frame,
  no title plate, no slot cards, no counters, no labels, no UI widgets. Godot
  composes biome frame, title plate, slot markers, highlights, overlays, and
  text above the biome background.
- Final cards are assembled in Godot from separate layers: `card_frame_*`,
  card illustration, icons/cost sockets, and editable text. Do not generate
  final full cards unless explicitly requested as a concept/mockup.
- Frames, slot markers, plates, buttons, panels, icons, overlays, and card
  illustrations are separate production asset types.
- Production art assets must be **text-free**. Leave empty title plaques,
  cost sockets, button bodies, info panels, frames, labels, and other UI
  containers blank. All names, numbers, costs, descriptions, counters, and
  Polish UI text are added later in Godot as editable text layers.
- The only exception is a temporary visual mockup explicitly requested as a
  mockup/reference, not a production asset.
- UI style: **dark wood + muted green + parchment**.
- Board layout: **rectangular 3×2 biome board**.
- Never use puzzle-shaped board elements.
- Act I: bright, lush, green-blue, natural, calm, hopeful.
- Act II: darker, corrupted, colder, ruined, same world after catastrophe.
- Cards: built from separate frame, illustration, icons, and editable text.
- Biomes: clean rectangular terrain backgrounds, with UI overlays added in Godot.
- Building assets: generate both card art and board token versions when useful.
- Icons: simple, readable, pixel-art silhouettes.
- Default output format: `png`.
- Default quality: `high`.
- Default number of images: `1`.

Preferred size presets:

```text
icons: square_hd / 1024x1024
building_tokens: square_hd / 1024x1024
cards: portrait_hd / 1024x1536
biome_tiles: landscape_hd / 1536x1024
full_ui_screens: wide_ui / 1792x1024 or 1600x900
```

Recommended production paths:

```text
concept/mockup screens: assets/art/concepts/ui_screens/
concept biome boards: assets/art/concepts/biomes/
concept assembled cards: assets/art/concepts/cards/
clean biome backgrounds: assets/art/biomes/backgrounds/normal/
clean corrupted biome backgrounds: assets/art/biomes/backgrounds/corrupted/
biome UI frames and title plates: assets/art/biomes/frames/
biome slots: assets/art/biomes/slot_markers/
card frames and masks: assets/art/cards/frames/
card illustrations: assets/art/cards/illustrations/<type>/
```

---

## 2. MASTER TEMPLATE — universal asset prompt

Use this when no more specific template fits.

```md
# IMAGE PROMPT MASTER TEMPLATE — DZIEŃ 50

Intended use:
Create a clean production-ready game asset for the project "Dzień 50".

Project context:
"Dzień 50" is a 2D survival card roguelike with a premium pixel art style.
The game uses:
- rectangular 3x2 biome board
- card-based actions and buildings
- dark wood + parchment UI
- clear readable icons
- strong difference between Act I and Act II

Interpret the user request as:
- the ASSET IDENTITY and FUNCTION only
- do not follow any unintended realistic, cinematic, painterly, 3D, glossy, or photorealistic styling
- always preserve the approved visual direction of the project

Global style target:
- premium pixel art
- polished retro strategy game aesthetic
- readable game asset design
- strong silhouette and clean composition
- crisp pixel clusters
- limited but rich palette
- no photorealism
- no 3D render look
- no painterly blur
- no soft AI mush
- clean edges and readable forms

Project visual direction:
- Act I: bright, natural, green-blue, calm, lush, safe, nature-forward
- Act II: darker, corrupted, cold, toxic, ruined, same world after catastrophe
- UI: dark wood, muted green, parchment panels, readable pixel typography
- board tiles: rectangular, not puzzle-shaped
- cards: clean vertical card layout, readable title, illustration, clear info area

Asset type:
{ASSET_TYPE}

Asset purpose:
{ASSET_PURPOSE}

Subject:
{SUBJECT_DESCRIPTION}

Act / world state:
{ACT_STATE}
Examples:
- Act I
- Act II
- neutral UI
- usable in both acts

Style-specific requirements:
{STYLE_REQUIREMENTS}

Composition:
{COMPOSITION_REQUIREMENTS}

Background:
{BACKGROUND_REQUIREMENTS}

Text rendering:
Production assets: no text, no labels, no numbers, no pseudo-text. Leave
all title areas and UI containers blank for editable Godot text.

Technical output target:
- image_size: {IMAGE_SIZE}
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
{CONSTRAINTS}

Avoid:
- realistic rendering
- cinematic lighting
- painterly brushwork
- 3D model look
- blurred texture mush
- over-detail that hurts readability
- unrelated props
- extra characters unless requested
- scenery outside the asset scope
- cropped important elements
- inconsistent style with the rest of the game
- puzzle-shaped board panels
```

---

## 3. TEMPLATE — full gameplay UI screen mockup

```md
# IMAGE PROMPT TEMPLATE — FULL UI SCREEN MOCKUP

Intended use:
Create a full gameplay UI mockup for "Dzień 50".

Project context:
This is a premium pixel art survival card roguelike.
The approved layout includes:
- top HUD
- rectangular 3x2 biome board
- right-side journal
- bottom card hand area
- dark wood + parchment UI
- no puzzle-shaped board sections

Global style target:
- premium pixel art
- polished retro strategy UI
- readable game screen
- strong visual hierarchy
- clean information grouping
- crisp pixel clusters
- no photorealism
- no 3D
- no painterly blur

Asset type:
Full gameplay UI mockup

Asset purpose:
A presentation mockup of the main gameplay screen.

Subject:
{SCREEN_DESCRIPTION}
Example:
- Act I forest-themed run screen
- Act II plague-themed run screen
- BUM transition screen

Act / world state:
{ACT_STATE}

Style-specific requirements:
{STYLE_REQUIREMENTS}

Composition:
- wide 16:9 screen
- top status HUD
- center 3x2 rectangular biome board
- right journal panel
- bottom card/action row
- clear readable Polish UI text if requested
- strong distinction between board, HUD, and hand area

Background:
- full-screen mockup

Text rendering:
{TEXT_REQUIREMENTS}

Technical output target:
- image_size: wide_ui
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must match the chosen project style
- no puzzle board layout
- must feel like a real game screen, not a loose concept art sheet

Avoid:
- photorealism
- painterly rendering
- modern mobile-game style
- generic fantasy UI unrelated to the project
- puzzle-shaped board panels
```

---

## 4. TEMPLATE — clean biome background

```md
# IMAGE PROMPT TEMPLATE — CLEAN BIOME BACKGROUND

Intended use:
Create a clean production-ready biome background for the board in "Dzień 50".

Project context:
"Dzień 50" is a 2D survival card roguelike with premium pixel art.
Board layout is rectangular 3x2. Godot composes the final biome tile from
separate layers: clean biome background, biome frame, title plate, slot markers,
state overlays, and editable text.

Interpret the user request as:
the biome identity and gameplay readability only.
Do not introduce realism, 3D, cinematic, painterly, unrelated scene complexity,
or baked UI elements.

Global style target:
- premium pixel art
- polished retro strategy game aesthetic
- clean readable biome panel
- rich but controlled environment detail
- crisp shapes
- readable even at board scale

Asset type:
Clean biome background

Asset purpose:
A pure terrain/background layer used inside a rectangular biome tile.

Subject:
{BIOME_NAME}
Example:
- Forest biome
- Meadow biome
- River biome
- Lakeshore biome
- Hills biome
- Corrupted forest biome

Act / world state:
{ACT_STATE}
Example:
- Act I
- Act II

Style-specific requirements:
{STYLE_REQUIREMENTS}
Examples:
- Act I: bright, lush, calm, green-blue, safe, sunny
- Act II: corrupted, darker, dead vegetation, toxic glow, ruined atmosphere

Composition:
- one rectangular terrain background
- wide horizontal composition
- readable central area
- visible environmental identity
- leave visually calm areas where Godot can overlay 2-4 building slots
- no title plaque, no frame, no slot cards, no counters, no captions
- no puzzle connectors and no separate UI around the image

Background:
- no transparency
- the full image is the clean biome terrain background

Text rendering:
Production biome backgrounds are always text-free: no text, no labels,
no numbers, no pseudo-text, no fake glyphs.

Technical output target:
- image_size: landscape_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must fit the approved board style
- must remain readable when scaled down
- should visually match other biome tiles
- should support slot, frame, title, and highlight overlays later

Avoid:
- puzzle-shaped board tile
- any frame, title plate, slot card, label, number, or UI element
- photorealism
- cinematic concept art style
- excessive clutter
- human characters unless explicitly requested
- giant foreground objects blocking slot space
```

---

## 5. TEMPLATE — hidden / unknown biome tile

Use for the Act I map discovery mechanic.

```md
# IMAGE PROMPT TEMPLATE — UNKNOWN BIOME TILE

Intended use:
Create a clean production-ready hidden biome tile for the Act I map discovery mechanic in "Dzień 50".

Project context:
At the start of Act I, most biome tiles are hidden as "Nieznany teren".
The player reveals tiles by moving onto adjacent tiles.
The hidden tile should feel mysterious but still cozy and readable.

Global style target:
- premium pixel art
- polished retro strategy UI
- mysterious but not horror
- readable rectangular board tile
- no puzzle shape
- crisp pixel clusters

Asset type:
Unknown biome tile

Asset purpose:
A hidden board tile displayed before a biome is discovered.

Subject:
Unknown terrain / hidden biome / fog-covered map tile

Act / world state:
Act I discovery

Style-specific requirements:
- dark green and teal fog
- soft forest or mountain silhouettes
- subtle mystery
- cozy exploration mood
- gentle glow or compass/map motif
- no clear biome identity unless this is a hint variant

Composition:
- one rectangular tile
- no visible building slots unless requested
- optional small compass icon
- optional title area
- centered readable mystery symbol
- enough clean space for UI overlay

Background:
- full tile asset
- no transparency

Text rendering:
{TEXT_REQUIREMENTS}
Examples:
- no text
- render Polish text exactly: "Nieznany teren"
- render Polish text exactly: "???"

Technical output target:
- image_size: landscape_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must match Act I biome tile style
- must be visually distinct from revealed tiles
- must show that the tile is clickable/discoverable when highlighted

Avoid:
- horror mood
- too much darkness
- puzzle-shaped tile
- clear revealed biome identity
- photorealism
- painterly blur
```

---

## 6. TEMPLATE — building card

```md
# IMAGE PROMPT TEMPLATE — BUILDING CARD

Intended use:
Create a clean production-ready building card for "Dzień 50".

Project context:
"Dzień 50" is a 2D survival card roguelike in premium pixel art style.
Buildings exist both as cards and as board objects.

Interpret the user request as:
the building identity and gameplay readability only.
Do not follow realistic, painterly, cinematic, or 3D styling.

Global style target:
- premium pixel art
- readable survival card game asset
- bright parchment card body
- clear title area
- large readable building illustration
- clear lower info section

Asset type:
Building card

Asset purpose:
A vertical card used in the player's deck / hand.

Subject:
{BUILDING_NAME}
Example:
- Well
- Campfire
- Hut
- Barricade
- Palisade
- Workshop

Act / world state:
{ACT_STATE}
Usually:
- neutral UI
- usable in both acts

Style-specific requirements:
- premium pixel art
- dark wood + parchment card game style
- clear readable iconography
- strong silhouette of the building
- no clutter

Composition:
- exactly one vertical card
- title area at top
- one central building illustration
- lower information area kept clean and readable
- centered layout
- building should be fully visible
- no extra cards
- no full-screen UI scene

Background:
- full card asset
- no transparency unless explicitly requested

Text rendering:
{TEXT_REQUIREMENTS}
Examples:
- no text, only visual card frame
- render exact Polish title: "Studnia"
- optional tag: "BUDYNEK"

Technical output target:
- image_size: portrait_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- card must visually match the rest of the game
- card art should remain readable in smaller UI scale
- building must be instantly recognizable

Avoid:
- multiple buildings
- extra scenery beyond what supports the card illustration
- photorealism
- 3D object render look
- muddy pixel texture
- unreadable tiny details
```

---

## 7. TEMPLATE — building board token

```md
# IMAGE PROMPT TEMPLATE — BUILDING TOKEN

Intended use:
Create a clean board token / board object asset for a building in "Dzień 50".

Project context:
This asset is placed onto a biome slot on the board after the building is constructed.

Interpret the user request as:
the board representation of the building only.

Global style target:
- premium pixel art
- readable at small size
- simple but recognizable
- consistent with the building card illustration

Asset type:
Building board token

Asset purpose:
A small building representation placed on a biome slot.

Subject:
{BUILDING_NAME}

Act / world state:
{ACT_STATE}
Examples:
- normal
- damaged
- ruin

Style-specific requirements:
- clean silhouette
- readable from a distance
- minimal clutter
- visually tied to the matching building card

Composition:
- exactly one building object
- centered
- enough margin around the object
- no additional scenery
- no other objects unless part of the building

Background:
{BACKGROUND_REQUIREMENTS}
Recommended:
- solid exact chroma green background #00FF00
or
- transparent-looking plain background if your pipeline prefers manual cutout

Text rendering:
- no text
- no labels
- no UI

Technical output target:
- image_size: square_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must read clearly when scaled down
- should have a strong silhouette
- should work on top of biome slot panels

Avoid:
- wide scene composition
- extra props outside the building concept
- heavy shadows touching the frame
- realism or painterly style
```

---

## 8. TEMPLATE — action card

```md
# IMAGE PROMPT TEMPLATE — ACTION CARD

Intended use:
Create a clean production-ready action card for "Dzień 50".

Project context:
Action cards are part of the player's deck and must be readable, elegant, and clearly themed.

Global style target:
- premium pixel art
- parchment card body
- clear title and cost area
- strong readable illustration
- strategy/survival game readability

Asset type:
Action card

Asset purpose:
A playable deck card representing an action.

Subject:
{CARD_NAME}
Example:
- Odpoczynek
- Eksploruj
- Opatrz rany
- Rąb drewno
- Zbieractwo
- Zwiad
- Wytycz szlak

Act / world state:
{ACT_STATE}
Usually:
- neutral
- Act I leaning
- Act II variant if corrupted/scavenging themed

Style-specific requirements:
{STYLE_REQUIREMENTS}

Composition:
- one vertical card
- title area at top
- central illustration representing the action
- clear bottom text/effect area
- readable even at smaller UI scale

Background:
- full card asset

Text rendering:
{TEXT_REQUIREMENTS}

Technical output target:
- image_size: portrait_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- illustration must clearly communicate the action
- card must match building and event cards stylistically

Avoid:
- full environment scenes
- multiple unrelated subjects
- photorealistic tools or scenery
- messy composition
```

---

## 9. TEMPLATE — event card / night event popup

```md
# IMAGE PROMPT TEMPLATE — NIGHT EVENT CARD

Intended use:
Create a clean large night event card / popup card for "Dzień 50".

Project context:
When the player clicks "Zakończ dzień", a large event card appears on screen.
The player must read the event and click OK before the effect is resolved.

Global style target:
- premium pixel art
- readable large card
- atmospheric but clear
- strong mood
- no photorealism
- no painterly blur

Asset type:
Night event card / popup card

Asset purpose:
A large card displayed in the center of the screen after ending the day.

Subject:
{EVENT_NAME}
Example:
- Spokojna noc
- Ulewa
- Chorobliwa mgła
- Powódź
- Martwe ptaki
- Zgnilec

Act / world state:
{ACT_STATE}
Example:
- Act I nature event
- Act I omen event
- Act II monster event
- Act II plague event

Style-specific requirements:
{STYLE_REQUIREMENTS}

Composition:
- one large vertical or slightly wider event card
- title area at top
- large central illustration
- clean text area at bottom
- room for effect description
- optional OK button area below the card if this is a full popup concept

Background:
- full card asset or popup card on simple darkened overlay

Text rendering:
{TEXT_REQUIREMENTS}
Examples:
- no text, only title placeholder
- render exact Polish title: "Spokojna noc"
- render title and short effect text if requested

Technical output target:
- image_size: portrait_hd or square_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must be readable and dramatic enough to stop the player for a moment
- should match card frame system
- should work as the center focus of a darkened end-of-day screen

Avoid:
- tiny unreadable text
- cluttered composition
- full-screen scene unrelated to card UI
- realism or 3D
```

---

## 10. TEMPLATE — monster card

```md
# IMAGE PROMPT TEMPLATE — MONSTER CARD

Intended use:
Create a clean production-ready monster card for Act II of "Dzień 50".

Project context:
Monsters appear after BUM as night event threats.
They are not classic combat enemies; they represent pressure on buildings, resources, and survival stats.

Global style target:
- premium pixel art
- dark survival card game look
- readable monster silhouette
- ominous but not gore
- no photorealism
- no 3D

Asset type:
Monster card

Asset purpose:
A negative event/threat card added to the night event deck after BUM.

Subject:
{MONSTER_NAME}
Example:
- Zgnilec
- Cień z lasu
- Nosiciel Plagi
- Sfora
- Zjawa

Act / world state:
Act II

Style-specific requirements:
- corrupted nature
- dark teal, gray, violet, toxic green accents
- strong silhouette
- readable threat identity
- no excessive gore

Composition:
- one vertical card
- title area at top
- central monster illustration
- lower effect area
- monster should be fully visible
- no extra characters unless requested

Background:
- full card asset

Text rendering:
{TEXT_REQUIREMENTS}
Examples:
- no text
- render exact Polish title: "Zgnilec"

Technical output target:
- image_size: portrait_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- monster must fit Act II plague/corruption atmosphere
- should look like part of the same card system
- must remain readable when scaled down

Avoid:
- horror gore
- realistic zombie photo look
- 3D creature render
- overly detailed anatomy
- unrelated fantasy monsters that do not fit survival dream/plague mood
```

---

## 11. TEMPLATE — UI icon

```md
# IMAGE PROMPT TEMPLATE — UI ICON

Intended use:
Create a clean UI icon for "Dzień 50".

Project context:
The icon will be used in HUD, card costs, tooltips, and logs.

Global style target:
- premium pixel art
- ultra-readable
- simple silhouette
- minimal detail
- strong contrast

Asset type:
UI icon

Asset purpose:
A small icon for gameplay readability.

Subject:
{ICON_NAME}
Example:
- health
- hunger
- thirst
- warmth
- energy
- wood
- water
- materials
- discovery
- movement
- defense
- repair
- ruin

Act / world state:
neutral UI

Style-specific requirements:
- pixel-perfect readability
- simple shape
- clear edge definition
- no unnecessary decoration

Composition:
- exactly one icon
- centered
- large enough inside the frame
- equal margin on all sides

Background:
- solid exact chroma green background #00FF00
or plain flat background for clean cutout pipeline

Text rendering:
- no text
- no labels

Technical output target:
- image_size: square_hd
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must remain readable at tiny size
- must visually match all other game icons

Avoid:
- complex scenes
- gradients if they reduce clarity
- soft blur
- realistic rendering
```

---

## 12. TEMPLATE — BUM transition / catastrophe overlay

```md
# IMAGE PROMPT TEMPLATE — BUM TRANSITION / CATASTROPHE OVERLAY

Intended use:
Create a visual effect or overlay for the BUM transition in "Dzień 50".

Project context:
BUM is the central twist of the game.
The board changes from Act I natural world into Act II corrupted world.
Buildings are damaged or ruined, and the event deck becomes infected with monsters.

Global style target:
- premium pixel art
- dramatic but readable
- dream turning into nightmare
- no photorealism
- no 3D
- no painterly blur

Asset type:
BUM transition overlay / FX frame / screen concept

Asset purpose:
Used during the transition from Act I to Act II.

Subject:
{BUM_EFFECT_DESCRIPTION}
Example:
- bright flash over the board
- toxic green corruption spreading
- cracked sky
- falling ash
- board tile flip effect

Act / world state:
Transition from Act I to Act II

Style-specific requirements:
- strong visual contrast
- ominous sky or flash
- toxic green / cold blue / ember orange accents
- should not hide UI permanently
- readable as an effect layer

Composition:
- wide screen overlay or FX sprite
- centered impact or spreading corruption
- transparent/overlay-friendly composition if requested
- no new UI layout

Background:
{BACKGROUND_REQUIREMENTS}
Examples:
- transparent background if supported
- black background for additive effect
- full-screen darkened overlay

Text rendering:
- no text
- no labels

Technical output target:
- image_size: wide_ui
- output_format: png
- quality: high
- num_images: 1

Asset constraints:
- must support layered use in Godot
- should read clearly for 0.5–2 seconds
- should not look like a separate cutscene style

Avoid:
- realistic explosion
- modern sci-fi blast
- gore
- excessive particle chaos
- unreadable blur
```

---

## 13. Quick prompt snippets

### Act I visual snippet

```text
Act I visual style: bright premium pixel art, lush green forest and meadow palette, sky blue and water blue accents, sunlight, wildflowers, calm survival atmosphere, cozy nature exploration, readable retro strategy UI.
```

### Act II visual snippet

```text
Act II visual style: corrupted premium pixel art, dark forest green, desaturated teal, cold blue, muted violet, toxic lime glow, ruined vegetation, dead branches, fog, same world after catastrophe, ominous but readable survival UI.
```

### Card style snippet

```text
Card style: vertical parchment card, dark wood/green frame, clean pixel-art illustration, readable title area, clear lower effect area, consistent survival deckbuilder UI.
```

### Board style snippet

```text
Board style: clean rectangular 3x2 biome board, no puzzle shapes, pixel-art landscapes, readable building slots, dark wood and muted green frames, premium retro strategy game interface.
```

### Icon style snippet

```text
Icon style: simple premium pixel-art icon, strong silhouette, centered, readable at tiny size, no text, no extra decoration.
```

---

## 14. Example filled prompt — Act I clean biome background: Las

```md
# IMAGE PROMPT — CLEAN BIOME BACKGROUND: LAS

Intended use:
Create a clean production-ready forest biome background for the board in "Dzień 50".

Project context:
"Dzień 50" is a 2D survival card roguelike with premium pixel art.
Board layout is rectangular 3x2. Godot adds frame, title, slot markers,
highlights, overlays, and editable text above this clean background.

Global style target:
- premium pixel art
- polished retro strategy game aesthetic
- clean readable biome panel
- rich but controlled environment detail
- crisp shapes
- readable even at board scale

Asset type:
Clean biome background

Asset purpose:
A pure forest terrain/background layer used inside a rectangular biome tile.

Subject:
Las / forest biome

Act / world state:
Act I

Style-specific requirements:
Bright, lush, calm, green-blue, safe, sunny. Pine forest, soft grass, rocks, flowers, distant trees, peaceful survival mood.

Composition:
- one rectangular terrain background
- wide horizontal composition
- readable central area
- visible forest identity
- calm foreground/midground areas where Godot can overlay 3 building slots
- no frame, no title plate, no slot cards, no counters, no UI widgets
- no puzzle connectors

Background:
- full image is the clean forest terrain background

Text rendering:
No text, no labels, no numbers, no pseudo-text, no fake glyphs.

Technical output target:
- image_size: landscape_hd
- output_format: png
- quality: high
- num_images: 1

Avoid:
- puzzle-shaped board tile
- any frame, title plate, slot card, label, number, or UI element
- photorealism
- cinematic concept art style
- excessive clutter
- human characters
- giant foreground objects blocking slot space
```

---

## 15. Example filled prompt — Act II clean biome background: Skażony Las

```md
# IMAGE PROMPT — CLEAN BIOME BACKGROUND: SKAŻONY LAS

Intended use:
Create a clean production-ready corrupted forest biome background for Act II of "Dzień 50".

Project context:
This is the Act II version of the forest biome after BUM.
It must look like the same world after catastrophe, not like a different game.

Global style target:
- premium pixel art
- polished retro strategy game aesthetic
- readable corrupted biome panel
- crisp shapes
- dark but not unreadable

Asset type:
Clean biome background

Asset purpose:
A pure corrupted forest terrain/background layer used inside a rectangular biome tile.

Subject:
Skażony Las / corrupted forest biome

Act / world state:
Act II

Style-specific requirements:
Corrupted forest, dark pines, dead undergrowth, toxic green spores, cold blue shadows, muted violet fog, ruined nature, ominous but not gore.

Composition:
- one rectangular terrain background
- wide horizontal composition
- readable central area
- visible corrupted forest identity
- calm foreground/midground areas where Godot can overlay 3 building slots
- no frame, no title plate, no slot cards, no counters, no UI widgets
- no puzzle connectors

Background:
- full image is the clean corrupted forest terrain background

Text rendering:
No text, no labels, no numbers, no pseudo-text, no fake glyphs.

Technical output target:
- image_size: landscape_hd
- output_format: png
- quality: high
- num_images: 1

Avoid:
- puzzle-shaped board tile
- any frame, title plate, slot card, label, number, or UI element
- photorealism
- cinematic concept art style
- excessive clutter
- gore
- giant foreground objects blocking slot space
```

---

## 16. Example filled prompt — building card: Studnia

```md
# IMAGE PROMPT — BUILDING CARD: STUDNIA

Intended use:
Create a clean production-ready building card for "Dzień 50".

Project context:
"Dzień 50" is a 2D survival card roguelike in premium pixel art style.
Buildings exist both as cards and as board objects.

Global style target:
- premium pixel art
- readable survival card game asset
- bright parchment card body
- clear title area
- large readable building illustration
- clear lower info section

Asset type:
Building card

Asset purpose:
A vertical card used in the player's deck / hand.

Subject:
Studnia / stone water well with wooden roof

Act / world state:
Neutral UI, usable in both acts

Style-specific requirements:
Dark wood + parchment card game style. Clear pixel-art well illustration. Strong silhouette. Small nature details allowed but no clutter.

Composition:
- exactly one vertical card
- title area at top
- one central building illustration
- lower information area kept clean and readable
- centered layout
- well fully visible
- no extra cards
- no full-screen UI scene

Background:
- full card asset

Text rendering:
Render exact Polish title:
"STUDNIA"
Optional tag:
"BUDYNEK"

Technical output target:
- image_size: portrait_hd
- output_format: png
- quality: high
- num_images: 1

Avoid:
- multiple buildings
- excessive scenery
- photorealism
- 3D object render look
- muddy pixel texture
- unreadable tiny details
```

---

## 17. Example filled prompt — unknown tile

```md
# IMAGE PROMPT — UNKNOWN TILE: NIEZNANY TEREN

Intended use:
Create a hidden biome tile for the Act I map discovery mechanic in "Dzień 50".

Project context:
At the start of Act I, most biome tiles are hidden.
The player reveals tiles by moving onto adjacent tiles.

Global style target:
- premium pixel art
- polished retro strategy UI
- mysterious but not horror
- readable rectangular board tile
- no puzzle shape
- crisp pixel clusters

Asset type:
Unknown biome tile

Asset purpose:
A hidden board tile displayed before a biome is discovered.

Subject:
Nieznany teren / unknown fog-covered terrain

Act / world state:
Act I discovery

Style-specific requirements:
Dark green and teal fog, soft forest and mountain silhouettes, subtle compass/map motif, cozy exploration mood, not scary.

Composition:
- one rectangular tile
- no visible building slots
- optional small compass icon
- centered readable mystery symbol
- enough clean space for UI overlay

Background:
- full tile asset
- no transparency

Text rendering:
Render Polish text exactly:
"NIEZNANY TEREN"

Technical output target:
- image_size: landscape_hd
- output_format: png
- quality: high
- num_images: 1

Avoid:
- horror mood
- too much darkness
- puzzle-shaped tile
- clear revealed biome identity
- photorealism
- painterly blur
```
