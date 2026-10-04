extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_a_random_rare_ball_costs_eight_mon() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 10
	var traveller: RunEvent = Events.event("traveller")
	assert_array(traveller.text_args()).is_equal([8])
	var outcome: EventOutcome = Events.choose(traveller, state, 0)
	assert_int(outcome.item.rarity).is_equal(ItemDefinition.Rarity.RARE)
	assert_int(state.mon).is_equal(2)
	assert_object(state.inventory.ball(state.inventory.ball_count() - 1)).is_same(outcome.item)
