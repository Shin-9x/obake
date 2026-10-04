class_name CharacterSelectScreen
extends Control
## The start of a run: one card per character with portrait, power, passive and starting bag.

signal character_chosen(character: CharacterDefinition)

const CARD_SIZE: Vector2 = Vector2(184, 250)
const PORTRAIT_SIZE: Vector2 = Vector2(64, 64)
const TEXT_WIDTH: float = 168.0
const BAG_ICON_SIZE: Vector2 = Vector2(12, 12)


func open(content: RunContent) -> void:
	UiKit.clear(self)
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
		cards.add_child(_card(character))
	body.add_child(cards)


func _card(character: CharacterDefinition) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.focus_mode = Control.FOCUS_NONE
	card.pressed.connect(character_chosen.emit.bind(character))
	var content: VBoxContainer = UiKit.column(4)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 8
	content.offset_top = 8
	content.offset_right = -8
	content.offset_bottom = -8
	card.add_child(content)
	content.add_child(UiKit.icon(character.portrait, PORTRAIT_SIZE))
	var name_label: Label = UiKit.label(character.name_key, 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(name_label)
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
	return card
