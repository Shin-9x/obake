@tool
class_name RunCarry
## Run-wide modifiers that boards read and some effects grow. The run keeps one between boards.

## Extra points per lantern role, such as Ema's bonus for blue lanterns.
var role_bonus_points: PackedInt32Array = PackedInt32Array()


func _init() -> void:
	role_bonus_points.resize(BoardGame.Role.size())


func add_role_bonus(role: BoardGame.Role, points: int) -> void:
	role_bonus_points[role] += points
