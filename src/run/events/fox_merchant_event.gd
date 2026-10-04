class_name FoxMerchantEvent
extends RunEvent
## The fox merchant: an omamori traded for a random one of a higher rarity, in the same slot.
## Legendaries cannot be traded; when no higher omamori is left at the next rarity, the fox
## reaches for the one above.


func _offers(state: RunState) -> Array[EventChoice]:
	var tradable: PackedInt32Array = PackedInt32Array()
	var charms: Array[OmamoriDefinition] = state.inventory.loadout.omamori
	for slot: int in charms.size():
		if charms[slot].rarity < ItemDefinition.Rarity.LEGENDARY:
			tradable.append(slot)
	var choice: EventChoice = EventChoice.new("EVENT_FOX_TRADE", [], not tradable.is_empty())
	choice.pick = EventChoice.Pick.OMAMORI
	choice.options = tradable
	return [choice]


func _apply(
	state: RunState, content: RunContent, _config: BalanceConfig, _index: int, pick: int
) -> EventOutcome:
	var given: OmamoriDefinition = state.inventory.loadout.omamori[pick]
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.REWARDS)
	for tier: int in range(given.rarity + 1, ItemDefinition.Rarity.LEGENDARY + 1):
		var candidates: Array[OmamoriDefinition] = []
		for charm: OmamoriDefinition in content.omamori:
			if charm.rarity == tier and not state.inventory.owns_omamori(charm):
				candidates.append(charm)
		if candidates.is_empty():
			continue
		var received: OmamoriDefinition = candidates[rng.next_below(candidates.size())]
		state.inventory.replace_omamori(pick, received)
		return EventOutcome.new("EVENT_FOX_TRADED", received)
	return EventOutcome.new(LEFT_KEY)
