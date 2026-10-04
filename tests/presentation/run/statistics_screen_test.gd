extends GdUnitTestSuite
## The statistics screen lists what the profile remembers.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")
const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_the_profile_numbers_are_listed() -> void:
	var profile: Profile = Profile.new()
	profile.runs = 6
	profile.runs_by_character[&"kitsune"] = 4
	profile.wins_by_character[&"kitsune"] = 2
	profile.best_shot = 4321
	profile.feats.append(&"first_matsuri")
	var screen: StatisticsScreen = auto_free(StatisticsScreen.new())
	add_child(screen)
	screen.open(Fixtures.content(), load("res://data/progression.tres"), profile)
	var texts: PackedStringArray = PackedStringArray()
	for label: Node in Screens.find_all(screen, Label):
		texts.append((label as Label).text)
	var shown: String = "\n".join(texts)
	assert_str(shown).contains(tr("STATS_RUNS") % 6)
	assert_str(shown).contains(tr("STATS_WINS") % 2)
	assert_str(shown).contains(tr("STATS_BEST_SHOT") % 4321)
	assert_str(shown).contains(tr("STATS_FEATS") % [1, 12])
	assert_str(shown).contains(tr("STATS_CHARACTER") % [tr("CHARACTER_KITSUNE"), 4, 2])
