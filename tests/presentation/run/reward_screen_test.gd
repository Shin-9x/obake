extends GdUnitTestSuite
## The reward screen: ball cards, skipping, then omamori after an elite, with replacement.

const Screens: GDScript = preload("res://tests/presentation/run/support.gd")
const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")

var _advanced: bool = false


func test_picking_a_ball_adds_it_and_leaves_the_rewards() -> void:
	var run: Run = Screens.run()
	Screens.win(run, MapNode.Kind.BOARD)
	var screen: RewardScreen = _open(run)
	var cards: Array[Node] = Screens.find_all(screen, ItemCard)
	assert_array(cards).has_size(3)
	var bag: int = run.state.inventory.ball_count()
	(cards[0] as ItemCard).pressed.emit()
	assert_int(run.state.inventory.ball_count()).is_equal(bag + 1)
	assert_bool(_advanced).is_true()


func test_an_elite_offers_omamori_after_the_ball_and_asks_what_to_replace() -> void:
	var run: Run = Screens.run()
	for id: String in ["chochin", "drum", "kaeru", "uchiwa", "patience"]:
		run.state.inventory.add_omamori(Fixtures.omamori(id))
	Screens.win(run, MapNode.Kind.ELITE)
	var screen: RewardScreen = _open(run)
	Screens.button(screen, tr("REWARD_SKIP") % 2).pressed.emit()
	await get_tree().process_frame
	var offered: Array[Node] = Screens.find_all(screen, ItemCard)
	var charm: OmamoriDefinition = (offered[0] as ItemCard).item as OmamoriDefinition
	(offered[0] as ItemCard).pressed.emit()
	await get_tree().process_frame
	var owned: Array[Node] = Screens.find_all(screen, ItemCard)
	assert_array(owned).has_size(5)
	(owned[2] as ItemCard).pressed.emit()
	assert_object(run.state.inventory.loadout.omamori[2]).is_same(charm)
	assert_bool(_advanced).is_true()


func _open(run: Run) -> RewardScreen:
	_advanced = false
	var screen: RewardScreen = auto_free(RewardScreen.new())
	add_child(screen)
	screen.advanced.connect(func() -> void: _advanced = true)
	screen.open(run)
	return screen
