class_name Rewards
## Choices offered after a won board, drawn from the run's rewards stream: balls with the shop
## odds of the floor, omamori with the odds of the board kind. Choices never repeat, and omamori
## already owned are never offered.


static func ball_choices(
	state: RunState, content: RunContent, config: BalanceConfig
) -> Array[BallDefinition]:
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.REWARDS)
	var offered: Array = []
	for ball: BallDefinition in content.balls:
		if ball.rarity != ItemDefinition.Rarity.BASE:
			offered.append(ball)
	var taken: Array[StringName] = []
	var choices: Array[BallDefinition] = []
	for choice: int in config.reward_choices:
		var rarity: int = RarityRoll.item_rarity(config, state.floor_index, rng)
		var ball: BallDefinition = RarityRoll.pick(offered, rarity, taken, rng) as BallDefinition
		if ball == null:
			break
		taken.append(ball.id)
		choices.append(ball)
	return choices


## Omamori to choose from, drawn with [param weights], one per rarity from common to legendary.
static func omamori_choices(
	state: RunState, content: RunContent, config: BalanceConfig, weights: PackedInt32Array
) -> Array[OmamoriDefinition]:
	var rng: Pcg32 = state.streams.stream(RngStreams.Domain.REWARDS)
	var taken: Array[StringName] = []
	for charm: OmamoriDefinition in state.inventory.loadout.omamori:
		taken.append(charm.id)
	var choices: Array[OmamoriDefinition] = []
	for choice: int in config.reward_choices:
		var rarity: int = RarityRoll.weighted_rarity(weights, rng)
		var charm: OmamoriDefinition = (
			RarityRoll.pick(content.omamori, rarity, taken, rng) as OmamoriDefinition
		)
		if charm == null:
			break
		taken.append(charm.id)
		choices.append(charm)
	return choices
