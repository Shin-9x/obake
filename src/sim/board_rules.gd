@tool
class_name BoardRules
## What the run decides about a board beyond the player's loadout: the score target, the shots
## allowed and the boss. Without rules a board uses the first board's numbers from the config.

## Score to reach; 0 keeps [member BalanceConfig.first_board_target].
var target: int = 0
## Added to [member BalanceConfig.shots_per_board] before items change the shots.
var shot_delta: int = 0
## Null on boards without a boss.
var boss: BossDefinition


func _init(board_target: int = 0, shots: int = 0, board_boss: BossDefinition = null) -> void:
	target = board_target
	shot_delta = shots
	boss = board_boss
