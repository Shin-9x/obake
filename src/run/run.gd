class_name Run
## A whole run as a state machine. On each floor the player picks nodes on the map: boards lead
## to rewards, shops and shrines change the inventory, events offer choices. Beating a boss moves
## on to the next floor; beating the last one wins the run, and losing any board ends it.
##
## Presentation calls the action of the current [member phase] and reads the state back. Every
## action that succeeds is written to the [member run_log], and every random draw comes from the
## run's own streams, so the log replays the run. Whenever the run is back on the map the state is
## snapshotted, so a saved run resumes by replaying only what came after.

## An action succeeded and was written to the log.
signal action_recorded

enum Phase { MAP, BOARD, REWARD, SHOP, SHRINE, EVENT, VICTORY, DEFEAT }

const SAVE_FORMAT: int = 1

var phase: Phase = Phase.MAP
var state: RunState
var config: BalanceConfig
var content: RunContent
var library: LayoutLibrary
var run_log: RunLog
## Board of the current or last board node, and the game being played on it.
var board: BoardSpec
var placed: PlacedBoard
var game: BoardGame
## Mon paid by the last won board.
var payout: Payout
## Choices left after a won board: balls first, then omamori.
var ball_choices: Array[BallDefinition] = []
var omamori_choices: Array[OmamoriDefinition] = []
var shop: Shop
var event: RunEvent
## What the last event choice did; null until the player chooses.
var event_outcome: EventOutcome
## Items and bosses met in this run, by id, for the compendium.
var seen: Dictionary[StringName, bool] = {}
## State when the run was last on the map, and how many logged actions came before it.
var snapshot: Dictionary[String, Variant] = {}
var snapshot_at: int = 0

var _base_pegs: BasePegs


static func start(
	run_config: BalanceConfig,
	run_content: RunContent,
	layouts: LayoutLibrary,
	base_pegs: BasePegs,
	character: CharacterDefinition,
	seed_value: int,
	options: RunOptions = null
) -> Run:
	var used: RunOptions = options if options != null else RunOptions.new()
	var run: Run = _create(run_config, used.filter(run_content), layouts, base_pegs)
	run.state = RunState.start(run_config, character, seed_value)
	if used.hard:
		run.state.shot_delta += run_config.hard_shot_delta
	run.run_log = RunLog.new(seed_value, character.id, used)
	run._see(character.starting_balls)
	run._snapshot()
	return run


## Rebuilds a run saved with [method to_save]: the last snapshot, then the actions after it.
## Returns null when the save cannot be read.
static func resume(
	save: Dictionary,
	run_config: BalanceConfig,
	run_content: RunContent,
	layouts: LayoutLibrary,
	base_pegs: BasePegs
) -> Run:
	if int(save.get("format", 0)) != SAVE_FORMAT or not save.get("run_log") is Dictionary:
		return null
	var saved: RunLog = RunLog.from_dictionary(save["run_log"])
	var data: Variant = save.get("snapshot")
	if saved == null or not data is Dictionary:
		return null
	var run: Run = _create(run_config, saved.options.filter(run_content), layouts, base_pegs)
	run.state = RunCodec.decode(data, run_config, ItemCatalog.new(run_content))
	if run.state == null:
		return null
	var start: int = clampi(int(save.get("snapshot_at", 0)), 0, saved.size())
	run.run_log = RunLog.new(saved.run_seed, saved.character, saved.options)
	for id: Variant in save.get("seen", []):
		run.seen[StringName(str(id))] = true
	run.run_log.actions = saved.actions.slice(0, start)
	run._snapshot()
	for action: PackedInt32Array in saved.actions.slice(start):
		if not RunReplay.apply(run, action):
			return null
	return run


## Everything needed to resume this run later.
func to_save() -> Dictionary[String, Variant]:
	return {
		"format": SAVE_FORMAT,
		"run_log": run_log.to_dictionary(),
		"snapshot": snapshot,
		"snapshot_at": snapshot_at,
		"seen": seen.keys().map(func(id: StringName) -> String: return String(id)),
	}


func is_over() -> bool:
	return phase == Phase.VICTORY or phase == Phase.DEFEAT


## Nodes the player may pick next on the map.
func reachable_nodes() -> PackedInt32Array:
	if phase != Phase.MAP:
		return PackedInt32Array()
	return state.current_map().choices_from(state.node)


