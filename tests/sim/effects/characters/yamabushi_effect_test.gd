extends GdUnitTestSuite

const Harness: GDScript = preload("res://tests/sim/support/effect_harness.gd")
const YAMABUSHI: String = "res://data/characters/yamabushi.tres"


func test_green_lanterns_extend_the_guide_for_the_next_shots() -> void:
	var loadout: LoadoutDefinition = Harness.loadout()
	loadout.character = load(YAMABUSHI)
	var game: BoardGame = Harness.board(Harness.ROW, loadout)
	Harness.all_blue(game)
	game.roles[0] = BoardGame.Role.GREEN
	Harness.shoot(game)
	game.score_hit(1)
	assert_int(game.extended_guide_shots).is_equal(0)
	game.score_hit(0)
	Harness.finish(game)
	var params: Dictionary[StringName, int] = (load(YAMABUSHI) as CharacterDefinition).params
	assert_int(game.extended_guide_shots).is_equal(params[&"shots"])
	assert_int(game.guide_contacts()).is_equal(params[&"contacts"])
	var triggers: Array[SimEvent] = Harness.events_of(game, SimEvent.Kind.EFFECT_TRIGGERED)
	assert_array(triggers).has_size(1)
	assert_int(triggers[0].target).is_equal(Effect.CHARACTER_SLOT)
