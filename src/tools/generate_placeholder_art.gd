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
	"peg_kitsunebi": [Color("#5fe0c8"), Color("#1f6b5c"), Color("#e6fff9")],
	"peg_oni": [Color("#6b1f2a"), Color("#12060a"), Color("#ff7043")],
}
const BOSSES: Array[String] = ["jorogumo", "nue", "tamamo", "shuten_doji"]
const MAP_ICONS: Array[String] = ["board", "elite", "event", "shrine", "shop", "boss"]
const MAP_ICON_SIZE: int = 16
const BOSS_SIZE: int = 48
## Character portraits: head, ears or headgear, and the colour across the eyes.
const PORTRAITS: Dictionary[String, Array] = {
	"portrait_yamabushi": [Color("#e8c39e"), "cap", Color("#e8c39e"), Color("#f4f1ea")],
	"portrait_kitsune": [Color("#e07b39"), "pointed", Color("#e07b39"), Color("#fbeee0")],
	"portrait_tanuki": [Color("#8b6a4f"), "round", Color("#3b2a20"), Color("#d9c3a5")],
}
const PORTRAIT_SIZE: int = 32
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
	for portrait: String in PORTRAITS:
		var look: Array = PORTRAITS[portrait]
		_save(_portrait(look[0], look[1], look[2], look[3]), portrait)
	for boss: String in BOSSES:
		_save(_boss(boss), "boss_" + boss)
	for node: String in MAP_ICONS:
		_save(_map_icon(node), "map_" + node)
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


## A face looking out of the frame: head, ears or a cap, eyes on a band of [param band] and a
## lighter muzzle or robe of [param light].
func _portrait(head: Color, top: String, band: Color, light: Color) -> Image:
	var image: Image = _blank(PORTRAIT_SIZE, PORTRAIT_SIZE)
	var centre: Vector2 = Vector2(15.5, 18.5)
	var outline: Color = head.darkened(0.55)
	var eye: Color = Color("#f4f1ea") if band.get_luminance() < 0.3 else Color("#1a1a1a")
	for y: int in PORTRAIT_SIZE:
		for x: int in PORTRAIT_SIZE:
			var distance: float = Vector2(x, y).distance_to(centre)
			if distance > 11.5:
				continue
			var colour: Color = head
			if distance > 10.5:
				colour = outline
			elif y >= 21:
				colour = light
			elif y >= 15 and y <= 18:
				colour = band
			image.set_pixel(x, y, colour)
	for side: int in [-1, 1]:
		var eye_x: int = 16 + side * 4 - (1 if side < 0 else 0)
		image.set_pixel(eye_x, 16, eye)
		image.set_pixel(eye_x, 17, eye)
		match top:
			"pointed":
				for row: int in 6:
					for width: int in range(0, 6 - row):
						var ear_x: int = 16 + side * (6 + width) - (1 if side < 0 else 0)
						image.set_pixel(ear_x, 3 + row + 3, outline if width == 5 - row else head)
			"round":
				for dy: int in range(-2, 3):
					for dx: int in range(-2, 3):
						if dx * dx + dy * dy <= 5:
							image.set_pixel(
								16 + side * 8 + dx - (1 if side < 0 else 0), 8 + dy, outline
							)
	if top == "cap":
		for y: int in range(4, 9):
			for x: int in range(12 - (y - 4) / 2, 20 + (y - 4) / 2):
				image.set_pixel(x, y, Color("#1a1a1a"))
		for x: int in [11, 14, 17, 20]:
			image.set_pixel(x, 24, Color("#d94f4f"))
			image.set_pixel(x, 25, Color("#d94f4f"))
	image.set_pixel(15, 22, outline)
	image.set_pixel(16, 22, outline)
	return image


