class_name FloorMap
## The nodes of one floor, step by step: the choice steps, then the shop and the boss.

var nodes: Array[MapNode] = []
## Node indices of every step, in lane order.
var steps: Array[PackedInt32Array] = []


func add_node(node: MapNode) -> int:
	while steps.size() <= node.step:
		steps.append(PackedInt32Array())
	nodes.append(node)
	steps[node.step].append(nodes.size() - 1)
	return nodes.size() - 1


## Nodes the player may pick from [param current], or from the first step when it is -1.
func choices_from(current: int) -> PackedInt32Array:
	if current < 0:
		return steps[0] if not steps.is_empty() else PackedInt32Array()
	return nodes[current].next


func boss() -> int:
	return steps[steps.size() - 1][0]
