class_name SimBall
## A ball in flight. Position in milli-pixels, velocity in milli-pixels per second.

var x: int = 0
var y: int = 0
var vx: int = 0
var vy: int = 0
var radius: int = 0
var active: bool = false
## Consecutive ticks spent below the stuck speed.
var slow_ticks: int = 0
