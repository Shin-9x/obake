extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const UCHIWA: String = "res://data/omamori/uchiwa.tres"


func test_bucket_is_wider() -> void:
	var plain: BoardGame = Harness.board(Harness.ROW)
	var fanned: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(UCHIWA))
	var width: int = plain.simulation.bucket.half_width
	assert_int(fanned.simulation.bucket.half_width).is_equal(width * 3 / 2)
