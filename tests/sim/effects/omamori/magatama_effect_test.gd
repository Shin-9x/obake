extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const MAGATAMA: String = "res://data/omamori/magatama.tres"


func test_every_three_reds_add_mult() -> void:
	var game: BoardGame = Harness.board(
		Harness.ROW + Harness.ROW.map(_lower), Harness.with_omamori(MAGATAMA)
	)
	Harness.all_blue(game)
	for peg: int in 7:
		game.roles[peg] = BoardGame.Role.RED
	Harness.shoot(game)
	for peg: int in 7:
		game.score_hit(peg)
	Harness.finish(game)
	# Seven reds: +7 mult from the lanterns, +2 from two full sets of three.
	assert_int(game.shot_mult).is_equal(1000 + 7000 + 2000)


func _lower(position: Vector2i) -> Vector2i:
	return position + Vector2i(0, 60)
