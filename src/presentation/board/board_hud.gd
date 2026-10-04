class_name BoardHud
extends Control
## Side panels, touch controls and the end-of-board overlay. Reads the board game, never writes it.

## The end-of-board button was pressed: play again, or continue the run.
signal continue_requested

## Seconds the shot total takes to settle after bursting.
const BURST_TIME: float = 0.35
const BURST_SCALE: float = 1.8
## Seconds an omamori slot glows after its effect acts.
const FLASH_TIME: float = 0.3
const FLASH_TINT: Color = Color(1.8, 1.8, 1.4)
## Seconds and pixels of the boss portrait's jolt after each shot.
const JOLT_TIME: float = 0.3
const JOLT_DISTANCE: float = 3.0
const SLOT_SIZE: Vector2 = Vector2(20, 20)
const SLOT_COLOUR: Color = Color(0.180392, 0.203922, 0.286275, 1)

var _burst_age: float = -1.0
var _slot_ages: PackedFloat32Array = PackedFloat32Array()
var _slots: Array[ColorRect] = []
var _jolt_age: float = -1.0
var _portrait_age: float = -1.0

@onready var _shots: Label = %ShotsValue
@onready var _ball: Label = %BallValue
@onready var _ball_icon: TextureRect = %BallIcon
@onready var _next: Label = %NextValue
@onready var _next_icon: TextureRect = %NextIcon
@onready var _mon: Label = %MonValue
@onready var _slot_row: HFlowContainer = %OmamoriSlots
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
@onready var _continue: Button = %PlayAgainButton
@onready var _aim_left: Button = %AimLeftButton
@onready var _aim_right: Button = %AimRightButton
@onready var _shoot: Button = %ShootButton
@onready var _left_panel: ColorRect = %LeftPanel
@onready var _right_panel: ColorRect = %RightPanel
@onready var _character_row: Control = %CharacterRow
@onready var _character_portrait: TextureRect = %CharacterPortrait
@onready var _character_name: Label = %CharacterName
@onready var _character_power: Label = %CharacterPower
@onready var _boss_box: Control = %BossBox
@onready var _boss_portrait: TextureRect = %BossPortrait
@onready var _boss_name: Label = %BossName
@onready var _boss_rule: Label = %BossRule


func _ready() -> void:
	_touch_controls.visible = DisplayServer.is_touchscreen_available()
	_continue.pressed.connect(continue_requested.emit)
	for child: Node in _slot_row.get_children():
		_add_icon(child as ColorRect)
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


## Shows the omamori of [param loadout] in [param slots] slots, with name and description as
## tooltip.
func show_loadout(loadout: LoadoutDefinition, slots: int) -> void:
	while _slots.size() < slots:
		var frame: ColorRect = ColorRect.new()
		frame.custom_minimum_size = SLOT_SIZE
		frame.color = SLOT_COLOUR
		_slot_row.add_child(frame)
		_add_icon(frame)
	for index: int in _slots.size():
		_slots[index].visible = index < slots
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


## Shows the character's portrait, name and power, or nothing for [code]null[/code].
func show_character(character: CharacterDefinition) -> void:
	_character_row.visible = character != null
	_character_power.visible = character != null
	if character == null:
		return
	_character_portrait.texture = character.portrait
	_character_name.text = character.name_key
	_character_power.text = character.power_key


## Shows the boss and its rule, or hides the box on boards without one.
func show_boss(boss: BossDefinition) -> void:
	_boss_box.visible = boss != null
	if boss == null:
		return
	_boss_portrait.texture = boss.portrait
	_boss_name.text = boss.name_key
	_boss_rule.text = boss.description_key


## Text of the end-of-board button: play again on its own, continue in a run.
func set_continue_text(key: String) -> void:
	_continue.text = key


## The boss portrait jolts after a shot, the GDD's boss reacting to shots.
func boss_react() -> void:
	if _boss_box.visible:
		_jolt_age = 0.0
		set_process(true)


## Lights up omamori [param slot] for a moment after its effect acts; the character's slot lights
## up its portrait.
func flash_slot(slot: int) -> void:
	if slot == Effect.CHARACTER_SLOT:
		_portrait_age = 0.0
		_character_portrait.modulate = FLASH_TINT
		set_process(true)
		return
	if slot < 0 or slot >= _slots.size():
		return
	_slot_ages[slot] = 0.0
	_slots[slot].modulate = FLASH_TINT
	set_process(true)


func update_bag(game: BoardGame) -> void:
	_show_ball(game.bag.peek(0), _ball, _ball_icon)
	_show_ball(game.bag.peek(1), _next, _next_icon)


func show_board(placed: PlacedBoard, board_seed: int) -> void:
	_seed.text = "%s %X" % [tr("HUD_SEED"), board_seed]
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
	if _jolt_age >= 0.0:
		_jolt_age += delta
		var left: float = 1.0 - clampf(_jolt_age / JOLT_TIME, 0.0, 1.0)
		_boss_portrait.position.x = sin(_jolt_age * 60.0) * JOLT_DISTANCE * left
		if left <= 0.0:
			_jolt_age = -1.0
		else:
			busy = true
	if _portrait_age >= 0.0:
		_portrait_age += delta
		var faded: float = clampf(_portrait_age / FLASH_TIME, 0.0, 1.0)
		_character_portrait.modulate = FLASH_TINT.lerp(Color.WHITE, faded)
		if faded >= 1.0:
			_portrait_age = -1.0
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


func _add_icon(frame: ColorRect) -> void:
	_slots.append(frame)
	_slot_ages.append(-1.0)
	var icon: TextureRect = TextureRect.new()
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(icon)


func _show_ball(ball: BagBall, label: Label, icon: TextureRect) -> void:
	label.text = tr(ball.definition.name_key) if ball != null else tr("BALL_HITODAMA")
	icon.texture = ball.definition.texture if ball != null else null
