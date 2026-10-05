class_name BossDefinition
extends ItemDefinition
## A boss board: a fixed layout and a special rule, carried by the effect script and described by
## [member ItemDefinition.description_key].

@export var layout_id: String = ""
## Layout the rule can switch to during the board, such as Nue's transformation; empty if none.
@export var second_layout_id: String = ""
## Peg the rule places on the board, such as Shuten-doji's oni.
@export var special_peg: PegDefinition
## The boss board's target over the previous board's, in permille; it replaces the usual growth
## and reflects how much the rule holds the score back.
@export var target_factor: int = 1800
@export var portrait: Texture2D
