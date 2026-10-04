class_name ShrineScreen
extends Control
## A shrine: remove one ball from the bag or upgrade one, for free.

## The run has left the shrine.
signal advanced

enum Mode { CHOOSE, REMOVE, UPGRADE }

var _run: Run
var _bar: RunBar
var _body: VBoxContainer
var _mode: Mode = Mode.CHOOSE


func open(run: Run) -> void:
	_run = run
	_mode = Mode.CHOOSE
	if _body == null:
		var page: Control = UiKit.page(self)
		_bar = RunBar.new()
		_bar.position = Vector2(16, 8)
		page.add_child(_bar)
		_body = UiKit.body(page)
	_refresh()


func _refresh() -> void:
	if _run.phase != Run.Phase.SHRINE:
		advanced.emit()
		return
	_bar.show_run(_run)
	UiKit.clear(_body)
	_body.add_child(UiKit.label("SHRINE_TITLE", UiKit.TITLE_SIZE))
	var inventory: Inventory = _run.state.inventory
	if _mode == Mode.CHOOSE:
		_body.add_child(UiKit.paragraph(tr("SHRINE_TEXT"), UiKit.PAGE_SIZE.x - 32))
		var bag: BagList = BagList.new()
		bag.show_bag(inventory)
		_body.add_child(bag)
		var actions: HBoxContainer = UiKit.row(8)
		var remove: Button = UiKit.button("SHRINE_REMOVE")
		remove.disabled = not inventory.can_remove_ball()
		remove.pressed.connect(_set_mode.bind(Mode.REMOVE))
		actions.add_child(remove)
		var upgrade: Button = UiKit.button("SHRINE_UPGRADE")
		upgrade.disabled = inventory.upgradable_balls().is_empty()
		upgrade.pressed.connect(_set_mode.bind(Mode.UPGRADE))
		actions.add_child(upgrade)
		var leave: Button = UiKit.button("SHRINE_LEAVE")
		leave.pressed.connect(_leave)
		actions.add_child(leave)
		_body.add_child(actions)
		return
	var removing: bool = _mode == Mode.REMOVE
	_body.add_child(UiKit.label("SHRINE_PICK_REMOVE" if removing else "SHRINE_PICK_UPGRADE"))
	var allowed: PackedInt32Array = inventory.upgradable_balls()
	if removing:
		allowed = PackedInt32Array(range(inventory.ball_count()))
	var picker: BagList = BagList.new()
	picker.show_bag(inventory, allowed)
	picker.ball_picked.connect(_pick)
	_body.add_child(picker)
	var back: Button = UiKit.button("BUTTON_BACK")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_set_mode.bind(Mode.CHOOSE))
	_body.add_child(back)


func _pick(index: int) -> void:
	if _mode == Mode.REMOVE:
		_run.shrine_remove(index)
	else:
		_run.shrine_upgrade(index)
	_refresh()


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_refresh()


func _leave() -> void:
	_run.leave_shrine()
	_refresh()
