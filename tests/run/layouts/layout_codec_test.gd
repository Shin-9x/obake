extends GdUnitTestSuite

const TestLayouts: GDScript = preload("res://tests/run/support/test_layouts.gd")


func test_round_trip_is_lossless() -> void:
	var text: String = LayoutCodec.to_json(TestLayouts.sample())
	var errors: Array[String] = []
	var parsed: BoardLayout = LayoutCodec.from_json(text, errors)
	assert_array(errors).is_empty()
	assert_str(LayoutCodec.to_json(parsed)).is_equal(text)
	assert_int(parsed.peg_count()).is_equal(9)
	assert_int(parsed.groups[0].motion).is_equal(MovingGroup.Motion.ROTATE)
	assert_int(parsed.groups[1].travel_x).is_equal(30_000)


func test_keys_are_written_in_a_fixed_order() -> void:
	var text: String = LayoutCodec.to_json(TestLayouts.sample())
	var order: Array[int] = []
	for key: String in ['"format"', '"id"', '"biome"', '"mirrorable"', '"pegs"', '"groups"']:
		order.append(text.find(key))
	var sorted: Array[int] = order.duplicate()
	sorted.sort()
	assert_array(order).is_equal(sorted)


func test_kind_and_zones_round_trip_and_are_optional() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.kind = BoardLayout.Kind.BOSS
	layout.zones.append(LayoutZone.new(100_000, 120_000, 30_000))
	var text: String = LayoutCodec.to_json(layout)
	var errors: Array[String] = []
	var parsed: BoardLayout = LayoutCodec.from_json(text, errors)
	assert_array(errors).is_empty()
	assert_int(parsed.kind).is_equal(BoardLayout.Kind.BOSS)
	assert_int(parsed.zones.size()).is_equal(1)
	assert_int(parsed.zones[0].radius).is_equal(30_000)
	var plain: String = LayoutCodec.to_json(TestLayouts.sample())
	assert_str(plain).not_contains('"kind"')
	assert_str(plain).not_contains('"zones"')
	assert_int(LayoutCodec.from_json(plain, errors).kind).is_equal(BoardLayout.Kind.BOARD)


func test_rejects_unknown_kinds_and_empty_zones() -> void:
	_assert_rejected(
		{"format": 1, "id": "x", "biome": "y", "kind": "secret", "pegs": [_round()]}, "secret"
	)
	var zone: Dictionary = {"x": 10, "y": 10, "radius": 0}
	_assert_rejected(
		{"format": 1, "id": "x", "biome": "y", "pegs": [_round()], "zones": [zone]}, "radius"
	)


func test_rejects_an_unknown_format() -> void:
	_assert_rejected({"format": 2, "id": "x", "biome": "y", "pegs": [_round()]}, "format")


func test_rejects_missing_fields() -> void:
	_assert_rejected({"format": 1, "biome": "y", "pegs": [_round()]}, "'id'")
	_assert_rejected({"format": 1, "id": "x", "biome": "y", "pegs": []}, "no pegs")


func test_rejects_unknown_shapes_and_motions() -> void:
	var odd_peg: Dictionary = {"x": 1, "y": 1, "shape": "star"}
	_assert_rejected({"format": 1, "id": "x", "biome": "y", "pegs": [odd_peg]}, "star")
	var odd_group: Dictionary = {"motion": "spin", "period": 10, "pegs": [_round()]}
	_assert_rejected(
		{"format": 1, "id": "x", "biome": "y", "pegs": [_round()], "groups": [odd_group]}, "spin"
	)


func test_rejects_fractional_numbers() -> void:
	var peg: Dictionary = {"x": 1.5, "y": 1, "shape": "round"}
	_assert_rejected({"format": 1, "id": "x", "biome": "y", "pegs": [peg]}, "integer")


func test_rejects_text_that_is_not_an_object() -> void:
	var errors: Array[String] = []
	assert_object(LayoutCodec.from_json("[1, 2]", errors)).is_null()
	assert_array(errors).is_not_empty()


func _round() -> Dictionary:
	return {"x": 100000, "y": 100000, "shape": "round"}


func _assert_rejected(data: Dictionary, expected: String) -> void:
	var errors: Array[String] = []
	var layout: BoardLayout = LayoutCodec.from_json(JSON.stringify(data), errors)
	assert_object(layout).is_null()
	assert_str("\n".join(errors)).contains(expected)
