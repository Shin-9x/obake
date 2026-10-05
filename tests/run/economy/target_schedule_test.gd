extends GdUnitTestSuite
## The target formula, on fixed numbers so tuning never moves it: 800 first, x1.35 per board,
## elite x1.5, and a boss of factor x1.8 over the board before.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_standard_targets_grow_with_every_board() -> void:
	var config: BalanceConfig = _config()
	var targets: Array[int] = []
	for played: int in 4:
		targets.append(TargetSchedule.target(config, MapNode.Kind.BOARD, played))
	# 800, 1080, 1458 and 1968, rounded to tens.
	assert_array(targets).is_equal([800, 1080, 1460, 1970])


func test_elite_and_boss_targets() -> void:
	var config: BalanceConfig = _config()
	assert_int(TargetSchedule.target(config, MapNode.Kind.ELITE, 1)).is_equal(1620)
	# Boss after three boards: 1458 x 1.8 = 2624.4.
	var boss: BossDefinition = BossDefinition.new()
	boss.target_factor = 1800
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 3, false, boss)).is_equal(2620)
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 0, false, boss)).is_equal(1440)


func test_each_boss_brings_its_own_factor() -> void:
	var config: BalanceConfig = _config()
	var gentle: BossDefinition = BossDefinition.new()
	gentle.target_factor = 1200
	# 1080 x 1.2 = 1296.
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 2, false, gentle)).is_equal(1300)


static func _config() -> BalanceConfig:
	var config: BalanceConfig = Fixtures.config()
	config.first_board_target = 800
	config.board_target_growth = 1350
	config.elite_target_factor = 1500
	config.target_rounding = 10
	return config
