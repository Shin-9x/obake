class_name InfoPopup
extends PanelContainer
## A small card with an item's name and description, for touch screens, where tooltips never
## show: a tap on an item shows it, and it hides itself after a while or on the next tap.

const SHOW_TIME: float = 3.0
const WIDTH: float = 180.0

var _title: Label
var _text: Label
var _age: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	var column: VBoxContainer = UiKit.column(2)
	add_child(column)
	_title = UiKit.label("", 0, UiKit.MON, false)
	column.add_child(_title)
	_text = UiKit.paragraph("", WIDTH, UiKit.SMALL_SIZE)
	column.add_child(_text)
	set_process(false)


## Shows [param item] next to [param at], in the parent's space; a second tap on it hides it.
func show_item(item: ItemDefinition, at: Vector2) -> void:
	if visible and _title.text == tr(item.name_key):
		visible = false
		set_process(false)
		return
	_title.text = tr(item.name_key)
	_text.text = tr(item.description_key)
	position = at
	visible = true
	_age = 0.0
	set_process(true)


func _process(delta: float) -> void:
	_age += delta
	if _age >= SHOW_TIME:
		visible = false
		set_process(false)
