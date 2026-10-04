extends GdUnitTestSuite
## Floor maps: four choice steps of two or three nodes, a shop, then the boss, with links that
## never cross and always lead somewhere.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const SEEDS: int = 200


func test_floors_have_choice_steps_then_a_shop_and_the_boss() -> void:
	var config: BalanceConfig = Fixtures.config()
	for seed_value: int in SEEDS:
		var map: FloorMap = MapGenerator.generate(config, Pcg32.new(seed_value, 0))
		assert_int(map.steps.size()).is_equal(config.steps_per_floor + 2)
		for step: int in config.steps_per_floor:
			assert_int(map.steps[step].size()).is_between(2, 3)
		var shop: PackedInt32Array = map.steps[config.steps_per_floor]
		assert_int(shop.size()).is_equal(1)
		assert_int(map.nodes[shop[0]].kind).is_equal(MapNode.Kind.SHOP)
		assert_int(map.nodes[map.boss()].kind).is_equal(MapNode.Kind.BOSS)
		for node: int in map.steps[0]:
			assert_int(map.nodes[node].kind).is_equal(MapNode.Kind.BOARD)


func test_only_boards_repeat_within_a_step() -> void:
	var config: BalanceConfig = Fixtures.config()
	var kinds_seen: Dictionary[int, bool] = {}
	for seed_value: int in SEEDS:
		var map: FloorMap = MapGenerator.generate(config, Pcg32.new(seed_value, 0))
		for step: int in config.steps_per_floor:
			var seen: Dictionary[int, bool] = {}
			for node: int in map.steps[step]:
				var kind: int = map.nodes[node].kind
				kinds_seen[kind] = true
				assert_bool(kind != MapNode.Kind.BOARD and seen.has(kind)).is_false()
				seen[kind] = true
	for kind: int in [MapNode.Kind.ELITE, MapNode.Kind.EVENT, MapNode.Kind.SHRINE]:
		assert_bool(kinds_seen.has(kind)).is_true()


func test_links_lead_forward_without_crossing() -> void:
	var config: BalanceConfig = Fixtures.config()
	for seed_value: int in SEEDS:
		var map: FloorMap = MapGenerator.generate(config, Pcg32.new(seed_value, 0))
		var incoming: PackedInt32Array = PackedInt32Array()
		incoming.resize(map.nodes.size())
		for step: int in config.steps_per_floor + 1:
			var links: Array[Vector2i] = []
			for node: int in map.steps[step]:
				var from: MapNode = map.nodes[node]
				assert_int(from.next.size()).is_between(1, config.max_node_links)
				for target: int in from.next:
					assert_int(map.nodes[target].step).is_equal(step + 1)
					incoming[target] += 1
					links.append(Vector2i(from.lane, map.nodes[target].lane))
			for a: Vector2i in links:
				for b: Vector2i in links:
					(
						assert_bool(a.x < b.x and a.y > b.y)
						. override_failure_message("crossing")
						. is_false()
					)
		for node: int in map.nodes.size():
			if map.nodes[node].step > 0:
				assert_int(incoming[node]).is_greater(0)


func test_the_same_seed_draws_the_same_map() -> void:
	var config: BalanceConfig = Fixtures.config()
	assert_str(_describe(MapGenerator.generate(config, Pcg32.new(9, 0)))).is_equal(
		_describe(MapGenerator.generate(config, Pcg32.new(9, 0)))
	)
	var different: int = 0
	for seed_value: int in 10:
		var a: String = _describe(MapGenerator.generate(config, Pcg32.new(seed_value, 0)))
		var b: String = _describe(MapGenerator.generate(config, Pcg32.new(seed_value + 100, 0)))
		different += 1 if a != b else 0
	assert_int(different).is_greater(5)


func test_choices_start_on_the_first_step_and_follow_links() -> void:
	var map: FloorMap = MapGenerator.generate(Fixtures.config(), Pcg32.new(3, 0))
	assert_array(map.choices_from(-1)).is_equal(map.steps[0])
	var first: int = map.steps[0][0]
	assert_array(map.choices_from(first)).is_equal(map.nodes[first].next)


func _describe(map: FloorMap) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for node: MapNode in map.nodes:
		parts.append("%d:%d:%d>%s" % [node.kind, node.step, node.lane, str(node.next)])
	return ",".join(parts)
