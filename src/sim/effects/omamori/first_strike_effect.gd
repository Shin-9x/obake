@tool
class_name FirstStrikeEffect
extends Effect
## First Strike: the first peg hit in each shot scores multiplied points.
## Params: factor in permille.


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if hit.first_of_shot:
		hit.points_factor = FixedMath.div_round(
			hit.points_factor * param(&"factor"), FixedMath.PERMILLE
		)
		game.trigger(self)
