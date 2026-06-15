# One-off tool: key the specific bright green-screen color to alpha.
# Instead of a broad "any green hue" heuristic (which also ate the dark/muted
# green forest decorations), this keys by COLOR DISTANCE to the exact sampled
# screen green (~RGB 20,238,25). Forest/teal/gold pixels are far from that
# color in RGB space, so decorations survive. Soft band + green despill on the
# edges keeps the cutout clean.
#
# Run from project root:
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/chroma_key_fx.gd
extends SceneTree

const TARGETS := [
	"res://assets/art/fx/discovery/fx_tile_reveal_01.png",
	"res://assets/art/fx/discovery/fx_tile_reveal_02.png",
	"res://assets/art/fx/discovery/fx_tile_reveal_03.png",
	"res://assets/art/fx/discovery/fx_fog_loop_01.png",
	"res://assets/art/fx/discovery/fx_discover_flash_01.png",
]

# Sampled green-screen colour (corners of the originals).
const KEY := Vector3(20.0, 238.0, 25.0)
# Distance bands (in 0-255 RGB space).
const INNER := 80.0   # <= : fully transparent (pure screen + spill)
const OUTER := 145.0  # >= : fully opaque (real artwork, incl. green foliage)


func _init() -> void:
	for path in TARGETS:
		_process_image(path)
	quit()


func _process_image(path: String) -> void:
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
			var p := Vector3(c.r * 255.0, c.g * 255.0, c.b * 255.0)
			var d := p.distance_to(KEY)
			if d <= INNER:
				c.a = 0.0
				cleared += 1
			elif d < OUTER:
				var f := (d - INNER) / (OUTER - INNER)  # 0 (screen) .. 1 (art)
				c.a *= f
				# Despill: pull green tint down toward the red/blue level,
				# strongest nearest the screen colour.
				var floor_g := maxf(c.r, c.b)
				if c.g > floor_g:
					c.g = lerpf(c.g, floor_g, 1.0 - f)
				img.set_pixel(x, y, c)
				continue
			img.set_pixel(x, y, c)

	img.save_png(abs_path)
	print("Keyed %s  (%d px cleared)" % [path, cleared])
