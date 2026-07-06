class_name StatIcons
extends RefCounted
## Single source for stat/resource icon lookups. Icons are optional assets:
## drop `icon_<key>.png` into assets/art/ui/icons/stats/ and every view that
## asks here picks them up automatically; missing file = null = views keep
## their current text-only look.

const DIR := "res://assets/art/ui/icons/stats/"

## Keys used across the game: health, hunger, thirst, warmth, energy,
## food, water, wood, stone, tools.
static func texture(key: String) -> Texture2D:
	var path := "%sicon_%s.png" % [DIR, key]
	if ResourceLoader.exists(path):
		return load(path)
	return null
