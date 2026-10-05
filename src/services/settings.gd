extends Node
## The player's settings, loaded at start and applied to the engine: bus volumes, language,
## window scaling and full screen. Screens change [member values], then call [method commit].
## Gameplay code reads the values it cares about, such as screen shake.

signal changed

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var values: GameSettings = GameSettings.new()


func _ready() -> void:
	values = SaveService.load_settings()
	apply()


## Applies and saves the current values.
func commit() -> void:
	apply()
	SaveService.save_settings(values)
	changed.emit()


func apply() -> void:
	_set_volume(&"Master", values.master_volume)
	_set_volume(MUSIC_BUS, values.music_volume)
	_set_volume(SFX_BUS, values.sfx_volume)
	var locale: String = values.language if not values.language.is_empty() else OS.get_locale()
	TranslationServer.set_locale(locale)
	var root: Window = get_tree().root
	if values.scaling == GameSettings.Scaling.FRACTIONAL:
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	else:
		root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	if is_desktop():
		var mode: DisplayServer.WindowMode = (
			DisplayServer.WINDOW_MODE_FULLSCREEN
			if values.fullscreen
			else DisplayServer.WINDOW_MODE_WINDOWED
		)
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)


## Window settings only make sense on a desktop with a real display.
func is_desktop() -> bool:
	return OS.has_feature("pc") and DisplayServer.get_name() != "headless"


func _set_volume(bus: StringName, percent: int) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index < 0:
		return
	AudioServer.set_bus_mute(index, percent <= 0)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(percent, 1) / 100.0))
