extends GdUnitTestSuite

const PX: int = FixedMath.PX


func test_poses_compose_through_parents() -> void:
	var document: LayoutDocument = auto_free(LayoutDocument.new())
	var group: MovingGroupMarker = MovingGroupMarker.new()
	group.position = Vector2(100, 50)
	group.rotation_degrees = 90
	document.add_child(group)
	var peg: PegMarker = PegMarker.new()
	peg.position = Vector2(20, 0)
	group.add_child(peg)
	# Turned a quarter clockwise, (20, 0) lands 20 px below the group.
	assert_that(peg.document_pose()).is_equal(Vector3i(100 * PX, 70 * PX, 9000))


func test_zones_and_kind_are_exported() -> void:
	var document: LayoutDocument = auto_free(LayoutDocument.new())
	document.kind = BoardLayout.Kind.BOSS
	var group: Node2D = Node2D.new()
	document.add_child(group)
	var zone: ZoneMarker = ZoneMarker.new()
	zone.position = Vector2(120, 80)
	zone.radius = 25.0
	group.add_child(zone)
	var peg: PegMarker = PegMarker.new()
	document.add_child(peg)
	var layout: BoardLayout = document.build_layout()
	assert_int(layout.kind).is_equal(BoardLayout.Kind.BOSS)
	assert_int(layout.zones.size()).is_equal(1)
	assert_int(layout.zones[0].x).is_equal(120 * PX)
	assert_int(layout.zones[0].radius).is_equal(25 * PX)


func test_grid_is_centred_and_symmetric() -> void:
	var grid: GridPattern = auto_free(GridPattern.new())
	grid.columns = 4
	grid.rows = 3
	grid.spacing = Vector2(40, 30)
	grid.staggered = true
	var points: Array[Vector3i] = grid.local_points()
	assert_array(points).has_size(4 + 3 + 4)
	var sum: Vector2i = Vector2i.ZERO
	for point: Vector3i in points:
		sum += Vector2i(point.x, point.y)
	assert_that(sum).is_equal(Vector2i.ZERO)
	assert_that(points[0]).is_equal(Vector3i(-60 * PX, -30 * PX, 0))


func test_arc_endpoints_and_tangent_rectangles() -> void:
	var arc: ArcPattern = auto_free(ArcPattern.new())
	arc.radius = 50
	arc.from_degrees = 0
	arc.to_degrees = 90
	arc.count = 3
	var points: Array[Vector3i] = arc.local_points()
	assert_that(points[0]).is_equal(Vector3i(50 * PX, 0, 9000))
	assert_that(points[2]).is_equal(Vector3i(0, 50 * PX, 18000))


func test_baked_markers_reproduce_the_pattern() -> void:
	var document: LayoutDocument = auto_free(LayoutDocument.new())
	document.id = "bake"
	var circle: CirclePattern = CirclePattern.new()
	circle.position = Vector2(180, 150)
	circle.radius = 40
	circle.count = 6
	document.add_child(circle)
	circle.owner = document
	var before: Array[LayoutPeg] = document.build_layout().pegs
	circle.bake()
	document.remove_child(circle)
	circle.free()
	var after: Array[LayoutPeg] = document.build_layout().pegs
	assert_array(after).has_size(before.size())
	for index: int in before.size():
		assert_int(after[index].x).is_between(before[index].x - 1, before[index].x + 1)
		assert_int(after[index].y).is_between(before[index].y - 1, before[index].y + 1)


func test_oscillation_travel_follows_the_group_rotation() -> void:
	var document: LayoutDocument = auto_free(LayoutDocument.new())
	var group: MovingGroupMarker = MovingGroupMarker.new()
	group.motion = MovingGroup.Motion.OSCILLATE
	group.travel = Vector2(30, 0)
	group.period_seconds = 2.0
	group.rotation_degrees = 90
	document.add_child(group)
	var peg: PegMarker = PegMarker.new()
	group.add_child(peg)
	var built: LayoutGroup = group.build_group()
	assert_int(built.period).is_equal(240)
	assert_int(built.travel_x).is_equal(0)
	assert_int(built.travel_y).is_equal(30 * PX)
	assert_array(built.pegs).has_size(1)
