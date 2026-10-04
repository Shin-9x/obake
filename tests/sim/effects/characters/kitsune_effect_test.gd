extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const KITSUNE: String = "res://data/characters/kitsune.tres"


func test_green_lanterns_turn_blue_lanterns_into_kitsunebi() -> void:
	var game: BoardGame = _game()
	Harness.shoot(game)
	game.score_hit(0)
	var turned: Array[int] = []
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.SPECIAL:
			turned.append(peg)
			assert_str(String(game.definition_of(peg).id)).is_equal("kitsunebi")
	assert_array(turned).has_size(3)
	assert_int(game.red_remaining()).is_equal(1)
	var mult: int = game.shot_mult
	game.score_hit(turned[0])
	assert_int(game.shot_mult).is_equal(mult + 1000)


func test_red_lanterns_also_give_points() -> void:
	var game: BoardGame = _game()
	Harness.shoot(game)
	game.score_hit(Harness.ROW.size())
	assert_int(game.shot_points).is_equal(5)
	assert_int(game.shot_mult).is_equal(2000)


func _game() -> BoardGame:
	var loadout: LoadoutDefinition = Harness.loadout()
	loadout.character = load(KITSUNE)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	Harness.all_blue(game)
	game.roles[0] = BoardGame.Role.GREEN
	return game
