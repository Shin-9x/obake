@tool
class_name ShutenDojiEffect
extends Effect
## Shuten-doji: oni, the definition's special peg, replace blue lanterns. Each oni takes mult
## away, never below the floor, and enough oni in one shot halve its points.
## Params: oni (pegs placed), mult_floor (permille), halving_hits, points_factor (permille).

var _oni_hits: int = 0


func on_board_start(game: BoardGame) -> void:
	game.mult_floor = param(&"mult_floor")
	game.transform_random(BoardGame.Role.BLUE, param(&"oni"), _oni())


func on_shot_start(_game: BoardGame) -> void:
	_oni_hits = 0


func on_peg_hit(_game: BoardGame, hit: PegHit) -> void:
	if hit.definition == _oni():
		_oni_hits += 1


func on_shot_end(game: BoardGame) -> void:
	if _oni_hits < param(&"halving_hits"):
		return
	var ball: SimBall = game.launched_ball()
	game.multiply_points(param(&"points_factor"), ball.x, ball.y)
	game.trigger(self)


func _oni() -> PegDefinition:
	return (definition as BossDefinition).special_peg
