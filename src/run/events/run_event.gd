class_name RunEvent
## Behaviour of a yokai event: the choices it offers and what each does to the run. Every event
## ends its list with walking away, which does nothing.
##
## Subclasses implement [method _offers] and [method _apply]; random outcomes draw from the
## run's rewards stream.

const LEAVE_KEY: String = "EVENT_LEAVE"
const LEFT_KEY: String = "EVENT_LEFT"

var definition: EventDefinition


static func create(event: EventDefinition) -> RunEvent:
	var behaviour: RunEvent = event.event_script.new() as RunEvent
	behaviour.definition = event
	return behaviour


## The event of an event node, drawn from the map stream among those not met yet in this run;
## once every event has been met, any of them can come back.
static func draw(state: RunState, content: RunContent) -> EventDefinition:
	var fresh: Array[EventDefinition] = []
	for event: EventDefinition in content.events:
		if not state.events_seen.has(event.id):
			fresh.append(event)
	if fresh.is_empty():
		fresh = content.events.duplicate()
	if fresh.is_empty():
		return null
	var event: EventDefinition = fresh[state.streams.stream(RngStreams.Domain.MAP).next_below(
		fresh.size()
	)]
	state.events_seen.append(event.id)
	return event


## Values for the %d placeholders of the event text.
func text_args() -> Array:
	return []


func choices(state: RunState) -> Array[EventChoice]:
	var list: Array[EventChoice] = _offers(state)
	list.append(EventChoice.new(LEAVE_KEY))
	return list


## Applies option [param index], with [param pick] when it asks for one. Returns null when the
## option is not available or the pick is not allowed.
func choose(
	state: RunState, content: RunContent, config: BalanceConfig, index: int, pick: int = -1
) -> EventOutcome:
	var list: Array[EventChoice] = choices(state)
	if index < 0 or index >= list.size() or not list[index].enabled:
		return null
	if list[index].pick != EventChoice.Pick.NONE and not list[index].options.has(pick):
		return null
	if index == list.size() - 1:
		return EventOutcome.new(LEFT_KEY)
	return _apply(state, content, config, index, pick)


func param(key: StringName) -> int:
	return definition.params.get(key, 0)


## The options before walking away.
func _offers(_state: RunState) -> Array[EventChoice]:
	return []


func _apply(
	_state: RunState, _content: RunContent, _config: BalanceConfig, _index: int, _pick: int
) -> EventOutcome:
	return null


## A ball option offering every bag index in [param indices].
static func _ball_choice(key: String, indices: PackedInt32Array) -> EventChoice:
	var choice: EventChoice = EventChoice.new(key, [], not indices.is_empty())
	choice.pick = EventChoice.Pick.BALL
	choice.options = indices
	return choice
