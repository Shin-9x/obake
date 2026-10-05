extends GdUnitTestSuite
## Lantern sounds climb a semitone per lantern of a shot, up to a ceiling.


func test_the_lantern_pitch_climbs_by_semitones_then_stops() -> void:
	assert_float(BoardSounds.pitch_for(1)).is_equal_approx(1.0, 0.0001)
	assert_float(BoardSounds.pitch_for(13)).is_equal_approx(2.0, 0.0001)
	var ceiling: float = pow(2.0, BoardSounds.MAX_SEMITONES / 12.0)
	assert_float(BoardSounds.pitch_for(40)).is_equal_approx(ceiling, 0.0001)
