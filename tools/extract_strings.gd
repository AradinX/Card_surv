extends SceneTree
## Localization extractor: collects every player-facing string and (re)writes
## localization/strings.csv (columns: keys,en). The KEY IS THE POLISH SOURCE
## TEXT — no invented ids, missing translations fall back to Polish for free.
## Existing "en" entries in the CSV are preserved on re-runs, so this is safe
## to run after adding cards/events/UI text.
##
## Sources:
##   1. data/**.tres        — display_name/description (+ biome corrupted_*,
##                            disaster act2_rule_text, event choice label/result)
##   2. *.gd                — tr("...") / _tr("...") literals, every literal with
##                            Polish diacritics (const dictionaries translated at
##                            their use sites) and fragment args of the
##                            _append_*_part/_push_delta helpers
##   3. *.tscn              — text/tooltip_text properties (Controls auto-
##                            translate them with the source text as the key)
##
## Run:
##   godot --headless --path . -s tools/extract_strings.gd

const CSV_PATH := "res://localization/strings.csv"
const DATA_DIRS := ["res://data"]
const CODE_DIRS := ["res://systems", "res://scenes", "res://ui", "res://scripts"]
const SCENE_DIRS := ["res://scenes", "res://ui"]

var _keys: Array[String] = []
var _seen := {}
var _literal_re := RegEx.new()
var _tr_re := RegEx.new()
var _polish_re := RegEx.new()
var _helper_re := RegEx.new()
var _tscn_text_re := RegEx.new()


func _init() -> void:
	_literal_re.compile("\"((?:[^\"\\\\\\n]|\\\\.)*)\"")
	_tr_re.compile("\\b_?tr\\(\"((?:[^\"\\\\\\n]|\\\\.)*)\"")
	_polish_re.compile("[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]")
	_helper_re.compile("(?:_append_delta_part|_append_cost_part|_push_delta)\\([^\"\\n]*\"((?:[^\"\\\\\\n]|\\\\.)*)\"")
	_tscn_text_re.compile("^(?:text|tooltip_text|placeholder_text|ok_button_text|cancel_button_text|dialog_text)\\s*=\\s*\"((?:[^\"\\\\]|\\\\.)*)\"")

	for dir in DATA_DIRS:
		_walk_resources(dir)
	for dir in CODE_DIRS:
		_walk_files(dir, "gd")
	for dir in SCENE_DIRS:
		_walk_files(dir, "tscn")

	var existing := _load_existing()
	_write_csv(existing)
	var translated := 0
	for key in _keys:
		if str(existing.get(key, "")) != "":
			translated += 1
	print("Keys: %d total, %d translated (en), %d missing." % [
		_keys.size(), translated, _keys.size() - translated
	])
	quit(0)


func _add(text: String) -> void:
	if text.strip_edges() == "" or _seen.has(text):
		return
	# Skip pure format/number/punctuation strings — nothing to translate.
	var letters := false
	for ch in text:
		if (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or _polish_re.search(ch) != null:
			letters = true
			break
	if not letters:
		return
	_seen[text] = true
	_keys.append(text)


# --- 1. Data resources ---


func _walk_resources(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_walk_resources(dir_path.path_join(sub))
	for file in dir.get_files():
		if not file.ends_with(".tres"):
			continue
		var res := ResourceLoader.load(dir_path.path_join(file))
		if res == null:
			continue
		_collect_resource(res)


func _collect_resource(res: Resource) -> void:
	for prop in [
		"display_name", "description",
		"corrupted_display_name", "corrupted_description", "act2_rule_text",
	]:
		var value: Variant = res.get(prop)
		if value is String:
			_add(value)
	var choices: Variant = res.get("choices")
	if choices is Array:
		for choice in choices:
			if choice is Resource:
				_add(str(choice.get("label")))
				_add(str(choice.get("result_text")))


# --- 2/3. Code and scenes ---


func _walk_files(dir_path: String, ext: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_walk_files(dir_path.path_join(sub), ext)
	for file in dir.get_files():
		if not file.ends_with("." + ext):
			continue
		var path := dir_path.path_join(file)
		if ext == "gd":
			_scan_gd(path)
		else:
			_scan_tscn(path)


func _scan_gd(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	for m in _tr_re.search_all(text):
		_add(_unescape(m.get_string(1)))
	for m in _helper_re.search_all(text):
		_add(_unescape(m.get_string(1)))
	# Const-block dictionaries (BUM_OMENS, corrupted names, tutorial pages...)
	# hold raw Polish literals translated at their sinks — pick them all up.
	for line in text.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("#"):
			continue
		for m in _literal_re.search_all(line):
			var lit := m.get_string(1)
			if _polish_re.search(lit) != null:
				_add(_unescape(lit))


func _scan_tscn(path: String) -> void:
	var text := FileAccess.get_file_as_string(path)
	for line in text.split("\n"):
		var m := _tscn_text_re.search(line.strip_edges())
		if m != null:
			_add(_unescape(m.get_string(1)))


var _unicode_re: RegEx


func _unescape(text: String) -> String:
	if _unicode_re == null:
		_unicode_re = RegEx.new()
		_unicode_re.compile("\\\\u([0-9a-fA-F]{4})")
	var out := text.replace("\\n", "\n").replace("\\t", "\t").replace("\\\"", "\"")
	while true:
		var m := _unicode_re.search(out)
		if m == null:
			break
		out = out.substr(0, m.get_start()) + String.chr(("0x" + m.get_string(1)).hex_to_int()) \
			+ out.substr(m.get_end())
	return out.replace("\\\\", "\\")


# --- CSV in/out ---


func _load_existing() -> Dictionary:
	var translations := {}
	if not FileAccess.file_exists(CSV_PATH):
		return translations
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()  # header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 2 and row[0] != "":
			translations[row[0]] = row[1]
	file.close()
	return translations


func _write_csv(existing: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("res://localization")
	var file := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["keys", "en"]))
	_keys.sort()
	for key in _keys:
		file.store_csv_line(PackedStringArray([key, str(existing.get(key, ""))]))
	file.close()
