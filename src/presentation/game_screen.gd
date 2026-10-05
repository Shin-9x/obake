class_name GameScreen
extends Control
## The whole game in one place: the title and its menus, then a run from the choice of a
## character to its end. Holds the [Run] and shows the screen of its current phase, swapping
## screens as the phase changes. The run is saved after every action and resumed from the title;
## the profile learns of feats after every board and of marks and statistics when the run ends.
##
## A run pauses with the pause action or button: the run's screen stops, the pause menu and the
## settings keep working.

const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const CONTENT: RunContent = preload("res://data/run_content.tres")
const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const MAP_SKIN: MapSkin = preload("res://data/skins/map_skin.tres")
const PROGRESSION: ProgressionDefinition = preload("res://data/progression.tres")
const UI_SKIN: UiSkin = preload("res://data/skins/ui_skin.tres")
const MARK_KEYS: Array[String] = ["MARK_SHUTEN", "MARK_HARD", "MARK_FESTIVAL"]
const BOARD_SCENE: PackedScene = preload("res://src/presentation/board/board_screen.tscn")
const PAUSE_BUTTON_SIZE: Vector2 = Vector2(20, 18)
const PAUSE_MARGIN: float = 4.0

var run: Run
var profile: Profile
## The screen on show.
var current: Control
## Unlock notes, drawn over every screen.
var toasts: UnlockToasts
## Shown over a paused run; null while the run is playing.
var pause_menu: PauseMenu

var _library: LayoutLibrary
var _navigator: FocusNavigator = FocusNavigator.new()
var _pause_button: Button
## Settings opened over the pause menu.
var _overlay_settings: SettingsScreen


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_library = LayoutLibrary.load_from()
	profile = SaveService.load_profile()
	add_child(_navigator)
	toasts = UnlockToasts.new()
	toasts.skin = UI_SKIN
	add_child(toasts)
	_pause_button = UiKit.button("")
	_pause_button.icon = UI_SKIN.pause_icon
	_pause_button.custom_minimum_size = PAUSE_BUTTON_SIZE
	_pause_button.anchor_left = 1.0
	_pause_button.anchor_right = 1.0
	_pause_button.offset_left = -PAUSE_BUTTON_SIZE.x - PAUSE_MARGIN
	_pause_button.offset_right = -PAUSE_MARGIN
	_pause_button.offset_top = PAUSE_MARGIN
	_pause_button.offset_bottom = PAUSE_MARGIN + PAUSE_BUTTON_SIZE.y
	_pause_button.pressed.connect(pause)
	add_child(_pause_button)
	show_title()


func show_title() -> void:
	run = null
	var screen: TitleScreen = TitleScreen.new()
	_swap(screen)
	screen.open(UI_SKIN, SaveService.has_run())
	screen.continue_requested.connect(continue_run)
	screen.new_run_requested.connect(show_character_select)
	screen.compendium_requested.connect(show_compendium)
	screen.statistics_requested.connect(show_statistics)
	screen.settings_requested.connect(show_settings)
	screen.quit_requested.connect(get_tree().quit)


func show_character_select() -> void:
	run = null
	var screen: CharacterSelectScreen = CharacterSelectScreen.new()
	_swap(screen)
	screen.open(CONTENT, PROGRESSION, profile)
	screen.character_chosen.connect(_on_character_chosen)
	screen.back_requested.connect(show_title)


func show_compendium() -> void:
	var screen: CompendiumScreen = CompendiumScreen.new()
	_swap(screen)
	screen.open(CONTENT, PROGRESSION, profile)
	screen.closed.connect(show_title)


func show_statistics() -> void:
	var screen: StatisticsScreen = StatisticsScreen.new()
	_swap(screen)
	screen.open(CONTENT, PROGRESSION, profile)
	screen.closed.connect(show_title)


func show_settings() -> void:
	var screen: SettingsScreen = SettingsScreen.new()
	_swap(screen)
	screen.open()
	screen.closed.connect(show_title)


## Starts a run with the items the profile has unlocked. A [param custom_seed] run earns no
## feat and no mark.
func start_run(
	character: CharacterDefinition, seed_value: int, hard: bool = false, custom_seed: bool = false
) -> void:
	var options: RunOptions = RunOptions.new()
	options.pool = Progression.pool(CONTENT, PROGRESSION, profile)
	options.hard = hard and profile.hard_unlocked(character.id)
	options.custom_seed = custom_seed
	run = Run.start(BALANCE, CONTENT, _library, BASE_PEGS, character, seed_value, options)
	_watch(run)
	show_phase()


## Picks up the saved run where it was left; a save that cannot be read is dropped.
func continue_run() -> void:
	run = Run.resume(SaveService.load_run(), BALANCE, CONTENT, _library, BASE_PEGS)
	if run == null:
		SaveService.clear_run()
		show_title()
		return
	_watch(run)
	show_phase()


