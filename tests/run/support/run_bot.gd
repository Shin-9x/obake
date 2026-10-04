extends RefCounted
## Plays a run headless with simple, fixed habits: the first reachable node, the first reward,
## the first affordable ball in a shop, an upgrade at shrines, the first open event option, and
## shots aimed by its own random stream. Keeps a hash chain of what happened for golden tests.

const HASH_MODULUS: int = 2_147_483_647
const HASH_MULTIPLIER: int = 1_000_003

var run: Run
var chain: int = 0

var _aims: Pcg32


func _init(played: Run, aim_seed: int) -> void:
	run = played
	_aims = Pcg32.new(aim_seed, 0)


## Plays until the run is won or lost, or the player reaches floor [param last_floor].
func play(last_floor: int = 1_000) -> void:
	var actions: int = 0
	while run.phase != Run.Phase.VICTORY and run.phase != Run.Phase.DEFEAT:
		if run.state.floor_index >= last_floor or actions > 10_000:
			return
		act()
		actions += 1


func act() -> void:
	match run.phase:
		Run.Phase.MAP:
			run.choose_node(run.reachable_nodes()[0])
		Run.Phase.BOARD:
			_play_board()
		Run.Phase.REWARD:
			if not run.ball_choices.is_empty():
				run.take_ball(0)
			elif not run.take_omamori(0):
				run.take_omamori(0, 0)
		Run.Phase.SHOP:
			for index: int in run.shop.balls.size():
				if run.buy_ball(index):
					break
			run.leave_shop()
		Run.Phase.SHRINE:
			var upgradable: PackedInt32Array = run.state.inventory.upgradable_balls()
			if upgradable.is_empty():
				run.leave_shrine()
			else:
				run.shrine_upgrade(upgradable[0])
		Run.Phase.EVENT:
			_meet_event()
	_mix(run.phase)
	_mix(run.state.mon)


func _play_board() -> void:
	var game: BoardGame = run.game
	var limit: int = run.config.aim_limit
	while game.can_shoot():
		var aim: int = _aims.next_below(2 * limit + 1) - limit
		run.shoot(aim, game.simulation.clock)
		RunReplay.play_out(game)
	_mix(game.total)
	run.finish_board()


func _meet_event() -> void:
	var choices: Array[EventChoice] = run.event.choices(run.state)
	for index: int in choices.size():
		if choices[index].enabled:
			var pick: int = (
				choices[index].options[0] if not choices[index].options.is_empty() else -1
			)
			run.choose_event(index, pick)
			break
	run.finish_event()


func _mix(value: int) -> void:
	chain = (chain * HASH_MULTIPLIER + value) % HASH_MODULUS
