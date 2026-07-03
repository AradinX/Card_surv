# One-off tool: chroma-key the two regenerated "event choice" night popup
# panels IN PLACE (both are freshly exported RGB8 PNGs with no alpha yet):
# - night_popup_panel_event_choice.png keys a GREEN outer backdrop (simple
#   colour-distance key, like the rest of the panel family).
# - night_popup_panel_event_choice_two_notes.png was rendered on near-BLACK
#   instead of green, and the dark wood frame is *also* close to black in
#   places — a flat colour-distance key would eat chunks of the frame. This
#   one uses a BORDER FLOOD FILL instead: only pixels reachable from the
#   image edge through a continuous run of near-black pixels are cleared, so
#   disconnected dark wood grain deep inside the art survives untouched.
# - BOTH key the flat BLUE illustration placeholder to a hole afterwards,
#   same as the rest of the night-popup family (see chroma_key_night_popup.gd).
#
# Run from project root:
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/chroma_key_night_popup_choice.gd
extends SceneTree

const PANELS_DIR := "res://assets/art/ui/panels/"
const GREEN_KEY := Vector3(16.0, 224.0, 10.0)
const BLUE_KEY := Vector3(0.0, 0.0, 255.0)
const INNER := 80.0
const OUTER := 150.0
const BLACK_FLOOD_THRESHOLD := 8.0


func _init() -> void:
	_key_green_and_blue("night_popup_panel_event_choice.png")
	_key_black_flood_and_blue("night_popup_panel_event_choice_two_notes.png")
	quit()


func _load(name: String) -> Image:
	var abs_path := ProjectSettings.globalize_path(PANELS_DIR + name)
	var img := Image.load_from_file(abs_path)
	if img == null:
		push_error("Cannot load %s" % name)
		return null
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)
	return img


func _key_green_and_blue(name: String) -> void:
	var img := _load(name)
	if img == null:
		return
	_key_distance(img, GREEN_KEY, 1)
	_key_distance(img, BLUE_KEY, 2)
	img.save_png(ProjectSettings.globalize_path(PANELS_DIR + name))
	print("Saved ", name, " (green+blue distance key)")


func _key_black_flood_and_blue(name: String) -> void:
	var img := _load(name)
	if img == null:
		return
	var cleared := _flood_key_black(img)
	print("  border flood-fill cleared %d px" % cleared)
	_key_distance(img, BLUE_KEY, 2)
	img.save_png(ProjectSettings.globalize_path(PANELS_DIR + name))
	print("Saved ", name, " (black flood-fill + blue distance key)")


## BFS from every border pixel through a connected run of near-black pixels;
## only reachable pixels become transparent, so isolated dark wood grain
## deep inside the frame is left alone even though it's also dark.
func _flood_key_black(img: Image) -> int:
	var w := img.get_width()
	var h := img.get_height()
	var visited := PackedByteArray()
	visited.resize(w * h)
	var stack: Array[Vector2i] = []

	for x in w:
		stack.append(Vector2i(x, 0))
		stack.append(Vector2i(x, h - 1))
	for y in h:
		stack.append(Vector2i(0, y))
		stack.append(Vector2i(w - 1, y))

	var cleared := 0
	while not stack.is_empty():
		var p: Vector2i = stack.pop_back()
		var idx := p.y * w + p.x
		if visited[idx] != 0:
			continue
		visited[idx] = 1
		var c := img.get_pixel(p.x, p.y)
		var dist := Vector3(c.r * 255.0, c.g * 255.0, c.b * 255.0).length()
		if dist > BLACK_FLOOD_THRESHOLD:
			continue
		c.a = 0.0
		img.set_pixel(p.x, p.y, c)
		cleared += 1
		if p.x > 0:
			stack.append(Vector2i(p.x - 1, p.y))
		if p.x < w - 1:
			stack.append(Vector2i(p.x + 1, p.y))
		if p.y > 0:
			stack.append(Vector2i(p.x, p.y - 1))
		if p.y < h - 1:
			stack.append(Vector2i(p.x, p.y + 1))
	return cleared


func _key_distance(img: Image, key: Vector3, spill_channel: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var cleared := 0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var p := Vector3(c.r * 255.0, c.g * 255.0, c.b * 255.0)
			var d := p.distance_to(key)
			if d <= INNER:
				c.a = 0.0
				cleared += 1
				img.set_pixel(x, y, c)
			elif d < OUTER:
				var f := (d - INNER) / (OUTER - INNER)
				c.a *= f
				if spill_channel == 1 and c.g > maxf(c.r, c.b):
					c.g = lerpf(c.g, maxf(c.r, c.b), 1.0 - f)
				elif spill_channel == 2 and c.b > maxf(c.r, c.g):
					c.b = lerpf(c.b, maxf(c.r, c.g), 1.0 - f)
				img.set_pixel(x, y, c)
	print("  cleared ~%d px for key %s" % [cleared, key])
