extends Effect
## A peg effect that sets off an explosion around its own peg, like the Explosive lantern.

## Reaches pegs 40 px away: 36 px plus their 5 px radius.
const RADIUS: int = 36_000


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	var where: SimPeg = game.simulation.pegs[hit.peg]
	game.hit_pegs_near(where.x, where.y, RADIUS, PegHit.Source.AREA)
