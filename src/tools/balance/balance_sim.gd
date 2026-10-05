extends SceneTree
## Plays runs with the balance bot and writes their run log lines, for `make balance-sim`.
##
## Arguments after `--`, each as --name=value: runs (in total), jobs and job (this process plays
## the runs whose index divided by jobs leaves job), skill (aims tried per shot), hard (0 or 1),
## fresh (1 limits items to those a new profile has unlocked), first-seed, out (the .jsonl file
## to write, relative to the project) and set, which tries other balance numbers without editing
## them: whole-number BalanceConfig fields, a boss id for its target factor, or a character id
## and one of its params, as name:value pairs separated by commas, such as
## --set=board_target_growth:1250,tamamo:1200,kitsune.count:2. Characters take turns, run by run.

const CHARACTERS: Array[String] = ["yamabushi", "kitsune", "tanuki"]
const BALANCE: String = "res://data/balance.tres"
const CONTENT: String = "res://data/run_content.tres"
const PROGRESSION: String = "res://data/progression.tres"
const BASE_PEGS: String = "res://data/pegs/base_pegs.tres"
const CHARACTER: String = "res://data/characters/%s.tres"


func _init() -> void:
	var arguments: Dictionary[String, String] = _arguments()
	var runs: int = int(arguments.get("runs", "12"))
	var jobs: int = maxi(1, int(arguments.get("jobs", "1")))
	var job: int = int(arguments.get("job", "0"))
	var skill: int = int(arguments.get("skill", "8"))
	var first_seed: int = int(arguments.get("first-seed", "1"))
	var out_path: String = arguments.get("out", "reports/balance/runs.jsonl")
	var config: BalanceConfig = load(BALANCE) as BalanceConfig
	var content: RunContent = load(CONTENT) as RunContent
	for pair: String in arguments.get("set", "").split(",", false):
		var parts: PackedStringArray = pair.split(":")
		var boss: BossDefinition = _boss(content, parts[0])
		var names: PackedStringArray = parts[0].split(".")
		if parts.size() == 2 and parts[0] in config:
			config.set(parts[0], int(parts[1]))
		elif parts.size() == 2 and boss != null:
			boss.target_factor = int(parts[1])
		elif parts.size() == 2 and names.size() == 2 and CHARACTERS.has(names[0]):
			var character: CharacterDefinition = load(CHARACTER % names[0])
			character.params[StringName(names[1])] = int(parts[1])
		else:
			push_error("Unknown balance setting %s" % pair)
			quit(1)
			return
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var base_pegs: BasePegs = load(BASE_PEGS) as BasePegs
	var options: RunOptions = RunOptions.new()
	options.hard = arguments.get("hard", "0") == "1"
	if arguments.get("fresh", "0") == "1":
		var progression: ProgressionDefinition = load(PROGRESSION) as ProgressionDefinition
		options.pool = Progression.pool(content, progression, Profile.new())
	var absolute: String = ProjectSettings.globalize_path("res://").path_join(out_path)
	DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	var out: FileAccess = FileAccess.open(absolute, FileAccess.WRITE)
	if out == null:
		push_error("Cannot write %s" % absolute)
		quit(1)
		return
	for index: int in range(job, runs, jobs):
		var character: CharacterDefinition = load(CHARACTER % CHARACTERS[index % CHARACTERS.size()])
		var seed_value: int = first_seed + index
		var run: Run = Run.start(
			config, content, library, base_pegs, character, seed_value, options
		)
		var record: RunRecord = RunRecord.new(index + 1, BuildInfo.version(), RunRecord.BOT)
		var bot: BalanceBot = BalanceBot.new(run, base_pegs, skill, record, seed_value)
		bot.play()
		for line: Dictionary in bot.lines:
			line["skill"] = skill
			out.store_line(JSON.stringify(line))
		out.flush()
		print(
			(
				"run %d %s: %s on floor %d after %d boards"
				% [
					index + 1,
					character.id,
					"won" if run.phase == Run.Phase.VICTORY else "lost",
					run.state.floor_index + 1,
					run.state.boards_played,
				]
			)
		)
	quit()


static func _boss(content: RunContent, id: String) -> BossDefinition:
	for boss: BossDefinition in content.floor_bosses:
		if boss.id == id:
			return boss
	return null


static func _arguments() -> Dictionary[String, String]:
	var found: Dictionary[String, String] = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		found[parts[0]] = parts[1] if parts.size() > 1 else ""
	return found
