# One-off tool: chroma-key the blue illustration placeholder on the freshly
# generated night-event popup panels IN PLACE. Unlike the other panel batches,
# the imagegen output already has a transparent background outside the panel
# (no green screen to remove) — only the flat blue rectangle needs to become a
# hole so the event/monster illustration can show through it at runtime.
#
# Run from project root:
#   Godot_v4.5.1-stable_win64_console.exe --headless --path . -s tools/chroma_key_night_popup.gd
extends SceneTree

const TARGETS := [
	"res://assets/art/ui/panels/night_popup_panel_event_v4.png",
	"res://assets/art/ui/panels/night_popup_panel_event_choice_v4.png",
	"res://assets/art/ui/panels/night_popup_panel_monster_v4.png",
]

const BLUE_KEY := Vector3(0.0, 0.0, 255.0)
const INNER := 80.0
const OUTER := 150.0


func _init() -> void:
	for path in TARGETS:
		_key(path)
	quit()


func _key(path: String) -> void:
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
			var d := p.distance_to(BLUE_KEY)
			if d <= INNER:
				c.a = 0.0
				cleared += 1
				img.set_pixel(x, y, c)
			elif d < OUTER:
				var f := (d - INNER) / (OUTER - INNER)
				c.a *= f
				if c.b > maxf(c.r, c.g):
					c.b = lerpf(c.b, maxf(c.r, c.g), 1.0 - f)
				img.set_pixel(x, y, c)

	img.save_png(abs_path)
	print("Keyed %s  (%d px cleared)" % [path, cleared])
