extends GdUnitTestSuite
## The run inventory: bag with levels, omamori slots and purchased pegs.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


func test_the_bag_starts_with_the_character_balls() -> void:
	var inventory: Inventory = Inventory.new(Fixtures.config(), Fixtures.character("kitsune"))
	assert_int(inventory.ball_count()).is_equal(8)
	assert_str(String(inventory.ball(7).id)).is_equal("phantom")
	assert_int(inventory.level_of(7)).is_equal(1)
	assert_int(inventory.slots).is_equal(5)


func test_removing_a_ball_keeps_levels_aligned_and_never_empties_the_bag() -> void:
	var inventory: Inventory = Inventory.new(Fixtures.config())
	inventory.add_ball(Fixtures.ball("heavy"), 2)
	inventory.add_ball(Fixtures.ball("taiko"), 3)
	assert_bool(inventory.remove_ball(0)).is_true()
	assert_str(String(inventory.ball(0).id)).is_equal("taiko")
	assert_int(inventory.level_of(0)).is_equal(3)
	assert_bool(inventory.can_remove_ball()).is_false()
	assert_bool(inventory.remove_ball(0)).is_false()


func test_balls_go_up_to_level_three_and_the_hitodama_has_no_levels() -> void:
	var inventory: Inventory = Inventory.new(Fixtures.config(), Fixtures.character("tanuki"))
	assert_bool(inventory.can_upgrade_ball(0)).is_false()
	var zeni: int = inventory.ball_count() - 1
	assert_array(inventory.upgradable_balls()).is_equal(PackedInt32Array([zeni]))
	assert_bool(inventory.upgrade_ball(zeni)).is_true()
	assert_bool(inventory.upgrade_ball(zeni)).is_true()
	assert_int(inventory.level_of(zeni)).is_equal(3)
	assert_bool(inventory.upgrade_ball(zeni)).is_false()


func test_omamori_fill_the_slots() -> void:
	var inventory: Inventory = Inventory.new(Fixtures.config())
	for id: String in ["chochin", "drum", "kaeru", "uchiwa", "patience"]:
		assert_bool(inventory.add_omamori(Fixtures.omamori(id))).is_true()
	assert_int(inventory.free_slots()).is_equal(0)
	assert_bool(inventory.add_omamori(Fixtures.omamori("ema"))).is_false()
	assert_bool(inventory.owns_omamori(Fixtures.omamori("drum"))).is_true()
	inventory.replace_omamori(1, Fixtures.omamori("ema"))
	assert_bool(inventory.owns_omamori(Fixtures.omamori("drum"))).is_false()
	assert_str(String(inventory.remove_omamori(0).id)).is_equal("chochin")
	assert_int(inventory.free_slots()).is_equal(1)
