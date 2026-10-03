@tool
class_name TeruTeruBozuEffect
extends Effect
## Teru teru bōzu: a shot that hits no red lantern gives the next shot of the board extra mult.
## Params: mult in permille.


func on_shot_end(game: BoardGame) -> void:
	if game.shot_red_hits == 0:
		game.next_shot_mult_bonus += param(&"mult")
		game.trigger(self)
