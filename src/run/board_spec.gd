class_name BoardSpec
## The board a map node leads to: its layout, seed and rules, decided when the node is entered.

var kind: MapNode.Kind = MapNode.Kind.BOARD
var layout: BoardLayout
## Second form of a boss layout, such as Nue's; null when there is none.
var next_layer: BoardLayout
var board_seed: int = 0
var rules: BoardRules


## The playable board, with the run's inventory and carried modifiers.
func create(
	config: BalanceConfig, base_pegs: BasePegs, inventory: Inventory, carry: RunCarry
) -> PlacedBoard:
	return BoardSetup.create_board(
		config, base_pegs, layout, board_seed, inventory.loadout, carry, rules, next_layer
	)
