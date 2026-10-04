extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const TAMAMO: String = "res://data/bosses/tamamo.tres"


func test_a_third_of_the_pegs_are_illusions_drawn_again_every_shot() -> void:
	var game: BoardGame = Harness.boss_board(TAMAMO, Harness.ROW)
	Harness.all_blue(game)
	var seen: Dictionary[int, bool] = {}
	for shot: int in 4:
		Harness.shoot(game)
		var illusions: Array[int] = _illusions(game)
		# Six pegs in play: the row and the spare red, which is never an illusion.
		assert_array(illusions).has_size(2)
		assert_array(illusions).not_contains([Harness.ROW.size()])
		for peg: int in illusions:
			seen[peg] = true
		game.simulation.events.clear()
		_finish_without_hits(game)
	assert_int(seen.size()).is_greater(2)


func _illusions(game: BoardGame) -> Array[int]:
	var found: Array[int] = []
	for peg: int in game.roles.size():
		if game.simulation.pegs[peg].illusion:
			found.append(peg)
	return found


## The straight drop misses the row, so every peg stays in play between shots.
func _finish_without_hits(game: BoardGame) -> void:
	Harness.finish(game)
	Harness.all_blue(game)
