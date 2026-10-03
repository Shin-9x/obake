extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const LANTERN: String = "res://data/pegs/explosive_lantern.tres"
## The lantern, a neighbour within its blast and one beyond it.
const PEGS: Array[Vector2i] = [Vector2i(80, 200), Vector2i(100, 200), Vector2i(140, 200)]


func test_hitting_it_hits_every_peg_around_it() -> void:
	var game: BoardGame = Harness.board(PEGS)
	Harness.all_blue(game)
	game.place_special(0, load(LANTERN))
	Harness.shoot(game)
	game.score_hit(0)
	assert_bool(game.simulation.pegs[1].lit).is_true()
	assert_bool(game.simulation.pegs[2].lit).is_false()
	assert_int(game.shot_points).is_equal(10)
	assert_array(Harness.events_of(game, SimEvent.Kind.AREA_HIT)).has_size(1)


func test_explosions_chain_through_other_explosive_lanterns() -> void:
	var chain: Array[Vector2i] = [
		Vector2i(80, 200), Vector2i(100, 200), Vector2i(120, 200), Vector2i(140, 200)
	]
	var game: BoardGame = Harness.board(chain)
	Harness.all_blue(game)
	for peg: int in [0, 1, 2]:
		game.place_special(peg, load(LANTERN))
	Harness.shoot(game)
	game.score_hit(0)
	assert_bool(game.simulation.pegs[3].lit).is_true()
	assert_array(Harness.events_of(game, SimEvent.Kind.AREA_HIT)).has_size(3)