## A boss portrait: a big head with one telling feature each.
func _boss(boss: String) -> Image:
	var image: Image = _blank(BOSS_SIZE, BOSS_SIZE)
	var centre: Vector2 = Vector2(23.5, 26.5)
	var looks: Dictionary[String, Array] = {
		"jorogumo": [Color("#2b2233"), Color("#c62828")],
		"nue": [Color("#8d6e63"), Color("#f2b134")],
		"tamamo": [Color("#f5f0e6"), Color("#e3b341")],
		"shuten_doji": [Color("#c0392b"), Color("#f4e9c9")],
	}
	var head: Color = looks[boss][0]
	var accent: Color = looks[boss][1]
	var outline: Color = head.darkened(0.6)
	if boss == "jorogumo":
		for leg: int in 8:
			var angle: float = PI * (0.15 + 0.7 * (leg % 4) / 3.0) + (PI if leg >= 4 else 0.0)
			for step: int in range(14, 23):
				var at: Vector2 = centre + Vector2.from_angle(angle) * step
				image.set_pixelv(Vector2i(at.round()).clampi(0, BOSS_SIZE - 1), outline)
	if boss == "tamamo":
		for tail: int in 9:
			var angle: float = PI + PI * tail / 8.0
			for step: int in range(12, 23):
				var at: Vector2 = centre + Vector2.from_angle(angle) * step
				var pixel: Vector2i = Vector2i(at.round()).clampi(0, BOSS_SIZE - 1)
				image.set_pixelv(pixel, accent if step > 19 else head.darkened(0.15))
	for y: int in BOSS_SIZE:
		for x: int in BOSS_SIZE:
			var distance: float = Vector2(x, y).distance_to(centre)
			if distance > 14.5:
				continue
			var colour: Color = outline if distance > 13.5 else head
			if boss == "nue" and (x + y / 2) % 6 == 0 and distance <= 13.5:
				colour = accent.darkened(0.3)
			image.set_pixel(x, y, colour)
	var eye: Color = accent if boss != "shuten_doji" else Color("#ffeb3b")
	for side: int in [-1, 1]:
		var eye_x: int = 23 + side * 5 + (1 if side > 0 else 0)
		for dy: int in 2:
			image.set_pixel(eye_x, 23 + dy, eye)
			image.set_pixel(eye_x + side, 23 + dy, eye)
		if boss == "shuten_doji":
			for step: int in 7:
				image.set_pixel(
					23 + side * (7 + step / 2) + (1 if side > 0 else 0), 13 - step, accent
				)
				image.set_pixel(
					23 + side * (8 + step / 2) + (1 if side > 0 else 0), 13 - step, accent
				)
		if boss == "tamamo" or boss == "nue":
			for row: int in 5:
				for width: int in range(0, 5 - row):
					var ear_x: int = 23 + side * (7 + width) + (1 if side > 0 else 0)
					image.set_pixel(ear_x, 13 - row, outline if width == 4 - row else head)
	for x: int in range(20, 28):
		image.set_pixel(x, 32, outline)
	if boss == "jorogumo":
		for y: int in range(34, 38):
			image.set_pixel(23, y, accent)
			image.set_pixel(24, y, accent)
	return image


## Map node icons: a lantern for boards, a red one with a crest for elites, a question mark for
## events, a torii for shrines, a coin for shops and horns for the boss.
func _map_icon(node: String) -> Image:
	var image: Image = _blank(MAP_ICON_SIZE, MAP_ICON_SIZE)
	var ink: Color = Color("#1a1a1a")
	match node:
		"board", "elite":
			var body: Color = Color("#4a7ab5") if node == "board" else Color("#c8453b")
			for y: int in range(2, 14):
				for x: int in range(3, 13):
					var distance: float = Vector2(x - 7.5, y - 7.5).length()
					if distance <= 6.0:
						image.set_pixel(x, y, ink if distance > 5.0 else body)
			for x: int in range(6, 10):
				image.set_pixel(x, 1, ink)
				image.set_pixel(x, 14, ink)
			if node == "elite":
				for x: int in range(5, 11):
					image.set_pixel(x, 7, Color("#ffd866"))
				for y: int in range(4, 11):
					image.set_pixel(7, y, Color("#ffd866"))
					image.set_pixel(8, y, Color("#ffd866"))
		"event":
			var purple: Color = Color("#b58cff")
			for x: int in range(5, 11):
				image.set_pixel(x, 2, purple)
				image.set_pixel(x, 3, purple)
			for y: int in range(3, 8):
				image.set_pixel(10, y, purple)
				image.set_pixel(11, y, purple)
			for y: int in range(7, 11):
				image.set_pixel(7, y, purple)
				image.set_pixel(8, y, purple)
			for x: int in [7, 8]:
				image.set_pixel(x, 12, purple)
				image.set_pixel(x, 13, purple)
		"shrine":
			var red: Color = Color("#d9381e")
			for x: int in range(1, 15):
				image.set_pixel(x, 2, ink)
				image.set_pixel(x, 3, red)
			for x: int in range(3, 13):
				image.set_pixel(x, 6, red)
			for y: int in range(3, 15):
				for x: int in [4, 5, 10, 11]:
					image.set_pixel(x, y, red)
		"shop":
			for y: int in MAP_ICON_SIZE:
				for x: int in MAP_ICON_SIZE:
					var distance: float = Vector2(x - 7.5, y - 7.5).length()
					var hole: bool = absf(x - 7.5) < 2.0 and absf(y - 7.5) < 2.0
					if distance <= 7.0 and not hole:
						image.set_pixel(
							x, y, Color("#6b4a10") if distance > 6.0 else Color("#e0b030")
						)
		"boss":
			var face: Color = Color("#8e1f2b")
			for y: int in range(4, 15):
				for x: int in range(2, 14):
					var distance: float = Vector2(x - 7.5, y - 9.0).length()
					if distance <= 5.8:
						image.set_pixel(x, y, ink if distance > 4.8 else face)
			for step: int in 4:
				image.set_pixel(3 + step / 2, 4 - step, Color("#f4e9c9"))
				image.set_pixel(12 - step / 2, 4 - step, Color("#f4e9c9"))
			image.set_pixel(6, 8, Color("#ffeb3b"))
			image.set_pixel(9, 8, Color("#ffeb3b"))
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
