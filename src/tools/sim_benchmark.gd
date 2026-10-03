extends SceneTree
## Headless benchmark of a full board game, physics and item effects together: a shipped layout
## with a water wheel, the development loadout (Explosive, Splitter, Onibi, Magnetic, five omamori,
## six purchased pegs) and extra balls in flight. Run with `make bench`; it measures, it does not
## assert.

const PX: int = FixedMath.PX
const LAYOUT: String = "village_01"
const LOADOUT: String = "res://data/debug/dev_loadout.tres"
const BOARDS: int = 60
const EXTRA_BALLS: int = 3
## Two simulation ticks happen in each frame at 60 FPS.
const FRAME_USEC: int = 16_667


func _init() -> void:
	var config: BalanceConfig = BalanceConfig.new()
	var base_pegs: BasePegs = load("res://data/pegs/base_pegs.tres") as BasePegs
	var loadout: LoadoutDefinition = load(LOADOUT) as LoadoutDefinition
	var layout: BoardLayout = LayoutLibrary.load_from().find(LAYOUT)
	var rng: Pcg32 = Pcg32.new(1, 0)
	var total_ticks: int = 0
	var total_usec: int = 0
	var worst_tick_usec: int = 0
	var objects_created_while_stepping: int = 0
	for board: int in BOARDS:
		var game: BoardGame = (
			BoardSetup.create_board(config, base_pegs, layout, board, loadout).game
		)
		while game.can_shoot():
			var aim: int = rng.next_below(2 * config.aim_limit + 1) - config.aim_limit
			game.shoot(ShotInput.new(aim, game.simulation.clock))
			for extra: int in EXTRA_BALLS:
				var vx: int = (rng.next_below(401) - 200) * PX
				game.simulation.spawn_ball(
					config.launcher_x, config.launcher_y, vx, config.launch_speed
				)
			var ticks: int = 0
			while (
				game.simulation.is_shot_active() and ticks < 30 * BoardSimulation.TICKS_PER_SECOND
			):
				var objects_before: int = int(Performance.get_monitor(Performance.OBJECT_COUNT))
				var start: int = Time.get_ticks_usec()
				game.step()
				var elapsed: int = Time.get_ticks_usec() - start
				var created: int = (
					int(Performance.get_monitor(Performance.OBJECT_COUNT)) - objects_before
				)
				objects_created_while_stepping += maxi(0, created)
				game.events.clear()
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
