class_name CharacterSelectScreen
extends Control
## The start of a run: one card per character with portrait, power, passive, starting bag and
## completion marks, the Hard switch once it is earned, an optional seed, and the way back into
## a saved run.

## [param hard] is the card's Hard switch; [param seed_text] is what the player typed, if any.
signal character_chosen(character: CharacterDefinition, hard: bool, seed_text: String)
signal continue_requested
signal compendium_requested
signal statistics_requested

const CARD_SIZE: Vector2 = Vector2(184, 262)
const PORTRAIT_SIZE: Vector2 = Vector2(48, 48)
const TEXT_WIDTH: float = 168.0
const BAG_ICON_SIZE: Vector2 = Vector2(12, 12)
const MARK_SIZE: Vector2 = Vector2(12, 12)
const MISSING_MARK: Color = Color(1, 1, 1, 0.2)
const MARK_KEYS: Array[String] = ["MARK_SHUTEN", "MARK_HARD", "MARK_FESTIVAL"]
const SEED_WIDTH: float = 140.0

var _seed: LineEdit
var _hard: Dictionary[StringName, CheckBox] = {}


func open(
	content: RunContent, progression: ProgressionDefinition, profile: Profile, can_continue: bool
) -> void:
	UiKit.clear(self)
	_hard.clear()
	var page: Control = UiKit.page(self)
	var body: VBoxContainer = UiKit.body(page, 12)
	var title: Label = UiKit.label("GAME_TITLE", UiKit.TITLE_SIZE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	var prompt: Label = UiKit.label("CHOOSE_CHARACTER")
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(prompt)
	var cards: HBoxContainer = UiKit.row(12)
	for character: CharacterDefinition in content.characters:
		cards.add_child(_card(character, progression, profile))
	body.add_child(cards)
	var footer: HBoxContainer = UiKit.row(8)
	footer.add_child(UiKit.label("SEED_LABEL", 0, UiKit.MUTED))
	_seed = LineEdit.new()
	_seed.custom_minimum_size = Vector2(SEED_WIDTH, 0)
	_seed.placeholder_text = "SEED_RANDOM"
	footer.add_child(_seed)
	var compendium: Button = UiKit.button("BUTTON_COMPENDIUM")
	compendium.pressed.connect(compendium_requested.emit)
	footer.add_child(compendium)
	var statistics: Button = UiKit.button("BUTTON_STATISTICS")
	statistics.pressed.connect(statistics_requested.emit)
	footer.add_child(statistics)
	if can_continue:
		var resume: Button = UiKit.button("BUTTON_CONTINUE_RUN")
		resume.pressed.connect(continue_requested.emit)
		footer.add_child(resume)
	body.add_child(footer)


func _card(
	character: CharacterDefinition, progression: ProgressionDefinition, profile: Profile
) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(AudioService.play.bind(AudioService.UI_CONFIRM, 1.0))
	card.pressed.connect(_choose.bind(character))
	var content: VBoxContainer = UiKit.column(3)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_top = 6
	content.offset_right = -8
	content.offset_bottom = -6
	card.add_child(content)
	content.add_child(UiKit.icon(character.portrait, PORTRAIT_SIZE))
	var name_label: Label = UiKit.label(character.name_key, 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_label)
	var marks: HBoxContainer = UiKit.row(4)
	for mark: int in Profile.Mark.size():
		var badge: TextureRect = UiKit.icon(progression.mark_icons[mark], MARK_SIZE)
		badge.mouse_filter = Control.MOUSE_FILTER_PASS
		badge.tooltip_text = MARK_KEYS[mark]
		if not profile.has_mark(character.id, mark as Profile.Mark):
			badge.modulate = MISSING_MARK
		marks.add_child(badge)
	content.add_child(marks)
	content.add_child(UiKit.paragraph(tr(character.description_key), TEXT_WIDTH, UiKit.SMALL_SIZE))
	content.add_child(UiKit.label("CHARACTER_POWER_LABEL", 0, UiKit.MON))
	content.add_child(UiKit.paragraph(tr(character.power_key), TEXT_WIDTH, UiKit.SMALL_SIZE))
	content.add_child(UiKit.label("CHARACTER_PASSIVE_LABEL", 0, UiKit.MON))
	content.add_child(UiKit.paragraph(tr(character.passive_key), TEXT_WIDTH, UiKit.SMALL_SIZE))
	var bag: HFlowContainer = HFlowContainer.new()
	bag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for ball: BallDefinition in character.starting_balls:
		bag.add_child(UiKit.icon(ball.texture, BAG_ICON_SIZE))
	content.add_child(bag)
	if profile.hard_unlocked(character.id):
		var hard: CheckBox = CheckBox.new()
		hard.text = "HARD_MODE"
		hard.focus_mode = Control.FOCUS_NONE
		hard.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(hard)
		_hard[character.id] = hard
	return card


func _choose(character: CharacterDefinition) -> void:
	var hard: bool = _hard.has(character.id) and _hard[character.id].button_pressed
	character_chosen.emit(character, hard, _seed.text.strip_edges())
