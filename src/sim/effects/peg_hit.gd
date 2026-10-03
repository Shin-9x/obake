@tool
class_name PegHit
## A peg being hit, as effects see it. One instance is reused for every hit.
##
## Effects adjust the fields, then [BoardGame] scores (points + bonus_points) x points_factor,
## adds mult_add, applies mult_factor and pays mon. Additions therefore always come before
## multiplications, whatever order the effects run in.

enum Source { BALL, AREA, FIRE }

var peg: int = -1
## Ball that touched the peg, or -1 for explosions and fire.
var ball: int = -1
var source: Source = Source.BALL
var role: BoardGame.Role = BoardGame.Role.BLUE
var definition: PegDefinition
## First peg scored in the current shot.
var first_of_shot: bool = false
var points: int = 0
var bonus_points: int = 0
## Permille.
var points_factor: int = FixedMath.PERMILLE
## Permille.
var mult_add: int = 0
## Permille.
var mult_factor: int = FixedMath.PERMILLE
var mon: int = 0
