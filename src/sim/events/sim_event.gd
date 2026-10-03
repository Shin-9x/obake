class_name SimEvent
## One event emitted by the simulation for presentation and run logic to consume.
##
## Instances are pooled by [SimEventQueue] and overwritten after [method SimEventQueue.clear],
## so consumers must copy what they need instead of keeping references.

enum Kind { PEG_HIT, WALL_BOUNCE, BALL_LOST, SHOT_RESOLVED }

var kind: Kind = Kind.PEG_HIT
var tick: int = 0
## Index of the ball involved, or -1.
var ball: int = -1
## Index of the peg or wall involved, or -1.
var target: int = -1
## Ball position in milli-pixels when the event happened.
var x: int = 0
var y: int = 0
