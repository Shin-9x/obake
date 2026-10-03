extends GdUnitTestSuite

const UNIT: int = FixedMath.UNIT


func test_exact_values_at_right_angles() -> void:
	assert_int(Trig.sin_cd(0)).is_equal(0)
	assert_int(Trig.sin_cd(9000)).is_equal(UNIT)
	assert_int(Trig.sin_cd(18000)).is_equal(0)
	assert_int(Trig.sin_cd(27000)).is_equal(-UNIT)
	assert_int(Trig.cos_cd(0)).is_equal(UNIT)
	assert_int(Trig.cos_cd(18000)).is_equal(-UNIT)


func test_angles_wrap_around_and_negative_angles_are_odd() -> void:
	for angle: int in [1, 1234, 8500, 17999, 29999]:
		assert_int(Trig.sin_cd(angle + Trig.FULL_TURN)).is_equal(Trig.sin_cd(angle))
		assert_int(Trig.sin_cd(angle - 2 * Trig.FULL_TURN)).is_equal(Trig.sin_cd(angle))
		assert_int(Trig.sin_cd(-angle)).is_equal(-Trig.sin_cd(angle))
		assert_int(Trig.cos_cd(-angle)).is_equal(Trig.cos_cd(angle))


func test_every_centidegree_is_within_one_unit_of_float_sine() -> void:
	var worst: int = 0
	for angle: int in Trig.FULL_TURN:
		var expected: int = roundi(sin(deg_to_rad(angle / 100.0)) * UNIT)
		worst = maxi(worst, absi(Trig.sin_cd(angle) - expected))
	assert_int(worst).is_less_equal(1)


func test_pythagorean_identity_holds() -> void:
	for angle: int in range(0, Trig.FULL_TURN, 7):
		var s: int = Trig.sin_cd(angle)
		var c: int = Trig.cos_cd(angle)
		var squared_norm: int = s * s + c * c
		assert_int(absi(squared_norm - UNIT * UNIT)).is_less_equal(4 * UNIT)
