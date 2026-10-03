@tool
class_name ChochinEffect
extends Effect
## Chōchin: blue lanterns give extra points.
## Params: points.


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if hit.role == BoardGame.Role.BLUE:
		hit.bonus_points += param(&"points")
		game.trigger(self)
