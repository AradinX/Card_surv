class_name CardLibrary
extends RefCounted
## Loads card definitions (.tres) from data directories.
## Keeps card data fully decoupled from game logic and UI.

static func load_cards_from_dir(dir_path: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_error("CardLibrary: cannot open directory '%s'" % dir_path)
		return cards
	for file_name in dir.get_files():
		# In exported builds resources may be listed as *.tres.remap.
		var resource_name := file_name.trim_suffix(".remap")
		if not resource_name.ends_with(".tres"):
			continue
		var resource: Resource = load(dir_path.path_join(resource_name))
		if resource is CardData:
			cards.append(resource)
		else:
			push_warning("CardLibrary: '%s' is not a CardData resource" % resource_name)
	# Deterministic order regardless of filesystem listing.
	cards.sort_custom(func(a: CardData, b: CardData) -> bool: return a.id < b.id)
	return cards
