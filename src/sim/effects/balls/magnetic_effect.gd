@tool
class_name MagneticEffect
extends Effect
## Magnetic ball: pulled towards red lanterns in range.
## Level value: pull radius in milli-pixels. Params: strength, the pull's acceleration in
## milli-pixels per second squared.


func on_shot_start(game: BoardGame) -> void:
	var ball: SimBall = game.launched_ball()
	ball.attraction_radius = value()
	ball.attraction_strength = param(&"strength")
