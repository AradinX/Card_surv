class_name StatIcons
extends RefCounted
## Single source for stat/resource icon lookups. Icons are optional assets:
## drop `icon_<key>.png` into assets/art/ui/icons/stats/ and every view that
## asks here picks them up automatically; missing file = null = views keep
## their current text-only look.

const DIR := "res://assets/art/ui/icons/stats/"

## Keys used across the game: health, hunger, thirst, warmth, energy,
## food, water, wood, stone, tools, random (losowe znalezisko), card (dobór).
static func texture(key: String) -> Texture2D:
	var path := "%sicon_%s.png" % [DIR, key]
	if ResourceLoader.exists(path):
		return load(path)
	return null


# Genitive stat/resource words as produced by every effect-summary builder
# ("+2 wody", "-1 zdrowia nocą"). Ordered dict — no key is a substring of
# another, so plain replace is safe on effect lines.
const _WORD_KEYS := {
	"zdrowia": "health",
	"sytości": "hunger",
	"nawodnienia": "thirst",
	"ciepła": "warmth",
	"energii": "energy",
	"jedzenia": "food",
	"wody": "water",
	"drewna": "wood",
	"kamienia": "stone",
}


## Swaps stat words in an effect summary for inline BBCode icons
## ("+2 wody" -> "+2 [img]…icon_water.png[/img]"). For RichTextLabels with
## bbcode_enabled. Words whose icon file is missing stay text (plug-and-play).
static func iconify(text: String, height: int = 12) -> String:
	for word: String in _WORD_KEYS:
		if not text.contains(word):
			continue
		var path := "%sicon_%s.png" % [DIR, _WORD_KEYS[word]]
		if ResourceLoader.exists(path):
			text = text.replace(word, "[img=%dx%d]%s[/img]" % [height, height, path])
	return text
