class_name BoardScreen
extends Control
## Plays one board: steps the simulation at a fixed 120 Hz, interpolates rendering in between
## and routes input. Nothing computed for display ever flows back into the simulation.
##
## On its own (F6) it plays the development loadout on random layouts; the run screen turns
## [member standalone] off and hands it each board with [method play].

## The board is over and the player chose to continue the run.
signal board_finished(result: BoardResult)

const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const SKIN: BoardSkin = preload("res://data/skins/placeholder_skin.tres")
const UI_SKIN: UiSkin = preload("res://data/skins/ui_skin.tres")
## Character, bag, omamori and purchased pegs of a board played on its own; edit it in the
## Inspector to try items.
const DEV_LOADOUT: LoadoutDefinition = preload("res://data/debug/dev_loadout.tres")
const TICK_SECONDS: float = 1.0 / BoardSimulation.TICKS_PER_SECOND
## Caps catch-up after a long frame, so a hitch never turns into a burst of ticks.
const MAX_TICKS_PER_FRAME: int = 12
## Display-only speed of the slow motion near the last red lantern; the simulation is unchanged.
const SLOW_MOTION_SPEED: float = 0.3
## How near a ball must come to the last red lantern for the slow motion, in milli-pixels.
const SLOW_MOTION_REACH: int = 40_000
## Screen shake, in pixels, when the mult grows, is multiplied, an explosion goes off, and on a
## Matsuri.
const SHAKE_MULT: float = 1.0
const SHAKE_TIMES: float = 2.5
const SHAKE_BLAST: float = 2.0
const SHAKE_MATSURI: float = 5.0
const CONFETTI: int = 40
## Vibration on phones, in milliseconds, for a won board and for a Matsuri.
const VIBRATE_WIN: int = 40
const VIBRATE_MATSURI: int = 120
## Ticks between aim guide refreshes while pegs move (10 Hz); predictions cost too much to
## repeat every tick on low-end phones.
const GUIDE_REFRESH_TICKS: int = 12
const PX: float = 1000.0
const POINTS_COLOR: Color = Color("#bfe0ff")
const MULT_COLOR: Color = Color("#ff9a8a")
const TIMES_COLOR: Color = Color("#ffd866")
const MON_COLOR: Color = Color("#ffe08a")

## Plays random development boards when true; the run sets it to false before adding the screen.
var standalone: bool = true
## Fires shots for a run, which logs them: called with the aim and the board clock. Without it
## shots go straight to the board.
var shooter: Callable
var game: BoardGame
var placed: PlacedBoard
var board_seed: int = 0
## Microseconds spent on simulation ticks and their events in the last frame, for the
## performance tools.
var tick_usec: int = 0

var _library: LayoutLibrary
## Run-wide modifiers kept across boards of this session.
var _carry: RunCarry = RunCarry.new()
var _accumulator: float = 0.0
var _guide_ticks: int = 0
var _sounds: BoardSounds = BoardSounds.new()
var _camera: BoardCamera = BoardCamera.new()
## Lit pegs already given their leaving puff, by peg index.
var _puffed: PackedByteArray = PackedByteArray()

@onready var _view: BoardView = %BoardView
@onready var _guide: AimGuide = %AimGuide
@onready var _popups: ScorePopups = %ScorePopups
@onready var _blasts: BlastRings = %BlastRings
@onready var _hud: BoardHud = %Hud
@onready var _aim: AimInput = %AimInput
@onready var _background: ColorRect = %Background
@onready var _board_background: ColorRect = %BoardBackground
@onready var _sparks: HitSparks = %HitSparks
@onready var _trails: BallTrails = %BallTrails


func _ready() -> void:
	_background.color = SKIN.background_color
	_background.add_child(UiKit.pattern())
	_board_background.color = SKIN.board_color
	_guide.color = SKIN.guide_color
	_hud.apply_skin(SKIN)
	_hud.mascot_moods = UI_SKIN.mascot_moods
	_view.trails = _trails
	_camera.world = %World
	_camera.size = Vector2(BALANCE.board_width, BALANCE.board_height) / PX
	_library = LayoutLibrary.load_from()
	_aim.aim_limit = BALANCE.aim_limit
	_aim.board = _view
	_aim.launcher_position = Vector2(BALANCE.launcher_x, BALANCE.launcher_y) / PX
	_aim.aim_changed.connect(_on_aim_changed)
	_aim.shoot_requested.connect(shoot)
	_hud.connect_aim(_aim)
	_hud.continue_requested.connect(_on_continue)
	if standalone:
		start_board(_new_seed())


func _enter_tree() -> void:
	if not Performance.has_custom_monitor(PerfOverlay.TICK_MONITOR):
		Performance.add_custom_monitor(PerfOverlay.TICK_MONITOR, func() -> int: return tick_usec)


