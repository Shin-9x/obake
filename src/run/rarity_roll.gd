class_name RarityRoll
## Rarity draws and item picks for shops, rewards and events.


## Rarity of a shop or reward ball or peg on [param floor_index]: rare odds grow with the floor,
## uncommon odds stay put and common takes the rest.
static func item_rarity(config: BalanceConfig, floor_index: int, rng: Pcg32) -> int:
	var table: PackedInt32Array = config.rare_permille_by_floor
	var rare: int = table[clampi(floor_index, 0, table.size() - 1)] if not table.is_empty() else 0
	var roll: int = rng.next_below(FixedMath.PERMILLE)
	if roll < rare:
		return ItemDefinition.Rarity.RARE
	if roll < rare + config.uncommon_permille:
		return ItemDefinition.Rarity.UNCOMMON
	return ItemDefinition.Rarity.COMMON


## Rarity drawn by [param weights], one per rarity from common up.
static func weighted_rarity(weights: PackedInt32Array, rng: Pcg32) -> int:
	var total: int = 0
	for weight: int in weights:
		total += weight
	var roll: int = rng.next_below(maxi(1, total))
	for index: int in weights.size():
		roll -= weights[index]
		if roll < 0:
			return ItemDefinition.Rarity.COMMON + index
	return ItemDefinition.Rarity.COMMON


## A random item of [param rarity] from [param pool] that is not in [param excluded] (by id).
## When none is left at that rarity, the nearest rarity below is tried, then the ones above.
## Returns null when nothing is left at all.
static func pick(
	pool: Array, rarity: int, excluded: Array[StringName], rng: Pcg32
) -> ItemDefinition:
	var order: PackedInt32Array = PackedInt32Array([rarity])
	for lower: int in range(rarity - 1, ItemDefinition.Rarity.BASE, -1):
		order.append(lower)
	for higher: int in range(rarity + 1, ItemDefinition.Rarity.LEGENDARY + 1):
		order.append(higher)
	for tier: int in order:
		var candidates: Array[ItemDefinition] = []
		for item: ItemDefinition in pool:
			if item.rarity == tier and not excluded.has(item.id):
				candidates.append(item)
		if not candidates.is_empty():
			return candidates[rng.next_below(candidates.size())]
	return null
