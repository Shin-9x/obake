extends GdUnitTestSuite
## A new run: starting mon and bag, and every floor map and the order of the bosses drawn from
## the seed.

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


func test_the_seed_deals_the_early_bosses_and_keeps_the_last_one_last() -> void:
	var orders: Dictionary[String, bool] = {}
	for seed_value: int in range(1, 41):
		var order: PackedInt32Array = Fixtures.state("yamabushi", seed_value).boss_order
		assert_array(order).is_equal(Fixtures.state("tanuki", seed_value).boss_order)
		assert_int(order.size()).is_equal(4)
		assert_int(order[3]).is_equal(3)
		var early: Array = Array(order.slice(0, 3))
		early.sort()
		assert_array(early).is_equal([0, 1, 2])
		orders[str(order)] = true
	# Three bosses over three floors can come in six orders.
	assert_int(orders.size()).is_equal(6)


func test_dealing_bosses_leaves_the_maps_of_a_seed_alone() -> void:
	var with_bosses: RunState = Fixtures.state("yamabushi", 99)
	var without: RunState = RunState.start(Fixtures.config(), Fixtures.character(), 99, 0)
	assert_array(without.boss_order).is_empty()
	for floor_index: int in with_bosses.maps.size():
		var nodes: Array[MapNode] = with_bosses.maps[floor_index].nodes
		var plain: Array[MapNode] = without.maps[floor_index].nodes
		assert_int(nodes.size()).is_equal(plain.size())
		for index: int in nodes.size():
			assert_int(nodes[index].kind).is_equal(plain[index].kind)
			assert_array(nodes[index].next).is_equal(plain[index].next)


func test_fewer_early_bosses_than_floors_come_round_again() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.floors = 6
	var order: PackedInt32Array = RunState.start(config, Fixtures.character(), 5, 3).boss_order
	assert_int(order.size()).is_equal(6)
	assert_int(order[5]).is_equal(2)
	assert_int(order[2]).is_equal(order[0])
	assert_bool(order[0] != order[1]).is_true()
	assert_array(RunState.start(config, Fixtures.character(), 5, 1).boss_order).is_equal(
		[0, 0, 0, 0, 0, 0]
	)


func test_spending_needs_enough_mon() -> void:
	var state: RunState = Fixtures.state()
	assert_bool(state.spend(5)).is_false()
	assert_bool(state.spend(3)).is_true()
	assert_int(state.mon).is_equal(1)
