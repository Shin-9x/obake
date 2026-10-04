class_name RunBar
extends HBoxContainer
## The strip across the top of the run screens: floor, mon, bag size and omamori.

const SLOT_SIZE: Vector2 = Vector2(18, 18)


func show_run(run: Run) -> void:
	UiKit.clear(self)
	add_theme_constant_override("separation", 12)
	var state: RunState = run.state
	var floor_text: String = tr("RUN_FLOOR") % [state.floor_index + 1, run.config.floors]
	var biome: String = "BIOME_" + run.content.floor_biomes[state.floor_index].to_upper()
	add_child(UiKit.label("%s · %s" % [floor_text, tr(biome)], 0, UiKit.TEXT, false))
	add_child(UiKit.label(tr("RUN_MON") % state.mon, 0, UiKit.MON, false))
	add_child(UiKit.label(tr("RUN_BAG") % state.inventory.ball_count(), 0, UiKit.TEXT, false))
	var slots: HBoxContainer = UiKit.row(2)
	for slot: int in state.inventory.slots:
		var frame: ColorRect = ColorRect.new()
		frame.color = UiKit.PANEL
		frame.custom_minimum_size = SLOT_SIZE
		if slot < state.inventory.omamori_count():
			var charm: OmamoriDefinition = state.inventory.loadout.omamori[slot]
			var picture: TextureRect = UiKit.icon(charm.icon, SLOT_SIZE)
			frame.add_child(picture)
			frame.tooltip_text = "%s\n%s" % [tr(charm.name_key), tr(charm.description_key)]
		slots.add_child(frame)
	add_child(slots)
