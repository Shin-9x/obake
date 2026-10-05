class_name PerfOverlay
extends Label
## Frame rate, frame times, tick cost, draw calls and memory in a corner of the screen, for
## checking how a device copes. Shown from the settings; it refreshes twice a second so its own
## text costs next to nothing.

## Custom monitor where the board on show reports its tick cost in microseconds; it also appears
## in the editor's Monitors tab.
const TICK_MONITOR: StringName = &"obake/tick_usec"
const REFRESH_SECONDS: float = 0.5
const MARGIN: int = 4
const OUTLINE: int = 3
const MEGABYTE: float = 1_048_576.0

var _elapsed: float = 0.0
var _frames: int = 0
var _worst: float = 0.0
var _tick_total: int = 0


func _ready() -> void:
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", UiKit.SMALL_SIZE)
	add_theme_color_override("font_color", UiKit.TEXT)
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", OUTLINE)
	position = Vector2(MARGIN, MARGIN)
	show_values(false)


func show_values(on: bool) -> void:
	visible = on
	set_process(on)
	text = ""
	_reset()


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	_worst = maxf(_worst, delta)
	if Performance.has_custom_monitor(TICK_MONITOR):
		_tick_total += int(Performance.get_custom_monitor(TICK_MONITOR))
	if _elapsed < REFRESH_SECONDS:
		return
	var lines: PackedStringArray = [
		(
			tr("PERF_FRAMES")
			% [
				Engine.get_frames_per_second(),
				1000.0 * _elapsed / _frames,
				1000.0 * _worst,
			]
		),
		(
			tr("PERF_DETAILS")
			% [
				_tick_total / _frames,
				Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				Performance.get_monitor(Performance.MEMORY_STATIC) / MEGABYTE,
				Performance.get_monitor(Performance.OBJECT_COUNT),
			]
		),
	]
	text = "\n".join(lines)
	_reset()


func _reset() -> void:
	_elapsed = 0.0
	_frames = 0
	_worst = 0.0
	_tick_total = 0
