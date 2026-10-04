extends GdUnitTestSuite
## Zones: which points they hold and the drag they put on balls.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const PX: int = FixedMath.PX


func test_a_zone_holds_points_up_to_its_radius() -> void:
	var zone: SimZone = SimZone.new(100 * PX, 100 * PX, 10 * PX)
	assert_bool(zone.contains(110 * PX, 100 * PX)).is_true()
	assert_bool(zone.contains(108 * PX, 108 * PX)).is_false()


func test_zone_at_finds_the_first_zone_around_a_point() -> void:
	var simulation: BoardSimulation = BoardSimulation.new(TestBoards.gdd_config())
	simulation.add_zone(100 * PX, 100 * PX, 20 * PX)
	simulation.add_zone(110 * PX, 100 * PX, 20 * PX)
	assert_int(simulation.zone_at(115 * PX, 100 * PX)).is_equal(0)
	assert_int(simulation.zone_at(125 * PX, 100 * PX)).is_equal(1)
	assert_int(simulation.zone_at(300 * PX, 300 * PX)).is_equal(-1)


func test_drag_slows_a_ball_inside_the_zone() -> void:
	var speeds: Array[int] = []
	for drag: int in [0, 20]:
		var simulation: BoardSimulation = _board_with_zone(drag)
		simulation.launch(ShotInput.new(0, simulation.bucket.period() / 4))
		for i: int in 60:
			simulation.step()
		speeds.append(simulation.balls[0].vy)
	assert_int(speeds[1]).is_less(speeds[0] / 2)


func test_the_prediction_feels_the_drag_too() -> void:
	var points: PackedInt32Array = PackedInt32Array()
	points.resize(2 * 200)
	var lengths: Array[int] = []
	for drag: int in [0, 20]:
		lengths.append(_board_with_zone(drag).predict_path(0, 4, points))
	assert_int(lengths[1]).is_greater(lengths[0])


func _board_with_zone(drag: int) -> BoardSimulation:
	var config: BalanceConfig = TestBoards.gdd_config()
	TestBoards.freeze_bucket(config)
	var simulation: BoardSimulation = BoardSimulation.new(config)
	var zone: int = simulation.add_zone(180 * PX, 150 * PX, 100 * PX)
	simulation.zones[zone].drag = drag
	return simulation
