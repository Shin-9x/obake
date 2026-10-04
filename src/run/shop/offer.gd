class_name Offer
## One item for sale in a shop.

var item: ItemDefinition
var price: int = 0
var sold: bool = false


func _init(offered: ItemDefinition = null, cost: int = 0) -> void:
	item = offered
	price = cost
