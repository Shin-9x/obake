extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const JOROGUMO: String = "res://data/bosses/jorogumo.tres"
## A web around the first two pegs of the harness row.
const WEB: Vector3i = Vector3i(60, 200, 30)


func test_webs_brake_the_ball() -> void:
	var game: BoardGame = Harness.boss_board(JOROGUMO, Harness.ROW, [WEB])
	var drag: int = (load(JOROGUMO) as BossDefinition).params[&"drag"]
	assert_int(drag).is_greater(0)
	assert_int(game.simulation.zones[0].drag).is_equal(drag)


func test_pegs_in_a_web_score_triple_points() -> void:
	var game: BoardGame = Harness.boss_board(JOROGUMO, Harness.ROW, [WEB])
	Harness.all_blue(game)
	Harness.shoot(game)
	game.score_hit(0)
	assert_int(game.shot_points).is_equal(30)
	game.score_hit(2)
	assert_int(game.shot_points).is_equal(40)
	var triggers: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.EFFECT_TRIGGERED)
	assert_array(triggers).has_size(1)
	assert_int(triggers[0].target).is_equal(Effect.BOSS_SLOT)
