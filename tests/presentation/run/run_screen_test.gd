extends GdUnitTestSuite
## The run screen follows the run from character choice through the map, a board and its
## rewards, to the end screen and back.

const SCENE: String = "res://src/presentation/run/run_screen.tscn"
const Screens: GDScript = preload("res://tests/presentation/run/support.gd")
const SEED: int = 777
## Keeps the tests away from the player's own saves.
const SAVES: String = "user://test_saves_screen"


func before_test() -> void:
	SaveService.directory = SAVES
	_wipe()


func after_test() -> void:
	_wipe()
	SaveService.directory = "user://"


func test_a_run_starts_with_the_choice_of_a_character() -> void:
	var screen: RunScreen = scene_runner(SCENE).scene() as RunScreen
	assert_object(screen.current).is_instanceof(CharacterSelectScreen)
	var cards: Array[Node] = Screens.find_all(screen.current, Button).filter(
		func(node: Node) -> bool: return (node as Button).text.is_empty()
	)
	assert_array(cards).has_size(3)
	(cards[2] as Button).pressed.emit()
	assert_object(screen.current).is_instanceof(MapScreen)
	assert_str(String(screen.run.state.inventory.loadout.character.id)).is_equal("tanuki")


func test_the_map_lets_only_reachable_nodes_be_picked() -> void:
	var screen: RunScreen = _started()
	var enabled: int = 0
	for button: Node in Screens.find_all(screen.current, Button):
		enabled += 0 if (button as Button).disabled else 1
	assert_int(enabled).is_equal(screen.run.reachable_nodes().size())


func test_a_board_node_plays_the_board_then_shows_the_rewards() -> void:
	var screen: RunScreen = _started()
	var node: int = screen.run.reachable_nodes()[0]
	screen._on_node_chosen(node)
	assert_object(screen.current).is_instanceof(BoardScreen)
	var board: BoardScreen = screen.current as BoardScreen
	assert_int(board.game.target).is_equal(800)
	assert_bool((board.get_node("%CharacterRow") as Control).visible).is_true()
	assert_bool((board.get_node("%BossBox") as Control).visible).is_false()
	_end_board(screen, BoardGame.Outcome.TARGET_REACHED)
	assert_object(screen.current).is_instanceof(RewardScreen)


func test_a_lost_board_ends_the_run_and_a_new_run_can_start() -> void:
	var screen: RunScreen = _started()
	screen._on_node_chosen(screen.run.reachable_nodes()[0])
	_end_board(screen, BoardGame.Outcome.FAILED)
	assert_object(screen.current).is_instanceof(RunEndScreen)
	Screens.button(screen.current, "BUTTON_NEW_RUN").pressed.emit()
	assert_object(screen.current).is_instanceof(CharacterSelectScreen)


func test_boss_boards_show_the_boss() -> void:
	var screen: RunScreen = _started()
	var map: FloorMap = screen.run.state.current_map()
	screen.run.state.node = map.steps[map.steps.size() - 2][0]
	screen._on_node_chosen(map.boss())
	var board: BoardScreen = screen.current as BoardScreen
	assert_bool((board.get_node("%BossBox") as Control).visible).is_true()
	assert_str((board.get_node("%BossName") as Label).text).is_equal("BOSS_JOROGUMO")
	assert_array(board.game.simulation.zones).is_not_empty()


func test_runs_are_saved_and_continued_from_the_character_screen() -> void:
	var screen: RunScreen = _started()
	screen._on_node_chosen(screen.run.reachable_nodes()[0])
	var board: BoardScreen = screen.current as BoardScreen
	board.shoot()
	var played: Run = screen.run
	assert_bool(SaveService.has_run()).is_true()
	screen.show_character_select()
	Screens.button(screen.current, "BUTTON_CONTINUE_RUN").pressed.emit()
	assert_object(screen.current).is_instanceof(BoardScreen)
	assert_array(screen.run.run_log.actions).is_equal(played.run_log.actions)
	assert_int(screen.run.game.shots_left).is_equal(played.game.shots_left)


func test_board_feats_reach_the_profile_and_a_lost_run_clears_its_save() -> void:
	var screen: RunScreen = _started()
	screen._on_node_chosen(screen.run.reachable_nodes()[0])
	var result: BoardResult = BoardResult.new()
	result.outcome = BoardGame.Outcome.FAILED
	result.best_shot_pegs = 35
	result.interest_cap = 5
	screen.run.game.outcome = result.outcome
	screen.run.game.result = result
	(screen.current as BoardScreen).board_finished.emit(result)
	assert_bool(screen.profile.has_feat(&"thirty_pegs")).is_true()
	assert_int(screen.toasts.pending()).is_equal(1)
	assert_int(screen.profile.runs).is_equal(1)
	assert_bool(SaveService.has_run()).is_false()
	assert_bool(SaveService.load_profile().has_feat(&"thirty_pegs")).is_true()


func test_hard_mode_shows_once_earned_and_a_typed_seed_counts_for_nothing() -> void:
	var screen: RunScreen = scene_runner(SCENE).scene() as RunScreen
	assert_array(Screens.find_all(screen.current, CheckBox)).is_empty()
	screen.profile.add_mark(&"kitsune", Profile.Mark.SHUTEN)
	screen.show_character_select()
	var switches: Array[Node] = Screens.find_all(screen.current, CheckBox)
	assert_array(switches).has_size(1)
	(switches[0] as CheckBox).button_pressed = true
	(Screens.find_all(screen.current, LineEdit)[0] as LineEdit).text = "BEEF"
	var cards: Array[Node] = Screens.find_all(screen.current, Button).filter(
		func(node: Node) -> bool: return (node as Button).text.is_empty()
	)
	(cards[1] as Button).pressed.emit()
	assert_bool(screen.run.run_log.options.hard).is_true()
	assert_bool(screen.run.run_log.options.custom_seed).is_true()
	assert_int(screen.run.state.run_seed).is_equal(0xBEEF)


func test_the_compendium_and_the_statistics_open_and_close() -> void:
	var screen: RunScreen = scene_runner(SCENE).scene() as RunScreen
	Screens.button(screen.current, "BUTTON_COMPENDIUM").pressed.emit()
	assert_object(screen.current).is_instanceof(CompendiumScreen)
	Screens.button(screen.current, "BUTTON_BACK").pressed.emit()
	assert_object(screen.current).is_instanceof(CharacterSelectScreen)
	Screens.button(screen.current, "BUTTON_STATISTICS").pressed.emit()
	assert_object(screen.current).is_instanceof(StatisticsScreen)


func _wipe() -> void:
	if not DirAccess.dir_exists_absolute(SAVES):
		return
	for file: String in DirAccess.get_files_at(SAVES):
		DirAccess.remove_absolute(SAVES.path_join(file))
	DirAccess.remove_absolute(SAVES)


func _started() -> RunScreen:
	var screen: RunScreen = scene_runner(SCENE).scene() as RunScreen
	screen.start_run(load("res://data/characters/kitsune.tres"), SEED)
	return screen


## Ends the board on screen with [param outcome] without simulating it, then continues.
func _end_board(screen: RunScreen, outcome: BoardGame.Outcome) -> void:
	var result: BoardResult = BoardResult.new()
	result.outcome = outcome
	result.interest_cap = 5
	screen.run.game.outcome = outcome
	screen.run.game.result = result
	(screen.current as BoardScreen).board_finished.emit(result)
