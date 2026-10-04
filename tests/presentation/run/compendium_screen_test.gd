extends GdUnitTestSuite
## The compendium hides what was never seen and tells how to unlock what is locked.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")
const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_entries_never_seen_are_silhouettes_with_the_feat_to_unlock_them() -> void:
	var screen: CompendiumScreen = _open(Profile.new())
	assert_int(screen.entries().size()).is_equal(10)
	var buttons: Array[Node] = _entries(screen)
	for entry: Node in buttons:
		var picture: TextureRect = entry.get_child(0) as TextureRect
		assert_that(picture.modulate).is_equal(CompendiumScreen.SILHOUETTE)
	var splitter: int = screen.entries().find(Fixtures.ball("splitter"))
	(buttons[splitter] as Button).pressed.emit()
	var texts: Array[String] = _texts(screen)
	assert_array(texts).contains(["COMPENDIUM_UNKNOWN"])
	assert_str("\n".join(texts)).contains(tr("FEAT_THIRTY_PEGS_DESC"))


func test_discovered_entries_show_their_name_and_description() -> void:
	var profile: Profile = Profile.new()
	profile.discovered[&"heavy"] = true
	var screen: CompendiumScreen = _open(profile)
	var heavy: int = screen.entries().find(Fixtures.ball("heavy"))
	var entry: Button = _entries(screen)[heavy] as Button
	assert_that((entry.get_child(0) as TextureRect).modulate).is_equal(Color.WHITE)
	entry.pressed.emit()
	assert_str("\n".join(_texts(screen))).contains(tr("BALL_HEAVY"))


func test_pages_list_omamori_pegs_and_bosses() -> void:
	var screen: CompendiumScreen = _open(Profile.new())
	var sizes: Array[int] = []
	for page: String in ["COMPENDIUM_OMAMORI", "COMPENDIUM_PEGS", "COMPENDIUM_BOSSES"]:
		Screens.button(screen, page).pressed.emit()
		await get_tree().process_frame
		sizes.append(screen.entries().size())
	assert_array(sizes).is_equal([15, 6, 4])


func _open(profile: Profile) -> CompendiumScreen:
	var screen: CompendiumScreen = auto_free(CompendiumScreen.new())
	add_child(screen)
	screen.open(Fixtures.content(), load("res://data/progression.tres"), profile)
	return screen


func _entries(screen: CompendiumScreen) -> Array[Node]:
	return Screens.find_all(screen, Button).filter(
		func(node: Node) -> bool: return node.get_child_count() > 0
	)


func _texts(screen: CompendiumScreen) -> Array[String]:
	var texts: Array[String] = []
	for label: Node in Screens.find_all(screen, Label):
		texts.append((label as Label).text)
	return texts
