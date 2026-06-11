class_name CardLibrary
extends RefCounted
## Loads authored data resources (.tres) from data directories.
## Keeps game data fully decoupled from game logic and UI.

static func load_cards_from_dir(dir_path: String) -> Array[CardData]:
	var cards: Array[CardData] = []
	for resource in load_resources_from_dir(dir_path):
		if resource is CardData:
			cards.append(resource)
		else:
			push_warning("CardLibrary: '%s' is not a CardData resource" % resource.resource_path)
	return cards


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
