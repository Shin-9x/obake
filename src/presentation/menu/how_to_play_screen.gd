class_name HowToPlayScreen
extends Control
## A few illustrated pages on how the game works, for players who never met a game of this kind:
## the lanterns, shots and targets, Matsuri and the bucket, the items, and the controls of this
## device. Shown before the first run and from the title.

signal closed

const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const BOARD_SKIN: BoardSkin = preload("res://data/skins/placeholder_skin.tres")
const COIN_PEG: PegDefinition = preload("res://data/pegs/coin_peg.tres")
const OMAMORI: OmamoriDefinition = preload("res://data/omamori/maneki_neko.tres")
const ICON_SIZE: Vector2 = Vector2(24, 24)
const TEXT_WIDTH: float = 500.0
const BUTTON_WIDTH: float = 90.0
## Each page: its title, then its rows as a picture and a line of text.
const PAGES: Array[Array] = [
	[
		"HOWTO_LANTERNS",
		[
			[&"blue", "HOWTO_BLUE"],
			[&"red", "HOWTO_RED"],
			[&"green", "HOWTO_GREEN"],
			[&"gold", "HOWTO_GOLD"],
		],
	],
	[
		"HOWTO_SHOTS",
		[
			[&"launcher", "HOWTO_SHOT_SCORE"],
			[&"ball", "HOWTO_TARGET"],
			[&"obo", "HOWTO_LOSE"],
		],
	],
	[
		"HOWTO_MATSURI_TITLE",
		[
			[&"red", "HOWTO_MATSURI"],
			[&"bucket", "HOWTO_BUCKET"],
		],
	],
	[
		"HOWTO_ITEMS",
		[
			[&"ball", "HOWTO_BAG"],
			[&"omamori", "HOWTO_OMAMORI"],
			[&"mon", "HOWTO_MON"],
		],
	],
]
const TOUCH_CONTROLS: Array[Array] = [[&"obo", "HOWTO_CONTROLS_TOUCH"]]
const DESKTOP_CONTROLS: Array[Array] = [
	[&"obo", "HOWTO_CONTROLS_MOUSE"],
	[&"obo", "HOWTO_CONTROLS_PAD"],
]

## The page on show, from 0.
var page_index: int = 0

var _pages: Array[Array] = []


func open() -> void:
	_pages = PAGES.duplicate()
	var controls: Array[Array] = (
		TOUCH_CONTROLS if DisplayServer.is_touchscreen_available() else DESKTOP_CONTROLS
	)
	_pages.append(["HOWTO_CONTROLS", controls])
	_show(0)


func page_count() -> int:
	return _pages.size()


## The page before, or out of the pages from the first one.
func back() -> void:
	if page_index > 0:
		_show(page_index - 1)
	else:
		closed.emit()


## The page after, or out of the pages from the last one.
func next() -> void:
	if page_index + 1 < _pages.size():
		_show(page_index + 1)
	else:
		closed.emit()


func _show(index: int) -> void:
	page_index = index
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	var body: VBoxContainer = UiKit.body(page, 24)
	body.add_theme_constant_override("separation", 14)
	var title: Label = UiKit.label(_pages[index][0], UiKit.TITLE_SIZE, UiKit.MON)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	for entry: Array in _pages[index][1]:
		var row: HBoxContainer = UiKit.row(12)
		row.add_child(UiKit.icon(_picture(entry[0]), ICON_SIZE))
		row.add_child(UiKit.paragraph(tr(entry[1]), TEXT_WIDTH))
		body.add_child(row)
	var filler: Control = Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	filler.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(filler)
	var last: bool = index == _pages.size() - 1
	var actions: HBoxContainer = UiKit.row(16)
	var previous: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	previous.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	previous.pressed.connect(back)
	actions.add_child(previous)
	var counter: String = tr("HOWTO_PAGE") % [index + 1, _pages.size()]
	actions.add_child(UiKit.label(counter, 0, UiKit.MUTED, false))
	var forward: Button = UiKit.button("BUTTON_DONE" if last else "BUTTON_NEXT")
	forward.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	forward.pressed.connect(next)
	actions.add_child(forward)
	body.add_child(actions)
	if FocusNavigator.using_pad:
		forward.grab_focus()


static func _picture(id: StringName) -> Texture2D:
	match id:
		&"blue":
			return BASE_PEGS.blue.texture
		&"red":
			return BASE_PEGS.red.texture
		&"green":
			return BASE_PEGS.green.texture
		&"gold":
			return BASE_PEGS.gold.texture
		&"launcher":
			return BOARD_SKIN.launcher_texture
		&"ball":
			return BOARD_SKIN.ball_texture
		&"bucket":
			return BOARD_SKIN.bucket_texture
		&"omamori":
			return OMAMORI.icon
		&"mon":
			return COIN_PEG.texture
	return UiKit.SKIN.mascot
