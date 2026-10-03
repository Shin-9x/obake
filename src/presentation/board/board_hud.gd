class_name BoardHud
extends Control
## Side panels, touch controls and the end-of-board overlay. Reads the board game, never writes it.

signal play_again_requested

## Seconds the shot total takes to settle after bursting.
const BURST_TIME: float = 0.35
const BURST_SCALE: float = 1.8
## Seconds an omamori slot glows after its effect acts.
const FLASH_TIME: float = 0.3
const FLASH_TINT: Color = Color(1.8, 1.8, 1.4)

var _burst_age: float = -1.0
var _slot_ages: PackedFloat32Array = PackedFloat32Array()
var _slots: Array[ColorRect] = []

@onready var _shots: Label = %ShotsValue
@onready var _ball: Label = %BallValue
@onready var _ball_icon: TextureRect = %BallIcon
@onready var _next: Label = %NextValue
@onready var _next_icon: TextureRect = %NextIcon
@onready var _mon: Label = %MonValue
@onready var _slot_row: HBoxContainer = %OmamoriSlots
@onready var _seed: Label = %SeedValue
@onready var _layout: Label = %LayoutValue
@onready var _shot: Label = %ShotValue
@onready var _shot_total: Label = %ShotTotal
@onready var _total: Label = %TotalValue
@onready var _red_left: Label = %RedValue
@onready var _touch_controls: Control = %TouchControls
@onready var _result: Control = %ResultOverlay
@onready var _result_title: Label = %ResultTitle
@onready var _result_total: Label = %ResultTotal
@onready var _result_shots: Label = %ResultShots
@onready var _play_again: Button = %PlayAgainButton
@onready var _aim_left: Button = %AimLeftButton
@onready var _aim_right: Button = %AimRightButton
@onready var _shoot: Button = %ShootButton
@onready var _left_panel: ColorRect = %LeftPanel
@onready var _right_panel: ColorRect = %RightPanel


func _ready() -> void:
	_touch_controls.visible = DisplayServer.is_touchscreen_available()
	_play_again.pressed.connect(play_again_requested.emit)
	for child: Node in _slot_row.get_children():
		_slots.append(child as ColorRect)
		var icon: TextureRect = TextureRect.new()
		icon.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		child.add_child(icon)
	_slot_ages.resize(_slots.size())
	_slot_ages.fill(-1.0)
	set_process(false)


## Formats a permille mult for display: 2000 is "2", 1500 is "1.5".
static func format_mult(permille: int) -> String:
	if permille % FixedMath.PERMILLE == 0:
		return str(permille / FixedMath.PERMILLE)
	return String.num(permille / float(FixedMath.PERMILLE), 2)


func connect_aim(aim: AimInput) -> void:
	_aim_left.button_down.connect(aim.hold_nudge.bind(-1))
	_aim_right.button_down.connect(aim.hold_nudge.bind(1))
	_aim_left.button_up.connect(aim.hold_nudge.bind(0))
	_aim_right.button_up.connect(aim.hold_nudge.bind(0))
	_shoot.pressed.connect(aim.shoot_requested.emit)


func apply_skin(skin: BoardSkin) -> void:
	_left_panel.color = skin.panel_color
	_right_panel.color = skin.panel_color


## Shows the omamori of [param loadout] in their slots, with name and description as tooltip.
func show_loadout(loadout: LoadoutDefinition) -> void:
	for index: int in _slots.size():
		var slot: ColorRect = _slots[index]
		var icon: TextureRect = slot.get_child(0) as TextureRect
		var charm: OmamoriDefinition = (
			loadout.omamori[index] if index < loadout.omamori.size() else null
		)
		icon.texture = charm.icon if charm != null else null
		slot.tooltip_text = (
			"" if charm == null else tr(charm.name_key) + "\n" + tr(charm.description_key)
		)
		slot.modulate = Color.WHITE


## Lights up omamori [param slot] for a moment after its effect acts.
func flash_slot(slot: int) -> void:
	if slot < 0 or slot >= _slots.size():
		return
	_slot_ages[slot] = 0.0
	_slots[slot].modulate = FLASH_TINT
	set_process(true)


func update_bag(game: BoardGame) -> void:
	_show_ball(game.bag.peek(0), _ball, _ball_icon)
	_show_ball(game.bag.peek(1), _next, _next_icon)


func show_board(placed: PlacedBoard, board_seed: int) -> void:
	_seed.text = "%X" % board_seed
	_layout.text = placed.layout.id
	if placed.mirrored:
		_layout.text += " " + tr("HUD_MIRRORED")
	_result.visible = false
	_shot_total.text = ""
	update_shot(placed.game)
	update_counts(placed.game)
	update_bag(placed.game)


func update_shot(game: BoardGame) -> void:
	_shot.text = "%d × %s" % [game.shot_points, format_mult(game.shot_mult)]


func update_counts(game: BoardGame) -> void:
	_shots.text = str(game.shots_left)
	_mon.text = "+%d" % game.mon_earned
	_total.text = "%d / %d" % [game.total, game.target]
	_red_left.text = str(game.red_remaining())


## Shows the score of the shot that just ended with a short scale pop.
func burst(score: int) -> void:
	_shot_total.text = "+%d" % score
	_shot_total.pivot_offset = _shot_total.size / 2.0
	_burst_age = 0.0
	set_process(true)


func show_result(game: BoardGame) -> void:
	match game.outcome:
		BoardGame.Outcome.TARGET_REACHED:
			_result_title.text = tr("RESULT_TARGET")
		BoardGame.Outcome.MATSURI:
			_result_title.text = tr("RESULT_MATSURI")
		_:
			_result_title.text = tr("RESULT_FAILED")
	_result_total.text = tr("RESULT_TOTAL") % game.total
	_result_shots.text = tr("RESULT_UNUSED_SHOTS") % game.shots_left
	_result_shots.visible = game.outcome != BoardGame.Outcome.FAILED
	_result.visible = true


func _process(delta: float) -> void:
	var busy: bool = false
	if _burst_age >= 0.0:
		_burst_age += delta
		var progress: float = clampf(_burst_age / BURST_TIME, 0.0, 1.0)
		_shot_total.scale = Vector2.ONE * lerpf(BURST_SCALE, 1.0, progress)
		if progress >= 1.0:
			_burst_age = -1.0
		else:
			busy = true
	for index: int in _slots.size():
		if _slot_ages[index] < 0.0:
			continue
		_slot_ages[index] += delta
		var fade: float = clampf(_slot_ages[index] / FLASH_TIME, 0.0, 1.0)
		_slots[index].modulate = FLASH_TINT.lerp(Color.WHITE, fade)
		if fade >= 1.0:
			_slot_ages[index] = -1.0
		else:
			busy = true
	if not busy:
		set_process(false)


func _show_ball(ball: BagBall, label: Label, icon: TextureRect) -> void:
	label.text = tr(ball.definition.name_key) if ball != null else tr("BALL_HITODAMA")
	icon.texture = ball.definition.texture if ball != null else null
