class_name RunScreen
extends Control
## The game from the choice of a character to the end of a run: owns the [Run] and shows the
## screen of its current phase, swapping screens as the phase changes.

const BALANCE: BalanceConfig = preload("res://data/balance.tres")
const CONTENT: RunContent = preload("res://data/run_content.tres")
const BASE_PEGS: BasePegs = preload("res://data/pegs/base_pegs.tres")
const MAP_SKIN: MapSkin = preload("res://data/skins/map_skin.tres")
const BOARD_SCENE: PackedScene = preload("res://src/presentation/board/board_screen.tscn")

var run: Run
## The screen on show.
var current: Control

var _library: LayoutLibrary


func _ready() -> void:
	_library = LayoutLibrary.load_from()
	show_character_select()


func show_character_select() -> void:
	run = null
	var screen: CharacterSelectScreen = CharacterSelectScreen.new()
	_swap(screen)
	screen.open(CONTENT)
	screen.character_chosen.connect(_on_character_chosen)


func start_run(character: CharacterDefinition, seed_value: int) -> void:
	run = Run.start(BALANCE, CONTENT, _library, character, seed_value)
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
	_swap(board)
	var spec: BoardSpec = run.board
	var inventory: Inventory = run.state.inventory
	board.play(
		spec.create(BALANCE, BASE_PEGS, inventory, run.state.carry),
		spec.board_seed,
		inventory.loadout,
		inventory.slots,
		spec.rules.boss
	)
	board.board_finished.connect(_on_board_finished)


func _swap(screen: Control) -> void:
	if current != null:
		remove_child(current)
		current.queue_free()
	current = screen
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)


func _on_character_chosen(character: CharacterDefinition) -> void:
	start_run(character, _new_seed())


func _on_node_chosen(node: int) -> void:
	if run.choose_node(node):
		show_phase()


func _on_board_finished(result: BoardResult) -> void:
	run.finish_board(result)
	show_phase()


## A fresh run seed from the clock; game randomness itself always comes from PCG32.
static func _new_seed() -> int:
	return int(Time.get_unix_time_from_system() * 1000.0) ^ Time.get_ticks_usec()
