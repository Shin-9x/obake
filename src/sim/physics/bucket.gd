@tool
class_name Bucket
## The bucket sliding along the bottom of the board. A ball caught in it makes the shot free.
##
## Its position depends only on its phase, counted in simulation ticks, so presentation can
## animate it between shots through [method x_at] without touching simulation state.

var phase: int = 0
## Centre between the rims, in milli-pixels.
var x: int = 0
## Height of the rim centres, in milli-pixels.
var y: int = 0
var half_width: int = 0
var rim_radius: int = 0

var _period: int = 1
var _center: int = 0
var _amplitude: int = 0


func _init(config: BalanceConfig) -> void:
	_period = maxi(1, config.bucket_period)
	half_width = config.bucket_width / 2
	rim_radius = config.bucket_rim_radius
	y = config.bucket_y
	_center = config.board_width / 2
	_amplitude = maxi(0, _center - half_width - rim_radius)
	set_phase(0)


func period() -> int:
	return _period


func set_phase(value: int) -> void:
	phase = posmod(value, _period)
	x = x_at(phase)


func advance() -> void:
	set_phase(phase + 1)


## Centre of the bucket at [param at_phase], in milli-pixels.
func x_at(at_phase: int) -> int:
	var angle: int = posmod(at_phase, _period) * Trig.FULL_TURN / _period
	return _center + FixedMath.div_round(_amplitude * Trig.sin_cd(angle), FixedMath.UNIT)


## True when a ball centred at ([param ball_x], [param ball_y]) has dropped into the bucket.
func catches(ball_x: int, ball_y: int) -> bool:
	return ball_y >= y and absi(ball_x - x) < half_width
