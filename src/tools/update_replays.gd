extends SceneTree
## Replays every golden replay in tests/replays/ with the shipped data and writes the results it
## reaches back into the file, after a deliberate change to the game. Run with
## `make replays`, then say in the commit message why the results moved.
## Exits with an error code when a recorded action no longer applies.

const REPLAYS: String = "res://tests/replays"


func _init() -> void:
	var failures: int = 0
	var files: PackedStringArray = DirAccess.get_files_at(REPLAYS)
	files.sort()
	for file: String in files:
		if file.get_extension() != "json":
			continue
		var path: String = REPLAYS.path_join(file)
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var run: Run = replay(data)
		if run == null:
			push_error("%s no longer replays" % file)
			failures += 1
			continue
		var updated: Dictionary[String, Variant] = {
			"description": data.get("description", ""),
			"log": run.run_log.to_dictionary(),
			"expected": expected(run),
		}
		var out: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		out.store_string(JSON.stringify(updated, "\t", false) + "\n")
		print(
			(
				"%s: phase %d, %d boards, %d mon"
				% [file, run.phase, run.state.boards_played, run.state.mon]
			)
		)
	quit(1 if failures > 0 else 0)


## The run a replay file describes, played again with the shipped data; null if it breaks.
static func replay(data: Variant) -> Run:
	if not data is Dictionary or not data.get("log") is Dictionary:
		return null
	var run_log: RunLog = RunLog.from_dictionary(data["log"])
	if run_log == null:
		return null
	return RunReplay.replay(
		run_log,
		load("res://data/balance.tres"),
		load("res://data/run_content.tres"),
		LayoutLibrary.load_from(),
		load("res://data/pegs/base_pegs.tres")
	)


static func expected(run: Run) -> Dictionary[String, Variant]:
	return {"phase": run.phase, "state": RunCodec.encode(run.state)}
