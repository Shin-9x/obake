extends GdUnitTestSuite
## The shrine screen: removing a ball through the bag picker.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")

var _advanced: bool = false


func test_removing_a_ball_through_the_picker() -> void:
	var run: Run = Screens.run()
	Screens.enter(run, MapNode.Kind.SHRINE)
	var screen: ShrineScreen = auto_free(ShrineScreen.new())
	add_child(screen)
	screen.advanced.connect(func() -> void: _advanced = true)
	screen.open(run)
	Screens.button(screen, "SHRINE_REMOVE").pressed.emit()
	await get_tree().process_frame
	var picker: BagList = Screens.find_all(screen, BagList)[0] as BagList
	picker.ball_picked.emit(0)
	assert_int(run.state.inventory.ball_count()).is_equal(7)
	assert_bool(_advanced).is_true()
