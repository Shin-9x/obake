@tool
class_name Pcg32
## PCG32 (XSH RR) random generator, bit-compatible with the reference implementation.
##
## The 64-bit state and increment are held as pairs of 32-bit words and multiplied through
## 16-bit limbs, so no intermediate value ever reaches 2^63. Godot's own generators are not
## used because their algorithms may change between engine versions.

const _MASK_32: int = 0xFFFFFFFF
const _MASK_16: int = 0xFFFF
const _MULTIPLIER_HI: int = 0x5851F42D
const _MULTIPLIER_LO: int = 0x4C957F2D
const _TWO_POW_32: int = 1 << 32

var _state_hi: int = 0
var _state_lo: int = 0
var _inc_hi: int = 0
var _inc_lo: int = 0


## Seeds the generator like the reference [code]pcg32_srandom(initial_state, sequence)[/code].
## Generators with different [param sequence] values produce independent streams.
func _init(initial_state: int = 0, sequence: int = 0) -> void:
	var sequence_hi: int = (sequence >> 32) & _MASK_32
	var sequence_lo: int = sequence & _MASK_32
	_inc_hi = ((sequence_hi << 1) | (sequence_lo >> 31)) & _MASK_32
	_inc_lo = ((sequence_lo << 1) | 1) & _MASK_32
	_state_hi = 0
	_state_lo = 0
	_advance()
	_add_to_state((initial_state >> 32) & _MASK_32, initial_state & _MASK_32)
	_advance()


## Next uniformly distributed value in [0, 2^32).
func next_u32() -> int:
	var old_hi: int = _state_hi
	var old_lo: int = _state_lo
	_advance()
	# xorshifted = ((old >> 18) ^ old) >> 27, truncated to 32 bits.
	var shifted_hi: int = old_hi >> 18
	var shifted_lo: int = ((old_lo >> 18) | (old_hi << 14)) & _MASK_32
	var mixed_hi: int = old_hi ^ shifted_hi
	var mixed_lo: int = old_lo ^ shifted_lo
	var xorshifted: int = ((mixed_lo >> 27) | (mixed_hi << 5)) & _MASK_32
	var rotation: int = old_hi >> 27
	return ((xorshifted >> rotation) | (xorshifted << ((32 - rotation) & 31))) & _MASK_32


## Uniform value in [0, [param bound]) without modulo bias. [param bound] must be in [1, 2^32).
func next_below(bound: int) -> int:
	var threshold: int = (_TWO_POW_32 - bound) % bound
	var value: int = next_u32()
	while value < threshold:
		value = next_u32()
	return value % bound


## Snapshot of the generator, restorable with [method set_state].
func get_state() -> PackedInt64Array:
	return PackedInt64Array([_state_hi, _state_lo, _inc_hi, _inc_lo])


func set_state(state: PackedInt64Array) -> void:
	_state_hi = state[0]
	_state_lo = state[1]
	_inc_hi = state[2]
	_inc_lo = state[3]


## state = state * multiplier + increment, modulo 2^64.
func _advance() -> void:
	# Full 64-bit product of the low words, from 16-bit limbs.
	var a0: int = _state_lo & _MASK_16
	var a1: int = _state_lo >> 16
	var b0: int = _MULTIPLIER_LO & _MASK_16
	var b1: int = _MULTIPLIER_LO >> 16
	var middle: int = a1 * b0 + a0 * b1
	var low: int = a0 * b0 + ((middle & _MASK_16) << 16)
	var carry: int = a1 * b1 + (middle >> 16) + (low >> 32)
	var cross: int = _mul_low_32(_state_hi, _MULTIPLIER_LO) + _mul_low_32(_state_lo, _MULTIPLIER_HI)
	_state_hi = (carry + cross) & _MASK_32
	_state_lo = low & _MASK_32
	_add_to_state(_inc_hi, _inc_lo)


func _add_to_state(add_hi: int, add_lo: int) -> void:
	var lo: int = _state_lo + add_lo
	_state_lo = lo & _MASK_32
	_state_hi = (_state_hi + add_hi + (lo >> 32)) & _MASK_32


## Low 32 bits of the product of two 32-bit values.
static func _mul_low_32(a: int, b: int) -> int:
	return ((a & _MASK_16) * b + ((((a >> 16) * b) & _MASK_16) << 16)) & _MASK_32
