@tool
class_name EmaEffect
extends Effect
## Ema: each Matsuri makes blue lanterns worth more points for the rest of the run.
## Params: points added per Matsuri.


func on_board_end(game: BoardGame, result: BoardResult) -> void:
	if result.outcome == BoardGame.Outcome.MATSURI:
		game.carry.add_role_bonus(BoardGame.Role.BLUE, param(&"points"))
		game.trigger(self)
