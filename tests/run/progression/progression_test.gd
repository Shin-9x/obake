extends GdUnitTestSuite
## Feats, the item pool they open, completion marks, statistics and discoveries.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const PROGRESSION: String = "res://data/progression.tres"


func test_twelve_items_are_locked_at_first_launch() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var ids: Array[StringName] = Progression.pool(Fixtures.content(), definition, Profile.new())
	assert_int(ids.size()).is_equal(18)
	assert_array(ids).not_contains([&"splitter", &"kaeru", &"shuten_sake", &"kagami"])
	assert_array(ids).contains([&"heavy", &"taiko", &"zeni", &"explosive", &"phantom"])


func test_a_feat_opens_its_item_for_the_next_runs() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var profile: Profile = Profile.new()
	profile.feats.append(&"thirty_pegs")
	assert_array(Progression.pool(Fixtures.content(), definition, profile)).contains([&"splitter"])


func test_locked_items_are_never_offered() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var options: RunOptions = RunOptions.new()
	options.pool = Progression.pool(Fixtures.content(), definition, Profile.new())
	for seed_value: int in 15:
		var run: Run = Run.start(
			Fixtures.config(),
			Fixtures.content(),
			LayoutLibrary.load_from(),
			Fixtures.base_pegs(),
			Fixtures.character(),
			seed_value,
			options
		)
		var shop: Shop = Shop.new(run.state, run.content, run.config)
		var offered: Array[ItemDefinition] = []
		for row: Array[Offer] in [shop.balls, shop.omamori, shop.pegs]:
			for offer: Offer in row:
				offered.append(offer.item)
		offered.append_array(Rewards.ball_choices(run.state, run.content, run.config))
		offered.append_array(
			Rewards.omamori_choices(
				run.state, run.content, run.config, run.config.boss_omamori_weights
			)
		)
		for item: ItemDefinition in offered:
			assert_array(options.pool).contains([item.id])


func test_the_pool_is_saved_with_the_run() -> void:
	var options: RunOptions = RunOptions.new()
	options.pool = [&"heavy", &"chochin", &"bell"]
	var run: Run = Run.start(
		Fixtures.config(),
		Fixtures.content(),
		LayoutLibrary.load_from(),
		Fixtures.base_pegs(),
		Fixtures.character(),
		1,
		options
	)
	var save: Dictionary = JSON.parse_string(JSON.stringify(run.to_save()))
	var resumed: Run = Run.resume(
		save, Fixtures.config(), Fixtures.content(), LayoutLibrary.load_from(), Fixtures.base_pegs()
	)
	assert_array(resumed.run_log.options.pool).is_equal(options.pool)
	assert_int(resumed.content.balls.size()).is_equal(1)
	assert_int(resumed.content.omamori.size()).is_equal(1)


func test_each_kind_of_feat() -> void:
	var cases: Array[Array] = [
		[FeatDefinition.Condition.PEGS_IN_SHOT, 30, {"best_shot_pegs": 30}, {"best_shot_pegs": 29}],
		[
			FeatDefinition.Condition.BUCKETS_IN_BOARD,
			3,
			{"bucket_catches": 3},
			{"bucket_catches": 2}
		],
		[FeatDefinition.Condition.ONE_SHOT_WIN, 0, {"shots_fired": 1}, {"shots_fired": 2}],
		[FeatDefinition.Condition.REDS_IN_SHOT, 5, {"best_shot_reds": 5}, {"best_shot_reds": 4}],
		[FeatDefinition.Condition.LAST_SHOT_WIN, 0, {"shots_left": 0}, {"shots_left": 1}],
		[FeatDefinition.Condition.POINTS_IN_SHOT, 1000, {"best_shot": 1000}, {"best_shot": 999}],
		[FeatDefinition.Condition.MULT_IN_SHOT, 10000, {"best_shot_mult": 10000}, {}],
		[FeatDefinition.Condition.MATSURI, 0, {"outcome": BoardGame.Outcome.MATSURI}, {}],
	]
	for case: Array in cases:
		var feat: FeatDefinition = _feat(case[0], case[1])
		(
			assert_bool(Progression.achieves(feat, _finished(case[2])))
			. override_failure_message("feat %d" % case[0])
			. is_true()
		)
		(
			assert_bool(Progression.achieves(feat, _finished(case[3])))
			. override_failure_message("feat %d" % case[0])
			. is_false()
		)


