extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const ONIBI: String = "res://data/balls/onibi.tres"
## Under the launcher, a near neighbour and a farther one, both within the fire's reach.
const PEGS: Array[Vector2i] = [Vector2i(181, 100), Vector2i(205, 100), Vector2i(215, 120)]


func test_touched_pegs_set_fire_to_their_nearest_neighbours() -> void:
	var definition: BallDefinition = load(ONIBI)
	var game: BoardGame = Harness.board(PEGS, Harness.with_ball(ONIBI))
	Harness.shoot(game)
	while Harness.events_of(game, SimEvent.Kind.PEG_HIT).is_empty():
		game.step()
	var burning: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.PEG_BURNING)
	assert_array(burning).has_size(definition.level_values[0])
	assert_int(burning[0].target).is_equal(1)
	assert_bool(game.simulation.pegs[1].lit).is_false()
	for i: int in definition.params[&"delay"]:
		game.step()
	assert_bool(game.simulation.pegs[1].lit or game.simulation.pegs[1].removed).is_true()


func test_pegs_hit_by_fire_or_explosions_do_not_spread_it() -> void:
	var game: BoardGame = Harness.board(Harness.ROW, Harness.with_ball(ONIBI))
	Harness.shoot(game)
	game.score_hit(1, PegHit.Source.FIRE)
	game.score_hit(2, PegHit.Source.AREA)
	assert_array(Harness.events_of(game, SimEvent.Kind.PEG_BURNING)).is_empty()
	game.score_hit(3, PegHit.Source.BALL, game.simulation.launched_ball)
	assert_array(Harness.events_of(game, SimEvent.Kind.PEG_BURNING)).is_not_empty()
