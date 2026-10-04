extends GdUnitTestSuite
## The run state survives JSON: inventory, money, progress and the random streams.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const RunBot: GDScript = preload("res://tests/run/support/run_bot.gd")


func test_a_state_round_trips_through_json_and_keeps_its_streams() -> void:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 1
	config.target_rounding = 1
	var bot: RefCounted = RunBot.new(Fixtures.run("kitsune", config), 5)
	bot.play(2)
	var state: RunState = bot.run.state
	state.inventory.add_omamori(Fixtures.omamori("drum"))
	state.inventory.add_peg(load("res://data/pegs/bell.tres"))
	state.carry.add_role_bonus(BoardGame.Role.BLUE, 2)
	var data: Dictionary = JSON.parse_string(JSON.stringify(RunCodec.encode(state)))
	var restored: RunState = RunCodec.decode(data, config, ItemCatalog.new(Fixtures.content()))
	assert_object(restored).is_not_null()
	assert_dict(RunCodec.encode(restored)).is_equal(RunCodec.encode(state))
	for domain: int in RngStreams.Domain.size():
		assert_int(restored.streams.stream(domain).next_u32()).is_equal(
			state.streams.stream(domain).next_u32()
		)
	assert_int(restored.maps.size()).is_equal(state.maps.size())
	assert_int(restored.maps[3].nodes.size()).is_equal(state.maps[3].nodes.size())


func test_unknown_items_make_the_state_unreadable() -> void:
	var data: Dictionary = RunCodec.encode(Fixtures.state())
	data["omamori"] = ["no_such_charm"]
	(
		assert_object(RunCodec.decode(data, Fixtures.config(), ItemCatalog.new(Fixtures.content())))
		. is_null()
	)
