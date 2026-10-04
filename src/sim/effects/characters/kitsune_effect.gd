@tool
class_name KitsuneEffect
extends Effect
## Kitsune. Power: blue lanterns turn into kitsunebi, the definition's power peg. Passive: red
## lanterns also give points.
## Params: count (lanterns turned), red_points.


func on_peg_hit(_game: BoardGame, hit: PegHit) -> void:
	if hit.role == BoardGame.Role.RED:
		hit.bonus_points += param(&"red_points")


func on_power(game: BoardGame, _hit: PegHit) -> void:
	var peg: PegDefinition = (definition as CharacterDefinition).power_peg
	if game.transform_random(BoardGame.Role.BLUE, param(&"count"), peg) > 0:
		game.trigger(self)
