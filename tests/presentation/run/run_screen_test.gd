extends GdUnitTestSuite
## The run screen follows the run from character choice through the map, a board and its
## rewards, to the end screen and back.

const SCENE: String = "res://src/presentation/run/run_screen.tscn"
const Screens: GDScript = preload("res://tests/presentation/run/support.gd")
const SEED: int = 777


func test_a_run_starts_with_the_choice_of_a_character() -> void:
	var screen: RunScreen = scene_runner(SCENE).scene() as RunScreen
	assert_object(screen.current).is_instanceof(CharacterSelectScreen)
	var cards: Array[Node] = Screens.find_all(screen.current, Button)
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
