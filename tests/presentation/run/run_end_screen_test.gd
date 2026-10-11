extends GdUnitTestSuite
## The end of a run shows its seed on a button that copies it.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")


func test_the_seed_button_copies_the_seed_and_says_so() -> void:
	var run: Run = Screens.run()
	Screens.enter(run, MapNode.Kind.BOARD)
	Screens.Fixtures.finish(run, BoardGame.Outcome.FAILED)
	var screen: RunEndScreen = auto_free(RunEndScreen.new())
	add_child(screen)
	screen.open(run)
	var seed_text: String = "%X" % run.state.run_seed
	assert_str(screen.seed_button.text).contains(seed_text)
	# The character select reads the seed back in this form.
	assert_int(seed_text.hex_to_int()).is_equal(run.state.run_seed)
	screen.seed_button.pressed.emit()
	assert_str(screen.seed_button.text).is_equal(tr("END_SEED_COPIED"))
	if DisplayServer.has_feature(DisplayServer.FEATURE_CLIPBOARD):
		assert_str(DisplayServer.clipboard_get()).is_equal(seed_text)
