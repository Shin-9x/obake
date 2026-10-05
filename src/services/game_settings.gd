class_name GameSettings
## The player's settings on this device, with their defaults and limits, and their JSON form.
## Values read from a file are clamped to their limits; unknown or missing ones keep the default.

enum Scaling { INTEGER, FRACTIONAL }

## Languages offered, by locale code; an empty code follows the system.
const LANGUAGES: Array[String] = ["", "en", "it"]
const MAX_VOLUME: int = 100
const FAST_FORWARD_SPEEDS: Array[int] = [2, 3]
const MIN_DRAG_SENSITIVITY: int = 50
const MAX_DRAG_SENSITIVITY: int = 200

## Volumes in percent.
var master_volume: int = 80
var music_volume: int = 70
var sfx_volume: int = 80
var language: String = ""
var scaling: Scaling = Scaling.INTEGER
var fullscreen: bool = false
var screen_shake: bool = true
var fast_forward_speed: int = 3
## Touch drag sensitivity in percent of the default.
var drag_sensitivity: int = 100
var vibration: bool = true
## Frame rate, frame times and draw calls in a corner of the screen.
var show_performance: bool = false


func to_dictionary() -> Dictionary[String, Variant]:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"language": language,
		"scaling": "fractional" if scaling == Scaling.FRACTIONAL else "integer",
		"fullscreen": fullscreen,
		"screen_shake": screen_shake,
		"fast_forward_speed": fast_forward_speed,
		"drag_sensitivity": drag_sensitivity,
		"vibration": vibration,
		"show_performance": show_performance,
	}


static func from_dictionary(data: Variant) -> GameSettings:
	var settings: GameSettings = GameSettings.new()
	if not data is Dictionary:
		return settings
	var source: Dictionary = data
	settings.master_volume = _volume(source, "master_volume", settings.master_volume)
	settings.music_volume = _volume(source, "music_volume", settings.music_volume)
	settings.sfx_volume = _volume(source, "sfx_volume", settings.sfx_volume)
	var language: Variant = source.get("language")
	if language is String and LANGUAGES.has(language):
		settings.language = language
	settings.scaling = (
		Scaling.FRACTIONAL if source.get("scaling") == "fractional" else Scaling.INTEGER
	)
	settings.fullscreen = source.get("fullscreen", false) == true
	settings.screen_shake = source.get("screen_shake", true) == true
	var speed: int = int(source.get("fast_forward_speed", settings.fast_forward_speed))
	if FAST_FORWARD_SPEEDS.has(speed):
		settings.fast_forward_speed = speed
	settings.drag_sensitivity = clampi(
		int(source.get("drag_sensitivity", settings.drag_sensitivity)),
		MIN_DRAG_SENSITIVITY,
		MAX_DRAG_SENSITIVITY
	)
	settings.vibration = source.get("vibration", true) == true
	settings.show_performance = source.get("show_performance", false) == true
	return settings


static func _volume(source: Dictionary, key: String, fallback: int) -> int:
	var value: Variant = source.get(key)
	if not (value is int or value is float):
		return fallback
	return clampi(int(value), 0, MAX_VOLUME)
