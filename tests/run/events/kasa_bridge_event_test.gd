extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_crossing_adds_a_slot_and_takes_a_shot_from_every_board() -> void:
	var state: RunState = Fixtures.state()
	Events.choose(Events.event("kasa_bridge"), state, 0)
	assert_int(state.inventory.slots).is_equal(6)
	assert_int(state.shot_delta).is_equal(-1)
