extends GdUnitTestSuite
## The shop screen: buying, greyed-out offers, upgrading and leaving.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")

var _advanced: bool = false


func test_buying_a_ball_spends_mon_and_marks_it_sold() -> void:
	var run: Run = Screens.run()
	Screens.enter(run, MapNode.Kind.SHOP)
	run.state.mon = 20
	var screen: ShopScreen = _open(run)
	var first: ItemCard = Screens.find_all(screen, ItemCard)[0] as ItemCard
	first.pressed.emit()
	await get_tree().process_frame
	assert_int(run.state.mon).is_equal(20 - run.shop.balls[0].price)
	var again: ItemCard = Screens.find_all(screen, ItemCard)[0] as ItemCard
	assert_bool(again.disabled).is_true()


func test_offers_out_of_reach_are_greyed_out() -> void:
	var run: Run = Screens.run()
	Screens.enter(run, MapNode.Kind.SHOP)
	run.state.mon = 0
	var screen: ShopScreen = _open(run)
	for card: Node in Screens.find_all(screen, ItemCard):
		assert_bool((card as ItemCard).disabled).is_true()


func test_the_upgrade_service_and_leaving() -> void:
	var run: Run = Screens.run("tanuki")
	Screens.enter(run, MapNode.Kind.SHOP)
	run.state.mon = 10
	var screen: ShopScreen = _open(run)
	Screens.button(screen, "SHOP_UPGRADE").pressed.emit()
	await get_tree().process_frame
	var bag: BagList = Screens.find_all(screen, BagList)[0] as BagList
	var zeni: int = run.state.inventory.ball_count() - 1
	bag.ball_picked.emit(zeni)
	assert_int(run.state.inventory.level_of(zeni)).is_equal(2)
	assert_int(run.state.mon).is_equal(5)
	await get_tree().process_frame
	Screens.button(screen, "SHOP_LEAVE").pressed.emit()
	assert_bool(_advanced).is_true()
	assert_int(run.phase).is_equal(Run.Phase.MAP)


func _open(run: Run) -> ShopScreen:
	_advanced = false
	var screen: ShopScreen = auto_free(ShopScreen.new())
	add_child(screen)
	screen.advanced.connect(func() -> void: _advanced = true)
	screen.open(run)
	return screen
