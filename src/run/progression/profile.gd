class_name Profile
## What the player has achieved across runs: feats, completion marks per character, discovered
## entries of the compendium and statistics, plus settings once they exist.

## GDD completion marks, earned per character.
enum Mark { SHUTEN, HARD, FESTIVAL }

const MARK_IDS: Array[StringName] = [&"shuten", &"hard", &"festival"]

var feats: Array[StringName] = []
## Mark ids earned, by character id.
var marks: Dictionary[StringName, Array] = {}
## Items and bosses seen at least once, by id.
var discovered: Dictionary[StringName, bool] = {}
var runs: int = 0
var runs_by_character: Dictionary[StringName, int] = {}
var wins_by_character: Dictionary[StringName, int] = {}
var best_shot: int = 0
var matsuri: int = 0
var boards_won: int = 0
## Opaque until the settings arrive.
var settings: Dictionary = {}


func has_feat(id: StringName) -> bool:
	return feats.has(id)


func has_mark(character: StringName, mark: Mark) -> bool:
	return marks.get(character, []).has(MARK_IDS[mark])


## Records [param mark] for [param character]; false when it was already earned.
func add_mark(character: StringName, mark: Mark) -> bool:
	if has_mark(character, mark):
		return false
	if not marks.has(character):
		marks[character] = []
	marks[character].append(MARK_IDS[mark])
	return true


## Hard mode opens once the character has beaten the final boss.
func hard_unlocked(character: StringName) -> bool:
	return has_mark(character, Mark.SHUTEN)


func wins() -> int:
	var total: int = 0
	for character: StringName in wins_by_character:
		total += wins_by_character[character]
	return total
