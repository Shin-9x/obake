class_name RunCodec
## Turns a [RunState] into JSON-friendly data and back. Items are stored by id and random
## streams by their 32-bit words; floor maps are not stored, since the seed draws them again.


static func encode(state: RunState) -> Dictionary[String, Variant]:
	var inventory: Inventory = state.inventory
	var balls: Array[Array] = []
	for index: int in inventory.ball_count():
		balls.append([String(inventory.ball(index).id), inventory.level_of(index)])
	var streams: Array[Array] = []
	for words: PackedInt64Array in state.streams.get_state():
		streams.append(Array(words))
	return {
		"seed": state.run_seed,
		"streams": streams,
		"character": String(inventory.loadout.character.id),
		"balls": balls,
		"omamori": _ids(inventory.loadout.omamori),
		"pegs": _ids(inventory.loadout.purchased_pegs),
		"slots": inventory.slots,
		"carry": Array(state.carry.role_bonus_points),
		"mon": state.mon,
		"shot_delta": state.shot_delta,
		"floor": state.floor_index,
		"node": state.node,
		"boards_played": state.boards_played,
		"floor_layouts": Array(state.floor_layouts),
		"bet": state.bet,
		"events_seen": _names(state.events_seen),
		"boards_won": state.boards_won,
		"matsuri": state.matsuri_count,
		"best_shot": state.best_shot,
	}


## Rebuilds the state written by [method encode]; null when an item is unknown.
static func decode(data: Dictionary, config: BalanceConfig, catalog: ItemCatalog) -> RunState:
	var character: CharacterDefinition = catalog.find(StringName(str(data["character"])))
	if character == null:
		return null
	var state: RunState = RunState.start(config, character, int(data["seed"]))
	var inventory: Inventory = Inventory.new(config, character)
	inventory.loadout.balls.clear()
	inventory.loadout.ball_levels.clear()
	for entry: Variant in data["balls"]:
		var ball: BallDefinition = catalog.find(StringName(str(entry[0]))) as BallDefinition
		if ball == null:
			return null
		inventory.add_ball(ball, int(entry[1]))
	for id: Variant in data["omamori"]:
		var charm: OmamoriDefinition = catalog.find(StringName(str(id))) as OmamoriDefinition
		if charm == null:
			return null
		inventory.loadout.omamori.append(charm)
	for id: Variant in data["pegs"]:
		var peg: PegDefinition = catalog.find(StringName(str(id))) as PegDefinition
		if peg == null:
			return null
		inventory.add_peg(peg)
	inventory.slots = int(data["slots"])
	state.inventory = inventory
	var streams: Array[PackedInt64Array] = []
	for words: Variant in data["streams"]:
		streams.append(PackedInt64Array(_ints(words)))
	state.streams.set_state(streams)
	state.carry.role_bonus_points = PackedInt32Array(_ints(data["carry"]))
	state.mon = int(data["mon"])
	state.shot_delta = int(data["shot_delta"])
	state.floor_index = int(data["floor"])
	state.node = int(data["node"])
	state.boards_played = int(data["boards_played"])
	state.floor_layouts = PackedStringArray(data["floor_layouts"])
	state.bet = int(data["bet"])
	for id: Variant in data["events_seen"]:
		state.events_seen.append(StringName(str(id)))
	state.boards_won = int(data["boards_won"])
	state.matsuri_count = int(data["matsuri"])
	state.best_shot = int(data["best_shot"])
	return state


static func _ids(items: Array) -> Array[String]:
	var ids: Array[String] = []
	for item: ItemDefinition in items:
		ids.append(String(item.id))
	return ids


static func _names(names: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for name: StringName in names:
		result.append(String(name))
	return result


## JSON numbers come back as floats; every stored number is a whole one.
static func _ints(values: Variant) -> Array[int]:
	var result: Array[int] = []
	for value: Variant in values:
		result.append(int(value))
	return result
