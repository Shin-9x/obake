extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PATIENCE: String = "res://data/omamori/patience.tres"


func test_long_shots_gain_mult() -> void:
	var needed: int = (load(PATIENCE) as OmamoriDefinition).params[&"pegs"]
	assert_int(_shot_mult(needed)).is_equal(4000)
	assert_int(_shot_mult(needed - 1)).is_equal(1000)


func _shot_mult(hits: int) -> int:
	var row: Array[Vector2i] = []
	for index: int in hits:
		row.append(Vector2i(14 + index * 11, 300))
	var game: BoardGame = Harness.board(row, Harness.with_omamori(PATIENCE))
	Harness.all_blue(game)
	Harness.shoot(game)
	for peg: int in hits:
		game.score_hit(peg)
	Harness.finish(game)
	return game.shot_mult
