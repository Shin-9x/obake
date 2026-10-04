class_name KasaBridgeEvent
extends RunEvent
## Kasa-obake's bridge: one more omamori slot, one shot fewer on every board, for the rest of
## the run.
## Params: slots, shots.


func _offers(_state: RunState) -> Array[EventChoice]:
	return [EventChoice.new("EVENT_KASA_CROSS")]


func _apply(
	state: RunState, _content: RunContent, _config: BalanceConfig, _index: int, _pick: int
) -> EventOutcome:
	state.inventory.slots += param(&"slots")
	state.shot_delta -= param(&"shots")
	return EventOutcome.new("EVENT_KASA_CROSSED")
