@tool
class_name TsukumogamiEffect
extends Effect
## Tsukumogami: every purchased peg is placed more than once.
## Params: copies.


func on_board_start(game: BoardGame) -> void:
	game.purchased_copies = param(&"copies")
