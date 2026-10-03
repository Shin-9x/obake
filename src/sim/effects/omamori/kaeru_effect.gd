@tool
class_name KaeruEffect
extends Effect
## Kaeru: pays mon whenever a ball drops into the bucket.
## Params: mon.


func on_bucket(game: BoardGame) -> void:
	var bucket: Bucket = game.simulation.bucket
	game.add_mon(param(&"mon"), bucket.x, bucket.y)
	game.trigger(self)
