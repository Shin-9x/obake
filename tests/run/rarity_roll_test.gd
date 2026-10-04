extends GdUnitTestSuite
## Rarity odds by floor and item picks that fall back when a rarity runs out.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const DRAWS: int = 20_000


func test_shop_odds_follow_the_gdd_and_rare_grows_with_the_floor() -> void:
	var config: BalanceConfig = Fixtures.config()
	var first: Dictionary[int, int] = _count(config, 0)
	assert_int(first[ItemDefinition.Rarity.COMMON] * 1000 / DRAWS).is_between(630, 670)
	assert_int(first[ItemDefinition.Rarity.UNCOMMON] * 1000 / DRAWS).is_between(260, 300)
	assert_int(first[ItemDefinition.Rarity.RARE] * 1000 / DRAWS).is_between(60, 80)
	var fourth: Dictionary[int, int] = _count(config, 3)
	assert_int(fourth[ItemDefinition.Rarity.RARE] * 1000 / DRAWS).is_between(95, 115)
	var far: Dictionary[int, int] = _count(config, 40)
	assert_int(far[ItemDefinition.Rarity.RARE] * 1000 / DRAWS).is_between(140, 160)


func test_weighted_rarity_follows_its_weights() -> void:
	var rng: Pcg32 = Pcg32.new(1, 0)
	var legendary: int = 0
	for i: int in DRAWS:
		var rarity: int = RarityRoll.weighted_rarity(PackedInt32Array([0, 0, 1, 1]), rng)
		assert_int(rarity).is_greater_equal(ItemDefinition.Rarity.RARE)
		legendary += 1 if rarity == ItemDefinition.Rarity.LEGENDARY else 0
	assert_int(legendary * 1000 / DRAWS).is_between(480, 520)


func test_picks_fall_back_to_nearby_rarities_and_skip_excluded_items() -> void:
	var pool: Array = [Fixtures.ball("heavy"), Fixtures.ball("onibi")]
	var rng: Pcg32 = Pcg32.new(2, 0)
	var picked: ItemDefinition = RarityRoll.pick(pool, ItemDefinition.Rarity.UNCOMMON, [], rng)
	assert_str(String(picked.id)).is_equal("heavy")
	picked = RarityRoll.pick(pool, ItemDefinition.Rarity.UNCOMMON, [&"heavy"], rng)
	assert_str(String(picked.id)).is_equal("onibi")
	(
		assert_object(RarityRoll.pick(pool, ItemDefinition.Rarity.RARE, [&"heavy", &"onibi"], rng))
		. is_null()
	)


func _count(config: BalanceConfig, floor_index: int) -> Dictionary[int, int]:
	var counts: Dictionary[int, int] = {
		ItemDefinition.Rarity.COMMON: 0,
		ItemDefinition.Rarity.UNCOMMON: 0,
		ItemDefinition.Rarity.RARE: 0,
	}
	var rng: Pcg32 = Pcg32.new(floor_index + 7, 0)
	for i: int in DRAWS:
		counts[RarityRoll.item_rarity(config, floor_index, rng)] += 1
	return counts
