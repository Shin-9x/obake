extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TAIKO: String = "res://data/balls/taiko.tres"


func test_wall_bounces_add_mult() -> void:
	var game: BoardGame = Harness.board([], Harness.with_ball(TAIKO))
	Harness.shoot(game, 8500)
	Harness.finish(game)
	var definition: BallDefinition = load(TAIKO)
	var counted: int = mini(game.shot_wall_bounces, definition.level_values[0])
	assert_int(game.shot_wall_bounces).is_greater(0)
	assert_int(game.shot_mult).is_equal(1000 + counted * definition.params[&"mult"])


func test_bounces_beyond_the_cap_add_nothing() -> void:
	var capped: BallDefinition = (load(TAIKO) as BallDefinition).duplicate()
	capped.level_values = PackedInt32Array([1])
	# A narrow board makes the ball bounce from wall to wall.
	var narrow: BalanceConfig = Harness.config()
	narrow.board_width = 120_000
	narrow.launcher_x = 60_000
	var game: BoardGame = Harness.board([], Harness.loadout([capped]), narrow)
	Harness.shoot(game, 8500)
	Harness.finish(game)
	assert_int(game.shot_wall_bounces).is_greater(1)
	assert_int(game.shot_mult).is_equal(1000 + capped.params[&"mult"])
