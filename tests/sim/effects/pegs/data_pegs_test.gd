extends GdUnitTestSuite
## Purchasable pegs whose definition says everything: no effect script.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")


func test_coin_peg_pays_mon() -> void:
	var game: BoardGame = _hit("res://data/pegs/coin_peg.tres")
	assert_int(game.mon_earned).is_equal(1)
	assert_int(game.shot_points).is_equal(0)


func test_bell_adds_mult() -> void:
	assert_int(_hit("res://data/pegs/bell.tres").shot_mult).is_equal(3000)


func test_kagami_multiplies_mult() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	game.place_special(0, load("res://data/pegs/kagami.tres"))
	Harness.shoot(game)
	game.add_mult(1000, 0, 0)
	game.score_hit(0)
	assert_int(game.shot_mult).is_equal(3000)


func test_torii_scores_once_per_shot_bounces_hard_and_stays() -> void:
	var game: BoardGame = Harness.board([Vector2i(181, 100)])
	game.place_special(0, load("res://data/pegs/torii.tres"))
	assert_int(game.simulation.pegs[0].restitution).is_equal(1300)
	Harness.shoot(game)
	Harness.finish(game)
	var torii_points: Array[int] = []
	for event: SimEvent in Harness.events_of(game, SimEvent.Kind.SCORE_POINTS):
		if event.target == 0:
			torii_points.append(event.amount)
	assert_array(torii_points).is_equal([15])
	assert_bool(game.simulation.pegs[0].removed).is_false()
	assert_bool(game.simulation.pegs[0].lit).is_false()


func _hit(path: String) -> BoardGame:
	var game: BoardGame = Harness.board(Harness.ROW)
	game.place_special(0, load(path))
	Harness.shoot(game)
	game.score_hit(0)
	return game
