extends GdUnitTestSuite
## A new run: starting mon and bag, and every floor map drawn from the seed.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_a_run_starts_with_the_gdd_mon_and_four_maps() -> void:
	var state: RunState = Fixtures.state("yamabushi")
	assert_int(state.mon).is_equal(4)
	assert_int(state.maps.size()).is_equal(4)
	assert_int(state.inventory.ball_count()).is_equal(8)
	assert_int(state.node).is_equal(-1)
	assert_object(state.current_node()).is_null()


func test_maps_depend_only_on_the_seed() -> void:
	var a: RunState = Fixtures.state("yamabushi", 99)
	var b: RunState = Fixtures.state("tanuki", 99)
	for floor_index: int in a.maps.size():
		var nodes_a: Array[MapNode] = a.maps[floor_index].nodes
		var nodes_b: Array[MapNode] = b.maps[floor_index].nodes
		assert_int(nodes_b.size()).is_equal(nodes_a.size())
		for index: int in nodes_a.size():
			assert_int(nodes_b[index].kind).is_equal(nodes_a[index].kind)


func test_spending_needs_enough_mon() -> void:
	var state: RunState = Fixtures.state()
	assert_bool(state.spend(5)).is_false()
	assert_bool(state.spend(3)).is_true()
	assert_int(state.mon).is_equal(1)
