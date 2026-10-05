class_name BoardSounds
extends RefCounted
## Turns board events into sounds. The lanterns of a shot climb in pitch, one semitone per
## lantern; several lanterns lit in one tick sound once, at the pitch of the last.

## Highest climb of the lantern sound, in semitones.
const MAX_SEMITONES: int = 18

## Plays the boss's drum when a shot is scored on a boss board.
var boss: bool = false

var _sounded_hits: int = 0


## Pitch of the lantern sound for the [param hits]-th lantern of a shot.
static func pitch_for(hits: int) -> float:
	return pow(2.0, mini(maxi(hits - 1, 0), MAX_SEMITONES) / 12.0)


func hear(event: SimEvent) -> void:
	match event.kind:
		SimEvent.Kind.BALL_DRAWN:
			_sounded_hits = 0
			AudioService.play(AudioService.LAUNCH)
		SimEvent.Kind.WALL_BOUNCE:
			AudioService.play(AudioService.WALL_BOUNCE)
		SimEvent.Kind.BUCKET_CATCH:
			AudioService.play(AudioService.BUCKET)
		SimEvent.Kind.BALL_LOST:
			AudioService.play(AudioService.BALL_LOST)
		SimEvent.Kind.MON_GAINED:
			AudioService.play(AudioService.MON)
		SimEvent.Kind.SCORE_MULT_ADD:
			if event.amount > 0:
				AudioService.play(AudioService.MULT)
		SimEvent.Kind.SCORE_MULT_TIMES:
			AudioService.play(AudioService.TIMES)
		SimEvent.Kind.AREA_HIT:
			AudioService.play(AudioService.EXPLOSION)
		SimEvent.Kind.PEG_BURNING:
			AudioService.play(AudioService.FIRE)
		SimEvent.Kind.BALL_SPLIT:
			AudioService.play(AudioService.SPLIT)
		SimEvent.Kind.PEG_VANISHED:
			AudioService.play(AudioService.VANISH)
		SimEvent.Kind.EFFECT_TRIGGERED:
			if event.target == Effect.CHARACTER_SLOT:
				AudioService.play(AudioService.POWER)
		SimEvent.Kind.LAYOUT_CHANGED:
			AudioService.play(AudioService.BOSS_HIT)
		SimEvent.Kind.SHOT_SCORED:
			AudioService.play(AudioService.SHOT_SCORED)
			if boss:
				AudioService.play(AudioService.BOSS_HIT)
		SimEvent.Kind.BOARD_ENDED:
			match event.amount:
				BoardGame.Outcome.MATSURI:
					AudioService.play(AudioService.MATSURI)
				BoardGame.Outcome.TARGET_REACHED:
					AudioService.play(AudioService.BOARD_WON)
				_:
					AudioService.play(AudioService.BOARD_LOST)


## Sounds the lanterns lit since the last call.
func after_events(game: BoardGame) -> void:
	if game.shot_pegs_hit > _sounded_hits:
		_sounded_hits = game.shot_pegs_hit
		AudioService.play(AudioService.PEG_HIT, pitch_for(_sounded_hits))
