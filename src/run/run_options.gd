class_name RunOptions
## How a run was started, beyond its seed and character. Saved with the run so replays match.

## Ids of the items shops, rewards and events may offer; empty offers every item.
var pool: Array[StringName] = []


## Copy of [param content] keeping only the items of the pool.
func filter(content: RunContent) -> RunContent:
	if pool.is_empty():
		return content
	var filtered: RunContent = content.duplicate()
	filtered.balls = content.balls.filter(_allowed)
	filtered.omamori = content.omamori.filter(_allowed)
	filtered.pegs = content.pegs.filter(_allowed)
	return filtered


func to_dictionary() -> Dictionary[String, Variant]:
	var ids: Array[String] = []
	for id: StringName in pool:
		ids.append(String(id))
	return {"pool": ids}


static func from_dictionary(data: Variant) -> RunOptions:
	var options: RunOptions = RunOptions.new()
	if data is Dictionary and data.get("pool") is Array:
		for id: Variant in data["pool"]:
			options.pool.append(StringName(str(id)))
	return options


func _allowed(item: ItemDefinition) -> bool:
	return pool.has(item.id)
