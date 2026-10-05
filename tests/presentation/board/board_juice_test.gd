extends GdUnitTestSuite
## The board's juice: slow motion near the last red lantern, the camera, sparks, trails and
## Obo's mood.

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const PX: int = FixedMath.PX
const REACH: int = 40 * PX


func test_slow_motion_needs_a_single_unlit_red_and_a_ball_near_it() -> void:
	var game: BoardGame = Harness.board(Harness.ROW)
	Harness.all_blue(game)
	var spare: int = Harness.ROW.size()
	Harness.shoot(game)
	var ball: SimBall = game.launched_ball()
	var red: SimPeg = game.simulation.pegs[spare]
	ball.x = red.x + 30 * PX
	ball.y = red.y
	assert_int(SlowMotion.target(game, REACH)).is_equal(spare)
	ball.x = red.x + 60 * PX
	assert_int(SlowMotion.target(game, REACH)).is_equal(-1)
	ball.x = red.x
	game.roles[0] = BoardGame.Role.RED
	assert_int(SlowMotion.target(game, REACH)).is_equal(-1)
	game.roles[0] = BoardGame.Role.BLUE
	red.lit = true
	assert_int(SlowMotion.target(game, REACH)).is_equal(-1)


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
