@tool
class_name Trig
## Sine and cosine of integer angles, read from a lookup table.
##
## Angles are in centidegrees and results are scaled by [constant FixedMath.UNIT].
## The table is built once with integer-only arithmetic, so it is bit-identical on every
## platform without shipping a generated file.

const FULL_TURN: int = 36000
const HALF_TURN: int = 18000
const QUARTER_TURN: int = 9000

## Table resolution in centidegrees; values in between are linearly interpolated.
const _STEP: int = 10
const _Q_ONE: int = 1 << 30
## Pi in Q30 fixed point.
const _PI_Q30: int = 3373259426

static var _quarter_wave: PackedInt32Array = PackedInt32Array()


static func _static_init() -> void:
	_quarter_wave.resize(QUARTER_TURN / _STEP + 1)
	for i: int in _quarter_wave.size():
		_quarter_wave[i] = _taylor_sine(i * _STEP)


static func sin_cd(angle: int) -> int:
	var a: int = posmod(angle, FULL_TURN)
	if a <= QUARTER_TURN:
		return _quarter_sine(a)
	if a <= HALF_TURN:
		return _quarter_sine(HALF_TURN - a)
	if a <= HALF_TURN + QUARTER_TURN:
		return -_quarter_sine(a - HALF_TURN)
	return -_quarter_sine(FULL_TURN - a)


static func cos_cd(angle: int) -> int:
	return sin_cd(angle + QUARTER_TURN)


static func _quarter_sine(angle: int) -> int:
	var index: int = angle / _STEP
	var remainder: int = angle % _STEP
	var base: int = _quarter_wave[index]
	if remainder == 0:
		return base
	return base + FixedMath.div_round((_quarter_wave[index + 1] - base) * remainder, _STEP)


## Sine of an angle in [0, 90] degrees via its Taylor series in Q30.
## Every product stays below 2^63 because the angle never exceeds pi/2.
static func _taylor_sine(angle: int) -> int:
	var x: int = angle * _PI_Q30 / HALF_TURN
	var x_squared: int = x * x / _Q_ONE
	var term: int = x
	var sum: int = x
	var n: int = 1
	while term != 0:
		term = -term * x_squared / _Q_ONE / ((2 * n) * (2 * n + 1))
		sum += term
		n += 1
	return FixedMath.div_round(sum * FixedMath.UNIT, _Q_ONE)
