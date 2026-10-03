extends SceneTree
## Headless benchmark of the board simulation on a shipped layout with a water wheel, with four
## balls in flight per shot. Run with `make bench`; it measures, it does not assert.

const PX: int = FixedMath.PX
const LAYOUT: String = "village_01"
const BOARDS: int = 50
const SHOTS_PER_BOARD: int = 8
const EXTRA_BALLS: int = 3
## Two simulation ticks happen in each frame at 60 FPS.
const FRAME_USEC: int = 16_667


func _init() -> void:
	var config: BalanceConfig = BalanceConfig.new()
	var base_pegs: BasePegs = load("res://data/pegs/base_pegs.tres") as BasePegs
	var layout: BoardLayout = LayoutLibrary.load_from().find(LAYOUT)
	var rng: Pcg32 = Pcg32.new(1, 0)
	var total_ticks: int = 0
	var total_usec: int = 0
	var worst_tick_usec: int = 0
	var objects_before: int = 0
	var objects_created_while_stepping: int = 0
	for board: int in BOARDS:
		var sim: BoardSimulation = (
			BoardSetup.create_board(config, base_pegs, layout, board).game.simulation
		)
		for shot: int in SHOTS_PER_BOARD:
			var aim: int = rng.next_below(2 * config.aim_limit + 1) - config.aim_limit
			sim.launch(ShotInput.new(aim))
			for extra: int in EXTRA_BALLS:
				var vx: int = (rng.next_below(401) - 200) * PX
				sim.spawn_ball(config.launcher_x, config.launcher_y, vx, config.launch_speed)
			var ticks: int = 0
			while sim.is_shot_active() and ticks < 30 * BoardSimulation.TICKS_PER_SECOND:
				objects_before = int(Performance.get_monitor(Performance.OBJECT_COUNT))
				var start: int = Time.get_ticks_usec()
				sim.step()
				var elapsed: int = Time.get_ticks_usec() - start
				objects_created_while_stepping += maxi(
					0, int(Performance.get_monitor(Performance.OBJECT_COUNT)) - objects_before
				)
				sim.events.clear()
				total_usec += elapsed
				worst_tick_usec = maxi(worst_tick_usec, elapsed)
				ticks += 1
			total_ticks += ticks
	var average: float = float(total_usec) / maxi(total_ticks, 1)
	print("Simulated ticks:         %d (%.1f s of play)" % [total_ticks, total_ticks / 120.0])
	print("Average per tick:        %.1f us" % average)
	print("Worst tick:              %d us" % worst_tick_usec)
	print("Ticks per second:        %d" % int(1_000_000.0 / maxf(average, 0.001)))
	print("Share of a 60 FPS frame: %.2f %%" % (200.0 * average / FRAME_USEC))
	print("Objects created in step: %d" % objects_created_while_stepping)
	quit()
