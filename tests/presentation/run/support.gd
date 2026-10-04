extends RefCounted
## Runs set up in a given phase and lookups of the controls the run screens build.

const Fixtures: GDScript = preload("res://tests/run/support/run_fixtures.gd")


static func run(character: String = "yamabushi") -> Run:
	return Fixtures.run(character)


## Turns the first reachable node into [param kind] and enters it.
static func enter(played: Run, kind: MapNode.Kind) -> void:
	var node: int = played.reachable_nodes()[0]
	played.state.current_map().nodes[node].kind = kind
	played.choose_node(node)


static func win(played: Run, kind: MapNode.Kind) -> void:
	enter(played, kind)
	Fixtures.finish(played, BoardGame.Outcome.TARGET_REACHED)


## Every descendant of [param node] that is a [param type], in tree order.
static func find_all(node: Node, type: Variant) -> Array[Node]:
	var found: Array[Node] = []
	for child: Node in node.get_children():
		if is_instance_of(child, type):
			found.append(child)
		found.append_array(find_all(child, type))
	return found


## The button whose text is [param text], or null.
static func button(node: Node, text: String) -> Button:
	for found: Node in find_all(node, Button):
		if (found as Button).text == text:
			return found as Button
	return null
