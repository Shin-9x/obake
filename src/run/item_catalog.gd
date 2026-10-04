class_name ItemCatalog
## Every item a run can hold or meet, found by id: the item pools, the characters with their
## starting balls and power pegs, and the bosses with their pegs. Saves refer to items by id.

var _items: Dictionary[StringName, ItemDefinition] = {}


func _init(content: RunContent) -> void:
	for pool: Array in [content.balls, content.omamori, content.pegs]:
		for item: ItemDefinition in pool:
			_add(item)
	for character: CharacterDefinition in content.characters:
		_add(character)
		_add(character.power_peg)
		for ball: BallDefinition in character.starting_balls:
			_add(ball)
	for boss: BossDefinition in content.floor_bosses:
		_add(boss)
		_add(boss.special_peg)


func find(id: StringName) -> ItemDefinition:
	return _items.get(id)


func _add(item: ItemDefinition) -> void:
	if item != null:
		_items[item.id] = item
