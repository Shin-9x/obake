extends GdUnitTestSuite
## GDD targets: 800 first, x1.35 per board, elite x1.5, boss x1.8 over the board before.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_standard_targets_grow_with_every_board() -> void:
	var config: BalanceConfig = Fixtures.config()
	var targets: Array[int] = []
	for played: int in 4:
		targets.append(TargetSchedule.target(config, MapNode.Kind.BOARD, played))
	# 800, 1080, 1458 and 1968, rounded to tens.
	assert_array(targets).is_equal([800, 1080, 1460, 1970])


func test_elite_and_boss_targets() -> void:
	var config: BalanceConfig = Fixtures.config()
	assert_int(TargetSchedule.target(config, MapNode.Kind.ELITE, 1)).is_equal(1620)
	# Boss after three boards: 1458 x 1.8 = 2624.4.
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 3)).is_equal(2620)
	assert_int(TargetSchedule.target(config, MapNode.Kind.BOSS, 0)).is_equal(1440)
