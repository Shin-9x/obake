extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_betting_pays_now_and_stakes_the_winnings() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 7
	var kappa: RunEvent = Events.event("kappa")
	assert_array(kappa.text_args()).is_equal([5, 15])
	assert_object(Events.choose(kappa, state, 0)).is_not_null()
	assert_int(state.mon).is_equal(2)
	assert_int(state.bet).is_equal(15)


func test_betting_needs_the_stake_and_no_pending_bet() -> void:
	var state: RunState = Fixtures.state()
	var kappa: RunEvent = Events.event("kappa")
	assert_bool(kappa.choices(state)[0].enabled).is_false()
	state.mon = 20
	state.bet = 15
	assert_bool(kappa.choices(state)[0].enabled).is_false()
