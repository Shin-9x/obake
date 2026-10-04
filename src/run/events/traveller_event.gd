class_name TravellerEvent
extends RunEvent
## The mysterious traveller: a random rare ball for a price.
## Params: price.


func text_args() -> Array:
	return [param(&"price")]


func _offers(state: RunState) -> Array[EventChoice]:
	var price: int = param(&"price")
	return [EventChoice.new("EVENT_TRAVELLER_BUY", [price], state.can_afford(price))]


func _apply(
	state: RunState, content: RunContent, _config: BalanceConfig, _index: int, _pick: int
) -> EventOutcome:
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.REWARDS)
	var ball: BallDefinition = (
		RarityRoll.pick(content.balls, ItemDefinition.Rarity.RARE, [], rng) as BallDefinition
	)
	state.spend(param(&"price"))
	state.inventory.add_ball(ball)
	return EventOutcome.new("EVENT_TRAVELLER_BOUGHT", ball)
