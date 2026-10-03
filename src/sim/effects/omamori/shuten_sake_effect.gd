@tool
class_name ShutenSakeEffect
extends Effect
## Shuten's Sake: the final mult of every shot is multiplied, at the cost of shots per board.
## Params: factor in permille, shots taken away (never below one shot).


func on_board_start(game: BoardGame) -> void:
	game.shots_left -= param(&"shots")


func on_shot_end(game: BoardGame) -> void:
	game.multiply_final_mult(param(&"factor"))
	game.trigger(self)
