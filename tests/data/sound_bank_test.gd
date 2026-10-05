extends GdUnitTestSuite
## The sound bank holds every cue the game plays; effects are short, music loops.

const AUDIO: GDScript = preload("res://src/services/audio_service.gd")
const BANK: String = "res://data/audio/sound_bank.tres"


func test_every_cue_has_a_short_effect() -> void:
	var bank: SoundBank = load(BANK)
	for cue: StringName in AUDIO.CUES:
		var stream: AudioStreamWAV = bank.cues.get(cue) as AudioStreamWAV
		assert_object(stream).override_failure_message(String(cue)).is_not_null()
		if stream != null:
			assert_float(stream.get_length()).is_between(0.01, 2.0)
			assert_int(stream.loop_mode).is_not_equal(AudioStreamWAV.LOOP_FORWARD)


func test_both_music_tracks_loop() -> void:
	var bank: SoundBank = load(BANK)
	for track: AudioStream in [bank.menu_music, bank.board_music]:
		var wav: AudioStreamWAV = track as AudioStreamWAV
		assert_object(wav).is_not_null()
		assert_int(wav.loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)
		assert_float(wav.get_length()).is_greater(10.0)
