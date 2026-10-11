class_name TitleScreen
extends Control
## The first screen: the title with Obo, and the way into everything else.

signal continue_requested
signal new_run_requested
signal compendium_requested
signal statistics_requested
signal how_to_requested
signal settings_requested
signal quit_requested

const MASCOT_SIZE: Vector2 = Vector2(72, 72)
const BUTTON_WIDTH: float = 180.0
const BUTTON_GAP: int = 4
const TITLE_SIZE: int = 36
const VERSION_MARGIN: int = 4

## The game version in a corner of the page.
var version_label: Label


## [param can_continue] offers to resume the saved run.
func open(skin: UiSkin, can_continue: bool) -> void:
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	version_label = UiKit.label("v" + BuildInfo.version(), UiKit.SMALL_SIZE, UiKit.MUTED, false)
	page.add_child(version_label)
	version_label.set_anchors_and_offsets_preset(
		Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, VERSION_MARGIN
	)
	var body: VBoxContainer = UiKit.body(page, 24)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	var title: Label = UiKit.label("GAME_TITLE", TITLE_SIZE, UiKit.MON)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(title)
	body.add_child(UiKit.icon(skin.mascot, MASCOT_SIZE))
	if can_continue:
		body.add_child(_button("BUTTON_CONTINUE_RUN", continue_requested, BUTTON_WIDTH))
	body.add_child(_button("BUTTON_NEW_RUN", new_run_requested, BUTTON_WIDTH))
	# The lesser entries share two columns, so the menu fits with a saved run and a Quit button.
	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", BUTTON_GAP)
	grid.add_theme_constant_override("v_separation", BUTTON_GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var half: float = (BUTTON_WIDTH - BUTTON_GAP) / 2.0
	grid.add_child(_button("BUTTON_COMPENDIUM", compendium_requested, half))
	grid.add_child(_button("BUTTON_STATISTICS", statistics_requested, half))
	grid.add_child(_button("BUTTON_HOW_TO", how_to_requested, half))
	grid.add_child(_button("BUTTON_SETTINGS", settings_requested, half))
	body.add_child(grid)
	if OS.has_feature("pc"):
		body.add_child(_button("BUTTON_QUIT", quit_requested, BUTTON_WIDTH))


func _button(key: String, pressed: Signal, width: float) -> Button:
	var button: Button = UiKit.button(key)
	button.custom_minimum_size = Vector2(width, 0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(pressed.emit)
	return button
