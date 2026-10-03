class_name BoardSetup
## Builds the boards of a run.
##
## Until layouts are authored as JSON (M3) every board uses one hardcoded placeholder layout.
## Positions are computed with integer trigonometry so they match on every platform.

const _PX: int = FixedMath.PX


static func create_placeholder_board(
	config: BalanceConfig, base_pegs: BasePegs, run_seed: int
) -> BoardGame:
	var simulation: BoardSimulation = BoardSimulation.new(config)
	_add_placeholder_layout(simulation)
	var streams: RngStreams = RngStreams.new(run_seed)
	return BoardGame.new(simulation, config, base_pegs, streams.stream(RngStreams.Domain.BOARD))


## About 65 pegs on a 360 px board: an arc under the launcher, two side columns, a staggered
## field, a bottom row and four bars.
static func _add_placeholder_layout(simulation: BoardSimulation) -> void:
	# Arc of 11 pegs, centred on the launcher, from 35 to 145 degrees.
	for step: int in 11:
		var angle: int = 3500 + step * 1100
		var x: int = 180 * _PX + FixedMath.div_round(120 * _PX * Trig.cos_cd(angle), FixedMath.UNIT)
		var y: int = FixedMath.div_round(120 * _PX * Trig.sin_cd(angle), FixedMath.UNIT)
		simulation.add_round_peg(x, y)
	for row: int in 4:
		simulation.add_round_peg(30 * _PX, (60 + row * 20) * _PX)
		simulation.add_round_peg(330 * _PX, (60 + row * 20) * _PX)
	for row: int in 5:
		var first: int = 40 if row % 2 == 0 else 60
		var last: int = 320 if row % 2 == 0 else 300
		for x: int in range(first, last + 1, 40):
			simulation.add_round_peg(x * _PX, (160 + row * 30) * _PX)
	for x: int in [40, 140, 220, 320]:
		simulation.add_round_peg(x * _PX, 310 * _PX)
	simulation.add_rect_peg(100 * _PX, 135 * _PX, 12 * _PX, 3 * _PX, 2000)
	simulation.add_rect_peg(260 * _PX, 135 * _PX, 12 * _PX, 3 * _PX, -2000)
	simulation.add_rect_peg(90 * _PX, 330 * _PX, 14 * _PX, 2 * _PX, 2500)
	simulation.add_rect_peg(270 * _PX, 330 * _PX, 14 * _PX, 2 * _PX, -2500)
