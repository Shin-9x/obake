extends GdUnitTestSuite
## The command-line tools run outside the game and its tests, so this at least proves they parse.

const TOOLS: Array[String] = ["res://src/tools", "res://src/tools/balance"]


func test_every_tool_script_parses() -> void:
	var checked: int = 0
	for folder: String in TOOLS:
		for file: String in DirAccess.get_files_at(folder):
			if file.get_extension() != "gd":
				continue
			var script: GDScript = load(folder.path_join(file)) as GDScript
			assert_object(script).override_failure_message(file).is_not_null()
			assert_bool(script.can_instantiate()).override_failure_message(file).is_true()
			checked += 1
	assert_int(checked).is_greater(5)
