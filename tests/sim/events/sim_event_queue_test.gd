extends GdUnitTestSuite


func test_events_keep_push_order_beyond_initial_capacity() -> void:
	var queue: SimEventQueue = SimEventQueue.new(2)
	for i: int in 5:
		queue.push(SimEvent.Kind.PEG_HIT, i, 0, i * 10, i, -i)
	assert_int(queue.size()).is_equal(5)
	for i: int in 5:
		var event: SimEvent = queue.at(i)
		assert_int(event.tick).is_equal(i)
		assert_int(event.target).is_equal(i * 10)
		assert_int(event.y).is_equal(-i)


func test_clear_reuses_pooled_events() -> void:
	var queue: SimEventQueue = SimEventQueue.new(1)
	queue.push(SimEvent.Kind.WALL_BOUNCE, 1, 0, 2, 0, 0)
	var first: SimEvent = queue.at(0)
	queue.clear()
	assert_int(queue.size()).is_equal(0)
	queue.push(SimEvent.Kind.BALL_LOST, 7, 0, -1, 0, 0)
	assert_object(queue.at(0)).is_same(first)
	assert_int(queue.at(0).kind).is_equal(SimEvent.Kind.BALL_LOST)
	assert_int(queue.at(0).tick).is_equal(7)
