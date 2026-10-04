class_name Payout
## The mon a won board pays, item by item, so the reward screen can show where they came from.

## Paid by coin pegs and items during the board.
var items: int = 0
var win: int = 0
var unused_shots: int = 0
var matsuri: int = 0
var interest: int = 0
## Paid back by a wager settled on this board.
var wager: int = 0


## GDD economy: a win pays by board kind, every unused shot pays, a Matsuri pays a bonus, and
## interest is paid on the mon held when the board ends, before the win is paid, up to the cap.
static func settle(
	config: BalanceConfig, result: BoardResult, kind: MapNode.Kind, mon_held: int
) -> Payout:
	var payout: Payout = Payout.new()
	payout.items = result.mon_earned
	if result.outcome == BoardGame.Outcome.FAILED:
		return payout
	var tier: int = 2 if kind == MapNode.Kind.BOSS else (1 if kind == MapNode.Kind.ELITE else 0)
	payout.win = config.win_mon[tier]
	payout.unused_shots = result.shots_left * config.unused_shot_mon
	if result.outcome == BoardGame.Outcome.MATSURI:
		payout.matsuri = config.matsuri_mon
	var held: int = mon_held + payout.items
	payout.interest = mini(result.interest_cap, held / maxi(1, config.interest_step))
	return payout


func total() -> int:
	return items + win + unused_shots + matsuri + interest + wager
