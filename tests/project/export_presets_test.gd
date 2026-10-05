extends GdUnitTestSuite
## Guards the export presets: what every build leaves out, and the settings a release relies on.

const PRESETS: String = "res://export_presets.cfg"


func test_every_preset_leaves_out_tests_and_tools() -> void:
	var presets: ConfigFile = _presets()
	for section: String in _preset_sections(presets):
		var excluded: String = presets.get_value(section, "exclude_filter", "")
		for folder: String in ["tests/*", "addons/gdUnit4/*", "src/tools/*"]:
			assert_str(excluded).contains(folder)
		assert_str(presets.get_value(section, "include_filter", "")).contains("data/layouts/*.json")


func test_builds_take_their_version_from_the_project() -> void:
	var presets: ConfigFile = _presets()
	var android: String = _options_of(presets, "Android")
	assert_str(presets.get_value(android, "version/name", "")).is_empty()
	assert_int(presets.get_value(android, "version/code", 0)).is_greater(0)
	var windows: String = _options_of(presets, "Windows")
	assert_str(presets.get_value(windows, "application/file_version", "")).is_empty()
	assert_str(presets.get_value(windows, "application/product_version", "")).is_empty()


func test_android_may_vibrate_and_has_launcher_icons() -> void:
	var presets: ConfigFile = _presets()
	var android: String = _options_of(presets, "Android")
	assert_bool(presets.get_value(android, "permissions/vibrate", false)).is_true()
	for key: String in presets.get_section_keys(android):
		if key.begins_with("launcher_icons/"):
			assert_bool(ResourceLoader.exists(presets.get_value(android, key))).is_true()


func _presets() -> ConfigFile:
	var presets: ConfigFile = ConfigFile.new()
	assert_int(presets.load(PRESETS)).is_equal(OK)
	return presets


func _preset_sections(presets: ConfigFile) -> Array[String]:
	var sections: Array[String] = []
	for section: String in presets.get_sections():
		if not section.ends_with(".options"):
			sections.append(section)
	return sections


func _options_of(presets: ConfigFile, preset_name: String) -> String:
	for section: String in _preset_sections(presets):
		if presets.get_value(section, "name", "") == preset_name:
			return section + ".options"
	return ""
