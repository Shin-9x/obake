class_name MapSkin
extends Resource
## Art of the floor map, so placeholder icons can be replaced without code changes.

## Icon of each node kind, in [enum MapNode.Kind] order: board, elite, event, shrine, shop, boss.
@export var node_icons: Array[Texture2D] = []
@export var line_color: Color = Color("#5a607a")
@export var open_line_color: Color = Color("#f4e9c9")
