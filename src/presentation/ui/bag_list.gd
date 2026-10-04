class_name BagList
extends HFlowContainer
## The balls of the bag as small buttons with their level. In picking mode only the allowed
## balls can be pressed.

signal ball_picked(index: int)

const BUTTON_SIZE: Vector2 = Vector2(30, 30)


## Lists [param inventory]'s balls; [param allowed] are the indices that can be picked, or
## null for a list that only shows.
func show_bag(inventory: Inventory, allowed: Variant = null) -> void:
	UiKit.clear(self)
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)
	for index: int in inventory.ball_count():
		var ball: BallDefinition = inventory.ball(index)
		var entry: Button = Button.new()
		entry.custom_minimum_size = BUTTON_SIZE
		entry.icon = ball.texture
		entry.expand_icon = false
		entry.focus_mode = Control.FOCUS_NONE
		entry.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		entry.text = (
			UiKit.level_text(inventory.level_of(index)) if ball.level_values.size() > 1 else ""
		)
		entry.add_theme_font_size_override("font_size", UiKit.SMALL_SIZE)
		entry.tooltip_text = "%s\n%s" % [tr(ball.name_key), tr(ball.description_key)]
		if allowed == null:
			entry.disabled = true
		else:
			entry.disabled = not (allowed as PackedInt32Array).has(index)
			entry.pressed.connect(ball_picked.emit.bind(index))
		add_child(entry)
