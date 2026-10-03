@tool
class_name ShimenawaEffect
extends Effect
## Shimenawa: the first shot of each board bounces off the bottom of the board.
## Params: bounces.


func on_shot_start(game: BoardGame) -> void:
	if game.shots_fired == 1:
		game.launched_ball().floor_bounces = param(&"bounces")
		game.trigger(self)
