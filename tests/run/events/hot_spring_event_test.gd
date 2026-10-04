extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_a_ball_goes_up_a_level_for_free() -> void:
	var state: RunState = Fixtures.state("tanuki")
	var spring: RunEvent = Events.event("hot_spring")
	var zeni: int = state.inventory.ball_count() - 1
	assert_array(spring.choices(state)[0].options).is_equal(PackedInt32Array([zeni]))
	Events.choose(spring, state, 0, zeni)
	assert_int(state.inventory.level_of(zeni)).is_equal(2)
	assert_int(state.mon).is_equal(4)
