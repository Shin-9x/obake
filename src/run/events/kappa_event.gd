class_name KappaEvent
extends RunEvent
## The gambling kappa: pay a bet now; a Matsuri on the next board pays the winnings.
## Params: bet, winnings.


func text_args() -> Array:
	return [param(&"bet"), param(&"winnings")]


func _offers(state: RunState) -> Array[EventChoice]:
	var bet: int = param(&"bet")
	return [EventChoice.new("EVENT_KAPPA_BET", [bet], state.can_afford(bet) and state.bet == 0)]


func _apply(
	state: RunState, _content: RunContent, _config: BalanceConfig, _index: int, _pick: int
) -> EventOutcome:
	state.spend(param(&"bet"))
	state.bet = param(&"winnings")
	return EventOutcome.new("EVENT_KAPPA_BET_DONE")
