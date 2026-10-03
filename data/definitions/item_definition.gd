class_name ItemDefinition
extends Resource
## Fields shared by every collectable item: balls, purchasable pegs and omamori.
##
## Behaviour lives in [member effect_script], a script extending the simulation's Effect class;
## the numbers it uses live here, per level in [member level_values] and by name in [member params].

enum Rarity { BASE, COMMON, UNCOMMON, RARE, LEGENDARY }

@export var id: StringName = &""
@export var name_key: String = ""
@export var description_key: String = ""
@export var rarity: Rarity = Rarity.BASE
@export var icon: Texture2D
## Script extending Effect; empty for items whose data fields say everything.
@export var effect_script: Script
## One value per level, from level 1 up, in the effect's own unit.
@export var level_values: PackedInt32Array = PackedInt32Array()
## Named constants the effect uses, in simulation units.
@export var params: Dictionary[StringName, int] = {}
