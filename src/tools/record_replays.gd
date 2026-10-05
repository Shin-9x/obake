extends SceneTree
## Records every golden replay in tests/replays/ again with the balance bot, keeping each file's
## description, seed, character and options, after a change that its recorded actions no longer
## fit, such as new targets ending boards sooner. Run with `make record-replays`, then say in the
## commit message why. When the recorded actions still apply, `make replays` is enough.

const REPLAYS: String = "res://tests/replays"
## Aims the bot tries per shot: enough for the runs to get past a boss.
const SKILL: int = 8
const Updater: GDScript = preload("res://src/tools/update_replays.gd")


func _init() -> void:
	var config: BalanceConfig = load("res://data/balance.tres") as BalanceConfig
	var content: RunContent = load("res://data/run_content.tres") as RunContent
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var base_pegs: BasePegs = load("res://data/pegs/base_pegs.tres") as BasePegs
	var files: PackedStringArray = DirAccess.get_files_at(REPLAYS)
	files.sort()
	for file: String in files:
		if file.get_extension() != "json":
			continue
		var path: String = REPLAYS.path_join(file)
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var old: RunLog = RunLog.from_dictionary(data.get("log", {}) if data is Dictionary else {})
		if old == null:
			push_error("%s has no run log to start from" % file)
			continue
		var character: CharacterDefinition = load("res://data/characters/%s.tres" % old.character)
		var run: Run = Run.start(
			config, content, library, base_pegs, character, old.run_seed, old.options
		)
		BalanceBot.new(run, base_pegs, SKILL, RunRecord.new(0, ""), old.run_seed).play()
		var recorded: Dictionary[String, Variant] = {
			"description": data.get("description", ""),
			"log": run.run_log.to_dictionary(),
			"expected": Updater.expected(run),
		}
		var out: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		out.store_string(JSON.stringify(recorded, "\t", false) + "\n")
		print(
			(
				"%s: phase %d, floor %d, %d boards"
				% [file, run.phase, run.state.floor_index + 1, run.state.boards_played]
			)
		)
	quit()
