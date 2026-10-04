class_name RunReplay
## Plays logged actions on a run: shots are fired and simulated to their end at once, so a
## whole run or the tail of a save replays without presentation.

## Ticks after which a shot is given up as broken; the stuck-ball rule ends real shots long before.
const MAX_SHOT_TICKS: int = 120 * 60


## Replays [param run_log] on a new run and returns it, or null when an action does not apply.
static func replay(
	run_log: RunLog,
	config: BalanceConfig,
	content: RunContent,
	library: LayoutLibrary,
	base_pegs: BasePegs
) -> Run:
	var character: CharacterDefinition = (
		ItemCatalog.new(content).find(run_log.character) as CharacterDefinition
	)
	if character == null:
		return null
	var run: Run = Run.start(config, content, library, base_pegs, character, run_log.run_seed)
	for action: PackedInt32Array in run_log.actions:
		if not apply(run, action):
			return null
	return run


## Applies one logged action; false when it does not apply to the run as it is.
static func apply(run: Run, action: PackedInt32Array) -> bool:
	var first: int = action[1]
	var second: int = action[2]
	match action[0]:
		RunLog.Action.CHOOSE_NODE:
			return run.choose_node(first)
		RunLog.Action.SHOOT:
			if not run.shoot(first, second):
				return false
			play_out(run.game)
			return true
		RunLog.Action.FINISH_BOARD:
			return run.finish_board()
		RunLog.Action.TAKE_BALL:
			return run.take_ball(first)
		RunLog.Action.SKIP_BALL:
			return run.skip_ball()
		RunLog.Action.TAKE_OMAMORI:
			return run.take_omamori(first, second)
		RunLog.Action.SKIP_OMAMORI:
			return run.skip_omamori()
		RunLog.Action.BUY_BALL:
			return run.buy_ball(first)
		RunLog.Action.BUY_OMAMORI:
			return run.buy_omamori(first)
		RunLog.Action.BUY_PEG:
			return run.buy_peg(first)
		RunLog.Action.REROLL:
			return run.reroll()
		RunLog.Action.UPGRADE_BALL:
			return run.upgrade_ball(first)
		RunLog.Action.SELL_OMAMORI:
			return run.sell_omamori(first)
		RunLog.Action.LEAVE_SHOP:
			return run.leave_shop()
		RunLog.Action.SHRINE_REMOVE:
			return run.shrine_remove(first)
		RunLog.Action.SHRINE_UPGRADE:
			return run.shrine_upgrade(first)
		RunLog.Action.LEAVE_SHRINE:
			return run.leave_shrine()
		RunLog.Action.CHOOSE_EVENT:
			return run.choose_event(first, second) != null
		RunLog.Action.FINISH_EVENT:
			return run.finish_event()
	return false


## Simulates the shot in flight to its end.
static func play_out(game: BoardGame) -> void:
	var ticks: int = 0
	while game.simulation.is_shot_active() and ticks < MAX_SHOT_TICKS:
		game.step()
		game.events.clear()
		ticks += 1
