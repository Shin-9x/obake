extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TANUKI: String = "res://data/characters/tanuki.tres"


func test_green_lanterns_turn_blue_lanterns_into_coin_pegs() -> void:
	var loadout: LoadoutDefinition = Harness.loadout()
	loadout.character = load(TANUKI)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	Harness.all_blue(game)
	game.roles[0] = BoardGame.Role.GREEN
	Harness.shoot(game)
	game.score_hit(0)
	var coins: Array[int] = []
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.SPECIAL:
			coins.append(peg)
			assert_str(String(game.definition_of(peg).id)).is_equal("coin_peg")
	assert_array(coins).has_size(3)
	game.score_hit(coins[0])
	assert_int(game.mon_earned).is_equal(1)
