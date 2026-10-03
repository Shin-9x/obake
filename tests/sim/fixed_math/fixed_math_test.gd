extends GdUnitTestSuite


func test_isqrt_of_small_values() -> void:
	assert_int(FixedMath.isqrt(-5)).is_equal(0)
	assert_int(FixedMath.isqrt(0)).is_equal(0)
	assert_int(FixedMath.isqrt(1)).is_equal(1)
	assert_int(FixedMath.isqrt(2)).is_equal(1)
	assert_int(FixedMath.isqrt(3)).is_equal(1)
	assert_int(FixedMath.isqrt(4)).is_equal(2)


func test_isqrt_is_exact_floor_around_perfect_squares() -> void:
	for root: int in [7, 255, 256, 1000, 65535, 999_999, 3_037_000_499]:
		var square: int = root * root
		assert_int(FixedMath.isqrt(square)).is_equal(root)
		assert_int(FixedMath.isqrt(square - 1)).is_equal(root - 1)
		assert_int(FixedMath.isqrt(square + 1)).is_equal(root)


func test_isqrt_of_largest_values() -> void:
	var largest: int = 0x7FFFFFFFFFFFFFFF
	var root: int = FixedMath.isqrt(largest)
	assert_int(root).is_equal(3_037_000_499)
	assert_int(FixedMath.isqrt(1 << 62)).is_equal(1 << 31)


func test_div_round_rounds_half_away_from_zero() -> void:
	assert_int(FixedMath.div_round(5, 2)).is_equal(3)
	assert_int(FixedMath.div_round(-5, 2)).is_equal(-3)
	assert_int(FixedMath.div_round(5, -2)).is_equal(-3)
	assert_int(FixedMath.div_round(-5, -2)).is_equal(3)
	assert_int(FixedMath.div_round(4, 3)).is_equal(1)
	assert_int(FixedMath.div_round(-4, 3)).is_equal(-1)
	assert_int(FixedMath.div_round(0, 7)).is_equal(0)


func test_length_of_pythagorean_triple() -> void:
	assert_int(FixedMath.length(3000, -4000)).is_equal(5000)
