class_name BalanceBot
extends RefCounted
## Plays a whole run headless for balancing, roughly as a careful player would. Each shot tries
## [member skill] aims spread across the launcher's range on copies of the run and keeps the one
## that scores most; with a skill of 1 it shoots at random. While a longer aim guide is on, as
## Yamabushi's power gives, it tries twice as many aims, as a player who sees more of the path
## plans better. In shops it fills its omamori slots,
## swaps its weakest omamori for a rarer one, buys a couple of balls, upgrades its best ball and
## rerolls when rich, always keeping some mon for interest; rewards go to the rarest item. The
## map and events follow its own random stream. It records the same lines as the game's run log,
## marked as played by a bot.

## Mon kept back when buying balls, pegs and upgrades, so interest keeps paying.
const RESERVE: int = 5
## Balls bought per shop visit; more would dilute the bag.
const BALLS_PER_SHOP: int = 2
## Mon above which the bot rerolls a shop, at most [constant MAX_REROLLS] times.
const REROLL_WEALTH: int = 20
const MAX_REROLLS: int = 2

var run: Run
var skill: int = 1
## Run log lines, in the order the game would write them.
var lines: Array[Dictionary] = []
## Board total the last chosen aim reached on its copy of the run; the real shot reaches the same,
## the simulation being deterministic. -1 before the first comparison.
var predicted_total: int = -1

var _base_pegs: BasePegs
var _record: RunRecord
var _rng: Pcg32


func _init(played: Run, base_pegs: BasePegs, aims: int, record: RunRecord, bot_seed: int) -> void:
	run = played
	_base_pegs = base_pegs
	skill = maxi(1, aims)
	_record = record
	_rng = Pcg32.new(bot_seed, 0)


## Plays until the run ends, or until [param max_boards] boards are settled.
func play(max_boards: int = 1_000) -> void:
	while not run.is_over() and run.state.boards_played < max_boards:
		_act()


func _act() -> void:
	match run.phase:
		Run.Phase.MAP:
			var nodes: PackedInt32Array = run.reachable_nodes()
			run.choose_node(nodes[_rng.next_below(nodes.size())])
		Run.Phase.BOARD:
			_play_board()
		Run.Phase.REWARD:
			_take_reward()
		Run.Phase.SHOP:
			_shop()
		Run.Phase.SHRINE:
			_visit_shrine()
		Run.Phase.EVENT:
			_meet_event()


func _play_board() -> void:
	var game: BoardGame = run.game
	while game.can_shoot():
		run.shoot(_best_aim(), game.simulation.clock)
		RunReplay.play_out(game)
	run.finish_board()
	lines.append(_record.board(run))
	if run.is_over():
		lines.append(_record.ending(run))


## The aim, among [member skill] tried on copies of the run, after which the board total is
## highest; one aim from each equal slice of the range, at a random point within it.
func _best_aim() -> int:
	var limit: int = run.config.aim_limit
	var tries: int = skill * (2 if run.game.guide_contacts() > 1 else 1)
	var slice: int = (2 * limit + 1) / tries
	if tries == 1:
		return _rng.next_below(2 * limit + 1) - limit
	var save: Dictionary[String, Variant] = run.to_save()
	var best_aim: int = 0
	var best_total: int = -1
	for index: int in tries:
		var aim: int = -limit + index * slice + _rng.next_below(slice)
		var copy: Run = Run.resume(save, run.config, run.content, run.library, _base_pegs)
		copy.shoot(aim, copy.game.simulation.clock)
		RunReplay.play_out(copy.game)
		if copy.game.total > best_total:
			best_total = copy.game.total
			best_aim = aim
	predicted_total = best_total
	return best_aim


func _take_reward() -> void:
	if not run.ball_choices.is_empty():
		run.take_ball(_rarest(run.ball_choices))
		return
	var charm: int = _rarest(run.omamori_choices)
	if run.take_omamori(charm):
		return
	var weakest: int = _weakest_slot()
	if run.omamori_choices[charm].rarity > _owned_rarity(weakest):
		run.take_omamori(charm, weakest)
	else:
		run.skip_omamori()


