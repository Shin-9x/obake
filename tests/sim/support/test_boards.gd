extends RefCounted
## Configuration and boards shared by the simulation tests.

const PX: int = FixedMath.PX
## Safety net for shots that never resolve; about 30 seconds of simulated time.
const MAX_SHOT_TICKS: int = 3600


## The GDD starting values, spelled out so that tuning data/balance.tres never changes the
## results of simulation tests.
static func gdd_config() -> BalanceConfig:
	var result: BalanceConfig = BalanceConfig.new()
	result.board_width = 360 * PX
	result.board_height = 360 * PX
	result.ball_radius = 4 * PX
	result.gravity = 300 * PX
	result.launch_speed = 280 * PX
	result.max_speed = 600 * PX
	result.wall_restitution = 900
	result.peg_radius = 5 * PX
	result.peg_restitution = 800
	result.launcher_x = 180 * PX
	result.launcher_y = 12 * PX
	result.aim_limit = 8500
	return result


## About 65 pegs: staggered rows of round pegs plus four rotated rectangles.
static func add_staggered_pegs(sim: BoardSimulation) -> void:
	for row: int in 7:
		var offset: int = 0 if row % 2 == 0 else 20
		for column: int in 9:
			var x: int = 20 + offset + column * 40
			if x < 350:
				sim.add_round_peg(x * PX, (90 + row * 32) * PX)
	sim.add_rect_peg(90 * PX, 66 * PX, 12 * PX, 3 * PX, 3000)
	sim.add_rect_peg(270 * PX, 66 * PX, 12 * PX, 3 * PX, -3000)
	sim.add_rect_peg(120 * PX, 316 * PX, 16 * PX, 2 * PX, 0)
	sim.add_rect_peg(240 * PX, 316 * PX, 16 * PX, 2 * PX, 4500)


## Launches a shot and steps until it resolves. Returns the number of ticks simulated.
static func run_shot(sim: BoardSimulation, aim: int) -> int:
	if not sim.launch(ShotInput.new(aim)):
		return 0
	var ticks: int = 0
	while sim.is_shot_active() and ticks < MAX_SHOT_TICKS:
		sim.step()
		ticks += 1
	return ticks
