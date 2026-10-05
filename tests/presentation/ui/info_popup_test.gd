extends GdUnitTestSuite
## The info card for touch screens: a tap shows an item, a second tap or a few seconds hide it.

const DRUM: String = "res://data/omamori/drum.tres"


func test_a_tap_shows_the_item_and_a_second_tap_hides_it() -> void:
	var popup: InfoPopup = auto_free(InfoPopup.new())
	add_child(popup)
	var drum: OmamoriDefinition = load(DRUM)
	popup.show_item(drum, Vector2(10, 10))
	assert_bool(popup.visible).is_true()
	popup.show_item(drum, Vector2(10, 10))
	assert_bool(popup.visible).is_false()


func test_the_card_hides_itself_after_a_while() -> void:
	var popup: InfoPopup = auto_free(InfoPopup.new())
	add_child(popup)
	popup.show_item(load(DRUM), Vector2.ZERO)
	popup._process(InfoPopup.SHOW_TIME + 0.1)
	assert_bool(popup.visible).is_false()
