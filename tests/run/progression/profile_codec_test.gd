extends GdUnitTestSuite
## Profiles survive JSON, older files are read with defaults, and broken ones are refused.


func test_a_profile_round_trips_through_json() -> void:
	var profile: Profile = Profile.new()
	profile.feats.append(&"thirty_pegs")
	profile.add_mark(&"kitsune", Profile.Mark.SHUTEN)
	profile.add_mark(&"kitsune", Profile.Mark.FESTIVAL)
	profile.discovered[&"splitter"] = true
	profile.runs = 7
	profile.runs_by_character[&"kitsune"] = 4
	profile.wins_by_character[&"kitsune"] = 1
	profile.best_shot = 2400
	profile.matsuri = 5
	profile.boards_won = 30
	var text: String = JSON.stringify(ProfileCodec.encode(profile))
	var restored: Profile = ProfileCodec.decode(JSON.parse_string(text))
	assert_dict(ProfileCodec.encode(restored)).is_equal(ProfileCodec.encode(profile))
	assert_bool(restored.has_mark(&"kitsune", Profile.Mark.FESTIVAL)).is_true()
	assert_bool(restored.hard_unlocked(&"kitsune")).is_true()
	assert_bool(restored.hard_unlocked(&"tanuki")).is_false()
	assert_int(restored.wins()).is_equal(1)


func test_an_older_profile_is_read_with_defaults() -> void:
	var restored: Profile = ProfileCodec.decode({"feats": ["first_matsuri"]})
	assert_bool(restored.has_feat(&"first_matsuri")).is_true()
	assert_int(restored.runs).is_equal(0)
	assert_dict(restored.marks).is_empty()


func test_broken_or_newer_profiles_are_refused() -> void:
	assert_object(ProfileCodec.decode("garbage")).is_null()
	assert_object(ProfileCodec.decode(null)).is_null()
	assert_object(ProfileCodec.decode({"schema": ProfileCodec.SCHEMA + 1})).is_null()
