extends GdUnitTestSuite
## The same board and the same inputs must always produce the same simulation, on every platform.

const TestBoards: GDScript = preload("res://tests/sim/support/test_boards.gd")
## No straight-down shot: it would balance on the peg under the launcher until M2 adds the
## stuck-ball rule.
const AIMS: Array[int] = [150, -2500, 1234, 8500, -8500, 4321, -777, 6000]
const HASH_MODULUS: int = 2_147_483_647
const HASH_MULTIPLIER: int = 1_000_003
## Hash chain of every tick of [constant AIMS] on the staggered board. If a deliberate physics
## change alters it, update it in the same commit and explain why in the commit message.
const GOLDEN_CHAIN: int = 150577145


func test_identical_inputs_produce_identical_runs() -> void:
	var first: Dictionary[String, Variant] = _record_run()
	var second: Dictionary[String, Variant] = _record_run()
	assert_array(second["hashes"]).is_equal(first["hashes"])
	assert_array(second["events"]).is_equal(first["events"])


func test_every_shot_resolves() -> void:
	var sim: BoardSimulation = _staggered_board()
	for aim: int in AIMS:
		TestBoards.run_shot(sim, aim)
		assert_bool(sim.is_shot_active()).is_false()


func test_run_matches_golden_hash() -> void:
	var run: Dictionary[String, Variant] = _record_run()
	assert_int(run["chain"]).is_equal(GOLDEN_CHAIN)


func _staggered_board() -> BoardSimulation:
	var sim: BoardSimulation = BoardSimulation.new(TestBoards.gdd_config())
	TestBoards.add_staggered_pegs(sim)
	return sim


func _record_run() -> Dictionary[String, Variant]:
	var sim: BoardSimulation = _staggered_board()
	var hashes: PackedInt64Array = PackedInt64Array()
	var events: PackedInt64Array = PackedInt64Array()
	var chain: int = 0
	for aim: int in AIMS:
		sim.launch(ShotInput.new(aim))
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
