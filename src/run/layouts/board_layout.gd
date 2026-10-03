@tool
class_name BoardLayout
## A hand-authored board: where its pegs are and how its moving groups move. Peg positions are
## never randomised; colours, mirroring and group phases vary with the board seed.

var id: String = ""
## Biome the layout belongs to, such as "bamboo_forest".
var biome: String = ""
## Whether a seed may flip the layout horizontally.
var mirrorable: bool = true
var pegs: Array[LayoutPeg] = []
var groups: Array[LayoutGroup] = []


func peg_count() -> int:
	var count: int = pegs.size()
	for group: LayoutGroup in groups:
		count += group.pegs.size()
	return count
