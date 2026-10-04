extends GdUnitTestSuite
## Ball and omamori rewards after a won board.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_three_different_balls_are_offered() -> void:
	for seed_value: int in 30:
		var state: RunState = Fixtures.state("yamabushi", seed_value)
		var balls: Array[BallDefinition] = Rewards.ball_choices(
			state, Fixtures.content(), Fixtures.config()
		)
		assert_array(balls).has_size(3)
		var ids: Dictionary[StringName, bool] = {}
		for ball: BallDefinition in balls:
			assert_bool(ids.has(ball.id)).is_false()
			ids[ball.id] = true
			assert_int(ball.rarity).is_not_equal(ItemDefinition.Rarity.BASE)


func test_omamori_rewards_skip_owned_ones_and_can_be_legendary() -> void:
	var config: BalanceConfig = Fixtures.config()
	var legendary: int = 0
	for seed_value: int in 40:
		var state: RunState = Fixtures.state("yamabushi", seed_value)
		state.inventory.add_omamori(Fixtures.omamori("chochin"))
		var choices: Array[OmamoriDefinition] = Rewards.omamori_choices(
			state, Fixtures.content(), config, config.boss_omamori_weights
		)
		assert_array(choices).has_size(3)
		for charm: OmamoriDefinition in choices:
			assert_str(String(charm.id)).is_not_equal("chochin")
			legendary += 1 if charm.rarity == ItemDefinition.Rarity.LEGENDARY else 0
	assert_int(legendary).is_greater(0)


func test_rewards_draw_from_their_own_stream() -> void:
	var state: RunState = Fixtures.state()
	var shop_before: int = Fixtures.state().streams.stream(RngStreams.Domain.SHOP).next_u32()
	Rewards.ball_choices(state, Fixtures.content(), Fixtures.config())
	assert_int(state.streams.stream(RngStreams.Domain.SHOP).next_u32()).is_equal(shop_before)
