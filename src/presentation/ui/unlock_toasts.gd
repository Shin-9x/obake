class_name UnlockToasts
extends Control
## Short notes that pop up over every screen when something is unlocked, with Obo celebrating.
## Notes queue up and each fades out on its own.

const SHOW_TIME: float = 3.0
const FADE_TIME: float = 0.4
const PANEL_SIZE: Vector2 = Vector2(260, 36)
const MASCOT_SIZE: Vector2 = Vector2(24, 24)
const PANEL_COLOUR: Color = Color("#22263aee")
const TOP_MARGIN: float = 6.0

var skin: UiSkin

var _queue: Array[PackedStringArray] = []
var _panel: ColorRect
var _title: Label
var _text: Label
var _age: float = -1.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = ColorRect.new()
	_panel.color = PANEL_COLOUR
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.offset_left = -PANEL_SIZE.x / 2.0
	_panel.offset_right = PANEL_SIZE.x / 2.0
	_panel.offset_top = TOP_MARGIN
	_panel.offset_bottom = TOP_MARGIN + PANEL_SIZE.y
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	var row: HBoxContainer = UiKit.row(6)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.position = Vector2(6, 6)
	row.size = PANEL_SIZE - Vector2(12, 12)
	_panel.add_child(row)
	row.add_child(UiKit.icon(skin.mascot if skin != null else null, MASCOT_SIZE))
	var words: VBoxContainer = UiKit.column(0)
	row.add_child(words)
	_title = UiKit.label("", 0, UiKit.MON, false)
	words.add_child(_title)
	_text = UiKit.label("", UiKit.SMALL_SIZE, UiKit.TEXT, false)
	words.add_child(_text)
	set_process(false)


## Queues a note with a [param title] and a line of [param text], both already translated.
func announce(title: String, text: String) -> void:
	_queue.append(PackedStringArray([title, text]))
	if _age < 0.0:
		_next()


func pending() -> int:
	return _queue.size() + (1 if _age >= 0.0 else 0)


func _next() -> void:
	if _queue.is_empty():
		_age = -1.0
		_panel.visible = false
		set_process(false)
		return
	var note: PackedStringArray = _queue.pop_front()
	_title.text = note[0]
	_text.text = note[1]
	_panel.modulate = Color.WHITE
	_panel.visible = true
	AudioService.play(AudioService.UNLOCK)
	_age = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_age += delta
	var left: float = SHOW_TIME - _age
	_panel.modulate.a = clampf(left / FADE_TIME, 0.0, 1.0)
	if left <= 0.0:
		_next()
