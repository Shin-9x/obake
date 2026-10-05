extends GdUnitTestSuite
## Applying settings: language, bus volumes, and saving through the save service.

const SETTINGS: GDScript = preload("res://src/services/settings.gd")
const SAVES: String = "user://test_saves_settings"

var _locale: String = ""


func before_test() -> void:
	_locale = TranslationServer.get_locale()
	SaveService.directory = SAVES


func after_test() -> void:
	TranslationServer.set_locale(_locale)
	Settings.apply()
	if DirAccess.dir_exists_absolute(SAVES):
		for file: String in DirAccess.get_files_at(SAVES):
			DirAccess.remove_absolute(SAVES.path_join(file))
		DirAccess.remove_absolute(SAVES)
	SaveService.directory = "user://"


func test_the_language_and_volumes_are_applied_and_saved() -> void:
	var settings: Node = auto_free(SETTINGS.new())
	add_child(settings)
	settings.values = GameSettings.new()
	settings.values.language = "it"
	settings.values.music_volume = 0
	settings.values.sfx_volume = 50
	settings.commit()
	assert_str(TranslationServer.get_locale()).is_equal("it")
	assert_str(tr("BUTTON_NEW_RUN")).is_equal("Nuova run")
	var music: int = AudioServer.get_bus_index(&"Music")
	var sfx: int = AudioServer.get_bus_index(&"SFX")
	assert_bool(AudioServer.is_bus_mute(music)).is_true()
	assert_float(AudioServer.get_bus_volume_db(sfx)).is_equal_approx(-6.02, 0.01)
	assert_str(SaveService.load_settings().language).is_equal("it")
