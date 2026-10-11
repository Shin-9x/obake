extends GdUnitTestSuite
## The board's juice: slow motion near the last red lantern, the camera, sparks, trails and
## Obo's mood.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PX: float = 1000.0


func test_the_last_red_is_the_only_one_left_and_still_unlit() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	var spare: int = Harness.ROW.size()
	assert_int(SlowMotion.last_red(game)).is_equal(spare)
	game.roles[0] = BoardGame.Role.RED
	assert_int(SlowMotion.last_red(game)).is_equal(-1)
	game.roles[0] = BoardGame.Role.BLUE
	game.simulation.pegs[spare].lit = true
	assert_int(SlowMotion.last_red(game)).is_equal(-1)


func test_the_view_slows_more_the_nearer_a_ball_comes_to_the_last_red() -> void:
	var game: BoardGame = _one_red_left()
	var red: SimPeg = game.simulation.pegs[Harness.ROW.size()]
	var ball: SimBall = game.launched_ball()
	var fever: SlowMotion = SlowMotion.new()
	_place(ball, red, 120)
	fever.update(game, 0.016)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.IDLE)
	assert_float(fever.speed).is_equal(1.0)
	_place(ball, red, 70)
	fever.update(game, 0.016)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.APPROACH)
	var far: float = fever.speed
	assert_float(far).is_between(SlowMotion.NEAR_SPEED, SlowMotion.FAR_SPEED)
	assert_that(fever.focus).is_equal(Vector2(red.x, red.y) / PX)
	_place(ball, red, 40)
	fever.update(game, 0.016)
	assert_float(fever.speed).is_less(far)
	_place(ball, red, 20)
	fever.update(game, 0.016)
	assert_float(fever.speed).is_equal_approx(SlowMotion.NEAR_SPEED, 0.001)


func test_a_near_miss_lingers_then_lets_the_ball_go() -> void:
	var game: BoardGame = _one_red_left()
	var red: SimPeg = game.simulation.pegs[Harness.ROW.size()]
	var ball: SimBall = game.launched_ball()
	var fever: SlowMotion = SlowMotion.new()
	_place(ball, red, 30)
	fever.update(game, 0.016)
	_place(ball, red, 45)
	fever.update(game, 0.016)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.LINGER)
	assert_float(fever.speed).is_equal(SlowMotion.LINGER_SPEED)
	fever.update(game, SlowMotion.LINGER_SECONDS / 2.0)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.LINGER)
	fever.update(game, SlowMotion.LINGER_SECONDS)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.IDLE)
	# Still near, but the moment has passed: no second slow motion until the ball comes back.
	_place(ball, red, 35)
	fever.update(game, 0.016)
	assert_float(fever.speed).is_equal(1.0)
	_place(ball, red, 200)
	fever.update(game, 0.016)
	_place(ball, red, 60)
	fever.update(game, 0.016)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.APPROACH)


func test_a_ball_that_hangs_about_does_not_keep_the_view_slow_for_ever() -> void:
	var game: BoardGame = _one_red_left()
	var red: SimPeg = game.simulation.pegs[Harness.ROW.size()]
	var fever: SlowMotion = SlowMotion.new()
	_place(game.launched_ball(), red, 30)
	fever.update(game, SlowMotion.APPROACH_SECONDS / 2.0)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.APPROACH)
	fever.update(game, SlowMotion.APPROACH_SECONDS)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.LINGER)


func test_lighting_the_last_red_all_but_stops_the_view_for_a_moment() -> void:
	var game: BoardGame = _one_red_left()
	var fever: SlowMotion = SlowMotion.new()
	fever.strike(Vector2(120, 80))
	assert_int(fever.stage).is_equal(SlowMotion.Stage.STRUCK)
	assert_float(fever.speed).is_equal(SlowMotion.STRUCK_SPEED)
	assert_that(fever.focus).is_equal(Vector2(120, 80))
	fever.update(game, SlowMotion.STRUCK_SECONDS / 2.0)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.STRUCK)
	fever.update(game, SlowMotion.STRUCK_SECONDS)
	assert_int(fever.stage).is_equal(SlowMotion.Stage.IDLE)
	assert_float(fever.speed).is_equal(1.0)


