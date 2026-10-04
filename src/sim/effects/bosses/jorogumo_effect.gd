@tool
class_name JorogumoEffect
extends Effect
## Jorogumo: the layout's zones are webs that brake the ball, and pegs caught in a web score
## more points.
## Params: drag (speed lost per tick inside a web, permille), points_factor (permille).


func on_board_start(game: BoardGame) -> void:
	for zone: SimZone in game.simulation.zones:
		zone.drag = param(&"drag")


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	var peg: SimPeg = game.simulation.pegs[hit.peg]
	if game.simulation.zone_at(peg.x, peg.y) < 0:
		return
	hit.points_factor = FixedMath.div_round(
		hit.points_factor * param(&"points_factor"), FixedMath.PERMILLE
	)
	game.trigger(self)
