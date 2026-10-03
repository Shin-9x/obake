class_name RngStreams
## One independent PCG32 stream per randomness domain of a run.
##
## Drawing from one domain never shifts another, so rerolling a shop cannot change future boards.

enum Domain { MAP, SHOP, REWARDS, BOARD }

var _streams: Array[Pcg32] = []


func _init(run_seed: int) -> void:
	for domain: int in Domain.size():
		_streams.append(Pcg32.new(run_seed, domain))


func stream(domain: Domain) -> Pcg32:
	return _streams[domain]


func get_state() -> Array[PackedInt64Array]:
	var states: Array[PackedInt64Array] = []
	for rng: Pcg32 in _streams:
		states.append(rng.get_state())
	return states


func set_state(states: Array[PackedInt64Array]) -> void:
	for domain: int in _streams.size():
		_streams[domain].set_state(states[domain])
