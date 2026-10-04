@tool
class_name YamabushiEffect
extends Effect
## Yamabushi. Power: the aim guide follows the ball further for the next shots. No passive.
## Params: shots, contacts (how far the extended guide reaches).


func on_power(game: BoardGame, _hit: PegHit) -> void:
	game.extend_guide(param(&"shots"), param(&"contacts"))
	game.trigger(self)
