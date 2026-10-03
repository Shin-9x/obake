class_name BoardScreen
extends Control
## Plays one board: steps the simulation at a fixed 120 Hz, interpolates rendering in between
## and routes input. Nothing computed for display ever flows back into the simulation.

const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const SKIN: BoardSkin = preload("res://data/skins/placeholder_skin.tres")
const TICK_SECONDS: float = 1.0 / BoardSimulation.TICKS_PER_SECOND
## Caps catch-up after a long frame, so a hitch never turns into a burst of ticks.
const MAX_TICKS_PER_FRAME: int = 12
## Display-only speed-up while fast-forward is held; the simulation is unchanged.
const FAST_FORWARD_SPEED: float = 3.0
const PX: float = 1000.0
const POINTS_COLOR: Color = Color("#bfe0ff")
const MULT_COLOR: Color = Color("#ff9a8a")
const TIMES_COLOR: Color = Color("#ffd866")

var game: BoardGame
var board_seed: int = 0

var _idle_bucket: Bucket
var _accumulator: float = 0.0

@onready var _view: BoardView = %BoardView
@onready var _guide: AimGuide = %AimGuide
@onready var _popups: ScorePopups = %ScorePopups
@onready var _hud: BoardHud = %Hud
@onready var _aim: AimInput = %AimInput
@onready var _background: ColorRect = %Background
@onready var _board_background: ColorRect = %BoardBackground


func _ready() -> void:
	_background.color = SKIN.background_color
	_board_background.color = SKIN.board_color
	_guide.color = SKIN.guide_color
	_hud.apply_skin(SKIN)
	_idle_bucket = Bucket.new(BALANCE)
	_aim.aim_limit = BALANCE.aim_limit
	_aim.board = _view
	_aim.launcher_position = Vector2(BALANCE.launcher_x, BALANCE.launcher_y) / PX
	_aim.aim_changed.connect(_on_aim_changed)
	_aim.shoot_requested.connect(shoot)
	_hud.connect_aim(_aim)
	_hud.play_again_requested.connect(_on_play_again)
	start_board(_new_seed())


func start_board(seed_value: int) -> void:
	board_seed = seed_value
	game = BoardSetup.create_placeholder_board(BALANCE, BASE_PEGS, seed_value)
	_idle_bucket.set_phase(0)
	_view.setup(game, BALANCE, SKIN)
	_view.bucket_source = _idle_bucket
	_view.set_aim(_aim.aim)
	_popups.hide_all()
	_hud.show_board(game, seed_value)
	_accumulator = 0.0
	_refresh_guide()


## Fires along the current aim. Ignored while a shot is in flight or once the board is over.
func shoot() -> void:
	if not game.can_shoot():
		return
	game.shoot(ShotInput.new(_aim.aim, _idle_bucket.phase))
	_view.bucket_source = game.simulation.bucket
	_guide.visible = false
	_hud.update_shot(game)
	_hud.update_counts(game)


func _process(delta: float) -> void:
	var speed: float = 1.0
	if game.simulation.is_shot_active() and _aim.fast_forward:
		speed = FAST_FORWARD_SPEED
	_accumulator = minf(_accumulator + delta * speed, MAX_TICKS_PER_FRAME * TICK_SECONDS)
	while _accumulator >= TICK_SECONDS:
		_accumulator -= TICK_SECONDS
		_tick()
	_view.render(_accumulator / TICK_SECONDS)


func _tick() -> void:
	_view.capture_previous()
	if not game.simulation.is_shot_active():
		_idle_bucket.advance()
		return
	game.step()
	_consume_events()
	if not game.simulation.is_shot_active():
		# Between shots the bucket keeps moving from where the shot left it.
		_idle_bucket.set_phase(game.simulation.bucket.phase)
		_view.bucket_source = _idle_bucket
		_refresh_guide()


func _consume_events() -> void:
	var events: SimEventQueue = game.events
	var pegs_changed: bool = false
	var score_changed: bool = false
	for index: int in events.size():
		var event: SimEvent = events.at(index)
		var at: Vector2 = Vector2(event.x, event.y) / PX
		match event.kind:
			SimEvent.Kind.PEG_HIT, SimEvent.Kind.STUCK_CLEARED, SimEvent.Kind.SHOT_RESOLVED:
				pegs_changed = true
			SimEvent.Kind.SCORE_POINTS:
				_popups.show_text("+%d" % event.amount, at, POINTS_COLOR)
				score_changed = true
			SimEvent.Kind.SCORE_MULT_ADD:
				var added: String = BoardHud.format_mult(event.amount)
				_popups.show_text(tr("POPUP_MULT_ADD") % added, at, MULT_COLOR)
				score_changed = true
			SimEvent.Kind.SCORE_MULT_TIMES:
				var factor: String = BoardHud.format_mult(event.amount)
				_popups.show_text(tr("POPUP_MULT_TIMES") % factor, at, TIMES_COLOR)
				score_changed = true
			SimEvent.Kind.BUCKET_CATCH:
				_popups.show_text(tr("POPUP_FREE_BALL"), at, POINTS_COLOR)
				_hud.update_counts(game)
			SimEvent.Kind.SHOT_SCORED:
				_hud.burst(event.amount)
				_hud.update_counts(game)
			SimEvent.Kind.BOARD_ENDED:
				_hud.show_result(game)
	if score_changed:
		_hud.update_shot(game)
	if pegs_changed:
		_view.refresh_pegs()
	events.clear()


func _on_aim_changed(aim: int) -> void:
	_view.set_aim(aim)
	_refresh_guide()


func _on_play_again() -> void:
	start_board(_new_seed())


func _refresh_guide() -> void:
	_guide.visible = game.can_shoot()
	if _guide.visible:
		_guide.show_path(game.simulation, _aim.aim)


## A fresh board seed from the clock; game randomness itself always comes from PCG32.
static func _new_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
