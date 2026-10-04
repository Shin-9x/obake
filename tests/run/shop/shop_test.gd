extends GdUnitTestSuite
## Shop offers, prices, rerolls, sales and the upgrade service.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_a_shop_offers_three_balls_two_omamori_and_two_pegs() -> void:
	for seed_value: int in 30:
		var shop: Shop = _shop(Fixtures.state("yamabushi", seed_value))
		assert_array(shop.balls).has_size(3)
		assert_array(shop.omamori).has_size(2)
		assert_array(shop.pegs).has_size(2)
		for row: Array[Offer] in [shop.balls, shop.omamori, shop.pegs]:
			var ids: Dictionary[StringName, bool] = {}
			for offer: Offer in row:
				assert_bool(ids.has(offer.item.id)).is_false()
				ids[offer.item.id] = true
				assert_int(offer.item.rarity).is_between(
					ItemDefinition.Rarity.COMMON, ItemDefinition.Rarity.RARE
				)


func test_the_tanuki_sees_one_more_ball() -> void:
	assert_array(_shop(Fixtures.state("tanuki")).balls).has_size(4)


func test_prices_follow_rarity() -> void:
	var expected: Dictionary[int, Array] = {
		ItemDefinition.Rarity.COMMON: [4, 5, 3],
		ItemDefinition.Rarity.UNCOMMON: [6, 7, 5],
		ItemDefinition.Rarity.RARE: [9, 10, 8],
	}
	for seed_value: int in 30:
		var shop: Shop = _shop(Fixtures.state("yamabushi", seed_value))
		for offer: Offer in shop.balls:
			assert_int(offer.price).is_equal(expected[offer.item.rarity][0])
		for offer: Offer in shop.omamori:
			assert_int(offer.price).is_equal(expected[offer.item.rarity][1])
		for offer: Offer in shop.pegs:
			assert_int(offer.price).is_equal(expected[offer.item.rarity][2])


func test_owned_omamori_are_not_offered() -> void:
	var state: RunState = Fixtures.state()
	var content: RunContent = Fixtures.content()
	for charm: OmamoriDefinition in content.omamori.slice(0, 5):
		state.inventory.add_omamori(charm)
	for attempt: int in 20:
		var shop: Shop = Shop.new(state, content, Fixtures.config())
		for offer: Offer in shop.omamori:
			assert_bool(state.inventory.owns_omamori(offer.item as OmamoriDefinition)).is_false()


func test_buying_takes_the_mon_and_adds_the_item_once() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 30
	var shop: Shop = _shop(state)
	var price: int = shop.balls[0].price
	var bag: int = state.inventory.ball_count()
	assert_bool(shop.buy_ball(0)).is_true()
	assert_int(state.mon).is_equal(30 - price)
	assert_int(state.inventory.ball_count()).is_equal(bag + 1)
	assert_bool(shop.buy_ball(0)).is_false()
	assert_bool(shop.buy_peg(0)).is_true()
	assert_int(state.inventory.loadout.purchased_pegs.size()).is_equal(1)
	assert_bool(shop.buy_omamori(0)).is_true()
	assert_int(state.inventory.omamori_count()).is_equal(1)


func test_buying_needs_enough_mon_and_a_free_slot() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 0
	var shop: Shop = _shop(state)
	assert_bool(shop.buy_ball(0)).is_false()
	state.mon = 100
	for id: String in ["chochin", "drum", "kaeru", "uchiwa", "patience"]:
		state.inventory.add_omamori(Fixtures.omamori(id))
	assert_bool(shop.buy_omamori(0)).is_false()
	assert_int(state.mon).is_equal(100)


func test_rerolls_cost_more_each_time_and_restock() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 12
	var shop: Shop = _shop(state)
	var before: String = _describe(shop)
	assert_int(shop.reroll_price()).is_equal(3)
	assert_bool(shop.reroll()).is_true()
	assert_int(shop.reroll_price()).is_equal(4)
	assert_bool(shop.reroll()).is_true()
	assert_int(state.mon).is_equal(5)
	assert_str(_describe(shop)).is_not_equal(before)
	assert_bool(shop.reroll()).is_true()
	assert_bool(shop.reroll()).is_false()


func test_rerolling_never_changes_the_other_streams() -> void:
	var rolled: RunState = Fixtures.state()
	var still: RunState = Fixtures.state()
	rolled.mon = 50
	var shop: Shop = _shop(rolled)
	for i: int in 4:
		shop.reroll()
	for domain: RngStreams.Domain in [RngStreams.Domain.BOARD, RngStreams.Domain.REWARDS]:
		assert_int(rolled.streams.stream(domain).next_u32()).is_equal(
			still.streams.stream(domain).next_u32()
		)


func test_omamori_sell_for_half_their_price() -> void:
	var state: RunState = Fixtures.state()
	state.inventory.add_omamori(Fixtures.omamori("maneki_neko"))
	state.inventory.add_omamori(Fixtures.omamori("shuten_sake"))
	var shop: Shop = _shop(state)
	assert_int(shop.sell_price(0)).is_equal(3)
	assert_int(shop.sell_price(1)).is_equal(5)
	assert_int(shop.sell_omamori(0)).is_equal(3)
	assert_int(state.mon).is_equal(7)
	assert_int(state.inventory.omamori_count()).is_equal(1)


func test_the_upgrade_service_charges_by_level() -> void:
	var state: RunState = Fixtures.state("tanuki")
	state.mon = 20
	var shop: Shop = _shop(state)
	var zeni: int = state.inventory.ball_count() - 1
	assert_int(shop.upgrade_price(0)).is_equal(-1)
	assert_int(shop.upgrade_price(zeni)).is_equal(5)
	assert_bool(shop.upgrade_ball(zeni)).is_true()
	assert_int(shop.upgrade_price(zeni)).is_equal(8)
	assert_bool(shop.upgrade_ball(zeni)).is_true()
	assert_int(state.mon).is_equal(7)
	assert_int(shop.upgrade_price(zeni)).is_equal(-1)


func _shop(state: RunState) -> Shop:
	return Shop.new(state, Fixtures.content(), Fixtures.config())


func _describe(shop: Shop) -> String:
	var ids: PackedStringArray = PackedStringArray()
	for row: Array[Offer] in [shop.balls, shop.omamori, shop.pegs]:
		for offer: Offer in row:
			ids.append(String(offer.item.id))
	return ",".join(ids)
