extends GdUnitTestSuite
## Profile and run files in a scratch folder: round trips, missing and broken files.

const SERVICE: GDScript = preload("res://src/services/save_service.gd")
const DIRECTORY: String = "user://test_saves_service"

var _service: Node


func before_test() -> void:
	_service = auto_free(SERVICE.new())
	_service.directory = DIRECTORY
	_wipe()


func after_test() -> void:
	_wipe()


func test_a_missing_profile_is_a_fresh_one() -> void:
	var profile: Profile = _service.load_profile()
	assert_int(profile.runs).is_equal(0)


func test_profiles_are_saved_and_loaded() -> void:
	var profile: Profile = Profile.new()
	profile.feats.append(&"first_matsuri")
	profile.runs = 3
	assert_int(_service.save_profile(profile)).is_equal(OK)
	var loaded: Profile = _service.load_profile()
	assert_bool(loaded.has_feat(&"first_matsuri")).is_true()
	assert_int(loaded.runs).is_equal(3)
	assert_bool(FileAccess.file_exists(DIRECTORY.path_join("profile.json.tmp"))).is_false()


func test_a_broken_profile_is_kept_aside_and_replaced() -> void:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file: FileAccess = FileAccess.open(DIRECTORY.path_join("profile.json"), FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	assert_int(_service.load_profile().runs).is_equal(0)
	assert_bool(FileAccess.file_exists(DIRECTORY.path_join("profile.json.bak"))).is_true()


func test_runs_are_saved_loaded_and_cleared() -> void:
	assert_bool(_service.has_run()).is_false()
	assert_dict(_service.load_run()).is_empty()
	_service.save_run({"format": 1, "snapshot_at": 4})
	assert_bool(_service.has_run()).is_true()
	assert_int(int(_service.load_run()["snapshot_at"])).is_equal(4)
	_service.clear_run()
	assert_bool(_service.has_run()).is_false()


func _wipe() -> void:
	if not DirAccess.dir_exists_absolute(DIRECTORY):
		return
	for file: String in DirAccess.get_files_at(DIRECTORY):
		DirAccess.remove_absolute(DIRECTORY.path_join(file))
	DirAccess.remove_absolute(DIRECTORY)
