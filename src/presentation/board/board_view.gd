class_name BoardView
extends Node2D
## Draws a board: pegs, balls, bucket and launcher, interpolating between simulation ticks.
##
## Pegs are drawn in a single pass and redrawn only on [method refresh_pegs]. Balls and the
## bucket are sprites moved every frame from the previous and current simulation states.

## Milli-pixels per pixel, as a float for rendering.
const PX: float = 1000.0
## Brightening applied to lit lanterns.
const LIT_TINT: Color = Color(1.6, 1.6, 1.6)

## Bucket being drawn: the game's while a shot is in flight, an idle copy between shots.
var bucket_source: Bucket

var _game: BoardGame
var _skin: BoardSkin
var _bucket_y: float = 0.0
var _balls: Array[Sprite2D] = []
var _previous: PackedVector2Array = PackedVector2Array()
var _was_active: PackedByteArray = PackedByteArray()
var _bucket_previous: float = 0.0
var _bucket_sprite: Sprite2D
var _launcher: Sprite2D


func setup(game: BoardGame, config: BalanceConfig, skin: BoardSkin) -> void:
	_game = game
	_skin = skin
	_bucket_y = config.bucket_y / PX
	if _launcher == null:
		_launcher = Sprite2D.new()
		_bucket_sprite = Sprite2D.new()
		add_child(_bucket_sprite)
		add_child(_launcher)
	_launcher.texture = skin.launcher_texture
	_launcher.position = Vector2(config.launcher_x, config.launcher_y) / PX
	_bucket_sprite.texture = skin.bucket_texture
	_bucket_sprite.offset = Vector2(0, skin.bucket_texture.get_height() / 2.0)
	for sprite: Sprite2D in _balls:
		sprite.visible = false
	_was_active.fill(0)
	refresh_pegs()


## Points the launcher along [param aim], in centidegrees from straight down.
func set_aim(aim: int) -> void:
	if _launcher != null:
		_launcher.rotation = -deg_to_rad(aim / 100.0)


func refresh_pegs() -> void:
	queue_redraw()


## Remembers where things are before the next simulation tick, for interpolation.
func capture_previous() -> void:
	var balls: Array[SimBall] = _game.simulation.balls
	if _previous.size() < balls.size():
		_previous.resize(balls.size())
		_was_active.resize(balls.size())
	for index: int in balls.size():
		var ball: SimBall = balls[index]
		_previous[index] = Vector2(ball.x, ball.y) / PX
		_was_active[index] = 1 if ball.active else 0
	if bucket_source != null:
		_bucket_previous = bucket_source.x / PX


## Places sprites [param alpha] of the way from the previous tick to the current one.
func render(alpha: float) -> void:
	var balls: Array[SimBall] = _game.simulation.balls
	while _balls.size() < balls.size():
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = _skin.ball_texture
		add_child(sprite)
		_balls.append(sprite)
	for index: int in _balls.size():
		var sprite: Sprite2D = _balls[index]
		var ball: SimBall = balls[index] if index < balls.size() else null
		sprite.visible = ball != null and ball.active
		if not sprite.visible:
			continue
		var current: Vector2 = Vector2(ball.x, ball.y) / PX
		var interpolate: bool = index < _was_active.size() and _was_active[index] == 1
		sprite.position = _previous[index].lerp(current, alpha) if interpolate else current
	if bucket_source != null:
		var x: float = lerpf(_bucket_previous, bucket_source.x / PX, alpha)
		_bucket_sprite.position = Vector2(x, _bucket_y)


func _draw() -> void:
	if _game == null:
		return
	var pegs: Array[SimPeg] = _game.simulation.pegs
	for index: int in pegs.size():
		var peg: SimPeg = pegs[index]
		if peg.removed:
			continue
		var definition: PegDefinition = _game.definition_of(index)
		var centre: Vector2 = Vector2(peg.x, peg.y) / PX
		var tint: Color = LIT_TINT if peg.lit else Color.WHITE
		if peg.shape == SimPeg.Shape.ROUND:
			var texture: Texture2D = definition.texture
			draw_texture(texture, centre - texture.get_size() / 2.0, tint)
			if peg.lit:
				draw_arc(centre, peg.radius / PX + 1.0, 0.0, TAU, 16, _skin.lit_color, 1.0)
		else:
			var half: Vector2 = Vector2(peg.half_width, peg.half_height) / PX
			var rect: Rect2 = Rect2(-half, half * 2.0)
			draw_set_transform(centre, deg_to_rad(peg.angle_cd / 100.0))
			draw_rect(rect, definition.color * tint)
			draw_rect(rect, _skin.lit_color if peg.lit else definition.color.darkened(0.5), false)
			draw_set_transform(Vector2.ZERO)
