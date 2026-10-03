@tool
class_name BagBall
## One ball in the bag, with its effect instance for the current board.

var definition: BallDefinition
var level: int = 1
## Null for balls without an effect, such as the Hitodama.
var effect: Effect


func _init(ball: BallDefinition, ball_level: int) -> void:
	definition = ball
	level = ball_level
	effect = Effect.create(ball, ball_level, Effect.BALL_SLOT)
