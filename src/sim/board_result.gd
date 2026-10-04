@tool
class_name BoardResult
## How a board ended, for the run's economy to settle and for feats to check.

var outcome: BoardGame.Outcome = BoardGame.Outcome.PLAYING
var total: int = 0
var shots_left: int = 0
## Mon paid by items during the board.
var mon_earned: int = 0
## Largest interest the run may pay for this board, in mon.
var interest_cap: int = 0
## Records of the board; see the matching fields of [BoardGame].
var best_shot: int = 0
var best_shot_pegs: int = 0
var best_shot_reds: int = 0
## In permille.
var best_shot_mult: int = 0
var bucket_catches: int = 0
var shots_fired: int = 0
var special_balls_fired: int = 0


func won() -> bool:
	return outcome == BoardGame.Outcome.TARGET_REACHED or outcome == BoardGame.Outcome.MATSURI


## Won with the board's last shot.
func won_on_last_shot() -> bool:
	return won() and shots_left == 0
