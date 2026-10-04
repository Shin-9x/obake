class_name AbandonedTempleEvent
extends RunEvent
## The abandoned temple: leave a ball behind for free, or take a random common omamori.

const REMOVE: int = 0


func _offers(state: RunState) -> Array[EventChoice]:
	var removable: PackedInt32Array = PackedInt32Array()
	if state.inventory.can_remove_ball():
		removable = PackedInt32Array(range(state.inventory.ball_count()))
	return [
		_ball_choice("EVENT_TEMPLE_REMOVE", removable),
		EventChoice.new("EVENT_TEMPLE_TAKE", [], state.inventory.free_slots() > 0),
	]


func _apply(
	state: RunState, content: RunContent, _config: BalanceConfig, index: int, pick: int
) -> EventOutcome:
	if index == REMOVE:
		state.inventory.remove_ball(pick)
		return EventOutcome.new("EVENT_TEMPLE_REMOVED")
	var owned: Array[StringName] = []
	for charm: OmamoriDefinition in state.inventory.loadout.omamori:
		owned.append(charm.id)
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.REWARDS)
	var found: OmamoriDefinition = (
		RarityRoll.pick(content.omamori, ItemDefinition.Rarity.COMMON, owned, rng)
		as OmamoriDefinition
	)
	if found == null:
		return EventOutcome.new(LEFT_KEY)
	state.inventory.add_omamori(found)
	return EventOutcome.new("EVENT_TEMPLE_TAKEN", found)
