@tool
class_name TamamoEffect
extends Effect
## Tamamo-no-Mae: one peg in every few still on the board is an illusion, drawn again at every
## shot from the blue lanterns.
## Params: one_in (one illusion for this many pegs in play).


func on_shot_start(game: BoardGame) -> void:
	game.scatter_illusions(game.pegs_in_play() / maxi(1, param(&"one_in")))
