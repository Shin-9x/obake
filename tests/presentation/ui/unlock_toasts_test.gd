extends GdUnitTestSuite
## Unlock notes queue up and fade out on their own.

const SKIN: UiSkin = preload("res://data/skins/ui_skin.tres")


func test_notes_queue_and_fade_out() -> void:
	var toasts: UnlockToasts = auto_free(UnlockToasts.new())
	toasts.skin = SKIN
	add_child(toasts)
	toasts.announce("first", "a")
	toasts.announce("second", "b")
	assert_int(toasts.pending()).is_equal(2)
	toasts._process(UnlockToasts.SHOW_TIME + 0.1)
	assert_int(toasts.pending()).is_equal(1)
	toasts._process(UnlockToasts.SHOW_TIME + 0.1)
	assert_int(toasts.pending()).is_equal(0)
	assert_bool(toasts.is_processing()).is_false()


func test_a_hint_shows_at_once_for_its_own_time() -> void:
	var toasts: UnlockToasts = auto_free(UnlockToasts.new())
	toasts.skin = SKIN
	add_child(toasts)
	toasts.announce("unlocked", "a")
	toasts.announce("waiting", "b")
	toasts.hint("press again", 1.0)
	assert_str(toasts._title.text).is_equal("press again")
	assert_bool(toasts._text.visible).is_false()
	toasts._process(1.1)
	assert_str(toasts._title.text).is_equal("waiting")
	assert_bool(toasts._text.visible).is_true()
