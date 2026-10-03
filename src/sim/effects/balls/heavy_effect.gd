@tool
class_name HeavyEffect
extends Effect
## Heavy ball: bounces dully and multiplies the points of every peg hit in its shot.
## Level value: points factor in permille. Params: restitution in permille.


func on_shot_start(game: BoardGame) -> void:
	game.launched_ball().restitution = param(&"restitution")


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	hit.points_factor = FixedMath.div_round(hit.points_factor * value(), FixedMath.PERMILLE)
	game.trigger(self)
