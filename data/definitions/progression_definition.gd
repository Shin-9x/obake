class_name ProgressionDefinition
extends Resource
## The meta-progression: feats and the items they unlock, and the numbers behind the
## completion marks.

@export var feats: Array[FeatDefinition] = []
## Matsuri boards a won run needs for the Festival Night mark.
@export var festival_matsuri: int = 8
## Badge of each completion mark, in [enum Profile.Mark] order.
@export var mark_icons: Array[Texture2D] = []
