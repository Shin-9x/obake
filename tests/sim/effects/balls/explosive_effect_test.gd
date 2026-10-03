extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const EXPLOSIVE: String = "res://data/balls/explosive.tres"
## Under the launcher, a neighbour in blast range and a peg out of it.
const PEGS: Array[Vector2i] = [Vector2i(181, 100), Vector2i(194, 100), Vector2i(240, 100)]


func test_first_impact_hits_the_pegs_around_it() -> void:
	var game: BoardGame = Harness.board(PEGS, Harness.with_ball(EXPLOSIVE))
	Harness.shoot(game)
	while Harness.events_of(game, SimEvent.Kind.PEG_HIT).is_empty():
		game.step()
	assert_array(Harness.events_of(game, SimEvent.Kind.AREA_HIT)).has_size(1)
	assert_bool(game.simulation.pegs[1].lit).is_true()
	assert_bool(game.simulation.pegs[2].lit).is_false()
	assert_int(game.shot_pegs_hit).is_equal(2)


func test_only_the_first_impact_explodes() -> void:
	var game: BoardGame = Harness.board(PEGS, Harness.with_ball(EXPLOSIVE))
	Harness.shoot(game)
	Harness.finish(game)
	assert_array(Harness.events_of(game, SimEvent.Kind.AREA_HIT)).has_size(1)