func test_run_and_boss_feats() -> void:
	var streak: FeatDefinition = _feat(FeatDefinition.Condition.MATSURI_IN_RUN, 3)
	var run: Run = _finished({"outcome": BoardGame.Outcome.MATSURI})
	run.state.matsuri_count = 3
	assert_bool(Progression.achieves(streak, run)).is_true()
	var collector: FeatDefinition = _feat(FeatDefinition.Condition.PEGS_BOUGHT_IN_RUN, 4)
	for peg: int in 4:
		run.state.inventory.add_peg(load("res://data/pegs/bell.tres"))
	assert_bool(Progression.achieves(collector, run)).is_true()
	var boss_run: Run = _finished({"special_balls_fired": 0}, true)
	var purist: FeatDefinition = _feat(FeatDefinition.Condition.BOSS_WITHOUT_SPECIALS, 0)
	assert_bool(Progression.achieves(purist, boss_run)).is_true()
	(
		assert_bool(Progression.achieves(purist, _finished({"special_balls_fired": 1}, true)))
		. is_false()
	)
	assert_bool(Progression.achieves(purist, _finished({}))).is_false()
	var slayer: FeatDefinition = _feat(FeatDefinition.Condition.BOSS_DEFEATED, 0)
	slayer.boss = boss_run.board.rules.boss
	assert_bool(Progression.achieves(slayer, boss_run)).is_true()
	slayer.boss = load("res://data/bosses/shuten_doji.tres")
	assert_bool(Progression.achieves(slayer, boss_run)).is_false()


func test_feats_are_recorded_once() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var profile: Profile = Profile.new()
	var run: Run = _finished({"best_shot_pegs": 31, "outcome": BoardGame.Outcome.MATSURI})
	var ids: Array[StringName] = []
	for feat: FeatDefinition in Progression.check_board(definition, profile, run):
		ids.append(feat.id)
	assert_array(ids).contains([&"thirty_pegs", &"first_matsuri"])
	assert_array(Progression.check_board(definition, profile, run)).is_empty()


func test_a_won_run_earns_marks_and_statistics() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var profile: Profile = Profile.new()
	var run: Run = Fixtures.run("tanuki")
	run.phase = Run.Phase.VICTORY
	run.state.matsuri_count = 8
	run.state.boards_won = 17
	run.state.best_shot = 3100
	var marks: Array[Profile.Mark] = Progression.finish_run(definition, profile, run)
	assert_array(marks).is_equal([Profile.Mark.SHUTEN, Profile.Mark.FESTIVAL])
	assert_int(profile.runs).is_equal(1)
	assert_int(profile.wins_by_character[&"tanuki"]).is_equal(1)
	assert_int(profile.best_shot).is_equal(3100)
	assert_int(profile.matsuri).is_equal(8)
	assert_int(profile.boards_won).is_equal(17)
	assert_array(Progression.finish_run(definition, profile, run)).is_empty()
	assert_int(profile.runs).is_equal(2)


func test_a_lost_run_counts_but_earns_no_mark() -> void:
	var profile: Profile = Profile.new()
	var run: Run = Fixtures.run()
	run.phase = Run.Phase.DEFEAT
	assert_array(Progression.finish_run(load(PROGRESSION), profile, run)).is_empty()
	assert_int(profile.runs).is_equal(1)
	assert_dict(profile.wins_by_character).is_empty()


func test_items_and_bosses_met_are_discovered() -> void:
	var run: Run = Fixtures.run()
	var node: int = run.reachable_nodes()[0]
	run.state.current_map().nodes[node].kind = MapNode.Kind.SHOP
	run.choose_node(node)
	var profile: Profile = Profile.new()
	Progression.merge_discoveries(profile, run)
	assert_bool(profile.discovered.has(&"hitodama")).is_true()
	assert_bool(profile.discovered.has(run.shop.balls[0].item.id)).is_true()
	var boss: Run = Fixtures.run()
	var map: FloorMap = boss.state.current_map()
	boss.state.node = map.steps[map.steps.size() - 2][0]
	boss.choose_node(map.boss())
	assert_bool(boss.seen.has(&"jorogumo")).is_true()


func _feat(condition: FeatDefinition.Condition, threshold: int) -> FeatDefinition:
	var feat: FeatDefinition = FeatDefinition.new()
	feat.condition = condition
	feat.threshold = threshold
	feat.unlocks = load("res://data/balls/splitter.tres")
	return feat


## A run whose board just ended with a won result carrying [param fields].
func _finished(fields: Dictionary, boss: bool = false) -> Run:
	var run: Run = Fixtures.run()
	var map: FloorMap = run.state.current_map()
	if boss:
		run.state.node = map.steps[map.steps.size() - 2][0]
		run.choose_node(map.boss())
	else:
		run.choose_node(run.reachable_nodes()[0])
	var result: BoardResult = BoardResult.new()
	result.outcome = BoardGame.Outcome.TARGET_REACHED
	result.shots_left = 3
	result.shots_fired = 5
	result.special_balls_fired = 2
	for key: String in fields:
		result.set(key, fields[key])
	run.game.outcome = result.outcome
	run.game.result = result
	run.finish_board()
	return run
