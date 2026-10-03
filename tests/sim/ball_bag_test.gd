extends GdUnitTestSuite


func test_draws_every_ball_before_reshuffling() -> void:
	var bag: BallBag = _bag(5, 1)
	var seen: Array[BagBall] = []
	for i: int in 5:
		var ball: BagBall = bag.draw()
		assert_array(seen).not_contains([ball])
		seen.append(ball)
		bag.discard(ball)
	assert_int(bag.size()).is_equal(5)
	assert_object(bag.draw()).is_not_null()


func test_peek_shows_current_and_next_balls() -> void:
	var bag: BallBag = _bag(3, 2)
	var current: BagBall = bag.peek(0)
	var after: BagBall = bag.peek(1)
	assert_object(bag.draw()).is_same(current)
	assert_object(bag.peek(0)).is_same(after)


func test_peek_reshuffles_early_to_show_the_next_ball() -> void:
	var bag: BallBag = _bag(2, 3)
	bag.discard(bag.draw())
	assert_object(bag.peek(1)).is_not_null()


func test_caught_ball_returns_after_the_shown_next_ball() -> void:
	for board_seed: int in 20:
		var bag: BallBag = _bag(6, board_seed)
		var caught: BagBall = bag.draw()
		var current: BagBall = bag.peek(0)
		var after: BagBall = bag.peek(1)
		bag.return_after_next(caught)
		assert_object(bag.peek(0)).is_same(current)
		assert_object(bag.peek(1)).is_same(after)
		assert_int(bag.size()).is_equal(6)


func test_push_top_makes_the_ball_next() -> void:
	var bag: BallBag = _bag(4, 5)
	var ball: BagBall = bag.draw()
	bag.push_top(ball)
	assert_object(bag.peek(0)).is_same(ball)


func test_order_depends_only_on_the_seed() -> void:
	var a: BallBag = _bag(6, 9)
	var b: BallBag = _bag(6, 9)
	for i: int in 6:
		assert_int(a.draw().level).is_equal(b.draw().level)


func test_empty_bag_draws_nothing() -> void:
	var bag: BallBag = BallBag.new([], Pcg32.new(1, 0))
	assert_object(bag.draw()).is_null()
	assert_object(bag.peek(0)).is_null()


## Balls told apart by their level, which stands in for identity here.
func _bag(count: int, board_seed: int) -> BallBag:
	var balls: Array[BagBall] = []
	for index: int in count:
		balls.append(BagBall.new(null, index + 1))
	return BallBag.new(balls, Pcg32.new(board_seed, RngStreams.Domain.BOARD))
