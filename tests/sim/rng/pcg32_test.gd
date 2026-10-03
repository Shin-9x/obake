extends GdUnitTestSuite

## First outputs of the reference pcg32-demo seeded with pcg32_srandom(42, 54).
const REFERENCE_OUTPUTS: Array[int] = [
	0xa15c02b7, 0x7b47f409, 0xba1d3330, 0x83d2f293, 0xbfa4784b, 0xcbed606e
]


func test_matches_reference_implementation() -> void:
	var rng: Pcg32 = Pcg32.new(42, 54)
	for expected: int in REFERENCE_OUTPUTS:
		assert_int(rng.next_u32()).is_equal(expected)


func test_negative_and_large_seeds_are_accepted() -> void:
	var a: Pcg32 = Pcg32.new(-1, -1)
	var b: Pcg32 = Pcg32.new(-1, -1)
	for i: int in 100:
		var value: int = a.next_u32()
		assert_int(value).is_between(0, 0xFFFFFFFF)
		assert_int(value).is_equal(b.next_u32())


func test_next_below_stays_in_range_and_covers_it() -> void:
	var rng: Pcg32 = Pcg32.new(7, 0)
	var seen: Array[bool] = []
	seen.resize(6)
	seen.fill(false)
	for i: int in 600:
		var value: int = rng.next_below(6)
		assert_int(value).is_between(0, 5)
		seen[value] = true
	assert_array(seen).not_contains([false])


func test_restored_state_resumes_the_same_sequence() -> void:
	var rng: Pcg32 = Pcg32.new(123456789, 3)
	for i: int in 10:
		rng.next_u32()
	var snapshot: PackedInt64Array = rng.get_state()
	var expected: Array[int] = []
	for i: int in 20:
		expected.append(rng.next_u32())
	var restored: Pcg32 = Pcg32.new()
	restored.set_state(snapshot)
	for value: int in expected:
		assert_int(restored.next_u32()).is_equal(value)


func test_sequences_select_independent_streams() -> void:
	var a: Pcg32 = Pcg32.new(99, 0)
	var b: Pcg32 = Pcg32.new(99, 1)
	var identical: int = 0
	for i: int in 50:
		if a.next_u32() == b.next_u32():
			identical += 1
	assert_int(identical).is_less(2)
