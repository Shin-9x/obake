extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const SHIMENAWA: String = "res://data/omamori/shimenawa.tres"


func test_only_the_first_shot_bounces_off_the_bottom() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_omamori(SHIMENAWA))
	Harness.shoot(game)
	assert_int(game.launched_ball().floor_bounces).is_equal(1)
	Harness.finish(game)
	assert_array(Harness.events_of(game, SimEvent.Kind.FLOOR_BOUNCE)).has_size(1)
	Harness.shoot(game)
	assert_int(game.launched_ball().floor_bounces).is_equal(0)
