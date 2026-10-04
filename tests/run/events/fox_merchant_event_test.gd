extends GdUnitTestSuite

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")
const Events: GDScript = preload("res://tests/run/events/support.gd")


func test_an_omamori_is_traded_for_a_rarer_one_in_the_same_slot() -> void:
	for seed_value: int in 20:
		var state: RunState = Fixtures.state("yamabushi", seed_value)
		state.inventory.add_omamori(Fixtures.omamori("drum"))
		state.inventory.add_omamori(Fixtures.omamori("chochin"))
		var outcome: EventOutcome = Events.choose(Events.event("fox_merchant"), state, 0, 1)
		var received: OmamoriDefinition = state.inventory.loadout.omamori[1]
		assert_object(outcome.item).is_same(received)
		assert_int(received.rarity).is_greater(ItemDefinition.Rarity.COMMON)
		assert_str(String(state.inventory.loadout.omamori[0].id)).is_equal("drum")


func test_legendaries_cannot_be_traded() -> void:
	var state: RunState = Fixtures.state()
	state.inventory.add_omamori(Fixtures.omamori("tsukumogami"))
	var trade: EventChoice = Events.event("fox_merchant").choices(state)[0]
	assert_bool(trade.enabled).is_false()
	assert_array(trade.options).is_empty()
