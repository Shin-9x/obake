class_name PauseMenu
extends Control
## The pause overlay of a run: resume, settings, give the run up (after a confirmation) or go
## back to the title, where the saved run waits.

signal resumed
signal settings_requested
signal abandon_confirmed
signal quit_requested

const BUTTON_WIDTH: float = 200.0
const DIM: Color = Color(0, 0, 0, 0.7)

var _body: VBoxContainer


func open() -> void:
	UiKit.clear(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim: ColorRect = ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_body = UiKit.column(8)
	_body.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_body.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_body.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_body)
	_show_choices()


func _show_choices() -> void:
	UiKit.clear(_body)
	var title: Label = UiKit.label("PAUSE_TITLE", UiKit.TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(title)
	_add("PAUSE_RESUME", resumed.emit)
	_add("BUTTON_SETTINGS", settings_requested.emit)
	_add("PAUSE_ABANDON", _ask_abandon)
	_add("PAUSE_QUIT_MENU", quit_requested.emit)


func _ask_abandon() -> void:
	UiKit.clear(_body)
	var question: Label = UiKit.label("PAUSE_ABANDON_CONFIRM")
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body.add_child(question)
	_add("BUTTON_YES", abandon_confirmed.emit)
	_add("BUTTON_NO", _show_choices)


func _add(key: String, action: Callable) -> void:
	var button: Button = UiKit.button(key)
	button.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(action)
	_body.add_child(button)
