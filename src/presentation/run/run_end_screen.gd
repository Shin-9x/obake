class_name RunEndScreen
extends Control
## The end of a run, won or lost: the character, how far the run went and its seed.

signal new_run_requested

const PORTRAIT_SIZE: Vector2 = Vector2(64, 64)


func open(run: Run) -> void:
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	var body: VBoxContainer = UiKit.body(page, 24)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var won: bool = run.phase == Run.Phase.VICTORY
	var title: Label = UiKit.label("RESULT_VICTORY" if won else "RESULT_DEFEAT", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var character: CharacterDefinition = run.state.inventory.loadout.character
	if character != null:
		body.add_child(UiKit.icon(character.portrait, PORTRAIT_SIZE))
	var state: RunState = run.state
	var lines: Array[String] = [
		tr("END_FLOOR") % [state.floor_index + 1, run.config.floors],
		tr("END_BOARDS") % state.boards_won,
		tr("END_MATSURI") % state.matsuri_count,
		tr("END_BEST_SHOT") % state.best_shot,
		tr("END_MON") % state.mon,
		tr("END_SEED") % ("%X" % state.run_seed),
	]
	for line: String in lines:
		var label: Label = UiKit.label(line, 0, UiKit.TEXT, false)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(label)
	var again: Button = UiKit.button("BUTTON_NEW_RUN")
	again.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	again.pressed.connect(new_run_requested.emit)
	body.add_child(again)
