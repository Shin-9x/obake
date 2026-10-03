extends GdUnitTestSuite
## Every layout source scene must match its exported JSON and pass the geometry checks.

const SOURCES: String = "res://src/tools/layout_editor/layouts"
const BIOMES: Array[String] = ["bamboo_forest", "haunted_village"]


func test_there_are_six_sources() -> void:
	assert_array(_source_paths()).has_size(6)


func test_exported_json_matches_every_source() -> void:
	for path: String in _source_paths():
		var document: LayoutDocument = _open(path)
		var exported: String = FileAccess.get_file_as_string(document.output_path())
		var message: String = "%s is out of date: run make layouts" % document.output_path()
		var expected: String = LayoutCodec.to_json(document.build_layout())
		assert_str(exported).override_failure_message(message).is_equal(expected)


func test_every_layout_is_clean_and_has_moving_pegs() -> void:
	for path: String in _source_paths():
		var layout: BoardLayout = _open(path).build_layout()
		var problems: Array[String] = LayoutChecks.find_problems(layout, LayoutDocument.BALANCE)
		var message: String = "%s: %s" % [layout.id, "; ".join(problems)]
		assert_array(problems).override_failure_message(message).is_empty()
		assert_array(layout.groups).is_not_empty()
		assert_int(layout.peg_count()).is_between(55, 75)
		assert_array(BIOMES).contains([layout.biome])


func _source_paths() -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(SOURCES):
		if file.get_extension() == "tscn":
			paths.append(SOURCES.path_join(file))
	paths.sort()
	return paths


func _open(path: String) -> LayoutDocument:
	return auto_free((load(path) as PackedScene).instantiate()) as LayoutDocument
