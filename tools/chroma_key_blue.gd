# One-off tool: key the solid blue (#0000FF) backdrop of the BUM / corruption
# FX to alpha, by COLOUR DISTANCE to pure blue. Rot/petals/clouds/cracks are far
# from pure blue in RGB space, so they survive; soft band + blue despill keeps
# the edges clean. Additive FX (flash/glow/motes on black) are NOT listed here.
#
# Run from project root:
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/chroma_key_blue.gd
extends SceneTree

const TARGETS := [
	"res://assets/art/fx/weather/fx_rain_overlay.png",
	"res://assets/art/fx/weather/fx_snow_overlay.png",
	"res://assets/art/fx/weather/fx_frost_edges.png",
	"res://assets/art/fx/fire/fx_burn_marks.png",
	"res://assets/art/fx/smoke/fx_smoke_loop.png",
	"res://assets/art/fx/bum/fx_shockwave_ring.png",
	"res://assets/art/fx/bum/fx_blast_petals.png",
	"res://assets/art/fx/bum/fx_sky_rift_01.png",
	"res://assets/art/fx/bum/fx_sky_rift_02.png",
	"res://assets/art/fx/bum/fx_screen_crack_overlay.png",
	"res://assets/art/fx/bum/fx_wilt_overlay.png",
	"res://assets/art/fx/corruption/fx_rot_wipe.png",
	"res://assets/art/fx/corruption/fx_plague_cloud_01.png",
	"res://assets/art/fx/corruption/fx_plague_cloud_02.png",
	"res://assets/art/fx/corruption/fx_corruption_vignette.png",
	"res://assets/art/fx/cards/fx_card_reveal_burst.png",
	"res://assets/art/ui/overlay_night_spotlight.png",
	"res://assets/art/ui/panels/top_status_bar_panel_act1_wreath_candidate.png",
	"res://assets/art/ui/panels/top_status_bar_panel_act2_withered_candidate.png",
]

const KEY := Vector3(0.0, 0.0, 255.0)
const INNER := 90.0   # <= : fully transparent (pure blue + spill)
const OUTER := 150.0  # >= : fully opaque (real FX art)


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
				var f := (d - INNER) / (OUTER - INNER)  # 0 (blue) .. 1 (art)
				c.a *= f
				# Despill: pull blue tint down toward the red/green level.
				var floor_b := maxf(c.r, c.g)
				if c.b > floor_b:
					c.b = lerpf(c.b, floor_b, 1.0 - f)
				img.set_pixel(x, y, c)
				continue
			img.set_pixel(x, y, c)

	img.save_png(abs_path)
	print("Keyed %s  (%d px cleared)" % [path, cleared])
