@tool
class_name StyleShots
## Style bonuses in the spirit of the classic peg games, followed ball by ball through a shot.
##
## A long shot, or a super long shot, is a red lantern lit far from the lantern the same ball
## touched just before; bounces off the walls in between do not matter, and the flight from the
## launcher does not count. A slide, or an extreme slide, is a row of rectangular pegs lit one
## after the other by the same ball, with nothing else touched and no long pause in between.
##
## Integers only. The per-ball arrays grow when a new ball shows up and are reused across shots.

enum Style { NONE, LONG_SHOT, SUPER_LONG_SHOT, SLIDE, EXTREME_SLIDE }

var _config: BalanceConfig
var _touched: PackedByteArray = PackedByteArray()
var _last_x: PackedInt32Array = PackedInt32Array()
var _last_y: PackedInt32Array = PackedInt32Array()
## Rectangular pegs lit in a row by each ball, and the tick of its last touch of one.
var _slide_count: PackedInt32Array = PackedInt32Array()
var _slide_tick: PackedInt64Array = PackedInt64Array()


func _init(config: BalanceConfig) -> void:
	_config = config


func start_shot() -> void:
	_touched.fill(0)
	_slide_count.fill(0)


## Points a style is worth.
func points_of(style: Style) -> int:
	match style:
		Style.LONG_SHOT:
			return _config.long_shot_points
		Style.SUPER_LONG_SHOT:
			return _config.super_long_shot_points
		Style.SLIDE:
			return _config.slide_points
		Style.EXTREME_SLIDE:
			return _config.extreme_slide_points
	return 0


## [param ball] touched a lantern at [param x], [param y]; [param lit_red] when that lit a red
## lantern. Returns the long shot it made, if any.
func long_shot(ball: int, x: int, y: int, lit_red: bool) -> Style:
	_make_room(ball)
	var style: Style = Style.NONE
	if lit_red and _touched[ball] == 1:
		var dx: int = x - _last_x[ball]
		var dy: int = y - _last_y[ball]
		var distance_squared: int = dx * dx + dy * dy
		var long: int = _config.long_shot_distance
		var super_long: int = _config.super_long_shot_distance
		if distance_squared >= super_long * super_long:
			style = Style.SUPER_LONG_SHOT
		elif distance_squared >= long * long:
			style = Style.LONG_SHOT
	_touched[ball] = 1
	_last_x[ball] = x
	_last_y[ball] = y
	return style


## [param ball] touched a peg at [param tick]: a rectangular one when [param brick], lit by this
## touch when [param lit]. Returns the slide it completed, if any.
func slide(ball: int, brick: bool, lit: bool, tick: int) -> Style:
	_make_room(ball)
	if not brick:
		_slide_count[ball] = 0
		return Style.NONE
	if _slide_count[ball] > 0 and tick - _slide_tick[ball] > _config.slide_gap_ticks:
		_slide_count[ball] = 0
	_slide_tick[ball] = tick
	if not lit:
		return Style.NONE
	_slide_count[ball] += 1
	if _slide_count[ball] == _config.extreme_slide_pegs:
		return Style.EXTREME_SLIDE
	if _slide_count[ball] == _config.slide_pegs:
		return Style.SLIDE
	return Style.NONE


func _make_room(ball: int) -> void:
	if ball < _touched.size():
		return
	var known: int = _touched.size()
	var size: int = ball + 1
	_touched.resize(size)
	_last_x.resize(size)
	_last_y.resize(size)
	_slide_count.resize(size)
	_slide_tick.resize(size)
	# A grown array does not promise zeroes, and the same shot must always play the same.
	for index: int in range(known, size):
		_touched[index] = 0
		_slide_count[index] = 0
