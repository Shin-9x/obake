@tool
class_name LayoutCodec
## Converts board layouts to and from JSON.
##
## Every number is an integer: milli-pixels, centidegrees and ticks. JSON parses numbers as
## doubles, which hold integers exactly below 2^53, so nothing is lost on the way back. Keys are
## written in a fixed order so exported files diff cleanly; "kind" and "zones" are optional and
## only written when they differ from a standard board without zones.

const FORMAT: int = 1
const _SHAPES: Dictionary[String, SimPeg.Shape] = {
	"round": SimPeg.Shape.ROUND,
	"rect": SimPeg.Shape.RECT,
}
const _MOTIONS: Dictionary[String, MovingGroup.Motion] = {
	"rotate": MovingGroup.Motion.ROTATE,
	"oscillate": MovingGroup.Motion.OSCILLATE,
}
const _KINDS: Dictionary[String, BoardLayout.Kind] = {
	"board": BoardLayout.Kind.BOARD,
	"boss": BoardLayout.Kind.BOSS,
}


static func to_json(layout: BoardLayout) -> String:
	return JSON.stringify(to_dictionary(layout), "\t", false) + "\n"


static func to_dictionary(layout: BoardLayout) -> Dictionary[String, Variant]:
	var groups: Array[Dictionary] = []
	for group: LayoutGroup in layout.groups:
		groups.append(_group_to_dictionary(group))
	var result: Dictionary[String, Variant] = {
		"format": FORMAT,
		"id": layout.id,
		"biome": layout.biome,
	}
	if layout.kind != BoardLayout.Kind.BOARD:
		result["kind"] = _KINDS.find_key(layout.kind)
	result["mirrorable"] = layout.mirrorable
	result["pegs"] = _pegs_to_array(layout.pegs)
	result["groups"] = groups
	if not layout.zones.is_empty():
		var zones: Array[Dictionary] = []
		for zone: LayoutZone in layout.zones:
			zones.append({"x": zone.x, "y": zone.y, "radius": zone.radius})
		result["zones"] = zones
	return result


## Parses [param text]. Returns null and appends to [param errors] when it is not a valid layout.
static func from_json(text: String, errors: Array[String]) -> BoardLayout:
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary:
		errors.append("not a JSON object")
		return null
	return from_dictionary(data as Dictionary, errors)


static func from_dictionary(data: Dictionary, errors: Array[String]) -> BoardLayout:
	var start: int = errors.size()
	if _read_int(data, "format", "layout", errors) != FORMAT:
		errors.append("layout: unsupported format, expected %d" % FORMAT)
	var layout: BoardLayout = BoardLayout.new()
	layout.id = _read_string(data, "id", "layout", errors)
	layout.biome = _read_string(data, "biome", "layout", errors)
	var kind: String = str(data.get("kind", "board"))
	if not _KINDS.has(kind):
		errors.append("layout: unknown kind '%s'" % kind)
	layout.kind = _KINDS.get(kind, BoardLayout.Kind.BOARD)
	layout.mirrorable = data.get("mirrorable", true) == true
	layout.pegs = _read_pegs(data, "layout", errors)
	for entry: Variant in _read_array(data, "groups", "layout", errors):
		var group: LayoutGroup = _read_group(entry, "group %d" % layout.groups.size(), errors)
		if group != null:
			layout.groups.append(group)
	for entry: Variant in _read_array(data, "zones", "layout", errors):
		var where: String = "zone %d" % layout.zones.size()
		if not entry is Dictionary:
			errors.append("%s: not an object" % where)
			continue
		var zone_data: Dictionary = entry
		var zone: LayoutZone = LayoutZone.new(
			_read_int(zone_data, "x", where, errors),
			_read_int(zone_data, "y", where, errors),
			_read_int(zone_data, "radius", where, errors)
		)
		if zone.radius <= 0:
			errors.append("%s: radius must be positive" % where)
		layout.zones.append(zone)
	if layout.peg_count() == 0:
		errors.append("layout: no pegs")
	return layout if errors.size() == start else null


