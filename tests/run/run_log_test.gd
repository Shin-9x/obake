extends GdUnitTestSuite
## Every action that succeeds is logged with its arguments; snapshots follow the map.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_board_actions_are_logged_with_their_arguments() -> void:
	var run: Run = Fixtures.run()
	var node: int = run.reachable_nodes()[0]
	run.state.current_map().nodes[node].kind = MapNode.Kind.BOARD
	run.choose_node(node)
	assert_bool(run.shoot(1234, 77)).is_true()
	assert_bool(run.take_ball(0)).is_false()
	assert_array(_entries(run)).is_equal(
		[[RunLog.Action.CHOOSE_NODE, node, -1], [RunLog.Action.SHOOT, 1234, 77]]
	)


func test_shop_actions_go_through_the_run_and_are_logged() -> void:
	var run: Run = Fixtures.run()
	var node: int = run.reachable_nodes()[0]
	run.state.current_map().nodes[node].kind = MapNode.Kind.SHOP
	run.choose_node(node)
	run.state.mon = 30
	assert_bool(run.buy_ball(0)).is_true()
	assert_bool(run.buy_ball(0)).is_false()
	assert_bool(run.reroll()).is_true()
	assert_bool(run.leave_shop()).is_true()
	var kinds: Array[int] = []
	for entry: Array in _entries(run):
		kinds.append(entry[0])
	assert_array(kinds).is_equal(
		[
			RunLog.Action.CHOOSE_NODE,
			RunLog.Action.BUY_BALL,
			RunLog.Action.REROLL,
			RunLog.Action.LEAVE_SHOP
		]
	)


func test_the_log_survives_json() -> void:
	var run: Run = Fixtures.run()
	run.choose_node(run.reachable_nodes()[1])
	run.shoot(-500, 12)
	var text: String = JSON.stringify(run.run_log.to_dictionary())
	var parsed: RunLog = RunLog.from_dictionary(JSON.parse_string(text))
	assert_int(parsed.run_seed).is_equal(run.run_log.run_seed)
	assert_str(String(parsed.character)).is_equal("yamabushi")
	assert_array(parsed.actions).is_equal(run.run_log.actions)
	assert_object(RunLog.from_dictionary({"format": 99})).is_null()


func test_snapshots_are_taken_whenever_the_run_is_on_the_map() -> void:
	var run: Run = Fixtures.run()
	assert_int(run.snapshot_at).is_equal(0)
	var node: int = run.reachable_nodes()[0]
	run.state.current_map().nodes[node].kind = MapNode.Kind.BOARD
	run.choose_node(node)
	run.shoot(0, 0)
	assert_int(run.snapshot_at).is_equal(0)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED)
	run.take_ball(0)
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	assert_int(run.snapshot_at).is_equal(run.run_log.size())
	assert_int(int(run.snapshot["mon"])).is_equal(run.state.mon)


func _entries(run: Run) -> Array[Array]:
	var entries: Array[Array] = []
	for entry: PackedInt32Array in run.run_log.actions:
		entries.append(Array(entry))
	return entries
