extends GdUnitTestSuite
## Item descriptions written for a level keep only that level's values.

const PHANTOM: BallDefinition = preload("res://data/balls/phantom.tres")
const HEAVY: BallDefinition = preload("res://data/balls/heavy.tres")
const HITODAMA: BallDefinition = preload("res://data/balls/hitodama.tres")

var _locale: String = ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	TranslationServer.set_locale("en")


func after_test() -> void:
	TranslationServer.set_locale(_locale)


func test_a_description_keeps_the_value_of_its_level() -> void:
	assert_str(UiKit.describe(PHANTOM, 1)).is_equal(
		"Passes through its first 2 pegs, hitting them."
	)
	assert_str(UiKit.describe(PHANTOM, 3)).is_equal(
		"Passes through its first 4 pegs, hitting them."
	)


func test_values_keep_their_sign() -> void:
	assert_str(UiKit.describe(HEAVY, 2)).is_equal("Bounces softly; hit pegs score ×3 points.")


func test_a_description_without_levels_is_left_alone() -> void:
	assert_str(UiKit.describe(HITODAMA, 2)).is_equal("No effect.")


func test_a_level_beyond_the_last_keeps_the_last_value() -> void:
	assert_str(UiKit.describe(PHANTOM, 9)).contains("first 4 pegs")