func _exit_tree() -> void:
	if Performance.has_custom_monitor(PerfOverlay.TICK_MONITOR):
		Performance.remove_custom_monitor(PerfOverlay.TICK_MONITOR)


## Plays a development board for [param seed_value] with the development loadout.
func start_board(seed_value: int) -> void:
	var layout: BoardLayout = BoardSetup.pick_layout(_library, seed_value)
	var board: PlacedBoard = BoardSetup.create_board(
		BALANCE, BASE_PEGS, layout, seed_value, DEV_LOADOUT, _carry
	)
	_show(board, seed_value, DEV_LOADOUT, BALANCE.omamori_slots, null)


## Plays a run's board: [param board] already holds the run's loadout and rules; the rest is
## for display.
func play(
	board: PlacedBoard,
	seed_value: int,
	loadout: LoadoutDefinition,
	slots: int,
	boss: BossDefinition
) -> void:
	_show(board, seed_value, loadout, slots, boss)


func _show(
	board: PlacedBoard,
	seed_value: int,
	loadout: LoadoutDefinition,
	slots: int,
	boss: BossDefinition
) -> void:
	board_seed = seed_value
	placed = board
	game = placed.game
	# Changes made while the board was set up, such as oni placed by a boss, are already drawn.
	game.events.clear()
	_view.setup(game, BALANCE, SKIN)
	_view.set_aim(_aim.aim)
	_popups.hide_all()
	_blasts.clear()
	_sparks.clear()
	_trails.clear()
	_camera.reset()
	_puffed.resize(game.simulation.pegs.size())
	_puffed.fill(0)
	_hud.show_mood(MascotMood.Mood.IDLE)
	_hud.show_loadout(loadout, slots)
	_hud.show_character(loadout.character)
	_hud.show_boss(boss)
	_hud.set_continue_text("BUTTON_PLAY_AGAIN" if standalone else "BUTTON_CONTINUE")
	_sounds.boss = boss != null
	AudioService.play_music(AudioService.Music.BOARD)
	_hud.show_board(placed, seed_value)
	if game.outcome != BoardGame.Outcome.PLAYING:
		_hud.show_result(game)
	_accumulator = 0.0
	_refresh_guide()


## Turns the launcher to [param aim], in centidegrees, as the player would.
func aim_at(aim: int) -> void:
	_aim.set_aim(aim)


## Fires along the current aim. Ignored while a shot is in flight or once the board is over.
func shoot() -> void:
	if not game.can_shoot():
		return
	if shooter.is_valid():
		shooter.call(_aim.aim, game.simulation.clock)
	else:
		game.shoot(ShotInput.new(_aim.aim, game.simulation.clock))
	_guide.visible = false
	_consume_events()
	_hud.update_shot(game)
	_hud.update_counts(game)
	_hud.update_bag(game)


func _process(delta: float) -> void:
	var speed: float = 1.0
	if game.simulation.is_shot_active():
		var red: int = SlowMotion.target(game, SLOW_MOTION_REACH)
		if red >= 0:
			speed = SLOW_MOTION_SPEED
			var peg: SimPeg = game.simulation.pegs[red]
			_camera.focus(Vector2(peg.x, peg.y) / PX, true)
		else:
			_camera.focus(Vector2.ZERO, false)
			if _aim.fast_forward:
				speed = Settings.values.fast_forward_speed
	else:
		_camera.focus(Vector2.ZERO, false)
	_accumulator = minf(_accumulator + delta * speed, MAX_TICKS_PER_FRAME * TICK_SECONDS)
	var started: int = Time.get_ticks_usec()
	while _accumulator >= TICK_SECONDS:
		_accumulator -= TICK_SECONDS
		_tick()
	tick_usec = Time.get_ticks_usec() - started
	_view.render(_accumulator / TICK_SECONDS)
	_camera.update(delta)


func _tick() -> void:
	_view.capture_previous()
	if not game.simulation.is_shot_active():
		game.idle_step()
		if not game.simulation.groups.is_empty():
			_guide_ticks += 1
			if _guide_ticks >= GUIDE_REFRESH_TICKS:
				_guide_ticks = 0
				_refresh_guide()
		return
	game.step()
	_consume_events()
	if not game.simulation.is_shot_active():
		_hud.update_bag(game)
		_refresh_guide()


