class_name FeatDefinition
extends Resource
## A feat: something done in a run that unlocks an item for the runs after it.

## What the feat asks for; [member threshold] gives the number where one is needed.
enum Condition {
	## Pegs hit in a single shot.
	PEGS_IN_SHOT,
	## Balls caught by the bucket on one board.
	BUCKETS_IN_BOARD,
	## A board won with its first and only shot.
	ONE_SHOT_WIN,
	## A boss beaten without firing a special ball.
	BOSS_WITHOUT_SPECIALS,
	## Red lanterns hit in a single shot.
	REDS_IN_SHOT,
	## A board won with its last shot.
	LAST_SHOT_WIN,
	## Points scored by a single shot.
	POINTS_IN_SHOT,
	## Mult reached in a single shot, in permille.
	MULT_IN_SHOT,
	## A board won by Matsuri.
	MATSURI,
	## Matsuri in one run.
	MATSURI_IN_RUN,
	## Pegs bought in one run.
	PEGS_BOUGHT_IN_RUN,
	## [member boss] beaten.
	BOSS_DEFEATED,
}

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
@export var condition: Condition = Condition.PEGS_IN_SHOT
@export var threshold: int = 0
@export var boss: BossDefinition
@export var unlocks: ItemDefinition
