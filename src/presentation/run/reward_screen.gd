class_name RewardScreen
extends Control
## After a won board: what it paid, then the ball choice and, after elites and bosses, the
## omamori choice. With every slot taken, picking an omamori asks which one it replaces.

## The run has left the reward phase.
signal advanced

var _run: Run
var _bar: RunBar
var _body: VBoxContainer
## Omamori choice waiting for a slot to replace, or -1.
var _replacing: int = -1


func open(run: Run) -> void:
	_run = run
	_replacing = -1
	if _body == null:
		var page: Control = UiKit.page(self)
		_bar = RunBar.new()
		_bar.position = Vector2(16, 8)
		page.add_child(_bar)
		_body = UiKit.body(page)
	_refresh()


func _refresh() -> void:
	if _run.phase != Run.Phase.REWARD:
		advanced.emit()
		return
	_bar.show_run(_run)
	UiKit.clear(_body)
	_body.add_child(UiKit.label("REWARD_TITLE", UiKit.TITLE_SIZE))
	_body.add_child(UiKit.label(_payout_text(_run.payout), 0, UiKit.MON, false))
	var cards: HBoxContainer = UiKit.row(8)
	var actions: HBoxContainer = UiKit.row(8)
	if not _run.ball_choices.is_empty():
		_body.add_child(UiKit.label("REWARD_PICK_BALL"))
		for index: int in _run.ball_choices.size():
			cards.add_child(_card(_run.ball_choices[index], _take_ball.bind(index)))
		var skip: Button = UiKit.button(tr("REWARD_SKIP") % _run.config.skip_reward_mon, false)
		skip.pressed.connect(_skip_ball)
		actions.add_child(skip)
	elif _replacing >= 0:
		_body.add_child(UiKit.label("REWARD_REPLACE"))
		var owned: Array[OmamoriDefinition] = _run.state.inventory.loadout.omamori
		for slot: int in owned.size():
			cards.add_child(_card(owned[slot], _replace.bind(slot)))
		var cancel: Button = UiKit.button("BUTTON_CANCEL", true, AudioService.UI_BACK)
		cancel.pressed.connect(_cancel_replace)
		actions.add_child(cancel)
	else:
		_body.add_child(UiKit.label("REWARD_PICK_OMAMORI"))
		for index: int in _run.omamori_choices.size():
			cards.add_child(_card(_run.omamori_choices[index], _take_omamori.bind(index)))
		var skip: Button = UiKit.button("REWARD_SKIP_OMAMORI")
		skip.pressed.connect(_skip_omamori)
		actions.add_child(skip)
	_body.add_child(cards)
	_body.add_child(actions)


func _card(item: ItemDefinition, action: Callable) -> ItemCard:
	var card: ItemCard = ItemCard.new()
	card.show_item(item)
	card.pressed.connect(AudioService.play.bind(AudioService.UI_CONFIRM, 1.0))
	card.pressed.connect(action)
	return card


func _take_ball(index: int) -> void:
	_run.take_ball(index)
	_refresh()


func _skip_ball() -> void:
	_run.skip_ball()
	_refresh()


func _take_omamori(index: int) -> void:
	if not _run.take_omamori(index):
		_replacing = index
	_refresh()


func _replace(slot: int) -> void:
	_run.take_omamori(_replacing, slot)
	_replacing = -1
	_refresh()


func _cancel_replace() -> void:
	_replacing = -1
	_refresh()


func _skip_omamori() -> void:
	_run.skip_omamori()
	_refresh()


func _payout_text(payout: Payout) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var lines: Array[Array] = [
		["PAYOUT_WIN", payout.win],
		["PAYOUT_SHOTS", payout.unused_shots],
		["PAYOUT_MATSURI", payout.matsuri],
		["PAYOUT_INTEREST", payout.interest],
		["PAYOUT_ITEMS", payout.items],
		["PAYOUT_WAGER", payout.wager],
	]
	for line: Array in lines:
		if line[1] > 0:
			parts.append(tr(line[0]) % line[1])
	return "%s = %s" % [" · ".join(parts), tr("PAYOUT_TOTAL") % payout.total()]
