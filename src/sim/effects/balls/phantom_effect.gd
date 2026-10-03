@tool
class_name PhantomEffect
extends Effect
## Phantom ball: passes through its first pegs, hitting them without bouncing.
## Level value: pegs passed through.


func on_shot_start(game: BoardGame) -> void:
	game.launched_ball().ghost_hits = value()