func choose_node(node: int) -> bool:
	if not reachable_nodes().has(node):
		return false
	state.node = node
	var kind: MapNode.Kind = state.current_node().kind
	match kind:
		MapNode.Kind.SHOP:
			shop = Shop.new(state, content, config)
			_see_offers()
			phase = Phase.SHOP
		MapNode.Kind.SHRINE:
			phase = Phase.SHRINE
		MapNode.Kind.EVENT:
			var definition: EventDefinition = RunEvent.draw(state, content)
			if definition != null:
				event = RunEvent.create(definition)
				event_outcome = null
				phase = Phase.EVENT
		_:
			board = _prepare_board(kind)
			if board.rules.boss != null:
				seen[board.rules.boss.id] = true
			placed = board.create(config, _base_pegs, state.inventory, state.carry)
			game = placed.game
			phase = Phase.BOARD
	_did(RunLog.Action.CHOOSE_NODE, node)
	return true


func current_boss() -> BossDefinition:
	return content.floor_bosses[state.floor_index]


## Fires the next shot of the board; [param clock] is the board clock when the player shot.
func shoot(aim: int, clock: int) -> bool:
	if phase != Phase.BOARD or not game.shoot(ShotInput.new(aim, clock)):
		return false
	_did(RunLog.Action.SHOOT, aim, clock)
	return true


## Settles the board once it is over: a loss ends the run, a win pays and offers rewards.
func finish_board() -> bool:
	if phase != Phase.BOARD or game.outcome == BoardGame.Outcome.PLAYING:
		return false
	var result: BoardResult = game.result
	state.boards_played += 1
	state.best_shot = maxi(state.best_shot, result.best_shot)
	payout = Payout.settle(config, result, board.kind, state.mon)
	if state.bet > 0:
		if result.outcome == BoardGame.Outcome.MATSURI:
			payout.wager = state.bet
		state.bet = 0
	state.mon += payout.total()
	ball_choices.clear()
	omamori_choices.clear()
	if result.outcome == BoardGame.Outcome.FAILED:
		phase = Phase.DEFEAT
	else:
		state.boards_won += 1
		if result.outcome == BoardGame.Outcome.MATSURI:
			state.matsuri_count += 1
		_offer_rewards()
	_did(RunLog.Action.FINISH_BOARD)
	return true


func take_ball(index: int) -> bool:
	if phase != Phase.REWARD or index < 0 or index >= ball_choices.size():
		return false
	state.inventory.add_ball(ball_choices[index])
	ball_choices.clear()
	_after_reward()
	_did(RunLog.Action.TAKE_BALL, index)
	return true


func skip_ball() -> bool:
	if phase != Phase.REWARD or ball_choices.is_empty():
		return false
	state.mon += config.skip_reward_mon
	ball_choices.clear()
	_after_reward()
	_did(RunLog.Action.SKIP_BALL)
	return true


## Takes omamori [param index] into a free slot, or in place of the one in [param replace_slot]
## when every slot is taken.
func take_omamori(index: int, replace_slot: int = -1) -> bool:
	if phase != Phase.REWARD or not ball_choices.is_empty():
		return false
	if index < 0 or index >= omamori_choices.size():
		return false
	var charm: OmamoriDefinition = omamori_choices[index]
	if not state.inventory.add_omamori(charm):
		if replace_slot < 0 or replace_slot >= state.inventory.omamori_count():
			return false
		state.inventory.replace_omamori(replace_slot, charm)
	omamori_choices.clear()
	_after_reward()
	_did(RunLog.Action.TAKE_OMAMORI, index, replace_slot)
	return true


func skip_omamori() -> bool:
	if phase != Phase.REWARD or not ball_choices.is_empty() or omamori_choices.is_empty():
		return false
	omamori_choices.clear()
	_after_reward()
	_did(RunLog.Action.SKIP_OMAMORI)
	return true


func buy_ball(index: int) -> bool:
	return phase == Phase.SHOP and _shop_did(shop.buy_ball(index), RunLog.Action.BUY_BALL, index)


func buy_omamori(index: int) -> bool:
	return (
		phase == Phase.SHOP and _shop_did(shop.buy_omamori(index), RunLog.Action.BUY_OMAMORI, index)
	)


func buy_peg(index: int) -> bool:
	return phase == Phase.SHOP and _shop_did(shop.buy_peg(index), RunLog.Action.BUY_PEG, index)


func reroll() -> bool:
	if phase != Phase.SHOP or not shop.reroll():
		return false
	_see_offers()
	_did(RunLog.Action.REROLL)
	return true


func upgrade_ball(index: int) -> bool:
	return (
		phase == Phase.SHOP
		and _shop_did(shop.upgrade_ball(index), RunLog.Action.UPGRADE_BALL, index)
	)


func sell_omamori(slot: int) -> bool:
	if phase != Phase.SHOP or slot < 0 or slot >= state.inventory.omamori_count():
		return false
	shop.sell_omamori(slot)
	_did(RunLog.Action.SELL_OMAMORI, slot)
	return true


