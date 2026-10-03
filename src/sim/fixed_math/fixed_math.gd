class_name FixedMath
## Integer fixed-point helpers for the deterministic simulation.
##
## Distances are in milli-pixels, ratios in permille, unit vectors and trigonometry in millionths.
## Callers keep every intermediate product below 2^63: signed overflow is undefined behaviour
## in the engine, so it must never be relied upon.

## Milli-pixels per pixel.
const PX: int = 1000
## Scale of unit vectors, sines and cosines.
const UNIT: int = 1_000_000
## Scale of ratios such as restitution.
const PERMILLE: int = 1000


## Floor of the square root of [param n]. Returns 0 for non-positive input.
static func isqrt(n: int) -> int:
	if n <= 0:
		return 0
	# Newton's method converges to the floor when it starts above the root.
	var x: int = 1 << ((_highest_bit(n) >> 1) + 1)
	var next: int = (x + n / x) >> 1
	while next < x:
		x = next
		next = (x + n / x) >> 1
	return x


## [param a] divided by [param b], rounded half away from zero. [param b] must not be zero.
static func div_round(a: int, b: int) -> int:
	var half: int = absi(b) >> 1
	if a >= 0:
		return (a + half) / b
	return (a - half) / b


static func length(x: int, y: int) -> int:
	return isqrt(x * x + y * y)


static func _highest_bit(n: int) -> int:
	var bit: int = 0
	var value: int = n
	var shift: int = 32
	while shift > 0:
		if value >= 1 << shift:
			value >>= shift
			bit += shift
		shift >>= 1
	return bit
