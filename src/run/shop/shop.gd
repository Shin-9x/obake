class_name Shop
## One shop visit: offers drawn from the run's shop stream, rerolls that grow dearer, sales and
## the ball upgrade service.
##
## Offers never repeat within a row. Omamori offers skip the ones already owned and the
## legendaries, which are never sold. Buying an omamori needs a free slot: the player sells one
## first to make room.

var balls: Array[Offer] = []
var omamori: Array[Offer] = []
var pegs: Array[Offer] = []
var rerolls: int = 0

var _state: RunState
var _content: RunContent
var _config: BalanceConfig


func _init(state: RunState, content: RunContent, config: BalanceConfig) -> void:
	_state = state
	_content = content
	_config = config
	_stock()


func reroll_price() -> int:
	return _config.reroll_price + rerolls * _config.reroll_increase


## Replaces every offer with fresh ones.
func reroll() -> bool:
	if not _state.spend(reroll_price()):
		return false
	rerolls += 1
	_stock()
	return true


func buy_ball(index: int) -> bool:
	if not _pay(balls, index):
		return false
	_state.inventory.add_ball(balls[index].item as BallDefinition)
	return true


func buy_omamori(index: int) -> bool:
	if _state.inventory.free_slots() == 0 or not _pay(omamori, index):
		return false
	_state.inventory.add_omamori(omamori[index].item as OmamoriDefinition)
	return true


func buy_peg(index: int) -> bool:
	if not _pay(pegs, index):
		return false
	_state.inventory.add_peg(pegs[index].item as PegDefinition)
	return true


## Price of taking the ball at [param ball_index] up one level, or -1 when it is at its top.
func upgrade_price(ball_index: int) -> int:
	if not _state.inventory.can_upgrade_ball(ball_index):
		return -1
	var level: int = _state.inventory.level_of(ball_index)
	var prices: PackedInt32Array = _config.upgrade_prices
	return prices[clampi(level - 1, 0, prices.size() - 1)]


func upgrade_ball(ball_index: int) -> bool:
	var price: int = upgrade_price(ball_index)
	if price < 0 or not _state.spend(price):
		return false
	return _state.inventory.upgrade_ball(ball_index)


func sell_price(slot: int) -> int:
	var charm: OmamoriDefinition = _state.inventory.loadout.omamori[slot]
	if charm.rarity == ItemDefinition.Rarity.LEGENDARY:
		return _config.legendary_sell_price
	return _price(charm, _config.omamori_prices) * _config.sell_permille / FixedMath.PERMILLE


## Sells the omamori in [param slot] and returns the mon it brought.
func sell_omamori(slot: int) -> int:
	var price: int = sell_price(slot)
	_state.inventory.remove_omamori(slot)
	_state.mon += price
	return price


func _pay(offers: Array[Offer], index: int) -> bool:
	if index < 0 or index >= offers.size() or offers[index].sold:
		return false
	if not _state.spend(offers[index].price):
		return false
	offers[index].sold = true
	return true


func _stock() -> void:
	var rng: Pcg32 = _state.streams.stream(RngStreams.Domain.SHOP)
	var extra: int = 0
	var character: CharacterDefinition = _state.inventory.loadout.character
	if character != null:
		extra = character.params.get(&"shop_extra_balls", 0)
	balls = _draw(_content.balls, _config.shop_balls + extra, _config.ball_prices, [], rng)
	var owned: Array[StringName] = []
	for charm: OmamoriDefinition in _state.inventory.loadout.omamori:
		owned.append(charm.id)
	omamori = _draw(_content.omamori, _config.shop_omamori, _config.omamori_prices, owned, rng)
	pegs = _draw(_content.pegs, _config.shop_pegs, _config.peg_prices, [], rng)


func _draw(
	pool: Array, count: int, prices: PackedInt32Array, excluded: Array[StringName], rng: Pcg32
) -> Array[Offer]:
	var sold: Array = []
	for item: ItemDefinition in pool:
		var rarity: int = item.rarity
		if rarity != ItemDefinition.Rarity.BASE and rarity != ItemDefinition.Rarity.LEGENDARY:
			sold.append(item)
	var taken: Array[StringName] = excluded.duplicate()
	var offers: Array[Offer] = []
	for slot: int in count:
		var rarity: int = RarityRoll.item_rarity(_config, _state.floor_index, rng)
		var item: ItemDefinition = RarityRoll.pick(sold, rarity, taken, rng)
		if item == null:
			break
		taken.append(item.id)
		offers.append(Offer.new(item, _price(item, prices)))
	return offers


static func _price(item: ItemDefinition, prices: PackedInt32Array) -> int:
	var tier: int = item.rarity - ItemDefinition.Rarity.COMMON
	return prices[clampi(tier, 0, prices.size() - 1)]
