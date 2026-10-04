extends RefCounted
## Helpers for the event tests.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


static func event(id: String) -> RunEvent:
	return RunEvent.create(load("res://data/events/%s.tres" % id))


static func choose(
	behaviour: RunEvent, state: RunState, index: int, pick: int = -1
) -> EventOutcome:
	return behaviour.choose(state, Fixtures.content(), Fixtures.config(), index, pick)
