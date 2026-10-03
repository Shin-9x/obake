@tool
class_name ExplosiveLanternEffect
extends Effect
## Explosive lantern: when hit, hits every peg around it.
## Params: radius in milli-pixels.


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	var where: SimPeg = game.simulation.pegs[hit.peg]
	game.hit_pegs_near(where.x, where.y, param(&"radius"), PegHit.Source.AREA)
	game.trigger(self)
