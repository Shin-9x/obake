class_name EventScreen
extends Control
## A yokai event: its story, the options, a pick when an option asks for a ball or an omamori,
## then what happened.

## The run has left the event.
signal advanced

const OPTION_WIDTH: float = 320.0

var _run: Run
var _bar: RunBar
var _body: VBoxContainer
## Option waiting for its pick, or -1.
var _picking: int = -1


func open(run: Run) -> void:
	_run = run
	_picking = -1
	if _body == null:
		var page: Control = UiKit.page(self)
		_bar = RunBar.new()
		_bar.position = Vector2(16, 8)
		page.add_child(_bar)
		_body = UiKit.body(page)
	_refresh()


func _refresh() -> void:
	if _run.phase != Run.Phase.EVENT:
		advanced.emit()
		return
	_bar.show_run(_run)
	UiKit.clear(_body)
	var event: RunEvent = _run.event
	_body.add_child(UiKit.label(event.definition.title_key, UiKit.TITLE_SIZE))
	var story: String = tr(event.definition.text_key)
	if not event.text_args().is_empty():
		story = story % event.text_args()
	_body.add_child(UiKit.paragraph(story, UiKit.PAGE_SIZE.x - 32))
	if _run.event_outcome != null:
		_show_outcome(_run.event_outcome)
	elif _picking >= 0:
		_show_pick(event.choices(_run.state)[_picking])
	else:
		_show_choices(event.choices(_run.state))


func _show_choices(choices: Array[EventChoice]) -> void:
	for index: int in choices.size():
		var choice: EventChoice = choices[index]
		var text: String = tr(choice.text_key)
		if not choice.args.is_empty():
			text = text % choice.args
		var option: Button = UiKit.button(text, false)
		option.custom_minimum_size = Vector2(OPTION_WIDTH, 0)
		option.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		option.disabled = not choice.enabled
		option.pressed.connect(_choose.bind(index))
		_body.add_child(option)


func _show_pick(choice: EventChoice) -> void:
	if choice.pick == EventChoice.Pick.BALL:
		_body.add_child(UiKit.label("EVENT_PICK_BALL"))
		var bag: BagList = BagList.new()
		bag.show_bag(_run.state.inventory, choice.options)
		bag.ball_picked.connect(_apply_pick)
		_body.add_child(bag)
	else:
		_body.add_child(UiKit.label("EVENT_PICK_OMAMORI"))
		var cards: HBoxContainer = UiKit.row(8)
		var owned: Array[OmamoriDefinition] = _run.state.inventory.loadout.omamori
		for slot: int in owned.size():
			var card: ItemCard = ItemCard.new()
			card.show_item(owned[slot])
			card.set_available(choice.options.has(slot))
			card.pressed.connect(_apply_pick.bind(slot))
			cards.add_child(card)
		_body.add_child(cards)
	var back: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_cancel_pick)
	_body.add_child(back)


func _show_outcome(outcome: EventOutcome) -> void:
	_body.add_child(UiKit.label(outcome.text_key, 0, UiKit.MON))
	if outcome.item != null:
		var card: ItemCard = ItemCard.new()
		card.show_item(outcome.item)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_body.add_child(card)
	var next: Button = UiKit.button("BUTTON_CONTINUE")
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(_finish)
	_body.add_child(next)


func _choose(index: int) -> void:
	var choice: EventChoice = _run.event.choices(_run.state)[index]
	if choice.pick != EventChoice.Pick.NONE:
		_picking = index
	else:
		_run.choose_event(index)
	_refresh()


func _apply_pick(pick: int) -> void:
	_run.choose_event(_picking, pick)
	_picking = -1
	_refresh()


func _cancel_pick() -> void:
	_picking = -1
	_refresh()


func _finish() -> void:
	_run.finish_event()
	_refresh()
