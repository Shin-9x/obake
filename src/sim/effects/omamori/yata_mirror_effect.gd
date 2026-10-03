@tool
class_name YataMirrorEffect
extends Effect
## Yata Mirror: the gold lantern multiplies the mult by more.
## Params: factor in permille, replacing the gold lantern's own.


func on_peg_hit(game: BoardGame, hit: PegHit) -> void:
	if hit.role == BoardGame.Role.GOLD:
		hit.mult_factor = param(&"factor")
		game.trigger(self)
