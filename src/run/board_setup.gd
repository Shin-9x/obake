class_name BoardSetup
## Turns an authored layout into a playable board for a seed.
##
## GDD seeded variation, drawn from the board stream in this order: horizontal mirroring, the
## starting phase of each moving group, then lantern colours. Peg positions are never randomised.


static func create_board(
	config: BalanceConfig,
	base_pegs: BasePegs,
	layout: BoardLayout,
	board_seed: int,
	loadout: LoadoutDefinition = null,
	carry: RunCarry = null,
	rules: BoardRules = null
) -> PlacedBoard:
	var rng: Pcg32 = RngStreams.new(board_seed).stream(RngStreams.Domain.BOARD)
	var placed: PlacedBoard = PlacedBoard.new()
	placed.layout = layout
	placed.mirrored = layout.mirrorable and rng.next_below(2) == 1
	var width: int = config.board_width
	var flip: bool = placed.mirrored
	var simulation: BoardSimulation = BoardSimulation.new(config)
	for peg: LayoutPeg in layout.pegs:
		_add_peg(simulation, peg, -1, flip, width)
	for group: LayoutGroup in layout.groups:
		var index: int = simulation.add_moving_group(
			group.motion,
			width - group.pivot_x if flip else group.pivot_x,
			group.pivot_y,
			-group.travel_x if flip else group.travel_x,
			group.travel_y,
			group.period,
			group.clockwise != flip,
			rng.next_below(group.period)
		)
		for peg: LayoutPeg in group.pegs:
			_add_peg(simulation, peg, index, flip, width)
	placed.game = BoardGame.new(simulation, config, base_pegs, rng, loadout, carry, rules)
	return placed


## Picks one of the library's layouts for [param run_seed] from the map stream.
static func pick_layout(library: LayoutLibrary, run_seed: int) -> BoardLayout:
	var rng: Pcg32 = RngStreams.new(run_seed).stream(RngStreams.Domain.MAP)
	return library.layouts[rng.next_below(library.layouts.size())]


static func _add_peg(
	simulation: BoardSimulation, peg: LayoutPeg, group: int, flip: bool, width: int
) -> void:
	var x: int = width - peg.x if flip else peg.x
	if peg.shape == SimPeg.Shape.ROUND:
		simulation.add_round_peg(x, peg.y, group)
	else:
		var angle: int = -peg.angle if flip else peg.angle
		simulation.add_rect_peg(x, peg.y, peg.half_width, peg.half_height, angle, group)
