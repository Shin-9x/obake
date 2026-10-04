extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_a_ball_can_be_left_for_free() -> void:
	var state: RunState = Fixtures.state("yamabushi")
	var temple: RunEvent = Events.event("abandoned_temple")
	assert_int(temple.choices(state)[0].pick).is_equal(EventChoice.Pick.BALL)
	Events.choose(temple, state, 0, 6)
	assert_int(state.inventory.ball_count()).is_equal(7)
	assert_int(state.mon).is_equal(4)


func test_a_common_omamori_can_be_taken_into_a_free_slot() -> void:
	var state: RunState = Fixtures.state()
	var outcome: EventOutcome = Events.choose(Events.event("abandoned_temple"), state, 1)
	assert_int(outcome.item.rarity).is_equal(ItemDefinition.Rarity.COMMON)
	assert_int(state.inventory.omamori_count()).is_equal(1)
	for id: String in ["chochin", "drum", "kaeru", "uchiwa"]:
		state.inventory.add_omamori(Fixtures.omamori(id))
	assert_bool(Events.event("abandoned_temple").choices(state)[1].enabled).is_false()
