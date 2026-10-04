@tool
class_name SimEvent
## One event emitted by the simulation for presentation and run logic to consume.
##
## Instances are pooled by [SimEventQueue] and overwritten after [method SimEventQueue.clear],
## so consumers must copy what they need instead of keeping references.

## New kinds go at the end so recorded event logs keep their meaning.
enum Kind {
	PEG_HIT,
	WALL_BOUNCE,
	BALL_LOST,
	## Every ball has left play; [code]tick[/code] is the last tick of the shot.
	SHOT_RESOLVED,
	BUCKET_CATCH,
	## The stuck-ball rule removed the lit pegs early.
	STUCK_CLEARED,
	SCORE_POINTS,
	## [code]amount[/code] is the mult added, in permille.
	SCORE_MULT_ADD,
	## [code]amount[/code] is the mult factor, in permille.
	SCORE_MULT_TIMES,
	## [code]amount[/code] is the score of the whole shot.
	SHOT_SCORED,
	## [code]amount[/code] is the [enum BoardGame.Outcome].
	BOARD_ENDED,
	## [code]amount[/code] is the mon paid.
	MON_GAINED,
	## An explosion; [code]amount[/code] is its radius in milli-pixels.
	AREA_HIT,
	## [code]target[/code] has caught fire and will be hit shortly.
	PEG_BURNING,
	## [code]ball[/code] is a new ball split from the shot's ball.
	BALL_SPLIT,
	FLOOR_BOUNCE,
	## A ball was drawn from the bag for the shot.
	BALL_DRAWN,
	## [code]target[/code] is the slot of the effect that acted: an omamori slot, or one of the
	## negative slot constants of [Effect].
	EFFECT_TRIGGERED,
	## [code]amount[/code] is the factor applied to the shot's points, in permille.
	SCORE_POINTS_TIMES,
	## [code]target[/code] has become another kind of peg.
	PEG_TRANSFORMED,
	## [code]target[/code] was an illusion and is gone, without scoring.
	PEG_VANISHED,
	## Another layer of the layout is now in play; [code]amount[/code] is the layer.
	LAYOUT_CHANGED,
}

var kind: Kind = Kind.PEG_HIT
var tick: int = 0
## Index of the ball involved, or -1.
var ball: int = -1
## Index of the peg or wall involved, or -1.
var target: int = -1
## Position in milli-pixels: the ball for physics events, the peg for scoring events.
var x: int = 0
var y: int = 0
## Value carried by scoring and outcome events.
var amount: int = 0
