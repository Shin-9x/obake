extends GdUnitTestSuite
## The "How to play" pages: every page has a picture and a text for each line, and the buttons
## walk through them and out.


func test_every_page_shows_its_lines_with_pictures() -> void:
	var screen: HowToPlayScreen = auto_free(HowToPlayScreen.new())
	add_child(screen)
	screen.open()
	assert_int(screen.page_count()).is_equal(HowToPlayScreen.PAGES.size() + 1)
	for page: int in screen.page_count():
		var pictures: Array[Node] = screen.find_children("", "TextureRect", true, false)
		var texts: int = 0
		for label: Node in screen.find_children("", "Label", true, false):
			if (label as Label).autowrap_mode != TextServer.AUTOWRAP_OFF:
				texts += 1
				assert_str((label as Label).text).is_not_empty()
				assert_bool((label as Label).text.begins_with("HOWTO_")).is_false()
		assert_int(texts).is_greater(0)
		for picture: Node in pictures:
			if picture.get_parent() is HBoxContainer:
				assert_object((picture as TextureRect).texture).is_not_null()
		if page + 1 < screen.page_count():
			screen.next()
			await get_tree().process_frame


func test_the_buttons_walk_through_the_pages_and_out() -> void:
	var screen: HowToPlayScreen = auto_free(HowToPlayScreen.new())
	add_child(screen)
	screen.open()
	var closed: Array[int] = [0]
	screen.closed.connect(func() -> void: closed[0] += 1)
	screen.next()
	screen.next()
	assert_int(screen.page_index).is_equal(2)
	screen.back()
	assert_int(screen.page_index).is_equal(1)
	screen.back()
	screen.back()
	assert_int(closed[0]).is_equal(1)
	for page: int in screen.page_count():
		screen.next()
	assert_int(closed[0]).is_equal(2)
	# Lets the pages replaced along the way be freed.
	await get_tree().process_frame
