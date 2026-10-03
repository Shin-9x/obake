@tool
class_name MagatamaEffect
extends Effect
## Magatama: extra mult for every few red lanterns hit in one shot.
## Params: reds per step, mult per step (permille).


func on_shot_end(game: BoardGame) -> void:
	var steps: int = game.shot_red_hits / param(&"reds")
	if steps > 0:
		game.add_mult(steps * param(&"mult"), 0, 0)
		game.trigger(self)
