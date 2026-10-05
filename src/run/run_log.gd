class_name RunLog
## Everything needed to play a run again from nothing: the seed, the character and every action
## taken, in order. Run resume and leaderboard validation replay it.

## Kinds of action; new kinds go at the end so recorded logs keep their meaning.
enum Action {
	CHOOSE_NODE,
	## Aim in centidegrees, then the board clock.
	SHOOT,
	FINISH_BOARD,
	TAKE_BALL,
	SKIP_BALL,
	## Choice, then the slot to replace or -1.
	TAKE_OMAMORI,
	SKIP_OMAMORI,
	BUY_BALL,
	BUY_OMAMORI,
	BUY_PEG,
	REROLL,
	UPGRADE_BALL,
	SELL_OMAMORI,
	LEAVE_SHOP,
	SHRINE_REMOVE,
	SHRINE_UPGRADE,
	LEAVE_SHRINE,
	## Option, then the pick or -1.
	CHOOSE_EVENT,
	FINISH_EVENT,
	## The player gave the run up.
	ABANDON,
}

const FORMAT: int = 1

var run_seed: int = 0
var character: StringName = &""
var options: RunOptions = RunOptions.new()
## Each entry holds the action kind and its two arguments.
var actions: Array[PackedInt32Array] = []


func _init(
	seed_value: int = 0, character_id: StringName = &"", run_options: RunOptions = null
) -> void:
	run_seed = seed_value
	character = character_id
	if run_options != null:
		options = run_options


func record(action: Action, first: int = -1, second: int = -1) -> void:
	actions.append(PackedInt32Array([action, first, second]))


func size() -> int:
	return actions.size()


func to_dictionary() -> Dictionary[String, Variant]:
	var entries: Array[Array] = []
	for entry: PackedInt32Array in actions:
		entries.append(Array(entry))
	return {
		"format": FORMAT,
		"seed": run_seed,
		"character": String(character),
		"options": options.to_dictionary(),
		"actions": entries,
	}


## Parses a log written by [method to_dictionary]; null when it is not one.
static func from_dictionary(data: Dictionary) -> RunLog:
	if int(data.get("format", 0)) != FORMAT or not data.get("actions") is Array:
		return null
	var run_log: RunLog = RunLog.new(
		int(data.get("seed", 0)),
		StringName(str(data.get("character"))),
		RunOptions.from_dictionary(data.get("options"))
	)
	for entry: Variant in data["actions"]:
		if not entry is Array or (entry as Array).size() != 3:
			return null
		var values: Array = entry
		run_log.actions.append(PackedInt32Array([int(values[0]), int(values[1]), int(values[2])]))
	return run_log
