class_name ItemCard
extends Button
## A clickable card for an item: icon, name in its rarity colour, description, and a footer such
## as a price or a level.

const CARD_SIZE: Vector2 = Vector2(112, 118)
const ICON_SIZE: Vector2 = Vector2(32, 32)
const TEXT_WIDTH: float = 100.0
## Tint of a card that cannot be picked.
const UNAVAILABLE: Color = Color(1, 1, 1, 0.45)

var item: ItemDefinition


## Shows [param definition]; [param footer] is plain text, already translated.
func show_item(definition: ItemDefinition, footer: String = "") -> void:
	item = definition
	custom_minimum_size = CARD_SIZE
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	tooltip_text = tr(definition.description_key)
	UiKit.clear(self)
	var content: VBoxContainer = UiKit.column(2)
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 6
	content.offset_top = 6
	content.offset_right = -6
	content.offset_bottom = -6
	add_child(content)
	content.add_child(UiKit.icon(_texture(definition), ICON_SIZE))
	var title: Label = UiKit.label(
		tr(definition.name_key), 0, UiKit.RARITY_COLOURS.get(definition.rarity, UiKit.TEXT), false
	)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var description: Label = UiKit.paragraph(
		tr(definition.description_key), TEXT_WIDTH, UiKit.SMALL_SIZE
	)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(description)
	if not footer.is_empty():
		var price: Label = UiKit.label(footer, 0, UiKit.MON, false)
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(price)


## Greys the card out when it cannot be picked.
func set_available(available: bool) -> void:
	disabled = not available
	modulate = Color.WHITE if available else UNAVAILABLE


static func _texture(definition: ItemDefinition) -> Texture2D:
	if definition is BallDefinition and (definition as BallDefinition).texture != null:
		return (definition as BallDefinition).texture
	if definition is PegDefinition and (definition as PegDefinition).texture != null:
		return (definition as PegDefinition).texture
	return definition.icon
