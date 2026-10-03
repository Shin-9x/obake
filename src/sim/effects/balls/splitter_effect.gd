@tool
class_name SplitterEffect
extends Effect
## Splitter ball: its first impact splits it into several balls.
## Level value: balls after the split. Params: spread, the angle between neighbours in
## centidegrees.

var _armed: bool = false


func on_shot_start(_game: BoardGame) -> void:
	_armed = true


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if not _armed or hit.source != PegHit.Source.BALL:
		return
	_armed = false
	game.split_ball(hit.ball, value(), param(&"spread"))
	game.trigger(self)
