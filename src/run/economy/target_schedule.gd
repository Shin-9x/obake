class_name TargetSchedule
## Score targets: the first board's, grown for every board played since; an elite board raises
## the standard target and a boss board grows the previous board's target by its boss's own
## factor. Hard mode raises every target.


## Target of a [param kind] board when [param boards_played] boards came before it; a boss board
## needs its [param boss].
static func target(
	config: BalanceConfig,
	kind: MapNode.Kind,
	boards_played: int,
	hard: bool = false,
	boss: BossDefinition = null
) -> int:
	var value: int = 0
	match kind:
		MapNode.Kind.ELITE:
			value = FixedMath.div_round(
				_standard(config, boards_played) * config.elite_target_factor, FixedMath.PERMILLE
			)
		MapNode.Kind.BOSS:
			value = FixedMath.div_round(
				_standard(config, maxi(0, boards_played - 1)) * boss.target_factor,
				FixedMath.PERMILLE
			)
		_:
			value = _standard(config, boards_played)
	if hard:
		value = FixedMath.div_round(value * config.hard_target_factor, FixedMath.PERMILLE)
	var step: int = maxi(1, config.target_rounding)
	return maxi(step, FixedMath.div_round(value, step) * step)


static func _standard(config: BalanceConfig, boards_played: int) -> int:
	var value: int = config.first_board_target
	for board: int in boards_played:
		value = FixedMath.div_round(value * config.board_target_growth, FixedMath.PERMILLE)
	return value
