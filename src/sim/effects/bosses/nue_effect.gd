@tool
class_name NueEffect
extends Effect
## Nue: once the board total reaches a share of the target, the layout turns into its second
## form, checked after each shot is scored.
## Params: threshold (share of the target, permille).

var _transformed: bool = false


func on_shot_scored(game: BoardGame) -> void:
	if _transformed or game.total * FixedMath.PERMILLE < game.target * param(&"threshold"):
		return
	_transformed = true
	game.switch_layer(1)
	game.trigger(self)
