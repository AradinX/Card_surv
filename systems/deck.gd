class_name Deck
extends RefCounted
## Generic card deck: draw pile + discard pile. When the draw pile runs out,
## the discard pile is reshuffled into it. Uses an injected RNG so runs can
## be seeded in the future.

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _rng: RandomNumberGenerator


func _init(cards: Array[CardData], rng: RandomNumberGenerator) -> void:
	_rng = rng
	_draw_pile = cards.duplicate()
	_shuffle(_draw_pile)


func draw() -> CardData:
	if _draw_pile.is_empty():
		_reshuffle_discard_into_draw()
	if _draw_pile.is_empty():
		return null
	return _draw_pile.pop_back()


func discard(card: CardData) -> void:
	_discard_pile.append(card)


func cards_left() -> int:
	return _draw_pile.size() + _discard_pile.size()


func _reshuffle_discard_into_draw() -> void:
	_draw_pile.append_array(_discard_pile)
	_discard_pile.clear()
	_shuffle(_draw_pile)


func _shuffle(cards: Array[CardData]) -> void:
	# Fisher-Yates using the injected RNG (Array.shuffle() uses the global one).
	for i in range(cards.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp := cards[i]
		cards[i] = cards[j]
		cards[j] = tmp
