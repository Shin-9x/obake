extends Effect
## Records the hooks it receives and applies the adjustments named in its definition's params:
## bonus_points, points_factor, mult_add and final_factor.

## "slot:hook" entries from every probe, so tests can see their relative order. Clear it first.
static var journal: Array[String] = []


func on_board_start(_game: BoardGame) -> void:
	journal.append("%d:board_start" % slot)


func on_shot_start(_game: BoardGame) -> void:
	journal.append("%d:shot_start" % slot)


func on_peg_hit(_game: BoardGame, hit: PegHit) -> void:
	journal.append("%d:peg_hit" % slot)
	hit.bonus_points += param(&"bonus_points")
	if definition.params.has(&"points_factor"):
		hit.points_factor = FixedMath.div_round(
			hit.points_factor * param(&"points_factor"), FixedMath.PERMILLE
		)


func on_power(_game: BoardGame, _hit: PegHit) -> void:
	journal.append("%d:power" % slot)


func on_wall_bounce(_game: BoardGame) -> void:
	journal.append("%d:wall_bounce" % slot)


func on_bucket(_game: BoardGame) -> void:
	journal.append("%d:bucket" % slot)


func on_shot_end(game: BoardGame) -> void:
	journal.append("%d:shot_end" % slot)
	if definition.params.has(&"final_factor"):
		game.multiply_final_mult(param(&"final_factor"))
	if definition.params.has(&"mult_add"):
		game.add_mult(param(&"mult_add"), 0, 0)


func on_shot_scored(_game: BoardGame) -> void:
	journal.append("%d:shot_scored" % slot)


func on_board_end(_game: BoardGame, _result: BoardResult) -> void:
	journal.append("%d:board_end" % slot)
