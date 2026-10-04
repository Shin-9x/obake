class_name MapNode
## One stop on a floor map.

enum Kind { BOARD, ELITE, EVENT, SHRINE, SHOP, BOSS }

var kind: Kind = Kind.BOARD
## Column of the map, from 0; the shop and the boss take the last two.
var step: int = 0
## Row within the step, from 0, for drawing.
var lane: int = 0
## Indices, in the floor map, of the nodes this one leads to.
var next: PackedInt32Array = PackedInt32Array()


func _init(node_kind: Kind = Kind.BOARD, node_step: int = 0, node_lane: int = 0) -> void:
	kind = node_kind
	step = node_step
	lane = node_lane


func is_board() -> bool:
	return kind == Kind.BOARD or kind == Kind.ELITE or kind == Kind.BOSS
