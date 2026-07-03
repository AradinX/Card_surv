class_name CardLibrary
extends RefCounted
## Loads authored data resources (.tres) from data directories.
## Keeps game data fully decoupled from game logic and UI.

## All dirs whose cards can end up in a run's deck: base actions plus the
## non-reward subdirs (class signatures, card upgrades, corrupted variants).
## Used to rebuild a saved deck from card ids (RunState.from_dict).
const DECK_CARD_DIRS: Array[String] = [
	"res://data/cards/actions",
	"res://data/cards/actions/signature",
	"res://data/cards/actions/upgrades",
	"res://data/cards/actions/corrupted",
]


## id -> CardData lookup covering every card a saved deck may reference.
static func load_deck_card_lookup() -> Dictionary:
	var cards: Dictionary = {}
	for dir_path in DECK_CARD_DIRS:
		for card in load_cards_from_dir(dir_path):
			cards[card.id] = card
	return cards


static func load_cards_from_dir(dir_path: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	for resource in load_resources_from_dir(dir_path):
		if resource is CardData:
			cards.append(resource)
		else:
			push_warning("CardLibrary: '%s' is not a CardData resource" % resource.resource_path)
	return cards


## Reward pool = action cards that are NOT gather_only. Biome gather actions stay
## pinned to their tile and must never be won as a level-up reward (keeps strong
## resources tied to their biome). Single choke point used by run start, resume,
## tutorial and the smoke bot, so the exclusion can't drift between call sites.
static func load_reward_pool_from_dir(dir_path: String) -> Array[CardData]:
	var pool: Array[CardData] = []
	for card in load_cards_from_dir(dir_path):
		if card is ActionCardData and (card as ActionCardData).gather_only:
			continue
		pool.append(card)
	return pool


static func load_biomes_from_dir(dir_path: String) -> Array[BiomeData]:
	var biomes: Array[BiomeData] = []
	for resource in load_resources_from_dir(dir_path):
		if resource is BiomeData:
			biomes.append(resource)
		else:
			push_warning("CardLibrary: '%s' is not a BiomeData resource" % resource.resource_path)
	return biomes


static func load_resources_from_dir(dir_path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("CardLibrary: cannot open directory '%s'" % dir_path)
		return resources
	var file_names := dir.get_files()
	# Deterministic order regardless of filesystem listing.
	file_names.sort()
	for file_name in file_names:
		# In exported builds resources may be listed as *.tres.remap.
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var resource: Resource = load(dir_path.path_join(resource_name))
		if resource != null:
			resources.append(resource)
	return resources
