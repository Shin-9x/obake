@tool
class_name PatienceEffect
extends Effect
## Patience: a shot that hits enough pegs gains extra mult.
## Params: pegs needed, mult added (permille).


func on_shot_end(game: BoardGame) -> void:
	if game.shot_pegs_hit >= param(&"pegs"):
		game.add_mult(param(&"mult"), 0, 0)
		game.trigger(self)
