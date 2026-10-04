extends GdUnitTestSuite
## What every event shares: walking away, refused options and the draw of events.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_every_event_ends_with_walking_away_which_changes_nothing() -> void:
	for event: EventDefinition in Fixtures.content().events:
		var state: RunState = Fixtures.state()
		var behaviour: RunEvent = RunEvent.create(event)
		var choices: Array[EventChoice] = behaviour.choices(state)
		assert_str(choices[choices.size() - 1].text_key).is_equal("EVENT_LEAVE")
		var outcome: EventOutcome = Events.choose(behaviour, state, choices.size() - 1)
		assert_str(outcome.text_key).is_equal("EVENT_LEFT")
		assert_int(state.mon).is_equal(4)
		assert_int(state.inventory.ball_count()).is_equal(8)


func test_disabled_options_and_bad_picks_are_refused() -> void:
	var state: RunState = Fixtures.state()
	state.mon = 0
	assert_object(Events.choose(Events.event("traveller"), state, 0)).is_null()
	assert_object(Events.choose(Events.event("hot_spring"), state, 0, 0)).is_null()


func test_events_are_drawn_without_repeats_until_all_were_met() -> void:
	var state: RunState = Fixtures.state()
	var content: RunContent = Fixtures.content()
	var met: Dictionary[StringName, bool] = {}
	for draw: int in content.events.size():
		var event: EventDefinition = RunEvent.draw(state, content)
		assert_bool(met.has(event.id)).is_false()
		met[event.id] = true
	assert_object(RunEvent.draw(state, content)).is_not_null()
