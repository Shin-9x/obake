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
