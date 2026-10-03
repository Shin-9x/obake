@tool
class_name OnibiEffect
extends Effect
## Onibi ball: every peg it touches sets fire to its nearest neighbours, which are hit a moment
## later. Pegs hit by fire do not spread it further.
## Level value: neighbours set on fire. Params: radius in milli-pixels, delay in ticks.


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if hit.source != PegHit.Source.BALL:
		return
	game.burn_neighbours(hit.peg, value(), param(&"radius"), param(&"delay"))
	game.trigger(self)
