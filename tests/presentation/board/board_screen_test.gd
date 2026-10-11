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


func test_the_ball_about_to_be_fired_says_what_it_does() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var power: Label = screen.get_node("%BallPower") as Label
	var ball: BagBall = screen.game.bag.peek(0)
	assert_str(power.text).is_not_empty()
	assert_str(power.text).is_equal(UiKit.describe(ball.definition, ball.level))
	screen.shoot()
	var next: BagBall = screen.game.bag.peek(0)
	assert_str(power.text).is_equal(UiKit.describe(next.definition, next.level))


func test_the_touch_layout_keeps_the_left_panel_clear_of_the_buttons() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var hud: BoardHud = screen.get_node("%Hud") as BoardHud
	hud.use_touch_layout(true)
	await runner.simulate_frames(2)
	var buttons_top: float = (
		(screen.get_node("%AimLeftButton") as Control).get_global_rect().position.y
	)
	var seed_line: Control = screen.get_node("%SeedValue") as Control
	assert_bool((screen.get_node("%TouchControls") as Control).visible).is_true()
	assert_float(seed_line.get_global_rect().end.y).is_less_equal(buttons_top)
	assert_bool((screen.get_node("%GameTitle") as Control).visible).is_false()
	assert_bool((screen.get_node("%LayoutValue") as Control).visible).is_false()
	var obo: Control = screen.get_node("%Obo") as Control
	assert_float(obo.get_global_rect().end.y).is_less(buttons_top)


func test_the_matsuri_begins_when_its_last_lantern_is_lit() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var game: BoardGame = screen.game
	game.target = 1_000_000_000
	var last: int = -1
	for peg: int in game.roles.size():
		if game.roles[peg] == BoardGame.Role.RED:
			if last < 0:
				last = peg
			else:
				game.roles[peg] = BoardGame.Role.BLUE
	screen.shoot()
	await runner.simulate_frames(2, 16)
	var ball: SimBall = game.launched_ball()
	var red: SimPeg = game.simulation.pegs[last]
	ball.x = red.x + 2000
	ball.y = red.y - 60_000
	ball.vx = 0
	ball.vy = 40_000
	var banner: Label = screen.get_node("%Celebration") as Label
	var slowed: bool = false
	var frames: int = 0
	while not red.lit and frames < 600:
		await runner.simulate_frames(1, 16)
		slowed = slowed or screen._fever.stage == SlowMotion.Stage.APPROACH
		frames += 1
	await runner.simulate_frames(2, 16)
	assert_bool(red.lit).is_true()
	assert_bool(slowed).is_true()
	assert_int(screen._fever.stage).is_equal(SlowMotion.Stage.STRUCK)
	assert_bool(banner.visible).is_true()
	assert_int(game.outcome).is_equal(BoardGame.Outcome.PLAYING)
	assert_float((screen.get_node("%World") as Node2D).scale.x).is_greater(1.0)


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


func test_a_tap_on_an_omamori_slot_shows_its_card() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var screen: BoardScreen = runner.scene() as BoardScreen
	screen.start_board(SEED)
	var slot: ColorRect = screen.get_node("%OmamoriSlots").get_child(0) as ColorRect
	var tap: InputEventScreenTouch = InputEventScreenTouch.new()
	tap.pressed = true
	slot.gui_input.emit(tap)
	var popups: Array[Node] = screen.get_node("%Hud").get_children().filter(
		func(node: Node) -> bool: return node is InfoPopup
	)
	assert_array(popups).has_size(1)
	assert_bool((popups[0] as InfoPopup).visible).is_true()
