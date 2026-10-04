class_name MapGenerator
## Builds floor maps in the style of Slay the Spire, from the run's map stream.
##
## A floor has [member BalanceConfig.steps_per_floor] steps of two or three nodes, then one shop
## and the boss. The first step holds boards only; later steps draw their kinds by weight and
## never repeat a kind other than a board within a step. Links between steps never cross, every
## node has a way in and a way out, and no node leads to more than
## [member BalanceConfig.max_node_links] others.

## Attempts at drawing valid links before falling back to straight ones.
const LINK_ATTEMPTS: int = 16


static func generate(config: BalanceConfig, rng: Pcg32) -> FloorMap:
	var map: FloorMap = FloorMap.new()
	var span: int = config.max_nodes_per_step - config.min_nodes_per_step + 1
	for step: int in config.steps_per_floor:
		var count: int = config.min_nodes_per_step + rng.next_below(maxi(1, span))
		var used: Dictionary[MapNode.Kind, bool] = {}
		for lane: int in count:
			var kind: MapNode.Kind = MapNode.Kind.BOARD
			if step > 0:
				kind = _draw_kind(config.node_weights, used, rng)
			used[kind] = true
			map.add_node(MapNode.new(kind, step, lane))
	var shop: int = map.add_node(MapNode.new(MapNode.Kind.SHOP, config.steps_per_floor, 0))
	var boss: int = map.add_node(MapNode.new(MapNode.Kind.BOSS, config.steps_per_floor + 1, 0))
	for step: int in config.steps_per_floor - 1:
		_link(map, map.steps[step], map.steps[step + 1], config.max_node_links, rng)
	for node: int in map.steps[config.steps_per_floor - 1]:
		map.nodes[node].next.append(shop)
	map.nodes[shop].next.append(boss)
	return map


## Weighted draw among the kinds still allowed in the step; boards may repeat.
static func _draw_kind(
	weights: PackedInt32Array, used: Dictionary[MapNode.Kind, bool], rng: Pcg32
) -> MapNode.Kind:
	var allowed: PackedInt32Array = PackedInt32Array()
	allowed.resize(weights.size())
	var total: int = 0
	for kind: int in weights.size():
		var open: bool = kind == MapNode.Kind.BOARD or not used.has(kind as MapNode.Kind)
		allowed[kind] = weights[kind] if open else 0
		total += allowed[kind]
	if total <= 0:
		return MapNode.Kind.BOARD
	var roll: int = rng.next_below(total)
	for kind: int in allowed.size():
		roll -= allowed[kind]
		if roll < 0:
			return kind as MapNode.Kind
	return MapNode.Kind.BOARD


## Links two steps with a staircase walk: from the top lanes, each move goes down one lane on the
## left, on the right or on both, so links never cross.
static func _link(
	map: FloorMap, left: PackedInt32Array, right: PackedInt32Array, max_links: int, rng: Pcg32
) -> void:
	for attempt: int in LINK_ATTEMPTS:
		var pairs: Array[Vector2i] = _walk(left.size(), right.size(), rng)
		if _fits(pairs, left.size(), max_links):
			for pair: Vector2i in pairs:
				map.nodes[left[pair.x]].next.append(right[pair.y])
			return
	for lane: int in left.size():
		map.nodes[left[lane]].next.append(right[mini(lane, right.size() - 1)])
	for lane: int in range(left.size(), right.size()):
		map.nodes[left[left.size() - 1]].next.append(right[lane])


static func _walk(left: int, right: int, rng: Pcg32) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = [Vector2i.ZERO]
	var i: int = 0
	var j: int = 0
	while i < left - 1 or j < right - 1:
		var moves: Array[Vector2i] = []
		if i < left - 1:
			moves.append(Vector2i(1, 0))
		if j < right - 1:
			moves.append(Vector2i(0, 1))
		if i < left - 1 and j < right - 1:
			moves.append(Vector2i(1, 1))
		var move: Vector2i = moves[rng.next_below(moves.size())]
		i += move.x
		j += move.y
		pairs.append(Vector2i(i, j))
	return pairs


static func _fits(pairs: Array[Vector2i], left: int, max_links: int) -> bool:
	var links: PackedInt32Array = PackedInt32Array()
	links.resize(left)
	for pair: Vector2i in pairs:
		links[pair.x] += 1
		if links[pair.x] > max_links:
			return false
	return true