func _consume_events() -> void:
	var events: SimEventQueue = game.events
	var pegs_changed: bool = false
	var score_changed: bool = false
	for index: int in events.size():
		var event: SimEvent = events.at(index)
		var at: Vector2 = Vector2(event.x, event.y) / PX
		_sounds.hear(event)
		match event.kind:
			SimEvent.Kind.PEG_HIT:
				var hit: SimPeg = game.simulation.pegs[event.target]
				_sparks.hit(Vector2(hit.x, hit.y) / PX, game.definition_of(event.target).color)
				pegs_changed = true
			SimEvent.Kind.STUCK_CLEARED, SimEvent.Kind.SHOT_RESOLVED:
				_puff_removed_pegs()
				pegs_changed = true
			SimEvent.Kind.PEG_BURNING:
				pegs_changed = true
			SimEvent.Kind.AREA_HIT:
				_blasts.burst(event.x, event.y, event.amount)
				_shake(SHAKE_BLAST)
				pegs_changed = true
			SimEvent.Kind.SCORE_POINTS:
				_popups.show_text("+%d" % event.amount, at, POINTS_COLOR)
				score_changed = true
				pegs_changed = true
			SimEvent.Kind.SCORE_MULT_ADD:
				var added: String = BoardHud.format_mult(absi(event.amount))
				var key: String = "POPUP_MULT_ADD" if event.amount >= 0 else "POPUP_MULT_SUB"
				_popups.show_text(tr(key) % added, at, MULT_COLOR)
				if event.amount > 0:
					_shake(SHAKE_MULT)
				score_changed = true
				pegs_changed = true
			SimEvent.Kind.SCORE_POINTS_TIMES:
				var scaled: String = BoardHud.format_mult(event.amount)
				_popups.show_text(tr("POPUP_POINTS_TIMES") % scaled, at, POINTS_COLOR)
				score_changed = true
			SimEvent.Kind.PEG_TRANSFORMED, SimEvent.Kind.PEG_VANISHED:
				pegs_changed = true
			SimEvent.Kind.LAYOUT_CHANGED:
				pegs_changed = true
				_hud.update_counts(game)
			SimEvent.Kind.SCORE_MULT_TIMES:
				var factor: String = BoardHud.format_mult(event.amount)
				_popups.show_text(tr("POPUP_MULT_TIMES") % factor, at, TIMES_COLOR)
				_shake(SHAKE_TIMES)
				score_changed = true
				pegs_changed = true
			SimEvent.Kind.MON_GAINED:
				_popups.show_text(tr("POPUP_MON") % event.amount, at, MON_COLOR)
				_hud.update_counts(game)
			SimEvent.Kind.BALL_DRAWN:
				var drawn: Texture2D = null
				if game.shot_ball != null:
					drawn = game.shot_ball.definition.texture
				_view.set_ball_texture(event.ball, drawn)
			SimEvent.Kind.BALL_SPLIT:
				_view.copy_ball_texture(event.target, event.ball)
			SimEvent.Kind.EFFECT_TRIGGERED:
				_hud.flash_slot(event.target)
				if event.target == Effect.CHARACTER_SLOT:
					_hud.show_mood(MascotMood.Mood.EXCITED)
			SimEvent.Kind.BUCKET_CATCH:
				_popups.show_text(tr("POPUP_FREE_BALL"), at, POINTS_COLOR)
				_hud.update_counts(game)
			SimEvent.Kind.SHOT_SCORED:
				_hud.burst(event.amount)
				_hud.boss_react()
				_hud.update_counts(game)
				_hud.show_mood(MascotMood.after_shot(game, event.amount))
			SimEvent.Kind.BOARD_ENDED:
				if event.amount != BoardGame.Outcome.FAILED:
					_vibrate(VIBRATE_WIN)
				if event.amount == BoardGame.Outcome.MATSURI:
					_vibrate(VIBRATE_MATSURI)
					_hud.celebrate("RESULT_MATSURI")
					_sparks.confetti(Vector2(_camera.size.x / 2.0, _camera.size.y * 0.6), CONFETTI)
					_shake(SHAKE_MATSURI)
				_hud.show_result(game)
	_sounds.after_events(game)
	if score_changed:
		_hud.update_shot(game)
	if pegs_changed:
		_view.refresh_pegs()
	events.clear()


func _vibrate(milliseconds: int) -> void:
	if Settings.values.vibration and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)


func _shake(strength: float) -> void:
	if Settings.values.screen_shake:
		_camera.shake(strength)


## A puff where each lit peg left the board since the last call.
func _puff_removed_pegs() -> void:
	var pegs: Array[SimPeg] = game.simulation.pegs
	for index: int in pegs.size():
		var peg: SimPeg = pegs[index]
		if peg.removed and peg.lit and _puffed[index] == 0:
			_puffed[index] = 1
			_sparks.puff(Vector2(peg.x, peg.y) / PX, game.definition_of(index).color)


func _on_aim_changed(aim: int) -> void:
	_view.set_aim(aim)
	_refresh_guide()


func _on_continue() -> void:
	if standalone:
		start_board(_new_seed())
	else:
		board_finished.emit(game.result)


func _refresh_guide() -> void:
	_guide.visible = game.can_shoot()
	if _guide.visible:
		_guide.show_path(game.simulation, _aim.aim, game.guide_contacts())


## A fresh board seed from the clock; game randomness itself always comes from PCG32.
static func _new_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
