extends SceneTree
## One-off translation shuttle for localization/strings.csv.
##
## Dump mode (default):  godot --headless -s tools/loc_en.gd
##   writes localization/keys_dump.tsv — one record per line:
##   <index>\t<key with newlines/tabs escaped>\t<current en, escaped>
##
## Merge mode:  LOC_MODE=merge godot --headless -s tools/loc_en.gd
##   reads localization/strings_en.tsv (lines: <index>\t<en, escaped>) and
##   rewrites strings.csv with those translations filled in by record index.

const CSV_PATH := "res://localization/strings.csv"
const DUMP_PATH := "res://localization/keys_dump.tsv"
const EN_PATH := "res://localization/strings_en.tsv"


func _init() -> void:
	var rows := _read_csv()
	if OS.get_environment("LOC_MODE") == "merge":
		_merge(rows)
	else:
		_dump(rows)
	quit(0)


func _read_csv() -> Array:
	var rows := []
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	file.get_csv_line()  # header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() >= 1 and row[0] != "":
			rows.append([row[0], row[1] if row.size() >= 2 else ""])
	file.close()
	return rows


func _dump(rows: Array) -> void:
	var file := FileAccess.open(DUMP_PATH, FileAccess.WRITE)
	for i in rows.size():
		file.store_line("%d\t%s\t%s" % [i, _esc(rows[i][0]), _esc(rows[i][1])])
	file.close()
	print("Dumped %d records to %s" % [rows.size(), DUMP_PATH])


func _merge(rows: Array) -> void:
	var file := FileAccess.open(EN_PATH, FileAccess.READ)
	var filled := 0
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() == "":
			continue
		var tab := line.find("\t")
		if tab == -1:
			continue
		var idx := int(line.substr(0, tab))
		if idx < 0 or idx >= rows.size():
			push_error("Bad index %d" % idx)
			continue
		var en := _unesc(line.substr(tab + 1))
		if en != "":
			rows[idx][1] = en
			filled += 1
	file.close()
	var out := FileAccess.open(CSV_PATH, FileAccess.WRITE)
	out.store_csv_line(PackedStringArray(["keys", "en"]))
	var missing := 0
	for row in rows:
		out.store_csv_line(PackedStringArray([row[0], row[1]]))
		if row[1] == "":
			missing += 1
	out.close()
	print("Merged %d translations; %d still missing." % [filled, missing])


func _esc(text: String) -> String:
	return text.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


func _unesc(text: String) -> String:
	var out := ""
	var i := 0
	while i < text.length():
		var ch := text[i]
		if ch == "\\" and i + 1 < text.length():
			var next := text[i + 1]
			if next == "n":
				out += "\n"
			elif next == "t":
				out += "\t"
			else:
				out += next
			i += 2
		else:
			out += ch
			i += 1
	return out
