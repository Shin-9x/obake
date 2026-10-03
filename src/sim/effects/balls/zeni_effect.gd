@tool
class_name ZeniEffect
extends Effect
## Zeni ball: pays mon for every so many pegs hit in its shot.
## Level value: pegs per payment. Params: mon per payment.

var _hits: int = 0


func on_shot_start(_game: BoardGame) -> void:
	_hits = 0


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	_hits += 1
	if _hits % value() == 0:
		hit.mon += param(&"mon")
		game.trigger(self)
