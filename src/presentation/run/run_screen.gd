class_name RunScreen
extends Control
## The game from the choice of a character to the end of a run: owns the [Run] and shows the
## screen of its current phase, swapping screens as the phase changes. The run is saved after
## every action and resumed from the character screen; the profile learns of feats after every
## board and of marks and statistics when the run ends.

const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const CONTENT: RunContent = preload("res://data/run_content.tres")
const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const MAP_SKIN: MapSkin = preload("res://data/skins/map_skin.tres")
const PROGRESSION: ProgressionDefinition = preload("res://data/progression.tres")
const BOARD_SCENE: PackedScene = preload("res://src/presentation/board/board_screen.tscn")

var run: Run
var profile: Profile
## The screen on show.
var current: Control

var _library: LayoutLibrary


func _ready() -> void:
	_library = LayoutLibrary.load_from()
	profile = SaveService.load_profile()
	show_character_select()


func show_character_select() -> void:
	run = null
	var screen: CharacterSelectScreen = CharacterSelectScreen.new()
	_swap(screen)
	screen.open(CONTENT, PROGRESSION, profile, SaveService.has_run())
	screen.character_chosen.connect(_on_character_chosen)
	screen.continue_requested.connect(continue_run)


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
		show_character_select()
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
	if current != null:
		remove_child(current)
		current.queue_free()
	current = screen
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)


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
	Progression.check_board(PROGRESSION, profile, run)
	if run.is_over():
		Progression.finish_run(PROGRESSION, profile, run)
		SaveService.clear_run()
	SaveService.save_profile(profile)
	show_phase()


## A fresh run seed from the clock; game randomness itself always comes from PCG32.
static func _new_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
