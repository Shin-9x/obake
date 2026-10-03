extends GdUnitTestSuite

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const TestLayouts: GDScript = preload("res://tests/run/support/test_layouts.gd")
const PX: int = FixedMath.PX


func test_board_holds_every_layout_peg_in_order() -> void:
	var placed: PlacedBoard = _place(_unmirrored_seed())
	var pegs: Array[SimPeg] = placed.game.simulation.pegs
	assert_int(pegs.size()).is_equal(9)
	assert_int(pegs[0].base_x).is_equal(40 * PX)
	assert_int(pegs[3].shape).is_equal(SimPeg.Shape.RECT)
	assert_int(placed.game.simulation.groups.size()).is_equal(2)
	assert_int(pegs[4].group).is_equal(0)
	assert_int(pegs[8].group).is_equal(1)


func test_mirroring_flips_the_layout_horizontally() -> void:
	var plain: PlacedBoard = _place(_unmirrored_seed())
	var flipped: PlacedBoard = _place(_mirrored_seed())
	assert_bool(plain.mirrored).is_false()
	assert_bool(flipped.mirrored).is_true()
	var width: int = TestBoards.gdd_config().board_width
	var plain_pegs: Array[SimPeg] = plain.game.simulation.pegs
	var flipped_pegs: Array[SimPeg] = flipped.game.simulation.pegs
	for index: int in plain_pegs.size():
		assert_int(flipped_pegs[index].base_x).is_equal(width - plain_pegs[index].base_x)
		assert_int(flipped_pegs[index].base_y).is_equal(plain_pegs[index].base_y)
		assert_int(flipped_pegs[index].base_angle).is_equal(-plain_pegs[index].base_angle)
	var plain_ring: MovingGroup = plain.game.simulation.groups[0]
	var flipped_ring: MovingGroup = flipped.game.simulation.groups[0]
	assert_int(flipped_ring.pivot_x).is_equal(width - plain_ring.pivot_x)
	assert_bool(flipped_ring.clockwise).is_not_equal(plain_ring.clockwise)
	assert_int(flipped.game.simulation.groups[1].travel_x).is_equal(
		-plain.game.simulation.groups[1].travel_x
	)


func test_layouts_that_forbid_mirroring_are_never_flipped() -> void:
	var layout: BoardLayout = TestLayouts.sample()
	layout.mirrorable = false
	for board_seed: int in 20:
		var placed: PlacedBoard = BoardSetup.create_board(
			TestBoards.gdd_config(), TestBoards.gdd_pegs(), layout, board_seed
		)
		assert_bool(placed.mirrored).is_false()


func test_group_phases_and_colours_depend_only_on_the_seed() -> void:
	var a: PlacedBoard = _place(7)
	var b: PlacedBoard = _place(7)
	assert_array(b.game.roles).is_equal(a.game.roles)
	assert_int(b.game.simulation.state_hash()).is_equal(a.game.simulation.state_hash())
	var offsets: Array[int] = []
	for board_seed: int in 10:
		offsets.append(_place(board_seed).game.simulation.groups[0].phase_offset)
	assert_int(offsets.max()).is_greater(offsets.min())


func test_pick_layout_uses_the_seed() -> void:
	var library: LayoutLibrary = LayoutLibrary.new()
	for id: String in ["a", "b", "c"]:
		var layout: BoardLayout = TestLayouts.sample()
		layout.id = id
		library.layouts.append(layout)
	var picked: Array[String] = []
	for run_seed: int in 30:
		picked.append(BoardSetup.pick_layout(library, run_seed).id)
	assert_array(picked).contains(["a", "b", "c"])
	assert_str(BoardSetup.pick_layout(library, 5).id).is_equal(picked[5])


func _place(board_seed: int) -> PlacedBoard:
	return BoardSetup.create_board(
		TestBoards.gdd_config(), TestBoards.gdd_pegs(), TestLayouts.sample(), board_seed
	)


func _mirrored_seed() -> int:
	return _seed_where(true)


func _unmirrored_seed() -> int:
	return _seed_where(false)


func _seed_where(mirrored: bool) -> int:
	for board_seed: int in 100:
		if _place(board_seed).mirrored == mirrored:
			return board_seed
	return -1
