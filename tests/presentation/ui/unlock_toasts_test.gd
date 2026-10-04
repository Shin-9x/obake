extends GdUnitTestSuite
## Unlock notes queue up and fade out on their own.


func test_notes_queue_and_fade_out() -> void:
	var toasts: UnlockToasts = auto_free(UnlockToasts.new())
	toasts.skin = load("res://data/skins/ui_skin.tres")
	add_child(toasts)
	toasts.announce("first", "a")
	toasts.announce("second", "b")
	assert_int(toasts.pending()).is_equal(2)
	toasts._process(UnlockToasts.SHOW_TIME + 0.1)
	assert_int(toasts.pending()).is_equal(1)
	toasts._process(UnlockToasts.SHOW_TIME + 0.1)
	assert_int(toasts.pending()).is_equal(0)
	assert_bool(toasts.is_processing()).is_false()
