extends GdUnitTestSuite


func test_the_version_comes_from_the_project_settings() -> void:
	assert_str(BuildInfo.version()).is_not_empty()
	assert_str(BuildInfo.version()).is_equal(
		ProjectSettings.get_setting("application/config/version")
	)
