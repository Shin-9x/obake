extends GdUnitTestSuite
## Pads and keys give the first usable control the focus; a mouse or touch takes it away.

var _navigator: FocusNavigator
var _screen: VBoxContainer


func before_test() -> void:
	FocusNavigator.using_pad = false
	_screen = auto_free(VBoxContainer.new())
	add_child(_screen)
	var disabled: Button = Button.new()
	disabled.disabled = true
	_screen.add_child(disabled)
	var first: Button = Button.new()
	first.name = "First"
	_screen.add_child(first)
	_screen.add_child(Button.new())
	_navigator = auto_free(FocusNavigator.new())
	add_child(_navigator)


func after_test() -> void:
	FocusNavigator.using_pad = false
	get_viewport().gui_release_focus()


func test_a_pad_press_focuses_the_first_usable_control() -> void:
	_navigator.focus(_screen)
	assert_object(get_viewport().gui_get_focus_owner()).is_null()
	var press: InputEventJoypadButton = InputEventJoypadButton.new()
	press.button_index = JOY_BUTTON_DPAD_DOWN
	press.pressed = true
	_navigator._input(press)
	assert_bool(FocusNavigator.using_pad).is_true()
	assert_str(get_viewport().gui_get_focus_owner().name).is_equal("First")


func test_the_mouse_takes_the_focus_away() -> void:
	FocusNavigator.using_pad = true
	(_screen.get_node("First") as Button).grab_focus()
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.pressed = true
	_navigator._input(click)
	assert_bool(FocusNavigator.using_pad).is_false()
	assert_object(get_viewport().gui_get_focus_owner()).is_null()