func _shop() -> void:
	_buy()
	while run.shop.rerolls < MAX_REROLLS and run.state.mon >= REROLL_WEALTH:
		if not run.reroll():
			break
		_buy()
	run.leave_shop()


func _buy() -> void:
	var shop: Shop = run.shop
	var inventory: Inventory = run.state.inventory
	while inventory.free_slots() > 0:
		var charm: int = _rarest_affordable(shop.omamori, 0)
		if charm < 0 or not run.buy_omamori(charm):
			break
	var offered: int = _rarest_affordable(shop.omamori, 0)
	if inventory.free_slots() == 0 and offered >= 0 and inventory.omamori_count() > 0:
		var weakest: int = _weakest_slot()
		if shop.omamori[offered].item.rarity > _owned_rarity(weakest):
			run.sell_omamori(weakest)
			run.buy_omamori(_rarest_affordable(shop.omamori, 0))
	for bought: int in BALLS_PER_SHOP:
		var ball: int = _rarest_affordable(shop.balls, RESERVE)
		if ball < 0 or not run.buy_ball(ball):
			break
	var peg: int = _rarest_affordable(shop.pegs, RESERVE)
	if peg >= 0:
		run.buy_peg(peg)
	while true:
		var best: int = _best_upgradable()
		if best < 0 or run.state.mon - shop.upgrade_price(best) < RESERVE:
			break
		if not run.upgrade_ball(best):
			break


func _visit_shrine() -> void:
	var inventory: Inventory = run.state.inventory
	var best: int = _best_upgradable()
	if best >= 0:
		run.shrine_upgrade(best)
		return
	for index: int in inventory.ball_count():
		if (
			inventory.ball(index).rarity == ItemDefinition.Rarity.BASE
			and inventory.can_remove_ball()
		):
			run.shrine_remove(index)
			return
	run.leave_shrine()


func _meet_event() -> void:
	var choices: Array[EventChoice] = run.event.choices(run.state)
	var open: PackedInt32Array = PackedInt32Array()
	for index: int in choices.size():
		if choices[index].enabled:
			open.append(index)
	if not open.is_empty():
		var choice: int = open[_rng.next_below(open.size())]
		var options: PackedInt32Array = choices[choice].options
		var pick: int = -1 if options.is_empty() else options[_rng.next_below(options.size())]
		run.choose_event(choice, pick)
	run.finish_event()


## The rarest item; ties go to the first.
static func _rarest(items: Array) -> int:
	var best: int = 0
	for index: int in items.size():
		if (items[index] as ItemDefinition).rarity > (items[best] as ItemDefinition).rarity:
			best = index
	return best


## The rarest unsold offer the run can pay for while keeping [param reserve] mon, or -1.
func _rarest_affordable(offers: Array[Offer], reserve: int) -> int:
	var best: int = -1
	for index: int in offers.size():
		var offer: Offer = offers[index]
		if offer.sold or run.state.mon - offer.price < reserve:
			continue
		if best < 0 or offer.item.rarity > offers[best].item.rarity:
			best = index
	return best


## The rarest ball that can still go up a level, leaving out the basic ones; -1 when none.
func _best_upgradable() -> int:
	var inventory: Inventory = run.state.inventory
	var best: int = -1
	for index: int in inventory.upgradable_balls():
		var rarity: ItemDefinition.Rarity = inventory.ball(index).rarity
		if (
			rarity > ItemDefinition.Rarity.BASE
			and (best < 0 or rarity > inventory.ball(best).rarity)
		):
			best = index
	return best


func _weakest_slot() -> int:
	var charms: Array[OmamoriDefinition] = run.state.inventory.loadout.omamori
	var weakest: int = 0
	for slot: int in charms.size():
		if charms[slot].rarity < charms[weakest].rarity:
			weakest = slot
	return weakest


func _owned_rarity(slot: int) -> ItemDefinition.Rarity:
	return run.state.inventory.loadout.omamori[slot].rarity
