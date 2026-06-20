# One-off tool: kill residual BLUE/PURPLE spill left on already-keyed FX whose
# art should contain NO blue (grey/brown smoke, dust, debris, warm vignettes).
# chroma_key_blue only despills inside its soft alpha band, so blue baked into
# the KEPT (opaque) art survives as a violet halo. This pass clamps every
# pixel's blue channel down to the GREEN channel (standard blue-spill
# suppression): purple/magenta -> pure red, royal-blue smoke -> neutral grey,
# warm dust -> warm brown. Alpha and warm/neutral hues are untouched (B<=G
# pixels, e.g. green rot, stay as-is).
#
# Only list FX that are meant to be warm/neutral. Do NOT add genuinely cool
# assets (rain/snow/frost, sky rifts, navy spotlight) — they would be greyed.
#
# Run from project root (overwrites in place):
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/despill_blue.gd
# Or pass explicit paths after `--`:
#   ... -s tools/despill_blue.gd -- res://assets/art/fx/buildings/fx_build_place.png
extends SceneTree

const TARGETS := [
	"res://assets/art/fx/buildings/fx_build_place.png",
	"res://assets/art/fx/buildings/fx_ruin_collapse.png",
	"res://assets/art/fx/ui/fx_low_hp_vignette.png",
	"res://assets/art/fx/result/fx_defeat_haze.png",
	"res://assets/art/fx/fire/fx_burn_marks.png",
	"res://assets/art/fx/smoke/fx_smoke_loop.png",
	"res://assets/art/fx/corruption/fx_rot_wipe.png",
	"res://assets/art/fx/corruption/fx_corruption_vignette.png",
]


func _init() -> void:
	var targets: Array = TARGETS
	var requested := OS.get_cmdline_user_args()
	if not requested.is_empty():
		targets = requested
	for path in targets:
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
	var fixed := 0
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			# Clamp blue to the green channel — kills the blue/purple spill while
			# leaving reds, browns and greens intact.
			if c.b > c.g:
				c.b = c.g
				img.set_pixel(x, y, c)
				fixed += 1

	img.save_png(abs_path)
	print("Despilled %s  (%d px corrected)" % [path, fixed])
