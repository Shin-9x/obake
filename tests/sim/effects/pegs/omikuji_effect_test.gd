extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const OMIKUJI: String = "res://data/pegs/omikuji.tres"


func test_draws_every_fortune_and_each_pays_what_it_says() -> void:
	var definition: PegDefinition = load(OMIKUJI)
	var fortunes: Dictionary[String, int] = {}
	for board_seed: int in 60:
		var game: BoardGame = Harness.board(Harness.ROW, null, null, board_seed)
		game.place_special(0, definition)
		Harness.shoot(game)
		game.score_hit(0)
		var fortune: String = "nothing"
		if game.shot_points == definition.params[&"points"]:
			fortune = "points"
		elif game.shot_mult == 1000 + definition.params[&"mult"]:
			fortune = "mult"
		elif game.mon_earned == definition.params[&"mon"]:
			fortune = "mon"
		else:
			assert_int(game.shot_points + game.mon_earned).is_equal(0)
			assert_int(game.shot_mult).is_equal(1000)
		fortunes[fortune] = fortunes.get(fortune, 0) + 1
	assert_array(fortunes.keys()).contains_exactly_in_any_order(
		["points", "mult", "mon", "nothing"]
	)


func test_same_seed_draws_the_same_fortune() -> void:
	var outcomes: Array[int] = []
	for attempt: int in 2:
		var game: BoardGame = Harness.board(Harness.ROW)
		game.place_special(0, load(OMIKUJI))
		Harness.shoot(game)
		game.score_hit(0)
		outcomes.append(game.shot_points * 1_000_000 + game.shot_mult * 100 + game.mon_earned)
	assert_int(outcomes[1]).is_equal(outcomes[0])
