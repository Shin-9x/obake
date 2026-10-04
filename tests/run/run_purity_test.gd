extends GdUnitTestSuite
## Static guard for src/run: run logic stays deterministic, so it never uses floats, engine
## randomness, clocks or scene nodes.

const RUN_ROOT: String = "res://src/run"
## JSON numbers arrive as floats; the codec only checks that they are whole.
const EXEMPT: Array[String] = ["res://src/run/layouts/layout_codec.gd"]
const FORBIDDEN: Dictionary[String, String] = {
	"float type": "\\bfloat\\b",
	"decimal literal": "\\b\\d[\\d_]*\\.\\d|\\b\\d[\\d_]*[eE][+-]?\\d",
	"engine randomness":
	"\\brand[fi]\\b|\\brand[fi]_range\\b|\\brandomize\\b|RandomNumberGenerator",
	"engine services": "\\b(Time|OS|Engine)\\.",
	"scene nodes": "\\bNode\\w*\\b|\\bget_tree\\b",
}


func test_run_sources_follow_determinism_rules() -> void:
	var patterns: Dictionary[String, RegEx] = {}
	for rule: String in FORBIDDEN:
		patterns[rule] = RegEx.create_from_string(FORBIDDEN[rule])
	var violations: PackedStringArray = PackedStringArray()
	var files: PackedStringArray = _gd_files(RUN_ROOT)
	assert_array(files).is_not_empty()
	for path: String in files:
		if path in EXEMPT:
			continue
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


func _strip_comment(line: String) -> String:
	var hash_index: int = line.find("#")
	return line if hash_index < 0 else line.substr(0, hash_index)
