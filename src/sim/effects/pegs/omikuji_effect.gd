@tool
class_name OmikujiEffect
extends Effect
## Omikuji: a fortune drawn from the board stream; points, mult, mon or nothing, equally likely.
## Params: points, mult (permille) and mon.

enum Fortune { POINTS, MULT, MON, NOTHING }


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	match game.random_below(Fortune.size()):
		Fortune.POINTS:
			hit.bonus_points += param(&"points")
		Fortune.MULT:
			hit.mult_add += param(&"mult")
		Fortune.MON:
			hit.mon += param(&"mon")
		_:
			return
	game.trigger(self)
