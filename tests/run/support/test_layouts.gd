extends RefCounted
## Small layouts built in code for run-logic tests.

const PX: int = FixedMath.PX


## Four static pegs, a rotating ring of four pegs and a sliding bar; not symmetric, so mirroring
## is visible.
static func sample() -> BoardLayout:
	var layout: BoardLayout = BoardLayout.new()
	layout.id = "sample"
	layout.biome = "test"
	layout.pegs = [
		LayoutPeg.round_at(40 * PX, 60 * PX),
		LayoutPeg.round_at(100 * PX, 60 * PX),
		LayoutPeg.round_at(300 * PX, 300 * PX),
		LayoutPeg.rect_at(70 * PX, 120 * PX, 12 * PX, 3 * PX, 2000),
	]
	var ring: LayoutGroup = LayoutGroup.new()
	ring.motion = MovingGroup.Motion.ROTATE
	ring.pivot_x = 200 * PX
	ring.pivot_y = 200 * PX
	ring.period = 720
	ring.clockwise = true
	for spoke: int in 4:
		var angle: int = spoke * 9000
		var x: int = 200 * PX + FixedMath.div_round(30 * PX * Trig.cos_cd(angle), FixedMath.UNIT)
		var y: int = 200 * PX + FixedMath.div_round(30 * PX * Trig.sin_cd(angle), FixedMath.UNIT)
		ring.pegs.append(LayoutPeg.round_at(x, y))
	var slide: LayoutGroup = LayoutGroup.new()
	slide.motion = MovingGroup.Motion.OSCILLATE
	slide.travel_x = 30 * PX
	slide.period = 480
	slide.pegs.append(LayoutPeg.rect_at(120 * PX, 280 * PX, 2 * PX, 10 * PX, 0))
	layout.groups = [ring, slide]
	return layout
