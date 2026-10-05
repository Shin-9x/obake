class_name RunRecord
## Lines of the local run log kept for balancing: one when a board is settled and one when the
## run ends. Each line is a dictionary ready for JSON, tagged with the game version, who played
## and which run it belongs to, so the lines of many runs and versions can share one file.

const FORMAT: int = 1
const PLAYER: String = "player"
const BOT: String = "bot"
const OUTCOMES: Array[String] = ["playing", "target", "matsuri", "failed"]
const NODE_KINDS: Array[String] = ["board", "elite", "event", "shrine", "shop", "boss"]

## Which run of the profile this is, counted from 1; it stays the same when a run is resumed.
var number: int = 0
var version: String = ""
## [constant PLAYER] or [constant BOT].
var source: String = PLAYER


func _init(run_number: int, game_version: String, played_by: String = PLAYER) -> void:
	number = run_number
	version = game_version
	source = played_by


## The board [param run] has just settled with [method Run.finish_board].
func board(run: Run) -> Dictionary[String, Variant]:
	var line: Dictionary[String, Variant] = _header(run, "board")
	var state: RunState = run.state
	var result: BoardResult = run.game.result
	var boss: BossDefinition = run.board.rules.boss
	var details: Dictionary[String, Variant] = {
		"floor": state.floor_index + 1,
		"step": state.current_node().step + 1,
		"node": NODE_KINDS[run.board.kind],
		"board": state.boards_played,
		"layout": run.board.layout.id,
		"boss": String(boss.id) if boss != null else "",
		"target": run.game.target,
		"score": result.total,
		"outcome": OUTCOMES[result.outcome],
		"shots_fired": result.shots_fired,
		"shots_left": result.shots_left,
		"best_shot": result.best_shot,
		"bucket_catches": result.bucket_catches,
		"payout": run.payout.total(),
		"mon": state.mon,
	}
	line.merge(details)
	line.merge(_loadout(state.inventory.loadout))
	return line


## The end of [param run]: won, lost or given up. Carries the whole action log, so a run can be
## replayed with the same version of the game.
func ending(run: Run) -> Dictionary[String, Variant]:
	var line: Dictionary[String, Variant] = _header(run, "run")
	var state: RunState = run.state
	var outcome: String = "victory" if run.phase == Run.Phase.VICTORY else "defeat"
	var actions: Array[PackedInt32Array] = run.run_log.actions
	if not actions.is_empty() and actions[actions.size() - 1][0] == RunLog.Action.ABANDON:
		outcome = "abandoned"
	var details: Dictionary[String, Variant] = {
		"outcome": outcome,
		"floor": state.floor_index + 1,
		"boards_played": state.boards_played,
		"boards_won": state.boards_won,
		"matsuri": state.matsuri_count,
		"best_shot": state.best_shot,
		"mon": state.mon,
		"log": run.run_log.to_dictionary(),
	}
	line.merge(details)
	line.merge(_loadout(state.inventory.loadout))
	return line


func _header(run: Run, kind: String) -> Dictionary[String, Variant]:
	var options: RunOptions = run.run_log.options
	return {
		"kind": kind,
		"format": FORMAT,
		"version": version,
		"source": source,
		"run": number,
		"seed": "%x" % run.run_log.run_seed,
		"character": String(run.run_log.character),
		"hard": options.hard,
		"custom_seed": options.custom_seed,
	}


static func _loadout(loadout: LoadoutDefinition) -> Dictionary[String, Variant]:
	var balls: Array[String] = []
	for ball: BallDefinition in loadout.balls:
		balls.append(String(ball.id))
	var charms: Array[String] = []
	for charm: OmamoriDefinition in loadout.omamori:
		charms.append(String(charm.id))
	var pegs: Array[String] = []
	for peg: PegDefinition in loadout.purchased_pegs:
		pegs.append(String(peg.id))
	return {
		"balls": balls,
		"ball_levels": Array(loadout.ball_levels),
		"omamori": charms,
		"pegs": pegs,
	}
