@tool
class_name BoardResult
## How a board ended, for the run's economy to settle.

var outcome: BoardGame.Outcome = BoardGame.Outcome.PLAYING
var total: int = 0
var shots_left: int = 0
var best_shot: int = 0
## Mon paid by items during the board.
var mon_earned: int = 0
## Largest interest the run may pay for this board, in mon.
var interest_cap: int = 0
