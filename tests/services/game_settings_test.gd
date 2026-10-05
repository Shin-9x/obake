extends GdUnitTestSuite
## Settings defaults, their JSON form, and limits on values read back.


func test_defaults_round_trip_through_json() -> void:
	var settings: GameSettings = GameSettings.new()
	settings.language = "it"
	settings.scaling = GameSettings.Scaling.FRACTIONAL
	settings.fast_forward_speed = 2
	settings.vibration = false
	settings.show_performance = true
	var text: String = JSON.stringify(settings.to_dictionary())
	var restored: GameSettings = GameSettings.from_dictionary(JSON.parse_string(text))
	assert_dict(restored.to_dictionary()).is_equal(settings.to_dictionary())


func test_values_read_back_are_clamped_or_fall_back_to_defaults() -> void:
	var restored: GameSettings = (
		GameSettings
		. from_dictionary(
			{
				"master_volume": 250,
				"music_volume": -4,
				"sfx_volume": "loud",
				"language": "fr",
				"fast_forward_speed": 7,
				"drag_sensitivity": 900,
			}
		)
	)
	var defaults: GameSettings = GameSettings.new()
	assert_int(restored.master_volume).is_equal(100)
	assert_int(restored.music_volume).is_equal(0)
	assert_int(restored.sfx_volume).is_equal(defaults.sfx_volume)
	assert_str(restored.language).is_equal("")
	assert_int(restored.fast_forward_speed).is_equal(defaults.fast_forward_speed)
	assert_int(restored.drag_sensitivity).is_equal(GameSettings.MAX_DRAG_SENSITIVITY)
	assert_int(GameSettings.from_dictionary("garbage").master_volume).is_equal(80)
	assert_bool(restored.show_performance).is_false()
