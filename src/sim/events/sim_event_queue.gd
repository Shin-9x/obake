class_name SimEventQueue
## Ordered, allocation-free queue of [SimEvent]s, cleared by whoever consumes them.

const DEFAULT_CAPACITY: int = 64

var _pool: Array[SimEvent] = []
var _count: int = 0


func _init(capacity: int = DEFAULT_CAPACITY) -> void:
	for i: int in capacity:
		_pool.append(SimEvent.new())


func size() -> int:
	return _count


func at(index: int) -> SimEvent:
	return _pool[index]


func clear() -> void:
	_count = 0


func push(kind: SimEvent.Kind, tick: int, ball: int, target: int, x: int, y: int) -> void:
	if _count == _pool.size():
		_pool.append(SimEvent.new())
	var event: SimEvent = _pool[_count]
	event.kind = kind
	event.tick = tick
	event.ball = ball
	event.target = target
	event.x = x
	event.y = y
	_count += 1
