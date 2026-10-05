extends GdUnitTestSuite
## Golden results of every boss board played with fixed inputs, which locks the boss rules, their
## layouts and the characters' powers together. If a deliberate change alters one, update it in
## the same commit and explain why in the commit message.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const AIMS: Array[int] = [0, -2500, 1234, 8500, -8500, 4321, -777, 6000]
const BUCKET_PHASES: Array[int] = [0, 100, 200, 300, 400, 37, 251, 479]
const BOARD_SEED: int = 20261004
## Low enough for Nue to reach half of it and transform.
const TARGET: int = 1600
const HASH_MODULUS: int = 2_147_483_647
const HASH_MULTIPLIER: int = 1_000_003
## Total and hash chain per boss.
const GOLDEN: Dictionary[String, Array] = {
	"jorogumo": [1380, 577019640],
	"nue": [1010, 2028664732],
	"tamamo": [685, 493019329],
	"shuten_doji": [850, 445596392],
}


func test_boss_boards_match_their_golden_results() -> void:
	for id: String in GOLDEN:
		var first: Dictionary[String, Variant] = _play(id)
		var second: Dictionary[String, Variant] = _play(id)
		assert_int(second["chain"]).is_equal(first["chain"])
		assert_array([first["total"], first["chain"]]).is_equal(GOLDEN[id])


func test_nue_transforms_during_its_golden_game() -> void:
	assert_bool(_play("nue")["transformed"]).is_true()


func _play(id: String) -> Dictionary[String, Variant]:
	var boss: BossDefinition = load("res://data/bosses/%s.tres" % id)
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var loadout: LoadoutDefinition = LoadoutDefinition.new()
	loadout.character = load("res://data/characters/kitsune.tres")
	loadout.balls.assign(loadout.character.starting_balls)
	var second: BoardLayout = null
	if not boss.second_layout_id.is_empty():
		second = library.find(boss.second_layout_id)
	var game: BoardGame = (
		BoardSetup
		. create_board(
			TestBoards.gdd_config(),
			TestBoards.gdd_pegs(),
			library.find(boss.layout_id),
			BOARD_SEED,
			loadout,
			null,
			BoardRules.new(TARGET, 0, boss),
			second
		)
		. game
	)
	var chain: int = 0
	var transformed: bool = false
	for shot: int in AIMS.size():
		if not game.shoot(ShotInput.new(AIMS[shot], BUCKET_PHASES[shot])):
			break
		while game.simulation.is_shot_active():
			game.step()
			for index: int in game.events.size():
				var event: SimEvent = game.events.at(index)
				chain = (chain * HASH_MULTIPLIER + event.amount) % HASH_MODULUS
				transformed = transformed or event.kind == SimEvent.Kind.LAYOUT_CHANGED
			game.events.clear()
		chain = (chain * HASH_MULTIPLIER + game.simulation.state_hash()) % HASH_MODULUS
	return {"total": game.total, "chain": chain, "transformed": transformed}
