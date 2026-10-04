extends GdUnitTestSuite
## The feats unlock twelve different items of the run content, with texts, and never a ball a
## character starts with.

const PROGRESSION: String = "res://data/progression.tres"


func test_twelve_feats_unlock_twelve_items_of_the_pools() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var content: RunContent = load("res://data/run_content.tres")
	var pooled: Dictionary[StringName, bool] = {}
	for items: Array in [content.balls, content.omamori, content.pegs]:
		for item: ItemDefinition in items:
			pooled[item.id] = true
	var unlocked: Dictionary[StringName, bool] = {}
	assert_array(definition.feats).has_size(12)
	for feat: FeatDefinition in definition.feats:
		assert_bool(pooled.has(feat.unlocks.id)).is_true()
		assert_bool(unlocked.has(feat.unlocks.id)).is_false()
		unlocked[feat.unlocks.id] = true
	for character: CharacterDefinition in content.characters:
		for ball: BallDefinition in character.starting_balls:
			assert_bool(unlocked.has(ball.id)).override_failure_message(String(ball.id)).is_false()


func test_feats_follow_the_gdd_and_have_texts() -> void:
	var definition: ProgressionDefinition = load(PROGRESSION)
	var texts: Dictionary[String, bool] = {}
	var file: FileAccess = FileAccess.open("res://locale/translations.csv", FileAccess.READ)
	while not file.eof_reached():
		texts[file.get_csv_line()[0]] = true
	var by_item: Dictionary[StringName, FeatDefinition] = {}
	for feat: FeatDefinition in definition.feats:
		by_item[feat.unlocks.id] = feat
		for key: String in [feat.name_key, feat.description_key]:
			assert_bool(texts.has(key)).override_failure_message(key).is_true()
	assert_int(by_item[&"splitter"].condition).is_equal(FeatDefinition.Condition.PEGS_IN_SHOT)
	assert_int(by_item[&"splitter"].threshold).is_equal(30)
	assert_int(by_item[&"kaeru"].threshold).is_equal(3)
	assert_int(by_item[&"hyotan"].condition).is_equal(FeatDefinition.Condition.ONE_SHOT_WIN)
	assert_int(by_item[&"onibi"].condition).is_equal(FeatDefinition.Condition.BOSS_WITHOUT_SPECIALS)
	assert_str(String(by_item[&"shuten_sake"].boss.id)).is_equal("shuten_doji")
