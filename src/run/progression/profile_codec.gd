class_name ProfileCodec
## Turns a [Profile] into JSON-friendly data and back. Every file carries its schema version;
## older ones are brought up to date field by field, with defaults for what they lack.

const SCHEMA: int = 1


static func encode(profile: Profile) -> Dictionary[String, Variant]:
	var marks: Dictionary[String, Array] = {}
	for character: StringName in profile.marks:
		marks[String(character)] = _strings(profile.marks[character])
	return {
		"schema": SCHEMA,
		"feats": _strings(profile.feats),
		"marks": marks,
		"discovered": _strings(profile.discovered.keys()),
		"stats":
		{
			"runs": profile.runs,
			"runs_by_character": _counts_out(profile.runs_by_character),
			"wins_by_character": _counts_out(profile.wins_by_character),
			"best_shot": profile.best_shot,
			"matsuri": profile.matsuri,
			"boards_won": profile.boards_won,
		},
		"settings": profile.settings,
	}


## Reads a profile written by [method encode] or by an older schema. Returns null for anything
## that is not a profile, or that a newer version of the game wrote.
static func decode(data: Variant) -> Profile:
	if not data is Dictionary:
		return null
	var source: Dictionary = data
	var schema: int = int(source.get("schema", 0))
	if schema > SCHEMA:
		return null
	var profile: Profile = Profile.new()
	for id: Variant in _array(source.get("feats")):
		profile.feats.append(StringName(str(id)))
	var marks: Variant = source.get("marks")
	if marks is Dictionary:
		for character: Variant in marks:
			profile.marks[StringName(str(character))] = _array(marks[character]).map(
				func(mark: Variant) -> StringName: return StringName(str(mark))
			)
	for id: Variant in _array(source.get("discovered")):
		profile.discovered[StringName(str(id))] = true
	var stats: Dictionary = source.get("stats") if source.get("stats") is Dictionary else {}
	profile.runs = int(stats.get("runs", 0))
	profile.runs_by_character = _counts_in(stats.get("runs_by_character"))
	profile.wins_by_character = _counts_in(stats.get("wins_by_character"))
	profile.best_shot = int(stats.get("best_shot", 0))
	profile.matsuri = int(stats.get("matsuri", 0))
	profile.boards_won = int(stats.get("boards_won", 0))
	if source.get("settings") is Dictionary:
		profile.settings = source["settings"]
	return profile


static func _strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value: Variant in values:
		result.append(str(value))
	return result


static func _array(value: Variant) -> Array:
	return value if value is Array else []


static func _counts_out(counts: Dictionary[StringName, int]) -> Dictionary[String, int]:
	var result: Dictionary[String, int] = {}
	for key: StringName in counts:
		result[String(key)] = counts[key]
	return result


static func _counts_in(value: Variant) -> Dictionary[StringName, int]:
	var result: Dictionary[StringName, int] = {}
	if value is Dictionary:
		for key: Variant in value:
			result[StringName(str(key))] = int(value[key])
	return result
