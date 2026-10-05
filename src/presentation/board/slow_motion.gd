class_name SlowMotion
## The GDD's slow-motion zoom: when a single red lantern is left and a ball in flight comes near
## it, the view slows down and closes in until the lantern is hit or the ball moves away. Only the
## view changes; the simulation runs as always.


## The last red lantern when a ball in flight is within [param reach] milli-pixels of it and it is
## still unlit; otherwise -1.
static func target(game: BoardGame, reach: int) -> int:
	var last: int = -1
	for peg: int in game.roles.size():
		if game.roles[peg] != BoardGame.Role.RED or game.simulation.pegs[peg].removed:
			continue
		if last >= 0:
			return -1
		last = peg
	if last < 0 or game.simulation.pegs[last].lit:
		return -1
	var red: SimPeg = game.simulation.pegs[last]
	for ball: SimBall in game.simulation.balls:
		if not ball.active:
			continue
		var dx: int = ball.x - red.x
		var dy: int = ball.y - red.y
		if dx * dx + dy * dy <= reach * reach:
			return last
	return -1
