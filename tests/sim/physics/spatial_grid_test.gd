extends GdUnitTestSuite

const PX: int = FixedMath.PX

var _grid: SpatialGrid


func before_test() -> void:
	_grid = SpatialGrid.new(360 * PX, 360 * PX)
	_insert_box(0, 50 * PX, 50 * PX, 5 * PX)
	_insert_box(1, 300 * PX, 300 * PX, 5 * PX)
	# Large enough to span several cells.
	_insert_box(2, 180 * PX, 180 * PX, 45 * PX)


func test_query_finds_nearby_pegs_only() -> void:
	_grid.query(46 * PX, 46 * PX, 54 * PX, 54 * PX)
	assert_array(_results()).contains_exactly([0])


func test_peg_spanning_many_cells_is_reported_once() -> void:
	_grid.query(130 * PX, 130 * PX, 230 * PX, 230 * PX)
	assert_array(_results()).contains_exactly([2])


func test_removed_pegs_are_skipped() -> void:
	_grid.remove(1)
	_grid.query(290 * PX, 290 * PX, 310 * PX, 310 * PX)
	assert_array(_results()).is_empty()


func test_queries_outside_the_board_are_clamped() -> void:
	_grid.query(-50 * PX, -50 * PX, 60 * PX, 60 * PX)
	assert_array(_results()).contains_exactly([0])


func test_candidate_order_is_stable() -> void:
	_grid.query(0, 0, 360 * PX, 360 * PX)
	var first: Array[int] = _results()
	_grid.query(0, 0, 360 * PX, 360 * PX)
	assert_array(_results()).is_equal(first)
	assert_array(first).contains_exactly_in_any_order([0, 1, 2])


func _insert_box(index: int, x: int, y: int, extent: int) -> void:
	_grid.insert(index, x - extent, y - extent, x + extent, y + extent)


func _results() -> Array[int]:
	var found: Array[int] = []
	for i: int in _grid.result_count:
		found.append(_grid.results[i])
	return found
