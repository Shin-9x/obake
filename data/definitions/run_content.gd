class_name RunContent
extends Resource
## Everything a run draws from: the characters, the floors with their biome and boss, and the
## items that shops and rewards can offer. Unlocks will narrow the item lists.

@export var characters: Array[CharacterDefinition] = []
## Biome of each floor, from the first; it picks the floor's standard layouts.
@export var floor_biomes: PackedStringArray = PackedStringArray()
## Boss at the end of each floor, from the first.
@export var floor_bosses: Array[BossDefinition] = []
@export var events: Array[EventDefinition] = []
@export var balls: Array[BallDefinition] = []
@export var omamori: Array[OmamoriDefinition] = []
@export var pegs: Array[PegDefinition] = []
