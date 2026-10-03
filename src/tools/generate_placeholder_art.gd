extends SceneTree
## Generates the placeholder pixel-art sprites under assets/sprites/placeholder/.
## Run with `make placeholder-art`; the output is committed, so this only runs when it changes.

const OUTPUT_DIR: String = "res://assets/sprites/placeholder"
const LANTERN_SIZE: int = 10
const BALL_SIZE: int = 8

const LANTERNS: Dictionary[String, Array] = {
	"lantern_blue": [Color("#4a7ab5"), Color("#1f3552"), Color("#a9c8ea")],
	"lantern_red": [Color("#c8453b"), Color("#5a1a17"), Color("#f2a49a")],
	"lantern_green": [Color("#5f9e4e"), Color("#24411d"), Color("#b8e0a4")],
	"lantern_gold": [Color("#e3b341"), Color("#6b4a10"), Color("#fbe7a1")],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	for lantern: String in LANTERNS:
		var colours: Array = LANTERNS[lantern]
		_save(_lantern(colours[0], colours[1], colours[2]), lantern)
	_save(_ball(), "ball_hitodama")
	_save(_bucket(), "bucket")
	_save(_launcher(), "launcher")
	quit()


## Paper lantern: round body, darker outline, two ribs and a highlight.
func _lantern(body: Color, outline: Color, highlight: Color) -> Image:
	var image: Image = _blank(LANTERN_SIZE, LANTERN_SIZE)
	var centre: float = (LANTERN_SIZE - 1) / 2.0
	for y: int in LANTERN_SIZE:
		for x: int in LANTERN_SIZE:
			var distance: float = Vector2(x - centre, y - centre).length()
			if distance > centre + 0.5:
				continue
			var colour: Color = body
			if distance > centre - 0.5:
				colour = outline
			elif y == 3 or y == 6:
				colour = body.darkened(0.25)
			image.set_pixel(x, y, colour)
	image.set_pixel(3, 2, highlight)
	image.set_pixel(3, 4, highlight)
	return image


## Hitodama wisp: bright core fading to a translucent edge.
func _ball() -> Image:
	var image: Image = _blank(BALL_SIZE, BALL_SIZE)
	var centre: float = (BALL_SIZE - 1) / 2.0
	for y: int in BALL_SIZE:
		for x: int in BALL_SIZE:
			var distance: float = Vector2(x - centre, y - centre).length()
			if distance > centre + 0.5:
				continue
			var colour: Color = Color("#ffffff")
			if distance > centre - 0.6:
				colour = Color("#6fc3ff", 0.85)
			elif distance > 1.6:
				colour = Color("#bfe9ff")
			image.set_pixel(x, y, colour)
	return image


## Wooden tub, 46 px wide so its rims line up with the 40 px rim-to-rim physics width.
func _bucket() -> Image:
	var width: int = 46
	var height: int = 10
	var image: Image = _blank(width, height)
	var wood: Color = Color("#8b5a2b")
	var dark: Color = Color("#4e3016")
	var band: Color = Color("#c9a46a")
	for y: int in height:
		var inset: int = y / 3
		for x: int in range(inset, width - inset):
			var colour: Color = wood
			if y == 0 or x == inset or x == width - inset - 1 or y == height - 1:
				colour = dark
			elif y == 3 or y == 7:
				colour = band
			image.set_pixel(x, y, colour)
	return image


## Launcher nozzle pointing down; presentation rotates it towards the aim.
func _launcher() -> Image:
	var size: int = 16
	var image: Image = _blank(size, size)
	var body: Color = Color("#2b2b3a")
	var accent: Color = Color("#e3b341")
	for y: int in size:
		var half: int = 6 - y / 3
		for x: int in range(8 - maxi(half, 2), 8 + maxi(half, 2)):
			image.set_pixel(x, y, accent if y == 5 or y == 6 else body)
	return image


func _blank(width: int, height: int) -> Image:
	var image: Image = Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


func _save(image: Image, file_name: String) -> void:
	var path: String = OUTPUT_DIR.path_join(file_name + ".png")
	var error: Error = image.save_png(ProjectSettings.globalize_path(path))
	print("%s: %s" % [path, error_string(error)])
