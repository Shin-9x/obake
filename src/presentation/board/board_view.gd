class_name BoardView
extends Node2D
## Draws a board: pegs, balls, bucket and launcher, interpolating between simulation ticks.
##
## Static pegs are drawn in a single pass and redrawn only on [method refresh_pegs]. Moving pegs
## live on their own layer, redrawn every frame only when the board has moving groups. Balls and
## the bucket are sprites moved every frame from the previous and current simulation states.

## Milli-pixels per pixel, as a float for rendering.
const PX: float = 1000.0
## Brightening applied to lit lanterns.
const LIT_TINT: Color = Color(1.6, 1.6, 1.6)
## Ring drawn around pegs that are about to be hit by fire.
const BURN_COLOUR: Color = Color("#ff7a2f")

var _game: BoardGame
var _skin: BoardSkin
var _bucket_y: float = 0.0
var _alpha: float = 0.0
var _balls: Array[Sprite2D] = []
var _ball_textures: Array[Texture2D] = []
var _previous: PackedVector2Array = PackedVector2Array()
var _was_active: PackedByteArray = PackedByteArray()
var _peg_previous: PackedVector2Array = PackedVector2Array()
var _bucket_previous: float = 0.0
var _moving_layer: Node2D
var _bucket_sprite: Sprite2D
var _launcher: Sprite2D


func setup(game: BoardGame, config: BalanceConfig, skin: BoardSkin) -> void:
	_game = game
	_skin = skin
	_bucket_y = config.bucket_y / PX
	if _launcher == null:
		_moving_layer = Node2D.new()
		_moving_layer.draw.connect(_draw_moving_pegs)
		add_child(_moving_layer)
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
	_ball_textures.fill(skin.ball_texture)
	_was_active.fill(0)
	_peg_previous.resize(game.simulation.pegs.size())
	capture_previous()
	refresh_pegs()
	_moving_layer.queue_redraw()


## Points the launcher along [param aim], in centidegrees from straight down.
func set_aim(aim: int) -> void:
	if _launcher != null:
		_launcher.rotation = -deg_to_rad(aim / 100.0)


func refresh_pegs() -> void:
	queue_redraw()


## Draws ball [param index] with [param texture], or the skin's default when it is null.
func set_ball_texture(index: int, texture: Texture2D) -> void:
	while _ball_textures.size() <= index:
		_ball_textures.append(_skin.ball_texture)
	_ball_textures[index] = texture if texture != null else _skin.ball_texture
	if index < _balls.size():
		_balls[index].texture = _ball_textures[index]


## Gives ball [param child] the look of ball [param parent], for balls split from another.
func copy_ball_texture(parent: int, child: int) -> void:
	var texture: Texture2D = _ball_textures[parent] if parent < _ball_textures.size() else null
	set_ball_texture(child, texture)


## Remembers where things are before the next simulation tick, for interpolation.
func capture_previous() -> void:
	var simulation: BoardSimulation = _game.simulation
	var balls: Array[SimBall] = simulation.balls
	if _previous.size() < balls.size():
		_previous.resize(balls.size())
		_was_active.resize(balls.size())
	for index: int in balls.size():
		var ball: SimBall = balls[index]
		_previous[index] = Vector2(ball.x, ball.y) / PX
		_was_active[index] = 1 if ball.active else 0
	_bucket_previous = simulation.bucket.x / PX
	if simulation.groups.is_empty():
		return
	for group: MovingGroup in simulation.groups:
		for peg_index: int in group.pegs:
			var peg: SimPeg = simulation.pegs[peg_index]
			_peg_previous[peg_index] = Vector2(peg.x, peg.y) / PX


## Places everything [param alpha] of the way from the previous tick to the current one.
func render(alpha: float) -> void:
	_alpha = alpha
	var simulation: BoardSimulation = _game.simulation
	var balls: Array[SimBall] = simulation.balls
	while _balls.size() < balls.size():
		var sprite: Sprite2D = Sprite2D.new()
		var index: int = _balls.size()
		sprite.texture = (
			_ball_textures[index] if index < _ball_textures.size() else _skin.ball_texture
		)
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
	var bucket_x: float = lerpf(_bucket_previous, simulation.bucket.x / PX, alpha)
	_bucket_sprite.position = Vector2(bucket_x, _bucket_y)
	if not simulation.groups.is_empty():
		_moving_layer.queue_redraw()


func _draw() -> void:
	if _game == null:
		return
	var pegs: Array[SimPeg] = _game.simulation.pegs
	for index: int in pegs.size():
		var peg: SimPeg = pegs[index]
		if peg.group < 0 and not peg.removed:
			_draw_peg(self, index, Vector2(peg.x, peg.y) / PX)


func _draw_moving_pegs() -> void:
	if _game == null:
		return
	var simulation: BoardSimulation = _game.simulation
	for group: MovingGroup in simulation.groups:
		for index: int in group.pegs:
			var peg: SimPeg = simulation.pegs[index]
			if peg.removed:
				continue
			var current: Vector2 = Vector2(peg.x, peg.y) / PX
			_draw_peg(_moving_layer, index, _peg_previous[index].lerp(current, _alpha))


func _draw_peg(canvas: CanvasItem, index: int, centre: Vector2) -> void:
	var peg: SimPeg = _game.simulation.pegs[index]
	var definition: PegDefinition = _game.definition_of(index)
	var tint: Color = LIT_TINT if peg.lit else Color.WHITE
	if _game.is_burning(index):
		canvas.draw_arc(centre, peg.extent / PX + 2.0, 0.0, TAU, 16, BURN_COLOUR, 1.0)
	if peg.shape == SimPeg.Shape.ROUND:
		var texture: Texture2D = definition.texture
		canvas.draw_texture(texture, centre - texture.get_size() / 2.0, tint)
		if peg.lit:
			canvas.draw_arc(centre, peg.radius / PX + 1.0, 0.0, TAU, 16, _skin.lit_color, 1.0)
		return
	var half: Vector2 = Vector2(peg.half_width, peg.half_height) / PX
	var rect: Rect2 = Rect2(-half, half * 2.0)
	canvas.draw_set_transform(centre, deg_to_rad(peg.angle_cd / 100.0))
	canvas.draw_rect(rect, definition.color * tint)
	canvas.draw_rect(rect, _skin.lit_color if peg.lit else definition.color.darkened(0.5), false)
	canvas.draw_set_transform(Vector2.ZERO)
