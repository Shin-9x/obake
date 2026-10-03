@tool
class_name ManekiNekoEffect
extends Effect
## Maneki-neko: raises the cap on the interest paid at the end of a board.
## Params: interest_cap, the mon added to the cap.


func on_board_end(game: BoardGame, result: BoardResult) -> void:
	result.interest_cap += param(&"interest_cap")
	game.trigger(self)
