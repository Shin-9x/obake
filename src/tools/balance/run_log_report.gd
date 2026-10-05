class_name RunLogReport
extends RefCounted
## Sums up run log lines from players or the balance bot: how far runs get, who wins, and how each
## board of a run goes against its target. Normal and Hard runs are kept apart.

const SUMMARY: String = "%s: %d runs, %d won (%s), %d given up"
const HEADER: String = "board  reached    won  matsuri  score/target  shots left  mon after"
const ROW: String = "%5d  %7d  %5s  %7s  %12.2f  %10.1f  %9.1f"
const NODE_HEADER: String = "floor  node   reached    won  matsuri  score/target"
const NODE_ROW: String = "%5d  %-5s  %7d  %5s  %7s  %12.2f"
const NODE_ORDER: Array[String] = ["board", "elite", "boss"]


## Everything known about one board of a run, by its place in the run.
class BoardStats:
	var reached: int = 0
	var won: int = 0
	var matsuri: int = 0
	var ratios: PackedFloat32Array = PackedFloat32Array()
	var shots_left_when_won: int = 0
	var mon: int = 0

	## Middle score-to-target ratio, or 0 without boards.
	func median_ratio() -> float:
		if ratios.is_empty():
			return 0.0
		var sorted: PackedFloat32Array = ratios.duplicate()
		sorted.sort()
		var middle: int = sorted.size() / 2
		if sorted.size() % 2 == 1:
			return sorted[middle]
		return (sorted[middle - 1] + sorted[middle]) / 2.0


class ModeStats:
	var runs: int = 0
	var outcomes: Dictionary[String, int] = {}
	## Runs lost or given up, by the floor they ended on.
	var losses_by_floor: Dictionary[int, int] = {}
	var runs_by_character: Dictionary[String, int] = {}
	var wins_by_character: Dictionary[String, int] = {}
	var boards: Dictionary[int, BoardStats] = {}
	## Boards by floor, then by kind of map node.
	var nodes: Dictionary[int, Dictionary] = {}


var _modes: Dictionary[bool, ModeStats] = {}


func add(line: Dictionary) -> void:
	var stats: ModeStats = mode(line.get("hard", false) == true)
	match line.get("kind"):
		"run":
			_add_run(stats, line)
		"board":
			_add_board(stats, line)


## The totals of Normal runs, or of Hard ones when [param hard].
func mode(hard: bool) -> ModeStats:
	if not _modes.has(hard):
		_modes[hard] = ModeStats.new()
	return _modes[hard]


func has_mode(hard: bool) -> bool:
	return _modes.has(hard)


## A plain-text summary, Normal first.
func text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for hard: bool in [false, true]:
		if has_mode(hard):
			parts.append(_mode_text("Hard" if hard else "Normal", mode(hard)))
	return "\n".join(parts)


func _add_run(stats: ModeStats, line: Dictionary) -> void:
	var outcome: String = str(line.get("outcome", ""))
	var character: String = str(line.get("character", ""))
	stats.runs += 1
	stats.outcomes[outcome] = stats.outcomes.get(outcome, 0) + 1
	stats.runs_by_character[character] = stats.runs_by_character.get(character, 0) + 1
	if outcome == "victory":
		stats.wins_by_character[character] = stats.wins_by_character.get(character, 0) + 1
	else:
		var floor_number: int = int(line.get("floor", 0))
		stats.losses_by_floor[floor_number] = stats.losses_by_floor.get(floor_number, 0) + 1


func _add_board(stats: ModeStats, line: Dictionary) -> void:
	var index: int = int(line.get("board", 0))
	if not stats.boards.has(index):
		stats.boards[index] = BoardStats.new()
	_count_board(stats.boards[index], line)
	var floor_number: int = int(line.get("floor", 0))
	var kind: String = str(line.get("node", ""))
	if not stats.nodes.has(floor_number):
		stats.nodes[floor_number] = {}
	var kinds: Dictionary = stats.nodes[floor_number]
	if not kinds.has(kind):
		kinds[kind] = BoardStats.new()
	_count_board(kinds[kind], line)


func _count_board(board: BoardStats, line: Dictionary) -> void:
	var outcome: String = str(line.get("outcome", ""))
	board.reached += 1
	board.mon += int(line.get("mon", 0))
	if outcome != "failed":
		board.won += 1
		board.shots_left_when_won += int(line.get("shots_left", 0))
	if outcome == "matsuri":
		board.matsuri += 1
	var target: int = int(line.get("target", 0))
	if target > 0:
		board.ratios.append(float(line.get("score", 0)) / target)


func _mode_text(title: String, stats: ModeStats) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var wins: int = stats.outcomes.get("victory", 0)
	var given_up: int = stats.outcomes.get("abandoned", 0)
	var won_share: String = _percent(wins, stats.runs)
	lines.append(SUMMARY % [title, stats.runs, wins, won_share, given_up])
	var floors: PackedStringArray = PackedStringArray()
	for floor_number: int in _sorted_keys(stats.losses_by_floor):
		floors.append("%d: %d" % [floor_number, stats.losses_by_floor[floor_number]])
	lines.append("Runs lost by floor: " + " · ".join(floors))
	var characters: PackedStringArray = PackedStringArray()
	for character: String in _sorted_keys(stats.runs_by_character):
		var won: int = stats.wins_by_character.get(character, 0)
		characters.append("%s %d/%d" % [character, won, stats.runs_by_character[character]])
	lines.append("Wins by character: " + " · ".join(characters))
	lines.append("")
	lines.append(HEADER)
	for index: int in _sorted_keys(stats.boards):
		var board: BoardStats = stats.boards[index]
		var shots_left: float = float(board.shots_left_when_won) / maxi(1, board.won)
		var mon: float = float(board.mon) / board.reached
		var won_rate: String = _percent(board.won, board.reached)
		var matsuri_rate: String = _percent(board.matsuri, board.reached)
		var ratio: float = board.median_ratio()
		lines.append(ROW % [index, board.reached, won_rate, matsuri_rate, ratio, shots_left, mon])
	lines.append("")
	lines.append(NODE_HEADER)
	for floor_number: int in _sorted_keys(stats.nodes):
		var kinds: Dictionary = stats.nodes[floor_number]
		for kind: String in NODE_ORDER:
			if not kinds.has(kind):
				continue
			var board: BoardStats = kinds[kind]
			var won_rate: String = _percent(board.won, board.reached)
			var matsuri_rate: String = _percent(board.matsuri, board.reached)
			var ratio: float = board.median_ratio()
			lines.append(
				NODE_ROW % [floor_number, kind, board.reached, won_rate, matsuri_rate, ratio]
			)
	lines.append("")
	return "\n".join(lines)


static func _percent(part: int, whole: int) -> String:
	if whole == 0:
		return "-"
	return "%d%%" % roundi(100.0 * part / whole)


static func _sorted_keys(values: Dictionary) -> Array:
	var keys: Array = values.keys()
	keys.sort()
	return keys
