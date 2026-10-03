@tool
class_name UchiwaEffect
extends Effect
## Uchiwa: a wider bucket.
## Params: width_factor in permille.


func on_board_start(game: BoardGame) -> void:
	var bucket: Bucket = game.simulation.bucket
	var width: int = 2 * bucket.half_width
	bucket.set_width(FixedMath.div_round(width * param(&"width_factor"), FixedMath.PERMILLE))
