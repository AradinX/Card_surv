# One-off tool: chroma-key the freshly generated action popup panels IN PLACE.
# - GREEN backdrop (outside the panel) -> alpha on all 6 panels.
# - BLUE region-preview placeholder -> alpha on the 2 secure panels.
# Keys by COLOUR DISTANCE to the sampled key colours, with a soft edge band and
# despill, so muted moss/brass/parchment and Act II cold shadows survive (they are
# far from the pure key colours in RGB space).
#
# Raw green originals are backed up in assets/_reference/panels_raw_greenkey/.
#
# Run from project root:
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/chroma_key_panels.gd
extends SceneTree

const PANELS_DIR := "res://assets/art/ui/panels/"
const GREEN_TARGETS := [
	"confirm_popup_panel_act1.png",
	"confirm_popup_panel_act2.png",
	"deck_popup_panel_act1.png",
	"deck_popup_panel_act2.png",
	"secure_popup_panel_act1.png",
	"secure_popup_panel_act2.png",
]
const BLUE_TARGETS := [
	"secure_popup_panel_act1.png",
	"secure_popup_panel_act2.png",
]

# Sampled corner green-screen colour (~RGB 2,249,3).
const GREEN_KEY := Vector3(2.0, 249.0, 3.0)
# Sampled blue placeholder colour (~RGB 0,38,254); key by distance to pure blue.
const BLUE_KEY := Vector3(0.0, 0.0, 255.0)
const INNER := 80.0   # <= : fully transparent (pure key + spill)
const OUTER := 150.0  # >= : fully opaque (real panel art)


func _init() -> void:
	for name in GREEN_TARGETS:
		_key(PANELS_DIR + name, GREEN_KEY, 1)  # channel 1 = green despill
	for name in BLUE_TARGETS:
		_key(PANELS_DIR + name, BLUE_KEY, 2)   # channel 2 = blue despill
	quit()


func _key(path: String, key: Vector3, spill_channel: int) -> void:
	var abs_path := ProjectSettings.globalize_path(path)
	var img := Image.load_from_file(abs_path)
	if img == null:
		push_error("Cannot load %s" % path)
		return
	if img.get_format() != Image.FORMAT_RGBA8:
		img.convert(Image.FORMAT_RGBA8)

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
				var f := (d - INNER) / (OUTER - INNER)  # 0 (key) .. 1 (art)
				c.a *= f
				# Despill: pull the key channel down toward the other two channels.
				if spill_channel == 1 and c.g > maxf(c.r, c.b):
					c.g = lerpf(c.g, maxf(c.r, c.b), 1.0 - f)
				elif spill_channel == 2 and c.b > maxf(c.r, c.g):
					c.b = lerpf(c.b, maxf(c.r, c.g), 1.0 - f)
				img.set_pixel(x, y, c)

	img.save_png(abs_path)
	print("Keyed %s  (%d px cleared)" % [path, cleared])
