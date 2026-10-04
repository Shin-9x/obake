class_name MapScreen
extends Control
## The floor map: steps from left to right, the shop and the boss at the end, links between the
## nodes, and the nodes the player can pick next lit up.

signal node_chosen(node: int)

const NODE_SIZE: Vector2 = Vector2(28, 28)
const BOSS_SIZE: Vector2 = Vector2(44, 44)
## Where the map is drawn inside the page.
const AREA: Rect2 = Rect2(40, 60, 560, 250)
const LANE_SPACING: float = 70.0
const DIMMED: Color = Color(1, 1, 1, 0.6)
const LEGEND_TOP: float = 326.0
const LEGEND_ICON: Vector2 = Vector2(14, 14)
const KIND_KEYS: Array[String] = [
	"MAP_NODE_BOARD",
	"MAP_NODE_ELITE",
	"MAP_NODE_EVENT",
	"MAP_NODE_SHRINE",
	"MAP_NODE_SHOP",
	"MAP_NODE_BOSS",
]

var _run: Run
var _skin: MapSkin
var _lines: Control
var _centres: PackedVector2Array = PackedVector2Array()


func open(run: Run, skin: MapSkin) -> void:
	_run = run
	_skin = skin
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	var bar: RunBar = RunBar.new()
	bar.position = Vector2(16, 8)
	page.add_child(bar)
	bar.show_run(run)
	var boss: BossDefinition = run.current_boss()
	var heading: Label = UiKit.label(
		tr("MAP_BOSS") % tr(boss.name_key),
		0,
		UiKit.RARITY_COLOURS[ItemDefinition.Rarity.LEGENDARY],
		false
	)
	heading.position = Vector2(16, 30)
	page.add_child(heading)
	_lines = Control.new()
	_lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lines.size = UiKit.PAGE_SIZE
	_lines.draw.connect(_draw_links)
	page.add_child(_lines)
	var map: FloorMap = run.state.current_map()
	_centres.resize(map.nodes.size())
	var columns: int = map.steps.size()
	for step: int in columns:
		var nodes: PackedInt32Array = map.steps[step]
		for lane: int in nodes.size():
			var x: float = AREA.position.x + AREA.size.x * step / maxf(1.0, columns - 1.0)
			var y: float = AREA.get_center().y + (lane - (nodes.size() - 1) / 2.0) * LANE_SPACING
			_centres[nodes[lane]] = Vector2(x, y)
	var reachable: PackedInt32Array = run.reachable_nodes()
	for index: int in map.nodes.size():
		page.add_child(_node_button(map, index, reachable.has(index)))
	var legend: HBoxContainer = UiKit.row(10)
	legend.position = Vector2(16, LEGEND_TOP)
	legend.size = Vector2(UiKit.PAGE_SIZE.x - 32, LEGEND_ICON.y)
	for kind: int in MapNode.Kind.BOSS:
		legend.add_child(UiKit.icon(skin.node_icons[kind], LEGEND_ICON))
		legend.add_child(UiKit.label(KIND_KEYS[kind], UiKit.SMALL_SIZE, UiKit.MUTED))
	page.add_child(legend)
	_lines.queue_redraw()


func _node_button(map: FloorMap, index: int, reachable: bool) -> Button:
	var node: MapNode = map.nodes[index]
	var button: Button = Button.new()
	var size: Vector2 = BOSS_SIZE if node.kind == MapNode.Kind.BOSS else NODE_SIZE
	button.custom_minimum_size = size
	button.size = size
	button.position = _centres[index] - size / 2.0
	button.focus_mode = Control.FOCUS_NONE
	button.icon = _skin.node_icons[node.kind]
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if node.kind == MapNode.Kind.BOSS:
		button.icon = _run.current_boss().portrait
	button.tooltip_text = _describe(node)
	button.disabled = not reachable
	# Nodes out of reach keep their icon readable; only the dimming below marks them.
	button.add_theme_color_override("icon_disabled_color", Color.WHITE)
	var boss: bool = node.kind == MapNode.Kind.BOSS
	if not reachable and not boss and index != _run.state.node:
		button.modulate = DIMMED
	button.pressed.connect(node_chosen.emit.bind(index))
	return button


func _describe(node: MapNode) -> String:
	var text: String = tr(KIND_KEYS[node.kind])
	if node.kind == MapNode.Kind.BOSS:
		var boss: BossDefinition = _run.current_boss()
		text += "\n%s\n%s" % [tr(boss.name_key), tr(boss.description_key)]
	if node.is_board():
		var target: int = TargetSchedule.target(_run.config, node.kind, _run.state.boards_played)
		text += "\n" + tr("MAP_TARGET") % target
	return text


func _draw_links() -> void:
	var map: FloorMap = _run.state.current_map()
	var reachable: PackedInt32Array = _run.reachable_nodes()
	for index: int in map.nodes.size():
		for next: int in map.nodes[index].next:
			var open: bool = index == _run.state.node and reachable.has(next)
			var colour: Color = _skin.open_line_color if open else _skin.line_color
			_lines.draw_line(_centres[index], _centres[next], colour, 1.0)
