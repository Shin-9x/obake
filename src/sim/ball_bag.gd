@tool
class_name BallBag
## The balls of a board: a draw pile and the balls already shot.
##
## The pile is shuffled when the board starts and the shot balls are reshuffled into it when it
## runs low, so the current and the next ball can always be shown. Shuffles use the board stream.

var _pile: Array[BagBall] = []
var _shot: Array[BagBall] = []
var _rng: Pcg32


func _init(balls: Array[BagBall], rng: Pcg32) -> void:
	_rng = rng
	_pile = balls.duplicate()
	_shuffle(_pile)


func size() -> int:
	return _pile.size() + _shot.size()


## The ball [param offset] places down the pile: 0 is the next ball shot, 1 the one after.
func peek(offset: int) -> BagBall:
	_refill(offset + 1)
	return _pile[offset] if offset < _pile.size() else null


func draw() -> BagBall:
	_refill(1)
	return _pile.pop_front() if not _pile.is_empty() else null


func discard(ball: BagBall) -> void:
	_shot.append(ball)


## Puts [param ball] back at a random place in the pile, never before the ball shown as next.
func return_after_next(ball: BagBall) -> void:
	var first: int = mini(2, _pile.size())
	_pile.insert(first + _rng.next_below(_pile.size() - first + 1), ball)


func push_top(ball: BagBall) -> void:
	_pile.push_front(ball)


func _refill(needed: int) -> void:
	if _pile.size() >= needed or _shot.is_empty():
		return
	_shuffle(_shot)
	_pile.append_array(_shot)
	_shot.clear()


## Fisher-Yates with the board stream.
func _shuffle(balls: Array[BagBall]) -> void:
	for i: int in range(balls.size() - 1, 0, -1):
		var j: int = _rng.next_below(i + 1)
		var swapped: BagBall = balls[i]
		balls[i] = balls[j]
		balls[j] = swapped