static func _pegs_to_array(pegs: Array[LayoutPeg]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for peg: LayoutPeg in pegs:
		var entry: Dictionary[String, Variant] = {
			"x": peg.x,
			"y": peg.y,
			"shape": _SHAPES.find_key(peg.shape),
		}
		if peg.shape == SimPeg.Shape.RECT:
			entry["half_width"] = peg.half_width
			entry["half_height"] = peg.half_height
			entry["angle"] = peg.angle
		result.append(entry)
	return result


static func _group_to_dictionary(group: LayoutGroup) -> Dictionary[String, Variant]:
	var entry: Dictionary[String, Variant] = {
		"motion": _MOTIONS.find_key(group.motion),
		"period": group.period,
	}
	if group.motion == MovingGroup.Motion.ROTATE:
		entry["x"] = group.pivot_x
		entry["y"] = group.pivot_y
		entry["clockwise"] = group.clockwise
	else:
		entry["dx"] = group.travel_x
		entry["dy"] = group.travel_y
	entry["pegs"] = _pegs_to_array(group.pegs)
	return entry


static func _read_group(entry: Variant, where: String, errors: Array[String]) -> LayoutGroup:
	if not entry is Dictionary:
		errors.append("%s: not an object" % where)
		return null
	var data: Dictionary = entry
	var group: LayoutGroup = LayoutGroup.new()
	var motion: String = _read_string(data, "motion", where, errors)
	if not _MOTIONS.has(motion):
		errors.append("%s: unknown motion '%s'" % [where, motion])
		return null
	group.motion = _MOTIONS[motion]
	group.period = _read_int(data, "period", where, errors)
	if group.period <= 0:
		errors.append("%s: period must be positive" % where)
	if group.motion == MovingGroup.Motion.ROTATE:
		group.pivot_x = _read_int(data, "x", where, errors)
		group.pivot_y = _read_int(data, "y", where, errors)
		group.clockwise = data.get("clockwise", true) == true
	else:
		group.travel_x = _read_int(data, "dx", where, errors)
		group.travel_y = _read_int(data, "dy", where, errors)
	group.pegs = _read_pegs(data, where, errors)
	if group.pegs.is_empty():
		errors.append("%s: no pegs" % where)
	return group


static func _read_pegs(data: Dictionary, where: String, errors: Array[String]) -> Array[LayoutPeg]:
	var pegs: Array[LayoutPeg] = []
	for entry: Variant in _read_array(data, "pegs", where, errors):
		var peg_where: String = "%s peg %d" % [where, pegs.size()]
		if not entry is Dictionary:
			errors.append("%s: not an object" % peg_where)
			continue
		var peg_data: Dictionary = entry
		var shape: String = _read_string(peg_data, "shape", peg_where, errors)
		if not _SHAPES.has(shape):
			errors.append("%s: unknown shape '%s'" % [peg_where, shape])
			continue
		var x: int = _read_int(peg_data, "x", peg_where, errors)
		var y: int = _read_int(peg_data, "y", peg_where, errors)
		if _SHAPES[shape] == SimPeg.Shape.ROUND:
			pegs.append(LayoutPeg.round_at(x, y))
			continue
		var half_width: int = _read_int(peg_data, "half_width", peg_where, errors)
		var half_height: int = _read_int(peg_data, "half_height", peg_where, errors)
		var angle: int = _read_int(peg_data, "angle", peg_where, errors)
		pegs.append(LayoutPeg.rect_at(x, y, half_width, half_height, angle))
	return pegs


static func _read_array(
	data: Dictionary, key: String, where: String, errors: Array[String]
) -> Array:
	var value: Variant = data.get(key, [])
	if value is Array:
		return value
	errors.append("%s: '%s' must be an array" % [where, key])
	return []


static func _read_string(
	data: Dictionary, key: String, where: String, errors: Array[String]
) -> String:
	var value: Variant = data.get(key)
	if value is String and not (value as String).is_empty():
		return value
	errors.append("%s: '%s' must be a non-empty string" % [where, key])
	return ""


## Accepts whole numbers only: JSON gives doubles, which must not carry a fraction.
static func _read_int(data: Dictionary, key: String, where: String, errors: Array[String]) -> int:
	var value: Variant = data.get(key)
	if value is int:
		return value
	if value is float and value == roundf(value) and absf(value) < 9.0e15:
		return int(value)
	errors.append("%s: '%s' must be an integer" % [where, key])
	return 0
