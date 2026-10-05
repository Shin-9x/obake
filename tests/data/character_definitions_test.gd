extends GdUnitTestSuite
## The three MVP characters match the GDD: starting bags, power numbers (as tuned with the balance
## bot in M8), art and texts.

## Special balls each starting bag holds besides the six Hitodama.
const BAGS: Dictionary[String, Array] = {
	"yamabushi": ["explosive", "taiko"],
	"kitsune": ["phantom", "phantom"],
	"tanuki": ["zeni"],
}
const PARAMS: Dictionary[String, Dictionary] = {
	"yamabushi": {&"shots": 2, &"contacts": 4},
	"kitsune": {&"count": 2, &"red_points": 5},
	"tanuki": {&"count": 5, &"shop_extra_balls": 2},
}
const HITODAMA_COUNT: int = 6

var _texts: Dictionary[String, PackedStringArray] = {}


func before() -> void:
	var file: FileAccess = FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		_texts[row[0]] = row


func test_starting_bags_match_the_gdd() -> void:
	for id: String in BAGS:
		var ids: Array[String] = []
		for ball: BallDefinition in _character(id).starting_balls:
			ids.append(String(ball.id))
		var expected: Array[String] = []
		for i: int in HITODAMA_COUNT:
			expected.append("hitodama")
		expected.append_array(BAGS[id])
		assert_array(ids).is_equal(expected)


func test_power_numbers_match_the_gdd() -> void:
	for id: String in PARAMS:
		var params: Dictionary = PARAMS[id]
		for key: StringName in params:
			assert_int(_character(id).params.get(key, -1)).is_equal(params[key])


func test_powers_place_the_right_pegs() -> void:
	assert_object(_character("yamabushi").power_peg).is_null()
	assert_str(String(_character("kitsune").power_peg.id)).is_equal("kitsunebi")
	assert_str(String(_character("tanuki").power_peg.id)).is_equal("coin_peg")
	var kitsunebi: PegDefinition = load("res://data/pegs/kitsunebi.tres")
	assert_int(kitsunebi.rarity).is_equal(ItemDefinition.Rarity.BASE)
	assert_int(kitsunebi.mult_add).is_equal(1000)
	assert_object(kitsunebi.texture).is_not_null()


func test_characters_have_a_script_a_portrait_and_texts() -> void:
	for id: String in BAGS:
		var character: CharacterDefinition = _character(id)
		assert_bool(character.effect_script.new() is Effect).is_true()
		assert_object(character.portrait).is_not_null()
		for key: String in [
			character.name_key,
			character.description_key,
			character.power_key,
			character.passive_key
		]:
			assert_bool(_texts.has(key)).override_failure_message("missing %s" % key).is_true()


func _character(id: String) -> CharacterDefinition:
	return load("res://data/characters/%s.tres" % id)
