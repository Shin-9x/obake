@tool
class_name TaikoEffect
extends Effect
## Taiko ball: every wall bounce adds mult, up to a cap.
## Level value: most bounces that count. Params: mult added per bounce, in permille.

var _counted: int = 0


func on_shot_start(_game: BoardGame) -> void:
	_counted = 0


func on_wall_bounce(game: BoardGame) -> void:
	if _counted >= value():
		return
	_counted += 1
	var ball: SimBall = game.launched_ball()
	game.add_mult(param(&"mult"), ball.x, ball.y)
	game.trigger(self)
