class_name FrameStats
## Summary of a stretch of frames: nearest-rank percentiles of the frame times, the frames that
## missed the 60 FPS budget, and the cost of the simulation ticks. Times are in microseconds.

const BUDGET_USEC: int = 16_667

var frames: int = 0
var p50: int = 0
var p95: int = 0
var p99: int = 0
var worst: int = 0
## Frames longer than one budget, which show as a dropped frame at 60 FPS.
var over_budget: int = 0
## Frames longer than two budgets, which show as a visible hitch.
var over_double_budget: int = 0
var tick_average: int = 0
var tick_worst: int = 0


static func from(frame_usec: PackedInt32Array, tick_usec: PackedInt32Array) -> FrameStats:
	var stats: FrameStats = FrameStats.new()
	stats.frames = frame_usec.size()
	if stats.frames == 0:
		return stats
	var sorted: PackedInt32Array = frame_usec.duplicate()
	sorted.sort()
	stats.p50 = _percentile(sorted, 50)
	stats.p95 = _percentile(sorted, 95)
	stats.p99 = _percentile(sorted, 99)
	stats.worst = sorted[sorted.size() - 1]
	for usec: int in sorted:
		if usec > BUDGET_USEC:
			stats.over_budget += 1
		if usec > 2 * BUDGET_USEC:
			stats.over_double_budget += 1
	var total: int = 0
	for usec: int in tick_usec:
		total += usec
		stats.tick_worst = maxi(stats.tick_worst, usec)
	if not tick_usec.is_empty():
		stats.tick_average = total / tick_usec.size()
	return stats


## The smallest time at or above [param percent] percent of the frames.
static func _percentile(sorted: PackedInt32Array, percent: int) -> int:
	var rank: int = ceili(sorted.size() * percent / 100.0)
	return sorted[clampi(rank - 1, 0, sorted.size() - 1)]
