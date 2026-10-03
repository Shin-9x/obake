@tool
class_name HyotanEffect
extends Effect
## Hyōtan: an extra shot on every board.
## Params: shots.


func on_board_start(game: BoardGame) -> void:
	game.shots_left += param(&"shots")
