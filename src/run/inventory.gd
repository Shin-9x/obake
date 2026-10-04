class_name Inventory
## What the player owns during a run, kept in a [LoadoutDefinition] so boards can use it as it is:
## the character, the bag with ball levels, the omamori in slot order and the purchased pegs.

var loadout: LoadoutDefinition = LoadoutDefinition.new()
var slots: int = 0

var _config: BalanceConfig


func _init(config: BalanceConfig, character: CharacterDefinition = null) -> void:
	_config = config
	slots = config.omamori_slots
	loadout.character = character
	if character != null:
		for ball: BallDefinition in character.starting_balls:
			add_ball(ball)


func ball_count() -> int:
	return loadout.balls.size()


func ball(index: int) -> BallDefinition:
	return loadout.balls[index]


func level_of(index: int) -> int:
	return loadout.level_of(index)


func add_ball(definition: BallDefinition, level: int = 1) -> void:
	_fill_levels()
	loadout.balls.append(definition)
	loadout.ball_levels.append(level)


func can_remove_ball() -> bool:
	return ball_count() > _config.min_bag_size


func remove_ball(index: int) -> bool:
	if not can_remove_ball() or index < 0 or index >= ball_count():
		return false
	_fill_levels()
	loadout.balls.remove_at(index)
	loadout.ball_levels.remove_at(index)
	return true


func can_upgrade_ball(index: int) -> bool:
	if index < 0 or index >= ball_count():
		return false
	var levels: int = maxi(1, ball(index).level_values.size())
	return level_of(index) < mini(_config.max_ball_level, levels)


func upgrade_ball(index: int) -> bool:
	if not can_upgrade_ball(index):
		return false
	_fill_levels()
	loadout.ball_levels[index] += 1
	return true


## Indices of the balls that can still go up a level.
func upgradable_balls() -> PackedInt32Array:
	var found: PackedInt32Array = PackedInt32Array()
	for index: int in ball_count():
		if can_upgrade_ball(index):
			found.append(index)
	return found


func omamori_count() -> int:
	return loadout.omamori.size()


func free_slots() -> int:
	return maxi(0, slots - omamori_count())


func owns_omamori(charm: OmamoriDefinition) -> bool:
	for owned: OmamoriDefinition in loadout.omamori:
		if owned.id == charm.id:
			return true
	return false


## Puts [param charm] in the first free slot; false when every slot is taken.
func add_omamori(charm: OmamoriDefinition) -> bool:
	if free_slots() == 0:
		return false
	loadout.omamori.append(charm)
	return true


func replace_omamori(slot: int, charm: OmamoriDefinition) -> void:
	loadout.omamori[slot] = charm


func remove_omamori(slot: int) -> OmamoriDefinition:
	var removed: OmamoriDefinition = loadout.omamori[slot]
	loadout.omamori.remove_at(slot)
	return removed


func add_peg(peg: PegDefinition) -> void:
	loadout.purchased_pegs.append(peg)


func _fill_levels() -> void:
	while loadout.ball_levels.size() < loadout.balls.size():
		loadout.ball_levels.append(1)