## Shows the screen of the run's current phase.
func show_phase() -> void:
	match run.phase:
		Run.Phase.MAP:
			var map: MapScreen = MapScreen.new()
			_swap(map)
			map.open(run, MAP_SKIN)
			map.node_chosen.connect(_on_node_chosen)
		Run.Phase.BOARD:
			_show_board()
		Run.Phase.REWARD:
			var reward: RewardScreen = RewardScreen.new()
			_swap(reward)
			reward.advanced.connect(show_phase)
			reward.open(run)
		Run.Phase.SHOP:
			var shop: ShopScreen = ShopScreen.new()
			_swap(shop)
			shop.advanced.connect(show_phase)
			shop.open(run)
		Run.Phase.SHRINE:
			var shrine: ShrineScreen = ShrineScreen.new()
			_swap(shrine)
			shrine.advanced.connect(show_phase)
			shrine.open(run)
		Run.Phase.EVENT:
			var event: EventScreen = EventScreen.new()
			_swap(event)
			event.advanced.connect(show_phase)
			event.open(run)
		_:
			var ending: RunEndScreen = RunEndScreen.new()
			_swap(ending)
			ending.open(run)
			ending.new_run_requested.connect(show_character_select)


func can_pause() -> bool:
	return run != null and not run.is_over() and pause_menu == null


## Stops the run where it stands and opens the pause menu.
func pause() -> void:
	if not can_pause():
		return
	get_tree().paused = true
	pause_menu = PauseMenu.new()
	add_child(pause_menu)
	pause_menu.open()
	pause_menu.resumed.connect(resume)
	pause_menu.settings_requested.connect(_open_pause_settings)
	pause_menu.abandon_confirmed.connect(_abandon)
	pause_menu.quit_requested.connect(_quit_to_title)
	_refresh_overlays()
	_navigator.focus(pause_menu)


func resume() -> void:
	if pause_menu == null:
		return
	pause_menu.queue_free()
	pause_menu = null
	get_tree().paused = false
	_refresh_overlays()
	_navigator.focus(current)


## The pause action pauses and resumes a run; the cancel action closes the settings over the pause
## menu, resumes, or goes back from a menu screen that has a way back.
func _unhandled_input(event: InputEvent) -> void:
	var pausing: bool = event.is_action_pressed("pause") and (can_pause() or pause_menu != null)
	if not pausing and not event.is_action_pressed("ui_cancel"):
		return
	if _overlay_settings != null:
		_close_pause_settings()
	elif pause_menu != null:
		resume()
	elif pausing:
		pause()
	elif current != null and current.has_method("back"):
		current.call("back")
	else:
		return
	get_viewport().set_input_as_handled()


func _open_pause_settings() -> void:
	_overlay_settings = SettingsScreen.new()
	_overlay_settings.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_settings)
	_overlay_settings.open()
	_overlay_settings.closed.connect(_close_pause_settings)
	_navigator.focus(_overlay_settings)


func _close_pause_settings() -> void:
	if _overlay_settings != null:
		_overlay_settings.queue_free()
		_overlay_settings = null
		_navigator.focus(pause_menu)


## Gives the run up: it ends as a loss and the end screen shows.
func _abandon() -> void:
	resume()
	if not run.abandon():
		return
	Progression.finish_run(PROGRESSION, profile, run)
	SaveService.clear_run()
	SaveService.save_profile(profile)
	show_phase()


## Leaves the run for the title; its save stays for later.
func _quit_to_title() -> void:
	resume()
	show_title()


func _show_board() -> void:
	var board: BoardScreen = BOARD_SCENE.instantiate() as BoardScreen
	board.standalone = false
	board.shooter = run.shoot
	_swap(board)
	var spec: BoardSpec = run.board
	var inventory: Inventory = run.state.inventory
	board.play(run.placed, spec.board_seed, inventory.loadout, inventory.slots, spec.rules.boss)
	board.board_finished.connect(_on_board_finished)


func _swap(screen: Control) -> void:
	if not screen is BoardScreen:
		AudioService.play_music(AudioService.Music.MENU)
	if current != null:
		remove_child(current)
		current.queue_free()
	current = screen
	screen.process_mode = Node.PROCESS_MODE_PAUSABLE
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	_refresh_overlays()
	_navigator.focus(screen)


## Keeps the pause button, the toasts and the pause menu above the screen, and the pause button
## only while a run can pause.
func _refresh_overlays() -> void:
	_pause_button.visible = can_pause()
	move_child(_pause_button, -1)
	move_child(toasts, -1)
	if pause_menu != null:
		move_child(pause_menu, -1)


func _watch(watched: Run) -> void:
	watched.action_recorded.connect(_save_run)
	_save_run()


func _save_run() -> void:
	SaveService.save_run(run.to_save())


func _on_character_chosen(character: CharacterDefinition, hard: bool, seed_text: String) -> void:
	if seed_text.is_empty():
		start_run(character, _new_seed(), hard)
	else:
		start_run(character, seed_text.hex_to_int(), hard, true)


func _on_node_chosen(node: int) -> void:
	if run.choose_node(node):
		show_phase()


func _on_board_finished(_result: BoardResult) -> void:
	if not run.finish_board():
		return
	for feat: FeatDefinition in Progression.check_board(PROGRESSION, profile, run):
		toasts.announce(tr("TOAST_UNLOCKED") % tr(feat.unlocks.name_key), tr(feat.description_key))
	if run.is_over():
		var character: CharacterDefinition = run.state.inventory.loadout.character
		for mark: Profile.Mark in Progression.finish_run(PROGRESSION, profile, run):
			toasts.announce(tr("TOAST_MARK") % tr(character.name_key), tr(MARK_KEYS[mark]))
		SaveService.clear_run()
	SaveService.save_profile(profile)
	show_phase()


## A fresh run seed from the clock; game randomness itself always comes from PCG32.
static func _new_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
