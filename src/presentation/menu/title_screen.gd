class_name TitleScreen
extends Control
## The first screen: the title with Obo, and the way into everything else.

signal continue_requested
signal new_run_requested
signal compendium_requested
signal statistics_requested
signal settings_requested
signal quit_requested

const MASCOT_SIZE: Vector2 = Vector2(72, 72)
const BUTTON_WIDTH: float = 180.0
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
	var entries: Array[Array] = []
	if can_continue:
		entries.append(["BUTTON_CONTINUE_RUN", continue_requested])
	(
		entries
		. append_array(
			[
				["BUTTON_NEW_RUN", new_run_requested],
				["BUTTON_COMPENDIUM", compendium_requested],
				["BUTTON_STATISTICS", statistics_requested],
				["BUTTON_SETTINGS", settings_requested],
			]
		)
	)
	if OS.has_feature("pc"):
		entries.append(["BUTTON_QUIT", quit_requested])
	for entry: Array in entries:
		var button: Button = UiKit.button(entry[0])
		button.custom_minimum_size = Vector2(BUTTON_WIDTH, 0)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect((entry[1] as Signal).emit)
		body.add_child(button)
