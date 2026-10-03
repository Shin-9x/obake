@tool
class_name DrumEffect
extends Effect
## Drum: every wall bounce adds points.
## Params: points.


func on_wall_bounce(game: BoardGame) -> void:
	var ball: SimBall = game.launched_ball()
	game.add_points(param(&"points"), ball.x, ball.y)
	game.trigger(self)
