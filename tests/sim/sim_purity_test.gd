extends GdUnitTestSuite
## Static guard for the determinism rules of src/sim: integer math only, no engine services,
## no nodes, no engine randomness and no loading from disk.

const SIM_ROOT: String = "res://src/sim"
const FORBIDDEN: Dictionary[String, String] = {
	"float type": "\\bfloat\\b",
	"decimal literal": "\\b\\d[\\d_]*\\.\\d|\\b\\d[\\d_]*[eE][+-]?\\d",
	"engine randomness":
	"\\brand[fi]\\b|\\brand[fi]_range\\b|\\brandomize\\b|RandomNumberGenerator",
	"engine services": "\\b(Time|OS|Engine)\\.",
	"scene nodes": "\\bNode\\w*\\b|\\bget_tree\\b",
	"float vectors": "\\b(Vector[234]i?|Transform2D|Rect2i?|Color)\\b",
	"float math": "\\b(sin|cos|tan|asin|acos|atan|atan2|sqrt|pow|exp|log|lerp|fmod|round)\\(",
	"float constants": "\\b(PI|TAU|INF|NAN)\\b",
	"disk access": "\\b(pre)?load\\(|ResourceLoader|FileAccess",
}


func test_sim_sources_follow_determinism_rules() -> void:
	var patterns: Dictionary[String, RegEx] = {}
	for rule: String in FORBIDDEN:
		patterns[rule] = RegEx.create_from_string(FORBIDDEN[rule])
	var violations: PackedStringArray = PackedStringArray()
	var files: PackedStringArray = _gd_files(SIM_ROOT)
	assert_array(files).is_not_empty()
	for path: String in files:
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for number: int in lines.size():
			var code: String = _strip_comment(lines[number])
			for rule: String in patterns:
				if patterns[rule].search(code) != null:
					violations.append("%s:%d %s: %s" % [path, number + 1, rule, code.strip_edges()])
	assert_array(violations).override_failure_message("\n".join(violations)).is_empty()


func _gd_files(directory: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(directory):
		if file.ends_with(".gd"):
			found.append(directory.path_join(file))
	for child: String in DirAccess.get_directories_at(directory):
		found.append_array(_gd_files(directory.path_join(child)))
	return found


## Drops everything after '#'. Simulation code holds no string literals that contain '#'.
func _strip_comment(line: String) -> String:
	var hash_index: int = line.find("#")
	return line if hash_index < 0 else line.substr(0, hash_index)
