@tool
class_name LayoutChecks
## Geometry checks for authored layouts: pegs inside the board and above the bucket, no
## overlaps, rectangles thick enough for the ball's top speed, and moving pegs that never run
## into another peg anywhere along their motion.
##
## Positions come from a real [BoardSimulation], so they are exactly the ones the game uses.

## Board clock samples taken over the longest group period.
const MOTION_SAMPLES: int = 48
## Thinnest allowed half-extent of a rectangle; see [member BalanceConfig.max_speed].
const MIN_HALF_EXTENT: int = FixedMath.PX


static func find_problems(layout: BoardLayout, config: BalanceConfig) -> Array[String]:
	var problems: Array[String] = []
	var simulation: BoardSimulation = BoardSimulation.new(config)
	var longest_period: int = 1
	for peg: LayoutPeg in layout.pegs:
		_add(simulation, peg, -1)
	for group: LayoutGroup in layout.groups:
		var index: int = simulation.add_moving_group(
			group.motion,
			group.pivot_x,
			group.pivot_y,
			group.travel_x,
			group.travel_y,
			group.period,
			group.clockwise,
			0
		)
		longest_period = maxi(longest_period, group.period)
		for peg: LayoutPeg in group.pegs:
			_add(simulation, peg, index)
	var pegs: Array[SimPeg] = simulation.pegs
	for peg: SimPeg in pegs:
		if (
			peg.shape == SimPeg.Shape.RECT
			and mini(peg.half_width, peg.half_height) < MIN_HALF_EXTENT
		):
			_report(problems, "rectangle at %s is thinner than 2 px" % _where(peg))
	var samples: int = MOTION_SAMPLES if not layout.groups.is_empty() else 1
	var stride: int = maxi(1, longest_period / MOTION_SAMPLES)
	for sample: int in samples:
		for peg: SimPeg in pegs:
			_check_bounds(peg, config, problems)
		for a: int in pegs.size():
			for b: int in range(a + 1, pegs.size()):
				# Static pairs, and pegs of one rigid group, only need checking once.
				var rigid: bool = pegs[a].group == pegs[b].group
				if sample > 0 and rigid:
					continue
				if overlap(pegs[a], pegs[b]):
					_report(
						problems, "pegs at %s and %s overlap" % [_where(pegs[a]), _where(pegs[b])]
					)
		for i: int in stride:
			simulation.idle_step()
	return problems


## True when two pegs intersect. Exact for circles; rectangles are probed at their centre,
## corners and edge midpoints, which is enough for authored layouts.
static func overlap(a: SimPeg, b: SimPeg) -> bool:
	if a.shape == SimPeg.Shape.ROUND and b.shape == SimPeg.Shape.ROUND:
		var reach: int = a.radius + b.radius
		var dx: int = a.x - b.x
		var dy: int = a.y - b.y
		return dx * dx + dy * dy < reach * reach
	var contact: Contact = Contact.new()
	if a.shape == SimPeg.Shape.ROUND:
		return Collision.circle_vs_box(a.x, a.y, a.radius, b, contact)
	if b.shape == SimPeg.Shape.ROUND:
		return Collision.circle_vs_box(b.x, b.y, b.radius, a, contact)
	return _probes_inside(a, b, contact) or _probes_inside(b, a, contact)


static func _probes_inside(probed: SimPeg, box: SimPeg, contact: Contact) -> bool:
	for step_x: int in [-1, 0, 1]:
		for step_y: int in [-1, 0, 1]:
			var local_x: int = step_x * probed.half_width
			var local_y: int = step_y * probed.half_height
			var x: int = (
				probed.x
				+ FixedMath.div_round(
					local_x * probed.cos_angle - local_y * probed.sin_angle, FixedMath.UNIT
				)
			)
			var y: int = (
				probed.y
				+ FixedMath.div_round(
					local_x * probed.sin_angle + local_y * probed.cos_angle, FixedMath.UNIT
				)
			)
			if Collision.circle_vs_box(x, y, 1, box, contact):
				return true
	return false


static func _check_bounds(peg: SimPeg, config: BalanceConfig, problems: Array[String]) -> void:
	var reach: int = peg.extent
	var bottom: int = config.bucket_y - config.bucket_rim_radius
	if peg.x - reach < 0 or peg.x + reach > config.board_width or peg.y - reach < 0:
		_report(problems, "peg at %s leaves the board" % _where(peg))
	elif peg.y + reach > bottom:
		_report(problems, "peg at %s reaches into the bucket lane" % _where(peg))


static func _add(simulation: BoardSimulation, peg: LayoutPeg, group: int) -> void:
	if peg.shape == SimPeg.Shape.ROUND:
		simulation.add_round_peg(peg.x, peg.y, group)
	else:
		simulation.add_rect_peg(peg.x, peg.y, peg.half_width, peg.half_height, peg.angle, group)


## Position at phase zero, in pixels, so authors can find the peg in the editor.
static func _where(peg: SimPeg) -> String:
	return "(%d, %d)" % [roundi(peg.base_x / 1000.0), roundi(peg.base_y / 1000.0)]


static func _report(problems: Array[String], problem: String) -> void:
	if not problems.has(problem):
		problems.append(problem)
