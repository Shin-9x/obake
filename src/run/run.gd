class_name Run
## A whole run as a state machine. On each floor the player picks nodes on the map: boards lead
## to rewards, shops and shrines change the inventory, events offer choices. Beating a boss moves
## on to the next floor; beating the last one wins the run, and losing any board ends it.
##
## Presentation calls the action of the current [member phase] and reads the state back; every
## random draw comes from the run's own streams, so the seed and the choices replay the run.

enum Phase { MAP, BOARD, REWARD, SHOP, SHRINE, EVENT, VICTORY, DEFEAT }

var phase: Phase = Phase.MAP
var state: RunState
var config: BalanceConfig
var content: RunContent
var library: LayoutLibrary
## Board of the current or last board node.
var board: BoardSpec
## Mon paid by the last won board.
var payout: Payout
## Choices left after a won board: balls first, then omamori.
var ball_choices: Array[BallDefinition] = []
var omamori_choices: Array[OmamoriDefinition] = []
var shop: Shop
var event: RunEvent
## What the last event choice did; null until the player chooses.
var event_outcome: EventOutcome


static func start(
	run_config: BalanceConfig,
	run_content: RunContent,
	layouts: LayoutLibrary,
	character: CharacterDefinition,
	seed_value: int
) -> Run:
	var run: Run = Run.new()
	run.config = run_config
	run.content = run_content
	run.library = layouts
	run.state = RunState.start(run_config, character, seed_value)
	return run


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
			phase = Phase.SHOP
		MapNode.Kind.SHRINE:
			phase = Phase.SHRINE
		MapNode.Kind.EVENT:
			var definition: EventDefinition = RunEvent.draw(state, content)
			if definition == null:
				return true
			event = RunEvent.create(definition)
			event_outcome = null
			phase = Phase.EVENT
		_:
			board = _prepare_board(kind)
			phase = Phase.BOARD
	return true


func current_boss() -> BossDefinition:
	return content.floor_bosses[state.floor_index]


## Settles the board just played: a loss ends the run, a win pays and offers rewards.
func finish_board(result: BoardResult) -> void:
	if phase != Phase.BOARD:
		return
	state.boards_played += 1
	state.best_shot = maxi(state.best_shot, result.best_shot)
	payout = Payout.settle(config, result, board.kind, state.mon)
	if state.bet > 0:
		if result.outcome == BoardGame.Outcome.MATSURI:
			payout.wager = state.bet
		state.bet = 0
	state.mon += payout.total()
	if result.outcome == BoardGame.Outcome.FAILED:
		phase = Phase.DEFEAT
		return
	state.boards_won += 1
	if result.outcome == BoardGame.Outcome.MATSURI:
		state.matsuri_count += 1
	ball_choices.clear()
	omamori_choices.clear()
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
	phase = Phase.REWARD
	_after_reward()


func take_ball(index: int) -> bool:
	if phase != Phase.REWARD or index < 0 or index >= ball_choices.size():
		return false
	state.inventory.add_ball(ball_choices[index])
	ball_choices.clear()
	_after_reward()
	return true


func skip_ball() -> void:
	if phase != Phase.REWARD or ball_choices.is_empty():
		return
	state.mon += config.skip_reward_mon
	ball_choices.clear()
	_after_reward()


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
	return true


func skip_omamori() -> void:
	if phase != Phase.REWARD or not ball_choices.is_empty():
		return
	omamori_choices.clear()
	_after_reward()


func leave_shop() -> void:
	if phase == Phase.SHOP:
		shop = null
		phase = Phase.MAP


func shrine_remove(index: int) -> bool:
	if phase != Phase.SHRINE or not state.inventory.remove_ball(index):
		return false
	phase = Phase.MAP
	return true


func shrine_upgrade(index: int) -> bool:
	if phase != Phase.SHRINE or not state.inventory.upgrade_ball(index):
		return false
	phase = Phase.MAP
	return true


func leave_shrine() -> void:
	if phase == Phase.SHRINE:
		phase = Phase.MAP


## Applies event option [param index]; the event stays on screen until [method finish_event].
func choose_event(index: int, pick: int = -1) -> EventOutcome:
	if phase != Phase.EVENT or event_outcome != null:
		return null
	event_outcome = event.choose(state, content, config, index, pick)
	return event_outcome


func finish_event() -> void:
	if phase == Phase.EVENT and event_outcome != null:
		event = null
		phase = Phase.MAP


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
	var target: int = TargetSchedule.target(config, kind, state.boards_played)
	spec.rules = BoardRules.new(target, state.shot_delta, boss)
	return spec
