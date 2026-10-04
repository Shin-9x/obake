extends GdUnitTestSuite
## Golden replays: the runs recorded in tests/replays/ must still play, with the shipped data, to
## the results they recorded. After a deliberate change, `make replays` writes the new results;
## the commit message says why they moved.

const REPLAYS: String = "res://tests/replays"
const Updater: GDScript = preload("res://src/tools/update_replays.gd")


func test_every_replay_reaches_its_recorded_result() -> void:
	var files: Array[String] = _replays()
	assert_array(files).is_not_empty()
	for file: String in files:
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
		var run: Run = Updater.replay(data)
		assert_object(run).override_failure_message("%s no longer replays" % file).is_not_null()
		if run == null:
			continue
		# Through JSON, so numbers compare the way the file stores them.
		var reached: Variant = JSON.parse_string(JSON.stringify(Updater.expected(run)))
		(
			assert_dict(reached)
			. override_failure_message(
				"%s moved: run make replays if the change is deliberate" % file
			)
			. is_equal(data["expected"])
		)


func test_the_replays_get_past_a_boss() -> void:
	var furthest: int = 0
	for file: String in _replays():
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(file))
		furthest = maxi(furthest, int(data["expected"]["state"]["floor"]))
	assert_int(furthest).is_greater_equal(1)


func _replays() -> Array[String]:
	var files: Array[String] = []
	for file: String in DirAccess.get_files_at(REPLAYS):
		if file.get_extension() == "json":
			files.append(REPLAYS.path_join(file))
	files.sort()
	return files
