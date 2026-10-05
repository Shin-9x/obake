class_name FocusNavigator
extends Node
## Keyboard and gamepad navigation of the menus. Remembers whether the player last used a pad or
## the keys, or a mouse or touch. With a pad or the keys the first control of a screen takes the
## focus, so its outline shows; with a mouse or touch the focus is dropped, so no outline lingers.

## Stick deflection that counts as the player using the pad.
const STICK_THRESHOLD: float = 0.5
## Mouse travel, in pixels, that counts as the player using the mouse.
const MOUSE_THRESHOLD: float = 2.0

## True when the last input came from a gamepad or the keyboard.
static var using_pad: bool = false

## Screen whose controls get the focus.
var screen: Control


## The first visible control in [param node] that can take the focus, or null.
static func first_focusable(node: Node) -> Control:
	for child: Node in node.get_children():
		if child is Control:
			var control: Control = child
			if not control.is_visible_in_tree():
				continue
			var usable: bool = not (control is BaseButton and (control as BaseButton).disabled)
			if control.focus_mode != Control.FOCUS_NONE and usable:
				return control
		var found: Control = first_focusable(child)
		if found != null:
			return found
	return null


## Moves the focus to [param target]'s first control when the player navigates with a pad or keys.
func focus(target: Control) -> void:
	screen = target
	if using_pad:
		_grab.call_deferred()


func _input(event: InputEvent) -> void:
	if _is_pad(event):
		var was_pointer: bool = not using_pad
		using_pad = true
		if was_pointer or get_viewport().gui_get_focus_owner() == null:
			# The press that brings the focus back only shows it; it does not move it on.
			if _grab():
				get_viewport().set_input_as_handled()
	elif _is_pointer(event) and using_pad:
		using_pad = false
		get_viewport().gui_release_focus()


## Focuses the screen's first control unless something in it has the focus; true when it did.
func _grab() -> bool:
	if screen == null or not is_instance_valid(screen):
		return false
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null and screen.is_ancestor_of(focused):
		return false
	var first: Control = first_focusable(screen)
	if first == null:
		return false
	first.grab_focus()
	return true


static func _is_pad(event: InputEvent) -> bool:
	if event is InputEventJoypadButton or event is InputEventKey:
		return event.is_pressed()
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > STICK_THRESHOLD
	return false


static func _is_pointer(event: InputEvent) -> bool:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		return true
	return (
		event is InputEventMouseMotion
		and (event as InputEventMouseMotion).relative.length() > MOUSE_THRESHOLD
	)
