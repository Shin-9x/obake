class_name UiKit
## Small builders for the run screens, so they share one look: colours, text sizes and the
## centred 640 x 360 page every screen lays out in.

const PAGE_SIZE: Vector2 = Vector2(640, 360)
const BACKGROUND: Color = Color("#1b1d2b")
const PANEL: Color = Color("#22263a")
const TEXT: Color = Color("#f4e9c9")
const MUTED: Color = Color("#9aa0b5")
const MON: Color = Color("#ffd866")
const RARITY_COLOURS: Dictionary[int, Color] = {
	ItemDefinition.Rarity.BASE: Color("#c9ccd6"),
	ItemDefinition.Rarity.COMMON: Color("#c9ccd6"),
	ItemDefinition.Rarity.UNCOMMON: Color("#6fc3ff"),
	ItemDefinition.Rarity.RARE: Color("#ffd866"),
	ItemDefinition.Rarity.LEGENDARY: Color("#ff8fa3"),
}
const TITLE_SIZE: int = 18
const SMALL_SIZE: int = 8


## A full-screen background holding a centred page; the screen's content goes in the page.
static func page(screen: Control) -> Control:
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(background)
	var centred: Control = Control.new()
	centred.set_anchors_preset(Control.PRESET_CENTER)
	centred.custom_minimum_size = PAGE_SIZE
	centred.position = -PAGE_SIZE / 2.0
	centred.size = PAGE_SIZE
	centred.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(centred)
	return centred


## A label showing translation key [param key], or plain text when [param translate] is false.
static func label(
	key: String, font_size: int = 0, colour: Color = TEXT, translate: bool = true
) -> Label:
	var result: Label = Label.new()
	result.text = key
	result.add_theme_color_override("font_color", colour)
	if font_size > 0:
		result.add_theme_font_size_override("font_size", font_size)
	if not translate:
		result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## A label wrapping its words within [param width] pixels.
static func paragraph(text: String, width: float, font_size: int = 0) -> Label:
	var result: Label = label(text, font_size, TEXT, false)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size = Vector2(width, 0)
	return result


## A button showing [param key] that plays [param cue] when pressed.
static func button(
	key: String, translate: bool = true, cue: StringName = AudioService.UI_CLICK
) -> Button:
	var result: Button = Button.new()
	result.text = key
	result.focus_mode = Control.FOCUS_NONE
	if not translate:
		result.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	result.pressed.connect(AudioService.play.bind(cue, 1.0))
	return result


static func icon(texture: Texture2D, size: Vector2) -> TextureRect:
	var result: TextureRect = TextureRect.new()
	result.texture = texture
	result.custom_minimum_size = size
	result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func row(separation: int = 8) -> HBoxContainer:
	var result: HBoxContainer = HBoxContainer.new()
	result.add_theme_constant_override("separation", separation)
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func column(separation: int = 4) -> VBoxContainer:
	var result: VBoxContainer = VBoxContainer.new()
	result.add_theme_constant_override("separation", separation)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


## A vertical stack filling [param page] below the run bar, with a margin all round.
static func body(page_node: Control, top: float = 30.0) -> VBoxContainer:
	var result: VBoxContainer = column(8)
	result.position = Vector2(16, top)
	result.size = Vector2(PAGE_SIZE.x - 32, PAGE_SIZE.y - top - 12)
	page_node.add_child(result)
	return result


## Removes and frees every child of [param node].
static func clear(node: Node) -> void:
	for child: Node in node.get_children():
		node.remove_child(child)
		child.queue_free()


## Roman numerals for item levels.
static func level_text(level: int) -> String:
	return ["", "I", "II", "III"][clampi(level, 0, 3)]
