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
	assert_bool(AudioService._last_played.has(AudioService.LAUNCH)).is_true()
	assert_int(AudioService.music).is_equal(AudioService.Music.BOARD)
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


func test_board_keeps_moving_while_aiming() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var simulation: BoardSimulation = screen.game.simulation
	assert_array(simulation.groups).is_not_empty()
	var peg: SimPeg = simulation.pegs[simulation.groups[0].pegs[0]]
	var clock: int = simulation.clock
	var where: Vector2i = Vector2i(peg.x, peg.y)
	await runner.simulate_frames(30, 16)
	assert_int(simulation.clock).is_greater(clock)
	assert_that(Vector2i(peg.x, peg.y)).is_not_equal(where)
	var layout: Label = screen.get_node("%LayoutValue") as Label
	assert_str(layout.text).starts_with(screen.placed.layout.id)


func test_a_run_board_shows_its_boss_and_continues_with_the_result() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.standalone = false
	var boss: BossDefinition = load("res://data/bosses/tamamo.tres")
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var loadout: LoadoutDefinition = LoadoutDefinition.new()
	loadout.character = load("res://data/characters/yamabushi.tres")
	var board: PlacedBoard = BoardSetup.create_board(
		BoardScreen.BALANCE,
		BoardScreen.BASE_PEGS,
		library.find(boss.layout_id),
		SEED,
		loadout,
		null,
		BoardRules.new(1, 0, boss)
	)
	screen.play(board, SEED, loadout, 6, boss)
	assert_bool((screen.get_node("%BossBox") as Control).visible).is_true()
	var slots: Array[Node] = screen.get_node("%OmamoriSlots").get_children()
	var shown: int = 0
	for slot: Node in slots:
		shown += 1 if (slot as Control).visible else 0
	assert_int(shown).is_equal(6)
	var finished: Array[BoardResult] = []
	screen.board_finished.connect(func(result: BoardResult) -> void: finished.append(result))
	screen.shoot()
	var frames: int = 0
	while screen.game.outcome == BoardGame.Outcome.PLAYING and frames < MAX_FRAMES:
		await runner.simulate_frames(10, 50)
		frames += 10
	assert_int(screen.game.outcome).is_equal(BoardGame.Outcome.TARGET_REACHED)
	(screen.get_node("%PlayAgainButton") as Button).pressed.emit()
	assert_array(finished).has_size(1)
	assert_object(finished[0]).is_same(screen.game.result)
