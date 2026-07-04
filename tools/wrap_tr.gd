extends SceneTree
## One-off localization helper: wraps Polish string literals in tr(...) (or a
## static-safe _tr(...) for files made of static funcs) so they become
## translation keys. Skips comments, class-level const/var initializer blocks
## (tr() cannot run there — those get translated at their use sites by hand)
## and dev-only lines (assert/push_error/print).
##
## Run:
##   godot --headless --path . -s tools/wrap_tr.gd
##
## Idempotent: literals already preceded by tr( / _tr( / translate( are skipped.

const TR_FILES := [
	"res://systems/survival_system.gd",
	"res://scenes/run.gd",
	"res://scenes/result.gd",
	"res://scenes/main_menu.gd",
	"res://ui/card_view.gd",
	"res://ui/top_status_bar_view.gd",
	"res://ui/night_overlay_view.gd",
	"res://ui/help_overlay.gd",
	"res://ui/credits_overlay.gd",
	"res://ui/building_popup_view.gd",
	"res://ui/biome_tile_view.gd",
	"res://scripts/resources/character_class_data.gd",
	"res://scripts/resources/building_state.gd",
]
## Static-func files: Object.tr() needs an instance, so these use a local
## _tr() helper (added by hand) that calls TranslationServer.
const STATIC_TR_FILES := [
	"res://systems/night_resolver.gd",
	"res://systems/bum_resolver.gd",
	"res://scripts/run_state.gd",
]

var _literal_re := RegEx.new()
var _polish_re := RegEx.new()
var _sentence_re := RegEx.new()


func _init() -> void:
	_literal_re.compile("\"(?:[^\"\\\\\\n]|\\\\.)*\"")
	_polish_re.compile("[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]")
	# Pass 2: diacritic-less player text — sentence-shaped literals (capital
	# start, lowercase inside, and a space / sentence end / format slot).
	_sentence_re.compile("^\"[A-ZĄĆĘŁŃÓŚŹŻ](?=.*[a-ząćęłńóśźż])(?:[^/])*( |\\.\"|:\"|%[ds])")
	var total := 0
	for path in TR_FILES:
		total += _wrap_file(path, "tr(")
	for path in STATIC_TR_FILES:
		total += _wrap_file(path, "_tr(")
	print("Wrapped %d literals." % total)
	quit(0)


func _wrap_file(path: String, wrapper: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open %s" % path)
		return 0
	var lines := file.get_as_text().split("\n")
	file.close()
	var wrapped := 0
	var const_depth := 0
	for i in lines.size():
		var line := lines[i]
		var stripped := line.strip_edges()
		# Track class-level initializer blocks (const/var/@export at column 0
		# opening brackets) — tr() is illegal inside them.
		if const_depth > 0:
			const_depth += _bracket_delta(line)
			continue
		if line.length() > 0 and not line.begins_with("\t") and not line.begins_with(" "):
			if stripped.begins_with("const ") or stripped.begins_with("var ") \
					or stripped.begins_with("static var ") or stripped.begins_with("@export"):
				const_depth = _bracket_delta(line)
				continue
		if stripped.begins_with("#"):
			continue
		if stripped.begins_with("func ") or stripped.begins_with("static func "):
			continue
		if "assert(" in line or "push_error(" in line or "push_warning(" in line \
				or "print(" in line or "print_rich(" in line:
			continue
		var out := ""
		var cursor := 0
		var changed := false
		for m in _literal_re.search_all(line):
			var lit := m.get_string()
			var start := m.get_start()
			if _polish_re.search(lit) == null and _sentence_re.search(lit) == null:
				continue
			if "res://" in lit or "user://" in lit or "/" in lit:
				continue
			# Already wrapped? Look at what directly precedes the literal.
			var prefix := line.substr(0, start)
			if prefix.ends_with("tr(") or prefix.ends_with("translate("):
				continue
			# Comment tail of a code line — don't touch.
			if "#" in prefix and prefix.find("#") > prefix.rfind("\""):
				continue
			out += line.substr(cursor, start - cursor) + wrapper + lit + ")"
			cursor = m.get_end()
			changed = true
		if changed:
			lines[i] = out + line.substr(cursor)
			wrapped += 1
	if wrapped > 0:
		var out_file := FileAccess.open(path, FileAccess.WRITE)
		out_file.store_string("\n".join(lines))
		out_file.close()
		print("%s: %d lines" % [path, wrapped])
	return wrapped


func _bracket_delta(line: String) -> int:
	# Strip string literals first so brackets inside text don't skew the count.
	var code := _literal_re.sub(line, "", true)
	var comment := code.find("#")
	if comment != -1:
		code = code.substr(0, comment)
	var delta := 0
	for ch in code:
		if ch == "{" or ch == "[" or ch == "(":
			delta += 1
		elif ch == "}" or ch == "]" or ch == ")":
			delta -= 1
	return delta
