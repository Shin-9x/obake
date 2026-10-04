@tool
class_name LayoutDocument
extends Node2D
## Root of a layout source scene. Its children describe the pegs: [PegMarker]s, pattern
## generators and [MovingGroupMarker]s, plus any [ZoneMarker]s. Export writes
## data/layouts/<id>.json.
##
## Coordinates are board pixels with the origin at the top-left corner of the board.

const OUTPUT_DIRECTORY: String = "res://data/layouts"
const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const PX: float = 1000.0
## Seconds between refreshes of the editor warnings while editing.
const CHECK_INTERVAL: float = 0.5
const FRAME_COLOUR: Color = Color("#f4e9c9")
const GUIDE_COLOUR: Color = Color("#f4e9c955")

@export var id: String = "":
	set(value):
		id = value
		mark_dirty()
@export_enum("bamboo_forest", "haunted_village") var biome: String = "bamboo_forest"
@export var kind: BoardLayout.Kind = BoardLayout.Kind.BOARD
@export var mirrorable: bool = true
@export_tool_button("Export JSON", "Save") var export_button: Callable = export_json

var _dirty: bool = true
var _since_check: float = 0.0
var _warnings: PackedStringArray = PackedStringArray()


## Appends the pegs described by [param node] and its children to [param pegs]. Moving groups
## are skipped: they collect their own pegs.
static func collect_pegs(node: Node, pegs: Array[LayoutPeg]) -> void:
	if node is MovingGroupMarker:
		return
	if node is PegMarker:
		pegs.append((node as PegMarker).to_layout_peg())
	elif node is LayoutPattern:
		pegs.append_array((node as LayoutPattern).generate_pegs())
		return
	for child: Node in node.get_children():
		collect_pegs(child, pegs)


func build_layout() -> BoardLayout:
	var layout: BoardLayout = BoardLayout.new()
	layout.id = id
	layout.biome = biome
	layout.kind = kind
	layout.mirrorable = mirrorable
	for child: Node in get_children():
		collect_pegs(child, layout.pegs)
	_collect_groups(self, layout.groups)
	_collect_zones(self, layout.zones)
	return layout


func output_path() -> String:
	return OUTPUT_DIRECTORY.path_join(id + ".json")


## Writes the layout JSON. Problems found by [LayoutChecks] are reported but do not block the
## export, so work in progress can still be tried in game.
func export_json() -> Error:
	if id.is_empty():
		push_error("Layout has no id; nothing exported.")
		return ERR_INVALID_PARAMETER
	var layout: BoardLayout = build_layout()
	for problem: String in LayoutChecks.find_problems(layout, BALANCE):
		push_warning("%s: %s" % [id, problem])
	var file: FileAccess = FileAccess.open(output_path(), FileAccess.WRITE)
	if file == null:
		push_error(
			"Cannot write %s: %s" % [output_path(), error_string(FileAccess.get_open_error())]
		)
		return FileAccess.get_open_error()
	file.store_string(LayoutCodec.to_json(layout))
	var summary: String = "%d pegs, %d groups" % [layout.peg_count(), layout.groups.size()]
	print("Exported %s (%s)" % [output_path(), summary])
	return OK


func mark_dirty() -> void:
	_dirty = true


func _ready() -> void:
	set_process(Engine.is_editor_hint())


func _process(delta: float) -> void:
	_since_check += delta
	if not _dirty or _since_check < CHECK_INTERVAL:
		return
	_dirty = false
	_since_check = 0.0
	_warnings = PackedStringArray(LayoutChecks.find_problems(build_layout(), BALANCE))
	if id.is_empty():
		_warnings.append("Set an id before exporting.")
	update_configuration_warnings()


func _get_configuration_warnings() -> PackedStringArray:
	return _warnings


func _draw() -> void:
	var size: Vector2 = Vector2(BALANCE.board_width, BALANCE.board_height) / PX
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOUR, false, 1.0)
	draw_dashed_line(
		Vector2(size.x / 2.0, 0), Vector2(size.x / 2.0, size.y), GUIDE_COLOUR, 1.0, 4.0
	)
	var lane: float = (BALANCE.bucket_y - BALANCE.bucket_rim_radius) / PX
	draw_line(Vector2(0, lane), Vector2(size.x, lane), GUIDE_COLOUR, 1.0)
	var launcher: Vector2 = Vector2(BALANCE.launcher_x, BALANCE.launcher_y) / PX
	draw_circle(launcher, BALANCE.ball_radius / PX, FRAME_COLOUR)


static func _collect_zones(node: Node, zones: Array[LayoutZone]) -> void:
	for child: Node in node.get_children():
		if child is ZoneMarker:
			zones.append((child as ZoneMarker).to_layout_zone())
		_collect_zones(child, zones)


static func _collect_groups(node: Node, groups: Array[LayoutGroup]) -> void:
	for child: Node in node.get_children():
		if child is MovingGroupMarker:
			groups.append((child as MovingGroupMarker).build_group())
		elif not child is LayoutPattern:
			_collect_groups(child, groups)
