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


func test_six_events_with_scripts_and_texts() -> void:
	var content: RunContent = load(CONTENT)
	var texts: Dictionary[String, bool] = {}
	var file: FileAccess = FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	while not file.eof_reached():
		texts[file.get_csv_line()[0]] = true
	assert_array(content.events).has_size(6)
	for event: EventDefinition in content.events:
		assert_bool(event.event_script.new() is RunEvent).is_true()
		for key: String in [event.title_key, event.text_key]:
			assert_bool(texts.has(key)).override_failure_message("missing %s" % key).is_true()
		var state: RunState = RunState.start(BalanceConfig.new(), content.characters[0], 1)
		for choice: EventChoice in RunEvent.create(event).choices(state):
			(
				assert_bool(texts.has(choice.text_key))
				. override_failure_message(choice.text_key)
				. is_true()
			)
