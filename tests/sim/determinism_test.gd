extends GdUnitTestSuite
## The same board and the same inputs must always produce the same simulation, on every platform.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
const AIMS: Array[int] = [0, -2500, 1234, 8500, -8500, 4321, -777, 6000]
const BUCKET_PHASES: Array[int] = [0, 100, 200, 300, 400, 37, 251, 479]
const BOARD_SEED: int = 20261003
const HASH_MODULUS: int = 2_147_483_647
const HASH_MULTIPLIER: int = 1_000_003
## Hash chain of every tick of [constant AIMS] on the staggered board. If a deliberate physics
## change alters it, update it in the same commit and explain why in the commit message.
const GOLDEN_CHAIN: int = 1289445351
## Hash chain of the same shots on a board with a water wheel and sliding stalks.
const GOLDEN_MOVING_CHAIN: int = 24347088
## Final total and hash chain of the same game with every ball, purchasable peg and a full set
## of omamori in play, which locks the behaviour of all the items together.
const GOLDEN_LOADOUT_TOTAL: int = 1085
const GOLDEN_LOADOUT_CHAIN: int = 1425766894
## Final total and hash chain of a full [BoardGame] played with the same inputs.
const GOLDEN_GAME_TOTAL: int = 890
const GOLDEN_GAME_CHAIN: int = 407667046


func test_identical_inputs_produce_identical_runs() -> void:
	var first: Dictionary[String, Variant] = _record_run(_staggered_board())
	var second: Dictionary[String, Variant] = _record_run(_staggered_board())
	assert_array(second["hashes"]).is_equal(first["hashes"])
	assert_array(second["events"]).is_equal(first["events"])


func test_every_shot_resolves() -> void:
	var sim: BoardSimulation = _staggered_board()
	for shot: int in AIMS.size():
		TestBoards.run_shot(sim, AIMS[shot], BUCKET_PHASES[shot])
		assert_bool(sim.is_shot_active()).is_false()


func test_run_matches_golden_hash() -> void:
	var run: Dictionary[String, Variant] = _record_run(_staggered_board())
	assert_int(run["chain"]).is_equal(GOLDEN_CHAIN)


func test_moving_board_matches_golden_hash() -> void:
	var sim: BoardSimulation = BoardSimulation.new(TestBoards.gdd_config())
	TestBoards.add_moving_pegs(sim)
	var first: Dictionary[String, Variant] = _record_run(sim)
	sim = BoardSimulation.new(TestBoards.gdd_config())
	TestBoards.add_moving_pegs(sim)
	var second: Dictionary[String, Variant] = _record_run(sim)
	assert_array(second["hashes"]).is_equal(first["hashes"])
	assert_int(first["chain"]).is_equal(GOLDEN_MOVING_CHAIN)


func test_board_game_matches_golden_result() -> void:
	var first: Dictionary[String, Variant] = _play_game()
	var second: Dictionary[String, Variant] = _play_game()
	assert_int(second["total"]).is_equal(first["total"])
	assert_int(second["chain"]).is_equal(first["chain"])
	assert_int(first["total"]).is_equal(GOLDEN_GAME_TOTAL)
	assert_int(first["chain"]).is_equal(GOLDEN_GAME_CHAIN)


func test_loaded_game_matches_golden_result() -> void:
	var first: Dictionary[String, Variant] = _play_game(_full_loadout())
	var second: Dictionary[String, Variant] = _play_game(_full_loadout())
	assert_int(second["total"]).is_equal(first["total"])
	assert_int(second["chain"]).is_equal(first["chain"])
	assert_int(first["total"]).is_equal(GOLDEN_LOADOUT_TOTAL)
	assert_int(first["chain"]).is_equal(GOLDEN_LOADOUT_CHAIN)


func _full_loadout() -> LoadoutDefinition:
	var loadout: LoadoutDefinition = LoadoutDefinition.new()
	var files: PackedStringArray = DirAccess.get_files_at("res://data/balls")
	files.sort()
	for file: String in files:
		loadout.balls.append(load("res://data/balls/" + file))
	for id: String in ["chochin", "first_strike", "patience", "drum", "yata_mirror"]:
		loadout.omamori.append(load("res://data/omamori/%s.tres" % id))
	for id: String in ["coin_peg", "bell", "explosive_lantern", "torii", "kagami", "omikuji"]:
		loadout.purchased_pegs.append(load("res://data/pegs/%s.tres" % id))
	return loadout


func _staggered_board() -> BoardSimulation:
	var sim: BoardSimulation = BoardSimulation.new(TestBoards.gdd_config())
	TestBoards.add_staggered_pegs(sim)
	return sim


func _record_run(sim: BoardSimulation) -> Dictionary[String, Variant]:
	var hashes: PackedInt64Array = PackedInt64Array()
	var events: PackedInt64Array = PackedInt64Array()
	var chain: int = 0
	for shot: int in AIMS.size():
		sim.launch(ShotInput.new(AIMS[shot], BUCKET_PHASES[shot]))
		var ticks: int = 0
		while sim.is_shot_active() and ticks < TestBoards.MAX_SHOT_TICKS:
			sim.step()
			ticks += 1
			var state: int = sim.state_hash()
			hashes.append(state)
			chain = (chain * HASH_MULTIPLIER + state) % HASH_MODULUS
			for index: int in sim.events.size():
				var event: SimEvent = sim.events.at(index)
				events.append_array(
					[event.kind, event.tick, event.ball, event.target, event.x, event.y]
				)
			sim.events.clear()
	return {"hashes": hashes, "events": events, "chain": chain}


func _play_game(loadout: LoadoutDefinition = null) -> Dictionary[String, Variant]:
	var game: BoardGame = TestBoards.staggered_game(BOARD_SEED, loadout)
	var chain: int = 0
	for shot: int in AIMS.size():
		if not game.shoot(ShotInput.new(AIMS[shot], BUCKET_PHASES[shot])):
			break
		while game.simulation.is_shot_active():
			game.step()
			for index: int in game.events.size():
				chain = (chain * HASH_MULTIPLIER + game.events.at(index).amount) % HASH_MODULUS
			game.events.clear()
		chain = (chain * HASH_MULTIPLIER + game.simulation.state_hash()) % HASH_MODULUS
	return {"total": game.total, "chain": chain}
