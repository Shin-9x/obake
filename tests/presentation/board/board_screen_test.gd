extends GdUnitTestSuite
## Smoke test: the board screen loads, plays a whole shot and reflects it in the HUD.

const SCENE: String = "res://src/presentation/board/board_screen.tscn"
const SEED: int = 12345
## Frames to wait for a shot to resolve; far more than a shot ever takes.
const MAX_FRAMES: int = 3000


func test_a_shot_plays_through_and_updates_the_hud() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var shots: Label = screen.get_node("%ShotsValue") as Label
	var shots_before: int = screen.game.shots_left
	assert_str(shots.text).is_equal(str(shots_before))
	screen.shoot()
	assert_bool(screen.game.simulation.is_shot_active()).is_true()
	var frames: int = 0
	while screen.game.simulation.is_shot_active() and frames < MAX_FRAMES:
		await runner.simulate_frames(10, 50)
		frames += 10
	assert_bool(screen.game.simulation.is_shot_active()).is_false()
	assert_str(shots.text).is_equal(str(screen.game.shots_left))
	var total: Label = screen.get_node("%TotalValue") as Label
	assert_str(total.text).starts_with(str(screen.game.total) + " /")


func test_play_again_starts_a_fresh_board() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var first: BoardGame = screen.game
	screen.start_board(SEED + 1)
	assert_object(screen.game).is_not_same(first)
	assert_int(screen.game.shots_left).is_equal(BoardScreen.BALANCE.shots_per_board)
	assert_bool((screen.get_node("%ResultOverlay") as Control).visible).is_false()
