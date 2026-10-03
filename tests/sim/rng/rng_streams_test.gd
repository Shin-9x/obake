extends GdUnitTestSuite

const SEED: int = 20261003


func test_same_seed_gives_same_streams() -> void:
	var a: RngStreams = RngStreams.new(SEED)
	var b: RngStreams = RngStreams.new(SEED)
	for domain: int in RngStreams.Domain.size():
		for i: int in 10:
			assert_int(a.stream(domain as RngStreams.Domain).next_u32()).is_equal(
				b.stream(domain as RngStreams.Domain).next_u32()
			)


func test_drawing_from_one_domain_does_not_shift_another() -> void:
	var untouched: RngStreams = RngStreams.new(SEED)
	var rerolled: RngStreams = RngStreams.new(SEED)
	for i: int in 37:
		rerolled.stream(RngStreams.Domain.SHOP).next_u32()
	for i: int in 10:
		var board_a: int = untouched.stream(RngStreams.Domain.BOARD).next_u32()
		var board_b: int = rerolled.stream(RngStreams.Domain.BOARD).next_u32()
		assert_int(board_b).is_equal(board_a)


func test_domains_produce_different_values() -> void:
	var streams: RngStreams = RngStreams.new(SEED)
	var map_value: int = streams.stream(RngStreams.Domain.MAP).next_u32()
	var board_value: int = streams.stream(RngStreams.Domain.BOARD).next_u32()
	assert_int(map_value).is_not_equal(board_value)


func test_state_round_trip() -> void:
	var streams: RngStreams = RngStreams.new(SEED)
	streams.stream(RngStreams.Domain.REWARDS).next_u32()
	var snapshot: Array[PackedInt64Array] = streams.get_state()
	var expected: int = streams.stream(RngStreams.Domain.REWARDS).next_u32()
	var restored: RngStreams = RngStreams.new(0)
	restored.set_state(snapshot)
	assert_int(restored.stream(RngStreams.Domain.REWARDS).next_u32()).is_equal(expected)
