class_name RunState
## Everything that describes a run between boards: enough to rebuild it from its seed and the
## choices made so far.

var run_seed: int = 0
var streams: RngStreams
var inventory: Inventory
var carry: RunCarry = RunCarry.new()
var mon: int = 0
## Added to the shots of every board, such as Kasa-obake's bridge.
var shot_delta: int = 0
## Current floor, from 0.
var floor_index: int = 0
var maps: Array[FloorMap] = []
## The boss of each floor, as an index into [member RunContent.floor_bosses]. The last boss there
## closes the run; the others are dealt to the earlier floors by the seed, without repeats while
## there are enough of them.
var boss_order: PackedInt32Array = PackedInt32Array()
## Node of the current floor the player stands on, or -1 before the first choice.
var node: int = -1
## Boards played so far, of any kind; targets grow with it.
var boards_played: int = 0
## Layouts already played on the current floor.
var floor_layouts: PackedStringArray = PackedStringArray()
## Mon staged on the next board ending in a Matsuri, such as the kappa's wager; 0 when none.
var bet: int = 0
var events_seen: Array[StringName] = []
var boards_won: int = 0
var matsuri_count: int = 0
var best_shot: int = 0


## A new run for [param character]: the starting bag and mon, and the maps of every floor and
## the order of the [param bosses] drawn up front, so a seed always gives the same maps and
## bosses whatever path is taken.
static func start(
	config: BalanceConfig, character: CharacterDefinition, seed_value: int, bosses: int
) -> RunState:
	var state: RunState = RunState.new()
	state.run_seed = seed_value
	state.streams = RngStreams.new(seed_value)
	state.inventory = Inventory.new(config, character)
	state.mon = config.starting_mon
	var map_stream: Pcg32 = state.streams.stream(RngStreams.Domain.MAP)
	for floor_number: int in config.floors:
		state.maps.append(MapGenerator.generate(config, map_stream))
	state.boss_order = _deal_bosses(config.floors, bosses, map_stream)
	return state


## The boss index of each floor: the last of [param bosses] on the last floor, the others
## shuffled over the floors before it.
static func _deal_bosses(floors: int, bosses: int, rng: Pcg32) -> PackedInt32Array:
	var order: PackedInt32Array = PackedInt32Array()
	if bosses <= 0:
		return order
	var last: int = bosses - 1
	var early: PackedInt32Array = PackedInt32Array()
	for index: int in last:
		early.append(index)
	for index: int in range(early.size() - 1, 0, -1):
		var other: int = rng.next_below(index + 1)
		var kept: int = early[index]
		early[index] = early[other]
		early[other] = kept
	for floor_number: int in floors:
		if floor_number == floors - 1 or early.is_empty():
			order.append(last)
		else:
			order.append(early[floor_number % early.size()])
	return order


func current_map() -> FloorMap:
	return maps[floor_index]


func current_node() -> MapNode:
	return current_map().nodes[node] if node >= 0 else null


func can_afford(price: int) -> bool:
	return mon >= price


## Takes [param price] mon if the player has them.
func spend(price: int) -> bool:
	if not can_afford(price):
		return false
	mon -= price
	return true
