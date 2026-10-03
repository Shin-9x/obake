extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TSUKUMOGAMI: String = "res://data/omamori/tsukumogami.tres"


func test_every_purchased_peg_appears_twice() -> void:
	var loadout: LoadoutDefinition = Harness.loadout(
		[], [load(TSUKUMOGAMI)], [load("res://data/pegs/bell.tres")]
	)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	var bells: int = 0
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.SPECIAL:
			bells += 1
	assert_int(bells).is_equal(2)
