@tool
class_name DarumaEffect
extends Effect
## Daruma ball: when lost, gets back up on top of the bag, a few times per board.
## Level value: returns per board.

var _returns_left: int = 0


func on_board_start(_game: BoardGame) -> void:
	_returns_left = value()


func on_shot_end(game: BoardGame) -> void:
	if game.shot_caught or _returns_left <= 0:
		return
	_returns_left -= 1
	game.keep_ball_on_top()
	game.trigger(self)
