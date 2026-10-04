class_name ShopScreen
extends Control
## A shop visit: balls, omamori and pegs for sale, the reroll, the upgrade service and omamori
## sales. Offers the player cannot pay for, or has no room for, are greyed out.

## The run has left the shop.
signal advanced

enum Mode { BUY, UPGRADE, SELL }

var _run: Run
var _bar: RunBar
var _body: VBoxContainer
var _mode: Mode = Mode.BUY


func open(run: Run) -> void:
	_run = run
	_mode = Mode.BUY
	if _body == null:
		var page: Control = UiKit.page(self)
		_bar = RunBar.new()
		_bar.position = Vector2(16, 8)
		page.add_child(_bar)
		_body = UiKit.body(page)
	_refresh()


func _refresh() -> void:
	if _run.phase != Run.Phase.SHOP:
		advanced.emit()
		return
	_bar.show_run(_run)
	UiKit.clear(_body)
	match _mode:
		Mode.UPGRADE:
			_show_upgrades()
		Mode.SELL:
			_show_sales()
		_:
			_show_offers()


func _show_offers() -> void:
	var shop: Shop = _run.shop
	_body.add_child(UiKit.label("SHOP_TITLE", UiKit.TITLE_SIZE))
	var first: HBoxContainer = UiKit.row(8)
	for index: int in shop.balls.size():
		first.add_child(_offer_card(shop.balls[index], true, _buy.bind(shop.buy_ball, index)))
	_body.add_child(first)
	var second: HBoxContainer = UiKit.row(8)
	var room: bool = _run.state.inventory.free_slots() > 0
	for index: int in shop.omamori.size():
		var card: ItemCard = _offer_card(
			shop.omamori[index], room, _buy.bind(shop.buy_omamori, index)
		)
		if not room:
			card.tooltip_text = tr("SHOP_NO_SLOT")
		second.add_child(card)
	for index: int in shop.pegs.size():
		second.add_child(_offer_card(shop.pegs[index], true, _buy.bind(shop.buy_peg, index)))
	_body.add_child(second)
	var services: HBoxContainer = UiKit.row(8)
	var reroll: Button = UiKit.button(tr("SHOP_REROLL") % shop.reroll_price(), false)
	reroll.disabled = not _run.state.can_afford(shop.reroll_price())
	reroll.pressed.connect(_reroll)
	services.add_child(reroll)
	var upgrade: Button = UiKit.button("SHOP_UPGRADE")
	upgrade.disabled = _run.state.inventory.upgradable_balls().is_empty()
	upgrade.pressed.connect(_set_mode.bind(Mode.UPGRADE))
	services.add_child(upgrade)
	var sell: Button = UiKit.button("SHOP_SELL")
	sell.disabled = _run.state.inventory.omamori_count() == 0
	sell.pressed.connect(_set_mode.bind(Mode.SELL))
	services.add_child(sell)
	var leave: Button = UiKit.button("SHOP_LEAVE")
	leave.pressed.connect(_leave)
	services.add_child(leave)
	_body.add_child(services)


func _show_upgrades() -> void:
	var prices: PackedInt32Array = _run.config.upgrade_prices
	_body.add_child(UiKit.label("SHOP_UPGRADE", UiKit.TITLE_SIZE))
	_body.add_child(
		UiKit.label(tr("SHOP_UPGRADE_PICK") % [prices[0], prices[1]], 0, UiKit.TEXT, false)
	)
	var affordable: PackedInt32Array = PackedInt32Array()
	for index: int in _run.state.inventory.upgradable_balls():
		if _run.state.can_afford(_run.shop.upgrade_price(index)):
			affordable.append(index)
	var bag: BagList = BagList.new()
	bag.show_bag(_run.state.inventory, affordable)
	bag.ball_picked.connect(_upgrade)
	_body.add_child(bag)
	_body.add_child(_back_button())


func _show_sales() -> void:
	_body.add_child(UiKit.label("SHOP_SELL", UiKit.TITLE_SIZE))
	_body.add_child(UiKit.label("SHOP_SELL_PICK"))
	var cards: HBoxContainer = UiKit.row(8)
	var owned: Array[OmamoriDefinition] = _run.state.inventory.loadout.omamori
	for slot: int in owned.size():
		var card: ItemCard = ItemCard.new()
		card.show_item(owned[slot], tr("SHOP_SELL_PRICE") % _run.shop.sell_price(slot))
		card.pressed.connect(_sell.bind(slot))
		cards.add_child(card)
	_body.add_child(cards)
	_body.add_child(_back_button())


func _offer_card(offer: Offer, room: bool, action: Callable) -> ItemCard:
	var card: ItemCard = ItemCard.new()
	var footer: String = tr("SHOP_SOLD") if offer.sold else tr("SHOP_PRICE") % offer.price
	card.show_item(offer.item, footer)
	card.set_available(not offer.sold and room and _run.state.can_afford(offer.price))
	card.pressed.connect(action)
	return card


func _back_button() -> Button:
	var back: Button = UiKit.button("BUTTON_BACK")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_set_mode.bind(Mode.BUY))
	return back


func _buy(purchase: Callable, index: int) -> void:
	purchase.call(index)
	_refresh()


func _reroll() -> void:
	_run.shop.reroll()
	_refresh()


func _upgrade(index: int) -> void:
	_run.shop.upgrade_ball(index)
	_mode = Mode.BUY
	_refresh()


func _sell(slot: int) -> void:
	_run.shop.sell_omamori(slot)
	_mode = Mode.BUY
	_refresh()


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_refresh()


func _leave() -> void:
	_run.leave_shop()
	_refresh()
