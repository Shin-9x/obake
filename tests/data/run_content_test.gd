extends GdUnitTestSuite
## The run content lists every MVP item once, a biome and a boss for each floor, and the three
## characters.

const CONTENT: String = "res://data/run_content.tres"


func test_floors_have_a_biome_with_layouts_and_a_boss() -> void:
	var content: RunContent = load(CONTENT)
	var config: BalanceConfig = load("res://data/balance.tres")
	var library: LayoutLibrary = LayoutLibrary.load_from()
	assert_int(content.floor_biomes.size()).is_equal(config.floors)
	assert_int(content.floor_bosses.size()).is_equal(config.floors)
	for biome: String in content.floor_biomes:
		assert_array(library.pool(biome)).is_not_empty()
	var bosses: Array[String] = []
	for boss: BossDefinition in content.floor_bosses:
		bosses.append(String(boss.id))
	assert_array(bosses).is_equal(["jorogumo", "nue", "tamamo", "shuten_doji"])


func test_item_pools_hold_every_collectable_item_once() -> void:
	var content: RunContent = load(CONTENT)
	assert_array(content.characters).has_size(3)
	for pool: Array in [content.balls, content.omamori, content.pegs]:
		var ids: Dictionary[StringName, bool] = {}
		for item: ItemDefinition in pool:
			assert_bool(ids.has(item.id)).is_false()
			ids[item.id] = true
			assert_int(item.rarity).is_not_equal(ItemDefinition.Rarity.BASE)
	assert_array(content.balls).has_size(9)
	assert_array(content.omamori).has_size(15)
	assert_array(content.pegs).has_size(6)
