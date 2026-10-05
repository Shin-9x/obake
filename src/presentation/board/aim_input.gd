class_name AimInput
extends Node
## Turns mouse, keyboard, touch and gamepad input into an integer aim, in centidegrees from
## straight down.
##
## The mouse aims at the pointer. Touch aims with a relative drag, so the finger never hides the
## target. A gamepad stick turns the aim faster the further it is pushed. Fine aim moves by
## [constant FINE_STEP] per wheel notch, key press, trigger or button repeat.

signal aim_changed(aim: int)
signal shoot_requested

## A tenth of a degree.
const FINE_STEP: int = 10
## Centidegrees of aim per viewport pixel of horizontal drag, at the default sensitivity setting.
const DRAG_SENSITIVITY: float = 40.0
## Seconds before a held fine-aim control starts repeating, then between repeats.
const REPEAT_DELAY: float = 0.35
const REPEAT_INTERVAL: float = 0.04
## Centidegrees per second with the stick pushed all the way.
const STICK_SPEED: float = 6000.0
## Stick deflection below which the stick counts as centred.
const STICK_DEADZONE: float = 0.2

var aim: int = 0
var aim_limit: int = 0
## Node whose local space [member launcher_position] is expressed in.
var board: Node2D
## Launcher position in [member board]'s local space, in pixels.
var launcher_position: Vector2 = Vector2.ZERO
## True while the player holds fast-forward: its key, the right mouse button or any touch.
var fast_forward: bool = false

var _hold_direction: int = 0
var _hold_time: float = 0.0
var _repeat_time: float = 0.0
var _touches: int = 0
var _drag_remainder: float = 0.0
## Stick deflection from -1 (left) to 1 (right), deadzone applied.
var _stick: float = 0.0
var _stick_remainder: float = 0.0


func _ready() -> void:
	set_process(false)


## Aim that points from the launcher along [param offset], clamped to [param limit].
static func aim_towards(offset: Vector2, limit: int) -> int:
	if offset.is_zero_approx():
		return 0
	var degrees: float = rad_to_deg(atan2(offset.x, offset.y))
	return clampi(roundi(degrees * 100.0), -limit, limit)


func set_aim(value: int) -> void:
	var clamped: int = clampi(value, -aim_limit, aim_limit)
	if clamped == aim:
		return
	aim = clamped
	aim_changed.emit(aim)


## Moves the aim by one fine step; [param direction] is -1 (left) or 1 (right).
func nudge(direction: int) -> void:
	set_aim(aim + direction * FINE_STEP)


## Starts repeating fine aim while a control is held; a [param direction] of 0 stops it.
func hold_nudge(direction: int) -> void:
	_hold_direction = direction
	_hold_time = 0.0
	_repeat_time = 0.0
	if direction != 0:
		nudge(direction)
	_update_processing()


func _process(delta: float) -> void:
	if _stick != 0.0:
		_stick_remainder += _stick * STICK_SPEED * delta
		var whole: int = int(_stick_remainder)
		_stick_remainder -= whole
		set_aim(aim + whole)
	if _hold_direction == 0:
		return
	_hold_time += delta
	if _hold_time < REPEAT_DELAY:
		return
	_repeat_time += delta
	while _repeat_time >= REPEAT_INTERVAL:
		_repeat_time -= REPEAT_INTERVAL
		nudge(_hold_direction)


func _update_processing() -> void:
	set_process(_hold_direction != 0 or _stick != 0.0)


func _unhandled_input(event: InputEvent) -> void:
	# Touch also produces emulated mouse events; touch is handled through its own events.
	if event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event is InputEventMouseMotion:
		if board != null:
			set_aim(aim_towards(board.get_local_mouse_position() - launcher_position, aim_limit))
	elif event is InputEventMouseButton:
		_on_mouse_button(event as InputEventMouseButton)
	elif event is InputEventScreenDrag:
		var sensitivity: float = DRAG_SENSITIVITY * Settings.values.drag_sensitivity / 100.0
		_drag_remainder += (event as InputEventScreenDrag).relative.x * sensitivity
		var whole: int = int(_drag_remainder)
		_drag_remainder -= whole
		set_aim(aim + whole)
	elif event is InputEventScreenTouch:
		_touches = maxi(0, _touches + (1 if (event as InputEventScreenTouch).pressed else -1))
	elif (
		event is InputEventJoypadMotion
		and (event as InputEventJoypadMotion).axis == JOY_AXIS_LEFT_X
	):
		var value: float = (event as InputEventJoypadMotion).axis_value
		_stick = value if absf(value) > STICK_DEADZONE else 0.0
		_update_processing()
	elif event.is_action_pressed("aim_fine_left"):
		hold_nudge(-1)
	elif event.is_action_pressed("aim_fine_right"):
		hold_nudge(1)
	elif event.is_action_released("aim_fine_left") or event.is_action_released("aim_fine_right"):
		hold_nudge(0)
	elif event.is_action_pressed("shoot"):
		shoot_requested.emit()
	fast_forward = _touches > 0 or Input.is_action_pressed("fast_forward")


func _on_mouse_button(event: InputEventMouseButton) -> void:
	if not event.pressed:
		return
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			shoot_requested.emit()
		MOUSE_BUTTON_WHEEL_UP:
			nudge(-1)
		MOUSE_BUTTON_WHEEL_DOWN:
			nudge(1)
