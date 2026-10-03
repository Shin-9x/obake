class_name BalanceConfig
extends Resource
## Tunable gameplay numbers, in simulation units.
##
## Distances in milli-pixels (1 px = 1000), speeds in milli-pixels per second, accelerations in
## milli-pixels per second squared, ratios in permille (1.0 = 1000), angles in centidegrees.

@export_group("Board")
@export var board_width: int = 360_000
@export var board_height: int = 360_000

@export_group("Ball")
@export var ball_radius: int = 4_000
@export var gravity: int = 300_000
@export var launch_speed: int = 280_000
## A step at this speed must stay shorter than the ball radius plus the thinnest peg
## half-extent, otherwise contacts can be skipped (5 px per tick at 120 Hz by default).
@export var max_speed: int = 600_000
@export var wall_restitution: int = 900

@export_group("Pegs")
@export var peg_radius: int = 5_000
@export var peg_restitution: int = 800

@export_group("Launcher")
@export var launcher_x: int = 180_000
@export var launcher_y: int = 12_000
## Largest aim deviation from straight down, either side.
@export var aim_limit: int = 8_500
