class_name ActionCardData
extends CardData
## Definition of a playable action card. Costs are paid up front,
## gains/deltas are applied immediately. "special" effects that need
## logic (random rewards, flags) are resolved by RunSystem.

@export_group("Costs")
@export var energy_cost: int = 0
@export var food_cost: int = 0
@export var wood_cost: int = 0
@export var materials_cost: int = 0

@export_group("Effects")
@export var health_delta: int = 0
@export var hunger_delta: int = 0
@export var thirst_delta: int = 0
@export var warmth_delta: int = 0
@export var energy_delta: int = 0
@export var food_gain: int = 0
@export var water_gain: int = 0
@export var wood_gain: int = 0
@export var materials_gain: int = 0
## Energy carried into TOMORROW's dawn (borrow-now/repay-later tempo cards).
@export var next_day_energy_delta: int = 0

## Special effects handled by SurvivalSystem:
## - craft_tools: sets has_tools (one-time; +1 food/wood gain from cards)
## - explore / double_explore: one / two random reward rolls
## - draw_two: refill hand by up to 2 cards
## - scout_reveal: reveal a random adjacent undiscovered tile
## - free_move: the next tile move today costs 0 energy
## - repair_tile: patch the most damaged standing building on the current tile
## - ward_night: this night's event/monster health & warmth losses are softened
## - set_trap: negate one monster attack on you this night
## - momentum: every later card played this turn refunds +1 energy
## - rhythm: recover energy for cards already played this turn
## - combo_food: +2 extra food if you already played a food card this turn
## - next_move_cost: the next tile move today costs +1 energy
@export_enum("none", "build_shelter", "craft_tools", "explore", "double_explore", "draw_two", "scout_reveal", "free_move", "repair_tile", "ward_night", "set_trap", "momentum", "rhythm", "combo_food", "next_move_cost")
var special: String = "none"

## Optional one-step upgrade: res:// path of the ActionCardData this card becomes
## when the player picks its upgrade reward (swaps in the deck). "" = no upgrade.
@export var upgrade_id: String = ""

## Keeps a card OUT of the level-up reward pool. Used for biome gather actions
## pinned to their tile (Poluj/Wedkowanie/Wydobycie kamienia/...) so resources
## stay tied to the biome that produces them (anti-camping economy), and for
## starter-deck-only fallbacks (Szukaj kamienia) that must not dilute rewards.
@export var gather_only: bool = false
