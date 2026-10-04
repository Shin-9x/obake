extends GdUnitTestSuite
## Every item definition matches the GDD numbers and has its script, art and texts.

const BALLS: Dictionary[String, Array] = {
	"hitodama": [ItemDefinition.Rarity.BASE, []],
	"heavy": [ItemDefinition.Rarity.COMMON, [2000, 3000, 4000]],
	"taiko": [ItemDefinition.Rarity.COMMON, [3, 5, 8]],
	"zeni": [ItemDefinition.Rarity.COMMON, [10, 8, 6]],
	"explosive": [ItemDefinition.Rarity.UNCOMMON, [16000, 22000, 28000]],
	"phantom": [ItemDefinition.Rarity.UNCOMMON, [2, 3, 4]],
	"magnetic": [ItemDefinition.Rarity.UNCOMMON, [30000, 40000, 50000]],
	"daruma": [ItemDefinition.Rarity.UNCOMMON, [1, 2, 3]],
	"splitter": [ItemDefinition.Rarity.RARE, [2, 3, 4]],
	"onibi": [ItemDefinition.Rarity.RARE, [1, 2, 3]],
}
const PEGS: Dictionary[String, ItemDefinition.Rarity] = {
	"coin_peg": ItemDefinition.Rarity.COMMON,
	"bell": ItemDefinition.Rarity.COMMON,
	"explosive_lantern": ItemDefinition.Rarity.UNCOMMON,
	"torii": ItemDefinition.Rarity.UNCOMMON,
	"kagami": ItemDefinition.Rarity.RARE,
	"omikuji": ItemDefinition.Rarity.RARE,
}
## Rarity and the GDD numbers each omamori must carry.
const OMAMORI: Dictionary[String, Array] = {
	"chochin": [ItemDefinition.Rarity.COMMON, {&"points": 5}],
	"first_strike": [ItemDefinition.Rarity.COMMON, {&"factor": 5000}],
	"patience": [ItemDefinition.Rarity.COMMON, {&"pegs": 15, &"mult": 3000}],
	"kaeru": [ItemDefinition.Rarity.COMMON, {&"mon": 2}],
	"uchiwa": [ItemDefinition.Rarity.COMMON, {&"width_factor": 1500}],
	"teru_teru_bozu": [ItemDefinition.Rarity.COMMON, {&"mult": 3000}],
	"drum": [ItemDefinition.Rarity.COMMON, {&"points": 5}],
	"maneki_neko": [ItemDefinition.Rarity.UNCOMMON, {&"interest_cap": 2}],
	"yata_mirror": [ItemDefinition.Rarity.UNCOMMON, {&"factor": 3000}],
	"magatama": [ItemDefinition.Rarity.UNCOMMON, {&"reds": 3, &"mult": 1000}],
	"shimenawa": [ItemDefinition.Rarity.UNCOMMON, {&"bounces": 1}],
	"hyotan": [ItemDefinition.Rarity.RARE, {&"shots": 1}],
	"ema": [ItemDefinition.Rarity.RARE, {&"points": 2}],
	"shuten_sake": [ItemDefinition.Rarity.LEGENDARY, {&"factor": 2000, &"shots": 2}],
	"tsukumogami": [ItemDefinition.Rarity.LEGENDARY, {&"copies": 2}],
}

var _texts: Dictionary[String, PackedStringArray] = {}


func before() -> void:
	var file: FileAccess = FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		_texts[row[0]] = row


func test_balls_match_the_gdd() -> void:
	for id: String in BALLS:
		var ball: BallDefinition = load("res://data/balls/%s.tres" % id)
		assert_int(ball.rarity).is_equal(BALLS[id][0])
		assert_array(Array(ball.level_values)).is_equal(BALLS[id][1])
		assert_object(ball.texture).is_not_null()
		assert_bool(ball.effect_script != null).is_equal(id != "hitodama")
		_assert_texts(ball)


func test_ball_constants_match_the_gdd() -> void:
	assert_int(_param("balls/heavy", &"restitution")).is_equal(500)
	assert_int(_param("balls/taiko", &"mult")).is_equal(1000)
	assert_int(_param("balls/zeni", &"mon")).is_equal(1)
	# GDD: Onibi's fire lands 0.3 s later.
	assert_int(_param("balls/onibi", &"delay")).is_equal(36)


func test_purchasable_pegs_match_the_gdd() -> void:
	for id: String in PEGS:
		var peg: PegDefinition = load("res://data/pegs/%s.tres" % id)
		assert_int(peg.rarity).is_equal(PEGS[id])
		assert_object(peg.texture).is_not_null()
		_assert_texts(peg)
	var coin: PegDefinition = load("res://data/pegs/coin_peg.tres")
	var bell: PegDefinition = load("res://data/pegs/bell.tres")
	var torii: PegDefinition = load("res://data/pegs/torii.tres")
	var kagami: PegDefinition = load("res://data/pegs/kagami.tres")
	assert_int(coin.mon).is_equal(1)
	assert_int(bell.mult_add).is_equal(2000)
	assert_int(torii.points).is_equal(15)
	assert_int(torii.restitution).is_equal(1300)
	assert_bool(torii.persistent).is_true()
	assert_int(kagami.mult_factor).is_equal(1500)
	assert_int(_param("pegs/explosive_lantern", &"radius")).is_equal(20000)
	assert_int(_param("pegs/omikuji", &"points")).is_equal(50)
	assert_int(_param("pegs/omikuji", &"mult")).is_equal(2000)
	assert_int(_param("pegs/omikuji", &"mon")).is_equal(2)


func test_omamori_match_the_gdd() -> void:
	for id: String in OMAMORI:
		var charm: OmamoriDefinition = load("res://data/omamori/%s.tres" % id)
		assert_int(charm.rarity).is_equal(OMAMORI[id][0])
		var expected: Dictionary = OMAMORI[id][1]
		for key: StringName in expected:
			assert_int(charm.params.get(key, -1)).is_equal(expected[key])
		assert_object(charm.effect_script).is_not_null()
		assert_object(charm.icon).is_not_null()
		_assert_texts(charm)


func test_effect_scripts_extend_effect() -> void:
	for folder: String in ["balls", "pegs", "omamori", "characters"]:
		for file: String in DirAccess.get_files_at("res://data/" + folder):
			var item: ItemDefinition = load("res://data/%s/%s" % [folder, file]) as ItemDefinition
			if item == null or item.effect_script == null:
				continue
			var instance: Object = item.effect_script.new()
			assert_bool(instance is Effect).is_true()


func _param(path: String, key: StringName) -> int:
	return (load("res://data/%s.tres" % path) as ItemDefinition).params.get(key, -1)


func _assert_texts(item: ItemDefinition) -> void:
	for key: String in [item.name_key, item.description_key]:
		assert_bool(_texts.has(key)).override_failure_message("missing text %s" % key).is_true()
		if _texts.has(key):
			assert_str(_texts[key][1]).is_not_empty()
			assert_str(_texts[key][2]).is_not_empty()
