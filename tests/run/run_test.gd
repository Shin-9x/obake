extends GdUnitTestSuite
## The run state machine, driven with made-up board results.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_a_run_starts_on_the_map_at_the_first_step() -> void:
	var run: Run = _run()
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	assert_array(run.reachable_nodes()).is_equal(run.state.current_map().steps[0])
	assert_bool(run.choose_node(run.state.current_map().steps[1][0])).is_false()


func test_a_board_node_prepares_the_board_of_the_floor() -> void:
	var run: Run = _run()
	run.state.shot_delta = -1
	_enter(run, MapNode.Kind.BOARD)
	assert_int(run.phase).is_equal(Run.Phase.BOARD)
	assert_int(run.board.rules.target).is_equal(800)
	assert_int(run.board.rules.shot_delta).is_equal(-1)
	assert_object(run.board.rules.boss).is_null()
	assert_str(run.board.layout.biome).is_equal("bamboo_forest")
	assert_int(run.board.layout.kind).is_equal(BoardLayout.Kind.BOARD)


func test_layouts_do_not_repeat_on_a_floor() -> void:
	var run: Run = _run()
	var seen: Dictionary[String, bool] = {}
	for board: int in 4:
		run.phase = Run.Phase.MAP
		run.state.node = -1
		_enter(run, MapNode.Kind.BOARD)
		assert_bool(seen.has(run.board.layout.id)).is_false()
		seen[run.board.layout.id] = true


func test_a_won_board_pays_and_offers_three_balls() -> void:
	var run: Run = _run()
	_enter(run, MapNode.Kind.BOARD)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 2)
	assert_int(run.phase).is_equal(Run.Phase.REWARD)
	# 4 mon held: no interest; win 4 and two unused shots.
	assert_int(run.state.mon).is_equal(10)
	assert_array(run.ball_choices).has_size(3)
	assert_array(run.omamori_choices).is_empty()
	var bag: int = run.state.inventory.ball_count()
	assert_bool(run.take_ball(1)).is_true()
	assert_int(run.state.inventory.ball_count()).is_equal(bag + 1)
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	assert_int(run.state.boards_won).is_equal(1)


func test_skipping_the_ball_pays_two_mon() -> void:
	var run: Run = _run()
	_enter(run, MapNode.Kind.BOARD)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 0)
	var mon: int = run.state.mon
	run.skip_ball()
	assert_int(run.state.mon).is_equal(mon + 2)
	assert_int(run.phase).is_equal(Run.Phase.MAP)


func test_an_elite_board_offers_a_ball_then_an_omamori() -> void:
	var run: Run = _run()
	_enter(run, MapNode.Kind.ELITE)
	assert_int(run.board.rules.target).is_equal(1200)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 0)
	assert_bool(run.take_omamori(0)).is_false()
	run.take_ball(0)
	assert_int(run.phase).is_equal(Run.Phase.REWARD)
	assert_array(run.omamori_choices).has_size(3)
	assert_bool(run.take_omamori(2)).is_true()
	assert_int(run.state.inventory.omamori_count()).is_equal(1)
	assert_int(run.phase).is_equal(Run.Phase.MAP)


func test_a_full_set_of_slots_needs_an_omamori_to_replace() -> void:
	var run: Run = _run()
	for id: String in ["chochin", "drum", "kaeru", "uchiwa", "patience"]:
		run.state.inventory.add_omamori(Fixtures.omamori(id))
	_enter(run, MapNode.Kind.ELITE)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 0)
	run.skip_ball()
	var offered: OmamoriDefinition = run.omamori_choices[0]
	assert_bool(run.take_omamori(0)).is_false()
	assert_bool(run.take_omamori(0, 3)).is_true()
	assert_object(run.state.inventory.loadout.omamori[3]).is_same(offered)


func test_beating_a_boss_offers_omamori_and_opens_the_next_floor() -> void:
	var run: Run = _run()
	_enter_boss(run)
	assert_object(run.board.rules.boss).is_same(run.content.floor_bosses[0])
	assert_str(run.board.layout.id).is_equal("jorogumo")
	Fixtures.finish(run, BoardGame.Outcome.MATSURI, 0)
	assert_array(run.ball_choices).is_empty()
	assert_array(run.omamori_choices).has_size(3)
	run.skip_omamori()
	assert_int(run.state.floor_index).is_equal(1)
	assert_int(run.state.node).is_equal(-1)
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	assert_int(run.state.matsuri_count).is_equal(1)


func test_nue_brings_its_second_form() -> void:
	var run: Run = _run()
	run.state.floor_index = 1
	_enter_boss(run)
	assert_str(run.board.layout.id).is_equal("nue_a")
	assert_str(run.board.next_layer.id).is_equal("nue_b")


func test_beating_the_last_boss_wins_the_run() -> void:
	var run: Run = _run()
	run.state.floor_index = 3
	_enter_boss(run)
	Fixtures.finish(run, BoardGame.Outcome.TARGET_REACHED, 0)
	assert_int(run.phase).is_equal(Run.Phase.VICTORY)


func test_losing_a_board_ends_the_run() -> void:
	var run: Run = _run()
	_enter(run, MapNode.Kind.BOARD)
	Fixtures.finish(run, BoardGame.Outcome.FAILED, 0)
	assert_int(run.phase).is_equal(Run.Phase.DEFEAT)


func test_the_kappa_pays_on_a_matsuri_and_forgets_the_bet_otherwise() -> void:
	for outcome: BoardGame.Outcome in [BoardGame.Outcome.MATSURI, BoardGame.Outcome.TARGET_REACHED]:
		var run: Run = _run()
		run.state.bet = 15
		_enter(run, MapNode.Kind.BOARD)
		Fixtures.finish(run, outcome, 0)
		var wager: int = 15 if outcome == BoardGame.Outcome.MATSURI else 0
		assert_int(run.payout.wager).is_equal(wager)
		assert_int(run.state.bet).is_equal(0)


func test_shops_shrines_and_events_return_to_the_map() -> void:
	var run: Run = _run()
	_enter(run, MapNode.Kind.SHOP)
	assert_int(run.phase).is_equal(Run.Phase.SHOP)
	assert_object(run.shop).is_not_null()
	run.leave_shop()
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	run.state.node = -1
	_enter(run, MapNode.Kind.SHRINE)
	assert_int(run.phase).is_equal(Run.Phase.SHRINE)
	assert_bool(run.shrine_upgrade(0)).is_false()
	assert_bool(run.shrine_upgrade(run.state.inventory.upgradable_balls()[0])).is_true()
	assert_int(run.phase).is_equal(Run.Phase.MAP)
	run.state.node = -1
	_enter(run, MapNode.Kind.EVENT)
	assert_int(run.phase).is_equal(Run.Phase.EVENT)
	var leave: int = run.event.choices(run.state).size() - 1
	assert_str(run.choose_event(leave).text_key).is_equal("EVENT_LEFT")
	run.finish_event()
	assert_int(run.phase).is_equal(Run.Phase.MAP)


func _run() -> Run:
	return Fixtures.run()


## Turns the first reachable node into [param kind] and enters it.
func _enter(run: Run, kind: MapNode.Kind) -> void:
	var node: int = run.reachable_nodes()[0]
	run.state.current_map().nodes[node].kind = kind
	assert_bool(run.choose_node(node)).is_true()


func _enter_boss(run: Run) -> void:
	var map: FloorMap = run.state.current_map()
	run.state.node = map.steps[map.steps.size() - 2][0]
	assert_bool(run.choose_node(map.boss())).is_true()
