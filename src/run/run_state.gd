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


## A new run for [param character]: the starting bag and mon, and the maps of every floor drawn
## up front, so a seed always gives the same maps whatever path is taken.
static func start(
	config: BalanceConfig, character: CharacterDefinition, seed_value: int
) -> RunState:
	var state: RunState = RunState.new()
	state.run_seed = seed_value
	state.streams = RngStreams.new(seed_value)
	state.inventory = Inventory.new(config, character)
	state.mon = config.starting_mon
	var map_stream: Pcg32 = state.streams.stream(RngStreams.Domain.MAP)
	for floor_number: int in config.floors:
		state.maps.append(MapGenerator.generate(config, map_stream))
	return state


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
