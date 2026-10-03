@tool
class_name ExplosiveEffect
extends Effect
## Explosive ball: its first impact also hits every peg around the impact point.
## Level value: blast radius in milli-pixels.

var _armed: bool = false


func on_shot_start(_game: BoardGame) -> void:
	_armed = true


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if not _armed or hit.source != PegHit.Source.BALL:
		return
	_armed = false
	var ball: SimBall = game.simulation.balls[hit.ball]
	game.hit_pegs_near(ball.x, ball.y, value(), PegHit.Source.AREA)
	game.trigger(self)
