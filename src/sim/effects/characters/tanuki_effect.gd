@tool
class_name TanukiEffect
extends Effect
## Tanuki. Power: blue lanterns turn into coin pegs, the definition's power peg. The passive
## lives in the run: the shop offers extra balls.
## Params: count (lanterns turned), shop_extra_balls (read by the shop).


func on_power(game: BoardGame, _hit: PegHit) -> void:
	var peg: PegDefinition = (definition as CharacterDefinition).power_peg
	if game.transform_random(BoardGame.Role.BLUE, param(&"count"), peg) > 0:
		game.trigger(self)
