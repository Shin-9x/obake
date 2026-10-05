extends GdUnitTestSuite
## Every translation key named in code, scenes and data exists in the translations, so no screen
## ever shows a raw key. Keys built at run time, such as biome names, are checked by their own
## data tests.

const CSV: String = "res://locale/translations.csv"
## A string literal shaped like a key: upper case words joined by underscores, not a StringName.
const KEY_IN_CODE: String = '(?<![&\\w])"([A-Z][A-Z0-9]*(?:_[A-Z0-9]+)+)"'
## A text field of a resource or scene.
const KEY_IN_DATA: String = '^(?:\\w+_key|text|placeholder_text) = "([A-Z][A-Z0-9_]+)"'
const ROOTS: Array[String] = ["res://src", "res://data"]
## Editor tools speak to the developer, not the player.
const SKIPPED: Array[String] = ["res://src/tools"]


func test_every_key_used_exists() -> void:
	var known: Dictionary[String, bool] = {}
	var file: FileAccess = FileAccess.open(CSV, FileAccess.READ)
	while not file.eof_reached():
		known[file.get_csv_line()[0]] = true
	var code: RegEx = RegEx.create_from_string(KEY_IN_CODE)
	var data: RegEx = RegEx.create_from_string(KEY_IN_DATA)
	var missing: PackedStringArray = PackedStringArray()
	var checked: int = 0
	for path: String in _files():
		var pattern: RegEx = code if path.ends_with(".gd") else data
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for number: int in lines.size():
			for found: RegExMatch in pattern.search_all(lines[number]):
				checked += 1
				if not known.has(found.get_string(1)):
					missing.append("%s:%d %s" % [path, number + 1, found.get_string(1)])
	assert_int(checked).is_greater(100)
	assert_array(missing).override_failure_message("\n".join(missing)).is_empty()


func _files(directory: String = "") -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	var roots: Array[String] = ROOTS.duplicate()
	if not directory.is_empty():
		roots = [directory]
	for root: String in roots:
		if SKIPPED.has(root):
			continue
		for file: String in DirAccess.get_files_at(root):
			if file.get_extension() in ["gd", "tscn", "tres"]:
				found.append(root.path_join(file))
		for child: String in DirAccess.get_directories_at(root):
			found.append_array(_files(root.path_join(child)))
	return found
