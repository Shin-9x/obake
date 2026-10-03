extends RefCounted
## Configuration, lantern definitions and boards shared by the simulation tests.

const PX: int = FixedMath.PX
## Safety net for shots that never resolve; about 30 seconds of simulated time.
const MAX_SHOT_TICKS: int = 3600


## The GDD starting values, spelled out so that tuning data/ never changes test results.
static func gdd_config() -> BalanceConfig:
	var result: BalanceConfig = BalanceConfig.new()
	result.board_width = 360 * PX
	result.board_height = 360 * PX
	result.shots_per_board = 8
	result.first_board_target = 800
	result.matsuri_total_factor = 2000
	result.red_permille = 220
	result.green_count = 2
	result.colour_zone_columns = 3
	result.colour_zone_rows = 3
	result.ball_radius = 4 * PX
	result.gravity = 300 * PX
	result.launch_speed = 280 * PX
	result.max_speed = 600 * PX
	result.wall_restitution = 900
	result.stuck_speed = 20 * PX
	result.stuck_ticks = 240
	result.peg_radius = 5 * PX
	result.peg_restitution = 800
	result.head_on_tolerance = 5 * PX
	result.head_on_nudge = 50
	result.bucket_width = 40 * PX
	result.bucket_y = 350 * PX
	result.bucket_rim_radius = 3 * PX
	result.bucket_period = 480
	result.launcher_x = 180 * PX
	result.launcher_y = 12 * PX
	result.aim_limit = 8500
	return result


## Slows the bucket to a crawl so it stays where a test puts it.
static func freeze_bucket(config: BalanceConfig) -> void:
	config.bucket_period = 4_000_000


## Phase that holds a frozen bucket against the right wall, away from the launcher.
static func bucket_right(config: BalanceConfig) -> int:
	return config.bucket_period / 4


## The four GDD lanterns: blue +10 points, red +1 mult, green +10 points, gold x2 mult.
static func gdd_pegs() -> BasePegs:
	var pegs: BasePegs = BasePegs.new()
	pegs.blue = _definition(&"blue_lantern", 10, 0, 1000)
	pegs.red = _definition(&"red_lantern", 0, 1000, 1000)
	pegs.green = _definition(&"green_lantern", 10, 0, 1000)
	pegs.gold = _definition(&"gold_lantern", 0, 0, 2000)
	return pegs


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


## A water wheel of eight pegs and two sliding rows of bamboo stalks, plus a few static pegs.
static func add_moving_pegs(sim: BoardSimulation) -> void:
	var wheel: int = sim.add_moving_group(
		MovingGroup.Motion.ROTATE, 180 * PX, 200 * PX, 0, 0, 720, true, 0
	)
	for spoke: int in 8:
		var angle: int = spoke * 4500
		var x: int = 180 * PX + FixedMath.div_round(40 * PX * Trig.cos_cd(angle), FixedMath.UNIT)
		var y: int = 200 * PX + FixedMath.div_round(40 * PX * Trig.sin_cd(angle), FixedMath.UNIT)
		sim.add_round_peg(x, y, wheel)
	sim.add_rect_peg(180 * PX, 200 * PX, 12 * PX, 3 * PX, 0, wheel)
	for row: int in 2:
		var slide: int = sim.add_moving_group(
			MovingGroup.Motion.OSCILLATE, 0, 0, 30 * PX, 0, 480, row == 0, row * 120
		)
		for stalk: int in 4:
			var x: int = (90 + stalk * 60) * PX
			sim.add_rect_peg(x, (100 + row * 180) * PX, 2 * PX, 10 * PX, 0, slide)
	for x: int in [40, 320]:
		sim.add_round_peg(x * PX, 150 * PX)
		sim.add_round_peg(x * PX, 250 * PX)


static func staggered_game(board_seed: int, loadout: LoadoutDefinition = null) -> BoardGame:
	var config: BalanceConfig = gdd_config()
	var sim: BoardSimulation = BoardSimulation.new(config)
	add_staggered_pegs(sim)
	var rng: Pcg32 = Pcg32.new(board_seed, RngStreams.Domain.BOARD)
	return BoardGame.new(sim, config, gdd_pegs(), rng, loadout)


## Launches a shot and steps until it resolves. Returns the number of ticks simulated.
static func run_shot(sim: BoardSimulation, aim: int, board_clock: int = 0) -> int:
	if not sim.launch(ShotInput.new(aim, board_clock)):
		return 0
	var ticks: int = 0
	while sim.is_shot_active() and ticks < MAX_SHOT_TICKS:
		sim.step()
		ticks += 1
	return ticks


## Plays one shot of a board game to the end. Returns false if it could not be fired.
static func play_shot(game: BoardGame, aim: int, board_clock: int = 0) -> bool:
	if not game.shoot(ShotInput.new(aim, board_clock)):
		return false
	var ticks: int = 0
	while game.simulation.is_shot_active() and ticks < MAX_SHOT_TICKS:
		game.step()
		ticks += 1
	return true


static func _definition(id: StringName, points: int, mult_add: int, factor: int) -> PegDefinition:
	var definition: PegDefinition = PegDefinition.new()
	definition.id = id
	definition.points = points
	definition.mult_add = mult_add
	definition.mult_factor = factor
	return definition
