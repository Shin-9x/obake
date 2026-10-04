extends GdUnitTestSuite
## The event screen: an option that asks for a ball, then the outcome and continuing.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")

var _advanced: bool = false


func test_an_option_with_a_pick_then_the_outcome() -> void:
	var run: Run = Screens.run("tanuki")
	Screens.enter(run, MapNode.Kind.EVENT)
	run.event = RunEvent.create(load("res://data/events/hot_spring.tres"))
	var screen: EventScreen = auto_free(EventScreen.new())
	add_child(screen)
	screen.advanced.connect(func() -> void: _advanced = true)
	screen.open(run)
	Screens.button(screen, tr("EVENT_SPRING_UPGRADE")).pressed.emit()
	await get_tree().process_frame
	var zeni: int = run.state.inventory.ball_count() - 1
	(Screens.find_all(screen, BagList)[0] as BagList).ball_picked.emit(zeni)
	await get_tree().process_frame
	assert_int(run.state.inventory.level_of(zeni)).is_equal(2)
	assert_array(Screens.find_all(screen, ItemCard)).has_size(1)
	Screens.button(screen, "BUTTON_CONTINUE").pressed.emit()
	assert_bool(_advanced).is_true()
	assert_int(run.phase).is_equal(Run.Phase.MAP)