func test_the_camera_closes_in_keeps_the_board_in_view_and_settles() -> void:
	var world: Node2D = auto_free(Node2D.new())
	var camera: BoardCamera = BoardCamera.new()
	camera.world = world
	camera.focus(Vector2(350, 350), true)
	for frame: int in 60:
		camera.update(1.0 / 60.0)
	assert_float(world.scale.x).is_equal_approx(BoardCamera.ZOOM, 0.001)
	var lowest: Vector2 = camera.size - camera.size * BoardCamera.ZOOM
	assert_float(world.position.x).is_equal_approx(lowest.x, 0.001)
	camera.focus(Vector2.ZERO, false)
	camera.shake(4.0)
	for frame: int in 60:
		camera.update(1.0 / 60.0)
	assert_bool(camera.busy()).is_false()
	assert_that(world.position).is_equal(Vector2.ZERO)


func test_the_camera_closes_in_as_far_as_asked() -> void:
	var world: Node2D = auto_free(Node2D.new())
	var camera: BoardCamera = BoardCamera.new()
	camera.world = world
	camera.focus(Vector2(180, 180), true, SlowMotion.ZOOM)
	for frame: int in 60:
		camera.update(1.0 / 60.0)
	assert_float(world.scale.x).is_equal_approx(SlowMotion.ZOOM, 0.001)
	# The focus sits in the middle of the view.
	assert_that(world.position).is_equal(camera.size / 2.0 - Vector2(180, 180) * SlowMotion.ZOOM)


func test_sparks_play_out_and_stop_processing() -> void:
	var sparks: HitSparks = auto_free(HitSparks.new())
	add_child(sparks)
	sparks.hit(Vector2(10, 10), Color.WHITE)
	sparks.confetti(Vector2(100, 100), 12)
	assert_int(sparks.showing()).is_equal(13)
	assert_bool(sparks.is_processing()).is_true()
	for frame: int in 10:
		sparks._process(0.2)
	assert_int(sparks.showing()).is_equal(0)
	assert_bool(sparks.is_processing()).is_false()


func test_trails_follow_flying_balls_and_drop_landed_ones() -> void:
	var trails: BallTrails = auto_free(BallTrails.new())
	for frame: int in 10:
		trails.track(1, Vector2(frame, 0), true)
	assert_int(trails._counts[1]).is_equal(BallTrails.LENGTH)
	trails.track(1, Vector2.ZERO, false)
	assert_int(trails._counts[1]).is_equal(0)


func test_obo_reacts_to_the_shot() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	game.target = 800
	assert_int(MascotMood.after_shot(game, 0)).is_equal(MascotMood.Mood.SAD)
	assert_int(MascotMood.after_shot(game, 250)).is_equal(MascotMood.Mood.HAPPY)
	assert_int(MascotMood.after_shot(game, 50)).is_equal(MascotMood.Mood.IDLE)
	game.shots_left = 2
	assert_int(MascotMood.after_shot(game, 50)).is_equal(MascotMood.Mood.WORRIED)
	game.outcome = BoardGame.Outcome.MATSURI
	assert_int(MascotMood.after_shot(game, 50)).is_equal(MascotMood.Mood.HAPPY)


## A board with a single red lantern left and a shot in flight.
func _one_red_left() -> BoardGame:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	Harness.shoot(game)
	return game


## Puts [param ball] at [param pixels] to the left of [param peg].
func _place(ball: SimBall, peg: SimPeg, pixels: int) -> void:
	ball.x = peg.x - pixels * FixedMath.PX
	ball.y = peg.y
