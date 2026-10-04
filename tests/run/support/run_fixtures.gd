extends RefCounted
## Configuration, content and run states shared by the run-logic tests.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const CONTENT: String = "res://data/run_content.tres"
const SEED: int = 4242


## GDD board numbers with the run numbers at their GDD defaults.
static func config() -> BalanceConfig:
	return TestBoards.gdd_config()


static func content() -> RunContent:
	return load(CONTENT)


static func character(id: String = "yamabushi") -> CharacterDefinition:
	return load("res://data/characters/%s.tres" % id)


static func state(id: String = "yamabushi", seed_value: int = SEED) -> RunState:
	return RunState.start(config(), character(id), seed_value)


static func omamori(id: String) -> OmamoriDefinition:
	return load("res://data/omamori/%s.tres" % id)


static func ball(id: String) -> BallDefinition:
	return load("res://data/balls/%s.tres" % id)
