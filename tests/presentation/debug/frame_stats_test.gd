extends GdUnitTestSuite
## Frame time percentiles, budget overruns and tick costs.


func test_percentiles_use_the_nearest_rank() -> void:
	var frames: PackedInt32Array = PackedInt32Array()
	for index: int in 100:
		frames.append((100 - index) * 1000)
	var stats: FrameStats = FrameStats.from(frames, PackedInt32Array())
	assert_int(stats.frames).is_equal(100)
	assert_int(stats.p50).is_equal(50_000)
	assert_int(stats.p95).is_equal(95_000)
	assert_int(stats.p99).is_equal(99_000)
	assert_int(stats.worst).is_equal(100_000)


func test_frames_over_one_and_two_budgets_are_counted() -> void:
	var frames: PackedInt32Array = [16_000, 16_667, 16_668, 33_335, 50_000]
	var stats: FrameStats = FrameStats.from(frames, [100, 300, 200])
	assert_int(stats.over_budget).is_equal(3)
	assert_int(stats.over_double_budget).is_equal(2)
	assert_int(stats.tick_average).is_equal(200)
	assert_int(stats.tick_worst).is_equal(300)


func test_no_frames_give_empty_stats() -> void:
	var stats: FrameStats = FrameStats.from(PackedInt32Array(), PackedInt32Array())
	assert_int(stats.frames).is_equal(0)
	assert_int(stats.worst).is_equal(0)
