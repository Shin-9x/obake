extends RefCounted
## Small, controlled boards for effect tests.
##
## Every peg starts blue except one gold, picked by the seed, plus a spare red lantern added last,
## out of every path, so a shot never wins by Matsuri by accident. The straight drop from the
## launcher misses pegs placed away from x = 180 px, and the bucket is parked against the right
## wall, so a shot ends with the ball lost.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const Probe: GDScript = preload("res://tests/sim/support/probe_effect.gd")
const PX: int = FixedMath.PX
const SEED: int = 7
## Where the spare red lantern sits.
const SPARE: Vector2i = Vector2i(340, 40)
## Pegs out of the ball's way: a row across the board at y = 200 px.
const ROW: Array[Vector2i] = [
	Vector2i(40, 200), Vector2i(80, 200), Vector2i(120, 200), Vector2i(240, 200), Vector2i(280, 200)
]


static func config() -> BalanceConfig:
	var result: BalanceConfig = TestBoards.gdd_config()
	result.red_permille = 0
	result.green_count = 0
	TestBoards.freeze_bucket(result)
	return result


## Typed arrays and dictionaries do not survive calls through a preloaded script, so the helpers
## take plain ones and convert them.
static func board(
	positions: Array,
	loadout: LoadoutDefinition = null,
	settings: BalanceConfig = null,
	board_seed: int = SEED,
	rules: BoardRules = null
) -> BoardGame:
	var used: BalanceConfig = settings if settings != null else config()
	var simulation: BoardSimulation = BoardSimulation.new(used)
	for position: Vector2i in positions:
		simulation.add_round_peg(position.x * PX, position.y * PX)
	simulation.add_round_peg(SPARE.x * PX, SPARE.y * PX)
	var rng: Pcg32 = Pcg32.new(board_seed, RngStreams.Domain.BOARD)
	var game: BoardGame = BoardGame.new(
		simulation, used, TestBoards.gdd_pegs(), rng, loadout, null, rules
	)
	var spare: int = positions.size()
	if game.roles[spare] == BoardGame.Role.GOLD and spare > 0:
		# The gold would turn the spare back to blue when it moves, ending the board in a
		# Matsuri; it starts on the first peg instead.
		game._gold = 0
		game.roles[0] = BoardGame.Role.GOLD
	game.roles[spare] = BoardGame.Role.RED
	return game


static func loadout(balls: Array = [], omamori: Array = [], pegs: Array = []) -> LoadoutDefinition:
	var result: LoadoutDefinition = LoadoutDefinition.new()
	result.balls.assign(balls)
	result.omamori.assign(omamori)
	result.purchased_pegs.assign(pegs)
	return result


## Fires straight down with the bucket parked away, without simulating anything yet.
static func shoot(game: BoardGame, aim: int = 0) -> void:
	game.shoot(ShotInput.new(aim, game.simulation.bucket.period() / 4))


static func finish(game: BoardGame) -> void:
	for i: int in TestBoards.MAX_SHOT_TICKS:
		if not game.simulation.is_shot_active():
			return
		game.step()


## Turns every peg but the spare red into a plain blue lantern, so scores are predictable.
static func all_blue(game: BoardGame) -> void:
	for peg: int in game.roles.size() - 1:
		game.roles[peg] = BoardGame.Role.BLUE


static func probe_ball() -> BallDefinition:
	var ball: BallDefinition = BallDefinition.new()
	ball.id = &"probe_ball"
	ball.effect_script = Probe
	return ball


static func probe_omamori(params: Dictionary = {}) -> OmamoriDefinition:
	var charm: OmamoriDefinition = OmamoriDefinition.new()
	charm.id = &"probe_omamori"
	charm.effect_script = Probe
	charm.params.assign(params)
	return charm


static func probe_character(params: Dictionary = {}) -> CharacterDefinition:
	var character: CharacterDefinition = CharacterDefinition.new()
	character.id = &"probe_character"
	character.effect_script = Probe
	character.params.assign(params)
	return character


static func probe_boss(params: Dictionary = {}) -> BossDefinition:
	var boss: BossDefinition = BossDefinition.new()
	boss.id = &"probe_boss"
	boss.effect_script = Probe
	boss.params.assign(params)
	return boss


static func probe_peg(script: GDScript = Probe) -> PegDefinition:
	var peg: PegDefinition = PegDefinition.new()
	peg.id = &"probe_peg"
	peg.points = 10
	peg.effect_script = script
	return peg


## Fires straight down with the bucket centred under the launcher, so the ball is caught.
static func shoot_into_bucket(game: BoardGame) -> void:
	game.shoot(ShotInput.new(0, 0))


## A loadout with one ball of [param path] at [param level].
static func with_ball(path: String, level: int = 1) -> LoadoutDefinition:
	var result: LoadoutDefinition = loadout([load(path)])
	result.ball_levels = PackedInt32Array([level])
	return result


static func with_omamori(path: String) -> LoadoutDefinition:
	return loadout([], [load(path)])


static func events_of(game: BoardGame, kind: SimEvent.Kind) -> Array[SimEvent]:
	var found: Array[SimEvent] = []
	for index: int in game.events.size():
		if game.events.at(index).kind == kind:
			found.append(game.events.at(index))
	return found
