extends Node
## Plays sound effects from a pool of voices made once at start, and crossfades between the two
## music loops. A sound played again within [constant COOLDOWN] of itself is skipped, so a burst
## of hits stays a burst of notes rather than noise.

enum Music { NONE, MENU, BOARD }

const BANK: SoundBank = preload("res://data/audio/sound_bank.tres")
const VOICES: int = 16
const COOLDOWN_MSEC: int = 30
const MUSIC_FADE: float = 0.6
const SILENT_DB: float = -60.0
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

const PEG_HIT: StringName = &"peg_hit"
const WALL_BOUNCE: StringName = &"wall_bounce"
const BUCKET: StringName = &"bucket"
const BALL_LOST: StringName = &"ball_lost"
const MON: StringName = &"mon"
const MULT: StringName = &"mult"
const TIMES: StringName = &"times"
const EXPLOSION: StringName = &"explosion"
const FIRE: StringName = &"fire"
const SPLIT: StringName = &"split"
const LAUNCH: StringName = &"launch"
const SHOT_SCORED: StringName = &"shot_scored"
const BOARD_WON: StringName = &"board_won"
const MATSURI: StringName = &"matsuri"
const BOARD_LOST: StringName = &"board_lost"
const POWER: StringName = &"power"
const BOSS_HIT: StringName = &"boss_hit"
const VANISH: StringName = &"vanish"
const UI_CLICK: StringName = &"ui_click"
const UI_CONFIRM: StringName = &"ui_confirm"
const UI_BACK: StringName = &"ui_back"
const PURCHASE: StringName = &"purchase"
const UNLOCK: StringName = &"unlock"
## Every cue the game plays; the bank must hold them all.
const CUES: Array[StringName] = [
	PEG_HIT,
	WALL_BOUNCE,
	BUCKET,
	BALL_LOST,
	MON,
	MULT,
	TIMES,
	EXPLOSION,
	FIRE,
	SPLIT,
	LAUNCH,
	SHOT_SCORED,
	BOARD_WON,
	MATSURI,
	BOARD_LOST,
	POWER,
	BOSS_HIT,
	VANISH,
	UI_CLICK,
	UI_CONFIRM,
	UI_BACK,
	PURCHASE,
	UNLOCK,
]

var music: Music = Music.NONE

var _voices: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last_played: Dictionary[StringName, int] = {}
var _tracks: Array[AudioStreamPlayer] = []
var _active_track: int = 0
var _fade: Tween


func _ready() -> void:
	for index: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = SFX_BUS
		add_child(voice)
		_voices.append(voice)
	for index: int in 2:
		var track: AudioStreamPlayer = AudioStreamPlayer.new()
		track.bus = MUSIC_BUS
		track.volume_db = SILENT_DB
		add_child(track)
		_tracks.append(track)


## Plays [param cue] at [param pitch]; false when the cue is unknown or cooling down.
func play(cue: StringName, pitch: float = 1.0) -> bool:
	var stream: AudioStream = BANK.cues.get(cue)
	if stream == null:
		return false
	var now: int = Time.get_ticks_msec()
	if _last_played.has(cue) and now - _last_played[cue] < COOLDOWN_MSEC:
		return false
	_last_played[cue] = now
	var voice: AudioStreamPlayer = _voices[_next]
	_next = (_next + 1) % _voices.size()
	voice.stream = stream
	voice.pitch_scale = pitch
	voice.play()
	return true


## Fades to [param track], or to silence; asking for the loop already playing does nothing.
func play_music(track: Music) -> void:
	if track == music:
		return
	music = track
	var outgoing: AudioStreamPlayer = _tracks[_active_track]
	_active_track = 1 - _active_track
	var incoming: AudioStreamPlayer = _tracks[_active_track]
	if _fade != null:
		_fade.kill()
	_fade = create_tween().set_parallel(true)
	_fade.tween_property(outgoing, "volume_db", SILENT_DB, MUSIC_FADE)
	if track != Music.NONE:
		incoming.stream = BANK.menu_music if track == Music.MENU else BANK.board_music
		incoming.volume_db = SILENT_DB
		incoming.play()
		_fade.tween_property(incoming, "volume_db", 0.0, MUSIC_FADE)
	_fade.chain().tween_callback(outgoing.stop)
