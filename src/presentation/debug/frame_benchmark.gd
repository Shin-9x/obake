class_name FrameBenchmark
extends Control
## Plays development boards on its own, shooting at random, and times every frame: a check of how
## smoothly a device runs a busy board, since the development loadout splits, explodes and burns.
## Offered in debug builds only. The results also go to the log, where `adb logcat` shows them.

signal closed

const BOARD_SCENE: PackedScene = preload("res://src/presentation/board/board_screen.tscn")
const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const SHOTS: int = 20
## Frames left out at the start, while shaders compile and the first board settles.
const WARM_UP_FRAMES: int = 60
## Room for every frame of the benchmark, reserved up front so measuring allocates nothing.
const MAX_FRAMES: int = 36_000
## Boards come from fixed seeds, so every device plays the same boards.
const FIRST_SEED: int = 8008
const DIM: Color = Color(0, 0, 0, 0.7)
const MARGIN: int = 4
const OUTLINE: int = 3

var board: BoardScreen
## Shots to time; tests shorten it.
var shots: int = SHOTS
## Null until the benchmark is over.
var stats: FrameStats

var _frame_usec: PackedInt32Array = PackedInt32Array()
var _tick_usec: PackedInt32Array = PackedInt32Array()
var _count: int = 0
var _last_frame: int = 0
var _skip: int = 0
var _shots: int = 0
var _boards: int = 0
var _rng: Pcg32 = Pcg32.new(FIRST_SEED, 0)
var _progress: Label


func start() -> void:
	UiKit.clear(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_frame_usec.resize(MAX_FRAMES)
	_tick_usec.resize(MAX_FRAMES)
	board = BOARD_SCENE.instantiate() as BoardScreen
	board.standalone = false
	add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_progress = UiKit.label("", UiKit.SMALL_SIZE, UiKit.TEXT, false)
	_progress.add_theme_color_override("font_outline_color", Color.BLACK)
	_progress.add_theme_constant_override("outline_size", OUTLINE)
	add_child(_progress)
	_progress.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, MARGIN
	)
	_progress.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_next_board()
	_skip = WARM_UP_FRAMES
	_show_progress()
	_last_frame = Time.get_ticks_usec()


func back() -> void:
	closed.emit()


func _process(_delta: float) -> void:
	if board == null or stats != null:
		return
	var now: int = Time.get_ticks_usec()
	if _skip > 0:
		_skip -= 1
	elif _count < MAX_FRAMES:
		_frame_usec[_count] = now - _last_frame
		_tick_usec[_count] = board.tick_usec
		_count += 1
	_last_frame = now
	var game: BoardGame = board.game
	if game.outcome != BoardGame.Outcome.PLAYING:
		_next_board()
	elif game.can_shoot():
		if _shots == shots:
			_finish()
			return
		board.aim_at(_rng.next_below(2 * BALANCE.aim_limit + 1) - BALANCE.aim_limit)
		board.shoot()
		_shots += 1
		_show_progress()


## Sets up the next board; its setup frame is left out, as the player sees it behind the result.
func _next_board() -> void:
	board.start_board(FIRST_SEED + _boards)
	_boards += 1
	_skip = maxi(_skip, 1)


func _show_progress() -> void:
	_progress.text = tr("BENCHMARK_PROGRESS") % [_shots, shots]


func _finish() -> void:
	stats = FrameStats.from(_frame_usec.slice(0, _count), _tick_usec.slice(0, _count))
	board.process_mode = Node.PROCESS_MODE_DISABLED
	_progress.visible = false
	var dim: ColorRect = ColorRect.new()
	dim.color = DIM
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var column: VBoxContainer = UiKit.column(6)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(column)
	column.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	var title: Label = UiKit.label("BUTTON_BENCHMARK", UiKit.TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	for line: String in result_lines():
		print(line)
		column.add_child(UiKit.label(line, 0, UiKit.TEXT, false))
	var leave: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	leave.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	leave.pressed.connect(back)
	column.add_child(leave)
	if FocusNavigator.using_pad:
		leave.grab_focus()


## The results, one translated line each.
func result_lines() -> PackedStringArray:
	var share: float = 100.0 * stats.over_budget / maxi(1, stats.frames)
	return [
		tr("BENCHMARK_FRAMES") % [stats.frames, _shots, _boards],
		(
			tr("BENCHMARK_PERCENTILES")
			% [stats.p50 / 1000.0, stats.p95 / 1000.0, stats.p99 / 1000.0, stats.worst / 1000.0]
		),
		tr("BENCHMARK_DROPPED") % [stats.over_budget, share, stats.over_double_budget],
		tr("BENCHMARK_TICKS") % [stats.tick_average, stats.tick_worst],
	]
