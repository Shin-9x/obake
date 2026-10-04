class_name BalanceConfig
extends Resource
## Tunable gameplay numbers, in simulation units.
##
## Distances in milli-pixels (1 px = 1000), speeds in milli-pixels per second, accelerations in
## milli-pixels per second squared, ratios and mult values in permille (1.0 = 1000), angles in
## centidegrees, durations in simulation ticks (120 per second).

@export_group("Board")
@export var board_width: int = 360_000
@export var board_height: int = 360_000
@export var shots_per_board: int = 8
@export var first_board_target: int = 800
## Applied to the board total when every red lantern is cleared.
@export var matsuri_total_factor: int = 2000
## Largest interest paid at the end of a board, in mon; omamori can raise it.
@export var interest_cap: int = 5

@export_group("Lantern colouring")
## Share of the board's pegs that become red lanterns.
@export var red_permille: int = 220
@export var green_count: int = 2
## Red lanterns are spread over a grid of zones, each getting its share of the board's reds.
@export var colour_zone_columns: int = 3
@export var colour_zone_rows: int = 3

@export_group("Ball")
@export var ball_radius: int = 4_000
@export var gravity: int = 300_000
@export var launch_speed: int = 280_000
## A step at this speed must stay shorter than the ball radius plus the thinnest peg
## half-extent, otherwise contacts can be skipped (5 px per tick at 120 Hz by default).
@export var max_speed: int = 600_000
@export var wall_restitution: int = 900
## A ball slower than this for [member stuck_ticks] ticks clears the lit pegs.
@export var stuck_speed: int = 20_000
@export var stuck_ticks: int = 240

@export_group("Pegs")
@export var peg_radius: int = 5_000
@export var peg_restitution: int = 800
## A peg hit with less sideways speed than this counts as head-on.
@export var head_on_tolerance: int = 5_000
## Sideways push given on a head-on hit, as a share of the rebound speed. Exact integer physics
## would otherwise bounce a ball dropped dead centre on a peg straight up and down.
@export var head_on_nudge: int = 50

@export_group("Bucket")
## Distance between the centres of the two rims.
@export var bucket_width: int = 40_000
## Height of the rims; a ball between them that drops below this line is caught.
@export var bucket_y: int = 350_000
@export var bucket_rim_radius: int = 3_000
## Duration of one full left-right-left cycle.
@export var bucket_period: int = 480

@export_group("Launcher")
@export var launcher_x: int = 180_000
@export var launcher_y: int = 12_000
## Largest aim deviation from straight down, either side.
@export var aim_limit: int = 8_500

@export_group("Run")
@export var starting_mon: int = 4
@export var floors: int = 4
@export var omamori_slots: int = 5
## Smallest bag a removal may leave.
@export var min_bag_size: int = 1
@export var max_ball_level: int = 3

@export_group("Map")
@export var steps_per_floor: int = 4
@export var min_nodes_per_step: int = 2
@export var max_nodes_per_step: int = 3
## Odds of each node kind after the first step, which holds boards only, in [enum MapNode.Kind]
## order: board, elite, event, shrine, shop.
@export var node_weights: PackedInt32Array = PackedInt32Array([40, 15, 20, 12, 13])
## Most next nodes a node may lead to.
@export var max_node_links: int = 2

@export_group("Targets")
## Growth from one board to the next, in permille.
@export var board_target_growth: int = 1350
## Elite target over the standard one, in permille.
@export var elite_target_factor: int = 1500
## Boss target over the previous board's, in permille; it replaces the usual growth.
@export var boss_target_factor: int = 1800
@export var target_rounding: int = 10

@export_group("Hard mode")
## Hard targets over the normal ones, in permille.
@export var hard_target_factor: int = 1250
## Added to the shots of every board in Hard mode.
@export var hard_shot_delta: int = -1

@export_group("Economy")
## Mon for winning a standard, an elite and a boss board.
@export var win_mon: PackedInt32Array = PackedInt32Array([4, 7, 10])
@export var unused_shot_mon: int = 1
@export var matsuri_mon: int = 5
## One mon of interest for every this many held at the end of a board.
@export var interest_step: int = 5
@export var skip_reward_mon: int = 2

@export_group("Shop")
@export var shop_balls: int = 3
@export var shop_omamori: int = 2
@export var shop_pegs: int = 2
## Prices by rarity: common, uncommon, rare.
@export var ball_prices: PackedInt32Array = PackedInt32Array([4, 6, 9])
@export var omamori_prices: PackedInt32Array = PackedInt32Array([5, 7, 10])
@export var peg_prices: PackedInt32Array = PackedInt32Array([3, 5, 8])
@export var reroll_price: int = 3
## Added to the reroll price for every reroll already made in the same shop.
@export var reroll_increase: int = 1
## Price of upgrading a ball to level 2, then to level 3.
@export var upgrade_prices: PackedInt32Array = PackedInt32Array([5, 8])
## Share of its price an omamori sells for, in permille.
@export var sell_permille: int = 500
## What a legendary omamori sells for, since it has no shop price.
@export var legendary_sell_price: int = 5

@export_group("Rarity")
@export var uncommon_permille: int = 280
## Rare share of shop and reward balls by floor, from the first; later floors keep the last.
@export var rare_permille_by_floor: PackedInt32Array = PackedInt32Array(
	[70, 80, 90, 105, 115, 125, 140, 150]
)
## Omamori reward odds: common, uncommon, rare, legendary.
@export var elite_omamori_weights: PackedInt32Array = PackedInt32Array([55, 30, 12, 3])
@export var boss_omamori_weights: PackedInt32Array = PackedInt32Array([35, 35, 22, 8])
@export var reward_choices: int = 3
