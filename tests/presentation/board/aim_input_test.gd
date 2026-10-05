extends GdUnitTestSuite

const LIMIT: int = 8500

var _aim: AimInput


func before_test() -> void:
	_aim = auto_free(AimInput.new())
	_aim.aim_limit = LIMIT


func test_pointer_below_the_launcher_aims_at_it() -> void:
	assert_int(AimInput.aim_towards(Vector2(0, 10), LIMIT)).is_equal(0)
	assert_int(AimInput.aim_towards(Vector2(10, 10), LIMIT)).is_equal(4500)
	assert_int(AimInput.aim_towards(Vector2(-10, 10), LIMIT)).is_equal(-4500)


func test_pointer_beside_or_above_the_launcher_is_clamped() -> void:
	assert_int(AimInput.aim_towards(Vector2(10, 0), LIMIT)).is_equal(LIMIT)
	assert_int(AimInput.aim_towards(Vector2(-10, -3), LIMIT)).is_equal(-LIMIT)
	assert_int(AimInput.aim_towards(Vector2.ZERO, LIMIT)).is_equal(0)


func test_fine_steps_move_by_a_tenth_of_a_degree_and_respect_the_limit() -> void:
	_aim.nudge(1)
	assert_int(_aim.aim).is_equal(AimInput.FINE_STEP)
	_aim.set_aim(LIMIT)
	_aim.nudge(1)
	assert_int(_aim.aim).is_equal(LIMIT)
	_aim.set_aim(-LIMIT - 500)
	assert_int(_aim.aim).is_equal(-LIMIT)


func test_aim_changes_are_signalled_once() -> void:
	var changes: Array[int] = []
	_aim.aim_changed.connect(func(value: int) -> void: changes.append(value))
	_aim.set_aim(120)
	_aim.set_aim(120)
	assert_array(changes).contains_exactly([120])


func test_mult_format_drops_needless_decimals() -> void:
	assert_str(BoardHud.format_mult(1000)).is_equal("1")
	assert_str(BoardHud.format_mult(3000)).is_equal("3")
	assert_str(BoardHud.format_mult(1500)).is_equal("1.5")
	assert_str(BoardHud.format_mult(1250)).is_equal("1.25")


func test_the_stick_turns_the_aim_faster_the_further_it_is_pushed() -> void:
	_aim._unhandled_input(_stick(1.0))
	assert_bool(_aim.is_processing()).is_true()
	_aim._process(0.5)
	assert_int(_aim.aim).is_equal(int(AimInput.STICK_SPEED * 0.5))
	_aim._unhandled_input(_stick(-0.5))
	_aim._process(0.5)
	assert_int(_aim.aim).is_equal(int(AimInput.STICK_SPEED * 0.25))
	_aim._unhandled_input(_stick(0.1))
	assert_bool(_aim.is_processing()).is_false()


func test_triggers_fine_aim() -> void:
	var trigger: InputEventJoypadMotion = InputEventJoypadMotion.new()
	trigger.axis = JOY_AXIS_TRIGGER_RIGHT
	trigger.axis_value = 1.0
	_aim._unhandled_input(trigger)
	assert_int(_aim.aim).is_equal(AimInput.FINE_STEP)


func _stick(value: float) -> InputEventJoypadMotion:
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = value
	return motion
