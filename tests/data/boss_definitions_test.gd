extends GdUnitTestSuite
## The four MVP bosses: layouts that exist, the rule numbers from the GDD, art and texts.

const BOSSES: Dictionary[String, Array] = {
	"jorogumo": ["jorogumo", "", {&"points_factor": 3000}],
	"nue": ["nue_a", "nue_b", {&"threshold": 500}],
	"tamamo": ["tamamo", "", {&"one_in": 3}],
	"shuten_doji": ["shuten", "", {&"mult_floor": 1000, &"halving_hits": 3, &"points_factor": 500}],
}

var _texts: Dictionary[String, PackedStringArray] = {}
var _library: LayoutLibrary


func before() -> void:
	_library = LayoutLibrary.load_from()
	var file: FileAccess = FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		_texts[row[0]] = row


func test_bosses_play_their_own_layouts() -> void:
	for id: String in BOSSES:
		var boss: BossDefinition = _boss(id)
		assert_str(boss.layout_id).is_equal(BOSSES[id][0])
		assert_str(boss.second_layout_id).is_equal(BOSSES[id][1])
		for layout_id: String in [boss.layout_id, boss.second_layout_id]:
			if layout_id.is_empty():
				continue
			var layout: BoardLayout = _library.find(layout_id)
			assert_object(layout).override_failure_message(layout_id).is_not_null()
			if layout != null:
				assert_int(layout.kind).is_equal(BoardLayout.Kind.BOSS)


func test_rule_numbers_match_the_gdd() -> void:
	for id: String in BOSSES:
		var expected: Dictionary = BOSSES[id][2]
		for key: StringName in expected:
			assert_int(_boss(id).params.get(key, -1)).is_equal(expected[key])
	var oni: PegDefinition = _boss("shuten_doji").special_peg
	assert_str(String(oni.id)).is_equal("oni")
	assert_int(oni.mult_add).is_equal(-1000)
	assert_int(oni.rarity).is_equal(ItemDefinition.Rarity.BASE)


func test_jorogumo_has_webs() -> void:
	assert_array(_library.find("jorogumo").zones).is_not_empty()


func test_bosses_have_a_script_a_portrait_and_texts() -> void:
	for id: String in BOSSES:
		var boss: BossDefinition = _boss(id)
		assert_bool(boss.effect_script.new() is Effect).is_true()
		assert_object(boss.portrait).is_not_null()
		for key: String in [boss.name_key, boss.description_key]:
			assert_bool(_texts.has(key)).override_failure_message("missing %s" % key).is_true()


func _boss(id: String) -> BossDefinition:
	return load("res://data/bosses/%s.tres" % id)
