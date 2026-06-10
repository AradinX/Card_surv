class_name DeckData
extends Resource
## Authored deck composition (e.g. the starting deck). Copies of a card are
## expressed by listing the same card resource multiple times.

@export var cards: Array[CardData] = []
