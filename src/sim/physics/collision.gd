@tool
class_name Collision
## Narrow-phase tests between a ball (a circle) and the board's obstacles.
##
## Each test returns true on overlap and writes into [param out] the unit normal that pushes the
## ball out and the penetration depth. Touching without overlap is not a contact.

const _UNIT: int = FixedMath.UNIT
## Extra resolution for distances used to build normals; a whole milli-pixel is too coarse.
const _FINE: int = 1000


static func circle_vs_circle(
	cx: int, cy: int, radius: int, other_x: int, other_y: int, other_radius: int, out: Contact
) -> bool:
	var dx: int = cx - other_x
	var dy: int = cy - other_y
	var reach: int = radius + other_radius
	var distance_squared: int = dx * dx + dy * dy
	if distance_squared >= reach * reach:
		return false
	_push_away(dx, dy, distance_squared, reach, out)
	return true


static func circle_vs_wall(cx: int, cy: int, radius: int, wall: SimWall, out: Contact) -> bool:
	var rx: int = cx - wall.ax
	var ry: int = cy - wall.ay
	var along: int = rx * (wall.bx - wall.ax) + ry * (wall.by - wall.ay)
	if along <= 0:
		return circle_vs_circle(cx, cy, radius, wall.ax, wall.ay, 0, out)
	if along >= wall.length_squared:
		return circle_vs_circle(cx, cy, radius, wall.bx, wall.by, 0, out)
	var signed_distance: int = FixedMath.div_round(rx * wall.nx + ry * wall.ny, _UNIT)
	if signed_distance >= radius or signed_distance <= -radius:
		return false
	out.set_normal(wall.nx, wall.ny, radius - signed_distance)
	return true


## Circle against a rotated rectangular peg, solved in the rectangle's local frame.
static func circle_vs_box(cx: int, cy: int, radius: int, peg: SimPeg, out: Contact) -> bool:
	var dx: int = cx - peg.x
	var dy: int = cy - peg.y
	var cos_a: int = peg.cos_angle
	var sin_a: int = peg.sin_angle
	var local_x: int = FixedMath.div_round(dx * cos_a + dy * sin_a, _UNIT)
	var local_y: int = FixedMath.div_round(dy * cos_a - dx * sin_a, _UNIT)
	var half_w: int = peg.half_width
	var half_h: int = peg.half_height
	var normal_x: int = 0
	var normal_y: int = 0
	var depth: int = 0
	if absi(local_x) <= half_w and absi(local_y) <= half_h:
		# Centre inside: leave through the nearest face.
		var gap_x: int = half_w - absi(local_x)
		var gap_y: int = half_h - absi(local_y)
		if gap_x < gap_y:
			normal_x = _UNIT if local_x >= 0 else -_UNIT
			depth = radius + gap_x
		else:
			normal_y = _UNIT if local_y > 0 else -_UNIT
			depth = radius + gap_y
	else:
		var outside_x: int = local_x - clampi(local_x, -half_w, half_w)
		var outside_y: int = local_y - clampi(local_y, -half_h, half_h)
		var distance_squared: int = outside_x * outside_x + outside_y * outside_y
		if distance_squared >= radius * radius:
			return false
		_push_away(outside_x, outside_y, distance_squared, radius, out)
		normal_x = out.nx
		normal_y = out.ny
		depth = out.depth
	out.set_normal(
		FixedMath.div_round(normal_x * cos_a - normal_y * sin_a, _UNIT),
		FixedMath.div_round(normal_x * sin_a + normal_y * cos_a, _UNIT),
		depth
	)
	return true


## Writes the unit normal from the obstacle point to the ball and the overlap left to [param reach].
## [param distance_squared] is below reach squared, so the scaled square stays far from 2^63.
static func _push_away(dx: int, dy: int, distance_squared: int, reach: int, out: Contact) -> void:
	var fine_distance: int = FixedMath.isqrt(distance_squared * _FINE * _FINE)
	if fine_distance == 0:
		# Concentric: push straight up, a fixed choice that keeps the result deterministic.
		out.set_normal(0, -_UNIT, reach)
		return
	out.set_normal(
		FixedMath.div_round(dx * _UNIT * _FINE, fine_distance),
		FixedMath.div_round(dy * _UNIT * _FINE, fine_distance),
		reach - FixedMath.div_round(fine_distance, _FINE)
	)
