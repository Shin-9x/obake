extends SceneTree
## Generates the placeholder pixel-art sprites under assets/sprites/placeholder/.
## Run with `make placeholder-art`; the output is committed, so this only runs when it changes.

const OUTPUT_DIR: String = "res://assets/sprites/placeholder"
const LANTERN_SIZE: int = 10
const BALL_SIZE: int = 8

## Ball sprites: fill, edge and a pattern drawn on top.
const BALLS: Dictionary[String, Array] = {
	"ball_heavy": [Color("#4b5563"), Color("#1f2937"), "highlight"],
	"ball_taiko": [Color("#c0392b"), Color("#5c1a14"), "band"],
	"ball_zeni": [Color("#d4a017"), Color("#6b4a10"), "hole"],
	"ball_explosive": [Color("#2b2b2b"), Color("#000000"), "core"],
	"ball_phantom": [Color("#e8f4ff", 0.45), Color("#ffffff", 0.7), "none"],
	"ball_magnetic": [Color("#d63c3c"), Color("#3c6fd6"), "halves"],
	"ball_daruma": [Color("#c8102e"), Color("#5a0a14"), "face"],
	"ball_splitter": [Color("#3fa34d"), Color("#1d4d24"), "diagonal"],
	"ball_onibi": [Color("#4fc3f7"), Color("#1565c0"), "core"],
}
## Purchasable peg sprites, drawn like lanterns: body, outline and highlight.
const SPECIAL_PEGS: Dictionary[String, Array] = {
	"peg_coin": [Color("#e0b030"), Color("#6b4a10"), Color("#fff2b0")],
	"peg_bell": [Color("#f2d24b"), Color("#7a5c00"), Color("#fffbe0")],
	"peg_explosive_lantern": [Color("#7a1f1f"), Color("#2a0a0a"), Color("#ff9a3c")],
	"peg_torii": [Color("#d9381e"), Color("#1a1a1a"), Color("#ffb3a3")],
	"peg_kagami": [Color("#c9d1d9"), Color("#5b6672"), Color("#ffffff")],
	"peg_omikuji": [Color("#f5f0e6"), Color("#b22222"), Color("#ffffff")],
}
## Omamori icons: one colour each; the emblem varies with the position in this list.
const OMAMORI: Array[String] = [
	"chochin",
	"first_strike",
	"patience",
	"kaeru",
	"uchiwa",
	"teru_teru_bozu",
	"drum",
	"maneki_neko",
	"yata_mirror",
	"magatama",
	"shimenawa",
	"hyotan",
	"ema",
	"shuten_sake",
	"tsukumogami",
]
const OMAMORI_COLOURS: Array[Color] = [
	Color("#e07a5f"),
	Color("#3d405b"),
	Color("#81b29a"),
	Color("#4caf50"),
	Color("#f2cc8f"),
	Color("#bde0fe"),
	Color("#a0522d"),
	Color("#f4a261"),
	Color("#c0c0c0"),
	Color("#6a4c93"),
	Color("#d4a373"),
	Color("#e9c46a"),
	Color("#8ecae6"),
	Color("#9b2226"),
	Color("#5e548e"),
]

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
	for ball: String in BALLS:
		var style: Array = BALLS[ball]
		_save(_styled_ball(style[0], style[1], style[2]), ball)
	for peg: String in SPECIAL_PEGS:
		var colours: Array = SPECIAL_PEGS[peg]
		_save(_lantern(colours[0], colours[1], colours[2]), peg)
	for index: int in OMAMORI.size():
		_save(_omamori(OMAMORI_COLOURS[index], index), "omamori_" + OMAMORI[index])
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


## A ball with a fill, an edge and a simple pattern on top.
func _styled_ball(fill: Color, edge: Color, pattern: String) -> Image:
	var image: Image = _blank(BALL_SIZE, BALL_SIZE)
	var centre: float = (BALL_SIZE - 1) / 2.0
	for y: int in BALL_SIZE:
		for x: int in BALL_SIZE:
			var distance: float = Vector2(x - centre, y - centre).length()
			if distance > centre + 0.5:
				continue
			var colour: Color = edge if distance > centre - 0.6 else fill
			match pattern:
				"band":
					if y == 3 or y == 4:
						colour = Color.WHITE
				"hole":
					if (x == 3 or x == 4) and (y == 3 or y == 4):
						colour = Color(0, 0, 0, 0)
				"core":
					if distance < 1.6:
						colour = Color("#ffd166")
				"halves":
					colour = fill if x < 4 else edge
				"face":
					if y >= 2 and y <= 4 and x >= 2 and x <= 5:
						colour = Color("#fff4e0")
				"diagonal":
					if x == y:
						colour = edge
				"highlight":
					if x == 2 and y == 2:
						colour = Color("#9ca3af")
			image.set_pixel(x, y, colour)
	return image


## An amulet bag with a knot on top and a small emblem picked by [param emblem].
func _omamori(body: Color, emblem: int) -> Image:
	var size: int = 16
	var image: Image = _blank(size, size)
	var outline: Color = body.darkened(0.5)
	for y: int in range(3, 15):
		for x: int in range(3, 13):
			var corner: bool = (x == 3 or x == 12) and (y == 3 or y == 14)
			if corner:
				continue
			var edge: bool = x == 3 or x == 12 or y == 3 or y == 14
			image.set_pixel(x, y, outline if edge else body)
	for x: int in range(6, 10):
		image.set_pixel(x, 1, outline)
		image.set_pixel(x, 2, Color("#f4e9c9"))
	# A 3 x 3 emblem whose cells follow the bits of the item's position.
	for cell: int in 9:
		if (emblem + 1) & (1 << cell) != 0:
			image.set_pixel(6 + cell % 3, 7 + cell / 3, Color("#f4e9c9"))
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
