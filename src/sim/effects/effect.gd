@tool
class_name Effect
extends RefCounted
## Base of every item behaviour: balls, purchasable pegs, omamori and, later, character powers.
##
## Subclasses override only the hooks they need and act only through [BoardGame]'s effect API.
## Hooks run in a fixed order: the shot's ball, then the hit peg, then omamori by slot.

## [member slot] of a ball's effect.
const BALL_SLOT: int = -1
## [member slot] of a purchased peg's effect.
const PEG_SLOT: int = -2

var definition: ItemDefinition
var level: int = 1
## Omamori slot, or [constant BALL_SLOT] / [constant PEG_SLOT].
var slot: int = BALL_SLOT


## Behaviour of [param item] at [param item_level], or null when the item has no effect script.
static func create(item: ItemDefinition, item_level: int, item_slot: int) -> Effect:
	if item == null or item.effect_script == null:
		return null
	var effect: Effect = item.effect_script.new() as Effect
	effect.definition = item
	effect.level = clampi(item_level, 1, maxi(1, item.level_values.size()))
	effect.slot = item_slot
	return effect


## The definition's value for the current level, or 0 for items without levels.
func value() -> int:
	if definition.level_values.is_empty():
		return 0
	return definition.level_values[level - 1]


func param(key: StringName) -> int:
	return definition.params.get(key, 0)


func on_board_start(_game: BoardGame) -> void:
	pass


func on_shot_start(_game: BoardGame) -> void:
	pass


## [param hit] can be adjusted before it is scored; see [PegHit].
func on_peg_hit(_game: BoardGame, _hit: PegHit) -> void:
	pass


func on_wall_bounce(_game: BoardGame) -> void:
	pass


func on_bucket(_game: BoardGame) -> void:
	pass


func on_shot_end(_game: BoardGame) -> void:
	pass


func on_board_end(_game: BoardGame, _result: BoardResult) -> void:
	pass