func leave_shop() -> bool:
	if phase != Phase.SHOP:
		return false
	shop = null
	phase = Phase.MAP
	_did(RunLog.Action.LEAVE_SHOP)
	return true


func shrine_remove(index: int) -> bool:
	if phase != Phase.SHRINE or not state.inventory.remove_ball(index):
		return false
	phase = Phase.MAP
	_did(RunLog.Action.SHRINE_REMOVE, index)
	return true


func shrine_upgrade(index: int) -> bool:
	if phase != Phase.SHRINE or not state.inventory.upgrade_ball(index):
		return false
	phase = Phase.MAP
	_did(RunLog.Action.SHRINE_UPGRADE, index)
	return true


func leave_shrine() -> bool:
	if phase != Phase.SHRINE:
		return false
	phase = Phase.MAP
	_did(RunLog.Action.LEAVE_SHRINE)
	return true


## Applies event option [param index]; the event stays on screen until [method finish_event].
func choose_event(index: int, pick: int = -1) -> EventOutcome:
	if phase != Phase.EVENT or event_outcome != null:
		return null
	event_outcome = event.choose(state, content, config, index, pick)
	if event_outcome != null:
		if event_outcome.item != null:
			seen[event_outcome.item.id] = true
		_did(RunLog.Action.CHOOSE_EVENT, index, pick)
	return event_outcome


func finish_event() -> bool:
	if phase != Phase.EVENT or event_outcome == null:
		return false
	event = null
	phase = Phase.MAP
	_did(RunLog.Action.FINISH_EVENT)
	return true


static func _create(
	run_config: BalanceConfig, run_content: RunContent, layouts: LayoutLibrary, base_pegs: BasePegs
) -> Run:
	var run: Run = Run.new()
	run.config = run_config
	run.content = run_content
	run.library = layouts
	run._base_pegs = base_pegs
	return run


func _did(action: RunLog.Action, first: int = -1, second: int = -1) -> void:
	run_log.record(action, first, second)
	if phase == Phase.MAP:
		_snapshot()
	action_recorded.emit()


func _shop_did(succeeded: bool, action: RunLog.Action, index: int) -> bool:
	if succeeded:
		_did(action, index)
	return succeeded


func _see(items: Array) -> void:
	for item: ItemDefinition in items:
		seen[item.id] = true


func _see_offers() -> void:
	for row: Array[Offer] in [shop.balls, shop.omamori, shop.pegs]:
		for offer: Offer in row:
			seen[offer.item.id] = true


func _snapshot() -> void:
	snapshot = RunCodec.encode(state)
	snapshot_at = run_log.size()


func _offer_rewards() -> void:
	match board.kind:
		MapNode.Kind.BOSS:
			if state.floor_index == config.floors - 1:
				phase = Phase.VICTORY
				return
			omamori_choices = Rewards.omamori_choices(
				state, content, config, config.boss_omamori_weights
			)
		MapNode.Kind.ELITE:
			ball_choices = Rewards.ball_choices(state, content, config)
			omamori_choices = Rewards.omamori_choices(
				state, content, config, config.elite_omamori_weights
			)
		_:
			ball_choices = Rewards.ball_choices(state, content, config)
	_see(ball_choices)
	_see(omamori_choices)
	phase = Phase.REWARD
	_after_reward()


func _after_reward() -> void:
	if not ball_choices.is_empty() or not omamori_choices.is_empty():
		return
	if board.kind == MapNode.Kind.BOSS:
		state.floor_index += 1
		state.node = -1
		state.floor_layouts.clear()
	phase = Phase.MAP


## Layout, seed and rules of a board node, drawn from the run's board stream. Standard and
## elite boards never repeat a layout already played on the floor while others are left.
func _prepare_board(kind: MapNode.Kind) -> BoardSpec:
	var spec: BoardSpec = BoardSpec.new()
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.BOARD)
	spec.kind = kind
	spec.board_seed = rng.next_u32()
	var boss: BossDefinition = null
	if kind == MapNode.Kind.BOSS:
		boss = current_boss()
		spec.layout = library.find(boss.layout_id)
		if not boss.second_layout_id.is_empty():
			spec.next_layer = library.find(boss.second_layout_id)
	else:
		var pool: Array[BoardLayout] = library.pool(content.floor_biomes[state.floor_index])
		var fresh: Array[BoardLayout] = []
		for layout: BoardLayout in pool:
			if not state.floor_layouts.has(layout.id):
				fresh.append(layout)
		if fresh.is_empty():
			fresh = pool
		spec.layout = fresh[rng.next_below(fresh.size())]
		state.floor_layouts.append(spec.layout.id)
	var target: int = TargetSchedule.target(config, kind, state.boards_played, run_log.options.hard)
	spec.rules = BoardRules.new(target, state.shot_delta, boss)
	return spec
