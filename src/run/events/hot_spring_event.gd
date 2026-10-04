class_name HotSpringEvent
extends RunEvent
## The hot spring: one ball goes up a level for free.


func _offers(state: RunState) -> Array[EventChoice]:
	return [_ball_choice("EVENT_SPRING_UPGRADE", state.inventory.upgradable_balls())]


func _apply(
	state: RunState, _content: RunContent, _config: BalanceConfig, _index: int, pick: int
) -> EventOutcome:
	state.inventory.upgrade_ball(pick)
	return EventOutcome.new("EVENT_SPRING_UPGRADED", state.inventory.ball(pick))
