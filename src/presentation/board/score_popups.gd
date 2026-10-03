class_name ScorePopups
extends Node2D
## Pooled floating labels for points, mult and other short feedback over the board.
##
## Labels are created once and animated by hand, so showing a popup allocates nothing.
## Processing is off whenever no popup is visible.

const POOL_SIZE: int = 24
## Seconds a popup stays visible.
const LIFETIME: float = 0.8
## Pixels per second a popup rises.
const RISE_SPEED: float = 16.0
const LABEL_SIZE: Vector2 = Vector2(60, 12)

var _labels: Array[Label] = []
var _ages: PackedFloat32Array = PackedFloat32Array()
var _next: int = 0


func _ready() -> void:
	_ages.resize(POOL_SIZE)
	_ages.fill(-1.0)
	for index: int in POOL_SIZE:
		var label: Label = Label.new()
		label.size = LABEL_SIZE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.visible = false
		add_child(label)
		_labels.append(label)
	set_process(false)


## Shows [param text] centred on [param at]; the oldest popup is reused when all are busy.
func show_text(text: String, at: Vector2, color: Color) -> void:
	var label: Label = _labels[_next]
	_ages[_next] = 0.0
	_next = (_next + 1) % POOL_SIZE
	label.text = text
	label.position = at - LABEL_SIZE / 2.0
	label.modulate = color
	label.visible = true
	set_process(true)


func hide_all() -> void:
	for index: int in POOL_SIZE:
		_ages[index] = -1.0
		_labels[index].visible = false
	set_process(false)


func _process(delta: float) -> void:
	var any_visible: bool = false
	for index: int in POOL_SIZE:
		if _ages[index] < 0.0:
			continue
		_ages[index] += delta
		var label: Label = _labels[index]
		if _ages[index] >= LIFETIME:
			_ages[index] = -1.0
			label.visible = false
			continue
		any_visible = true
		label.position.y -= RISE_SPEED * delta
		label.modulate.a = 1.0 - _ages[index] / LIFETIME
	if not any_visible:
		set_process(false)
