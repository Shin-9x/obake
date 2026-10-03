extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const DARUMA: String = "res://data/balls/daruma.tres"
const HITODAMA: String = "res://data/balls/hitodama.tres"


func test_lost_daruma_returns_on_top_until_its_returns_run_out() -> void:
	var daruma: BallDefinition = load(DARUMA)
	var returns: int = daruma.level_values[0]
	var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([daruma, load(HITODAMA)]))
	var daruma_shots: int = 0
	while daruma_shots <= returns:
		var is_daruma: bool = game.bag.peek(0).definition == daruma
		Harness.shoot(game)
		Harness.finish(game)
		if not is_daruma:
			continue
		daruma_shots += 1
		if daruma_shots <= returns:
			assert_object(game.bag.peek(0).definition).is_same(daruma)
	assert_array(Harness.events_of(game, SimEvent.Kind.EFFECT_TRIGGERED)).has_size(returns)


func test_a_caught_daruma_is_not_kept_on_top() -> void:
	var daruma: BallDefinition = load(DARUMA)
	var game: BoardGame = Harness.board(Harness.ROW, Harness.loadout([daruma, load(HITODAMA)]))
	while game.bag.peek(0).definition != daruma:
		Harness.shoot(game)
		Harness.finish(game)
	Harness.shoot_into_bucket(game)
	Harness.finish(game)
	assert_bool(game.shot_caught).is_true()
	assert_array(Harness.events_of(game, SimEvent.Kind.EFFECT_TRIGGERED)).is_empty()
