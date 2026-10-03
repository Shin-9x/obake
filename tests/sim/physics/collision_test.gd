extends GdUnitTestSuite

const UNIT: int = FixedMath.UNIT
## Rounding tolerance for normals that are not axis-aligned, in millionths.
const NORMAL_TOLERANCE: int = 2

var _contact: Contact


func before_test() -> void:
	_contact = Contact.new()


func test_circles_overlapping_vertically() -> void:
	assert_bool(Collision.circle_vs_circle(0, -8000, 4000, 0, 0, 5000, _contact)).is_true()
	_assert_contact(0, -UNIT, 1000)


func test_circles_overlapping_diagonally() -> void:
	assert_bool(Collision.circle_vs_circle(3000, 4000, 4000, 0, 0, 5000, _contact)).is_true()
	_assert_contact(600_000, 800_000, 4000)


func test_touching_circles_do_not_collide() -> void:
	assert_bool(Collision.circle_vs_circle(0, -9000, 4000, 0, 0, 5000, _contact)).is_false()


func test_concentric_circles_push_up() -> void:
	assert_bool(Collision.circle_vs_circle(10, 10, 4000, 10, 10, 5000, _contact)).is_true()
	_assert_contact(0, -UNIT, 9000)


func test_wall_pushes_towards_playable_side() -> void:
	var top: SimWall = SimWall.new(0, 0, 360_000, 0)
	assert_bool(Collision.circle_vs_wall(100_000, 3000, 4000, top, _contact)).is_true()
	_assert_contact(0, UNIT, 1000)


func test_wall_pushes_back_a_ball_whose_centre_crossed_it() -> void:
	var top: SimWall = SimWall.new(0, 0, 360_000, 0)
	assert_bool(Collision.circle_vs_wall(100_000, -1000, 4000, top, _contact)).is_true()
	_assert_contact(0, UNIT, 5000)


func test_wall_ignores_balls_far_behind_it() -> void:
	var top: SimWall = SimWall.new(0, 0, 360_000, 0)
	assert_bool(Collision.circle_vs_wall(100_000, -5000, 4000, top, _contact)).is_false()
	assert_bool(Collision.circle_vs_wall(100_000, 4000, 4000, top, _contact)).is_false()


func test_wall_endpoint_acts_as_a_point() -> void:
	var short: SimWall = SimWall.new(0, 0, 100_000, 0)
	assert_bool(Collision.circle_vs_wall(102_000, 2000, 4000, short, _contact)).is_true()
	_assert_contact(707_107, 707_107, 4000 - 2828)


func test_box_face_contact() -> void:
	var peg: SimPeg = SimPeg.create_rect(0, 0, 10_000, 2000, 0)
	assert_bool(Collision.circle_vs_box(0, -5000, 4000, peg, _contact)).is_true()
	_assert_contact(0, -UNIT, 1000)


func test_rotated_box_face_contact() -> void:
	var peg: SimPeg = SimPeg.create_rect(0, 0, 10_000, 2000, 9000)
	assert_bool(Collision.circle_vs_box(5000, 0, 4000, peg, _contact)).is_true()
	_assert_contact(UNIT, 0, 1000)


func test_box_corner_contact() -> void:
	var peg: SimPeg = SimPeg.create_rect(0, 0, 10_000, 2000, 0)
	assert_bool(Collision.circle_vs_box(12_000, 3000, 4000, peg, _contact)).is_true()
	_assert_contact(894_427, 447_214, 4000 - 2236)


func test_box_with_centre_inside_leaves_through_nearest_face() -> void:
	var peg: SimPeg = SimPeg.create_rect(0, 0, 10_000, 2000, 0)
	assert_bool(Collision.circle_vs_box(8000, 500, 4000, peg, _contact)).is_true()
	_assert_contact(0, UNIT, 5500)


func test_box_out_of_reach() -> void:
	var peg: SimPeg = SimPeg.create_rect(0, 0, 10_000, 2000, 0)
	assert_bool(Collision.circle_vs_box(0, -6000, 4000, peg, _contact)).is_false()


func test_rotated_box_bounds_contain_its_corners() -> void:
	var peg: SimPeg = SimPeg.create_rect(50_000, 50_000, 12_000, 3000, 3000)
	# Half-diagonal of a 24x6 px box: every corner lies within this radius of the centre.
	var half_diagonal: int = FixedMath.length(12_000, 3000)
	assert_int(peg.max_x - peg.min_x).is_less_equal(2 * half_diagonal + 2)
	for corner: Vector2i in [Vector2i(12_000, 3000), Vector2i(-12_000, 3000)]:
		for flip: int in [1, -1]:
			var lx: int = corner.x * flip
			var ly: int = corner.y * flip
			var wx: int = 50_000 + (lx * peg.cos_angle - ly * peg.sin_angle) / UNIT
			var wy: int = 50_000 + (lx * peg.sin_angle + ly * peg.cos_angle) / UNIT
			assert_int(wx).is_between(peg.min_x, peg.max_x)
			assert_int(wy).is_between(peg.min_y, peg.max_y)


func _assert_contact(nx: int, ny: int, depth: int) -> void:
	assert_int(_contact.nx).is_between(nx - NORMAL_TOLERANCE, nx + NORMAL_TOLERANCE)
	assert_int(_contact.ny).is_between(ny - NORMAL_TOLERANCE, ny + NORMAL_TOLERANCE)
	assert_int(_contact.depth).is_between(depth - 1, depth + 1)
