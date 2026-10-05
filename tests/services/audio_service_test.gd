extends GdUnitTestSuite
## Sound effects come from a fixed pool with a short cooldown per cue; music crossfades.

const AUDIO: GDScript = preload("res://src/services/audio_service.gd")

var _audio: Node


func before_test() -> void:
	_audio = auto_free(AUDIO.new())
	add_child(_audio)


func test_a_cue_plays_then_cools_down_briefly() -> void:
	assert_bool(_audio.play(AUDIO.PEG_HIT, 1.5)).is_true()
	assert_bool(_audio.play(AUDIO.PEG_HIT)).is_false()
	assert_bool(_audio.play(AUDIO.MON)).is_true()
	assert_bool(_audio.play(&"no_such_sound")).is_false()


func test_voices_are_made_once_and_reused() -> void:
	var players: int = _audio.get_child_count()
	for cue: StringName in AUDIO.CUES:
		_audio.play(cue)
	assert_int(_audio.get_child_count()).is_equal(players)
	assert_int(players).is_equal(AUDIO.VOICES + 2)


func test_music_switches_tracks_once() -> void:
	_audio.play_music(AUDIO.Music.BOARD)
	assert_int(_audio.music).is_equal(AUDIO.Music.BOARD)
	_audio.play_music(AUDIO.Music.BOARD)
	_audio.play_music(AUDIO.Music.NONE)
	assert_int(_audio.music).is_equal(AUDIO.Music.NONE)
