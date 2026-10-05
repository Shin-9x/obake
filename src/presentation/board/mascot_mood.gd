class_name MascotMood
## How Obo feels about the board: pleased by a big shot or a win, sad after a shot that scored
## nothing, worried when the last shots run out short of the target, excited by a power.

enum Mood { IDLE, HAPPY, WORRIED, SAD, EXCITED }

## A shot worth this share of the target, in permille, counts as a big one.
const BIG_SHOT: int = 250
## Shots left at which a board short of its target starts to worry Obo.
const WORRY_SHOTS: int = 2


static func after_shot(game: BoardGame, score: int) -> Mood:
	if (
		game.outcome == BoardGame.Outcome.MATSURI
		or game.outcome == BoardGame.Outcome.TARGET_REACHED
	):
		return Mood.HAPPY
	if score == 0:
		return Mood.SAD
	if score * FixedMath.PERMILLE >= game.target * BIG_SHOT:
		return Mood.HAPPY
	if game.shots_left <= WORRY_SHOTS and game.total < game.target:
		return Mood.WORRIED
	return Mood.IDLE
