extends GdUnitTestSuite


func test_loads_every_shipped_layout_in_id_order() -> void:
	var library: LayoutLibrary = LayoutLibrary.load_from()
	var ids: Array[String] = []
	for layout: BoardLayout in library.layouts:
		ids.append(layout.id)
	assert_array(ids).is_equal(
		["bamboo_01", "bamboo_02", "bamboo_03", "village_01", "village_02", "village_03"]
	)
	assert_object(library.find("village_02")).is_same(library.layouts[4])
	assert_object(library.find("missing")).is_null()


func test_pools_hold_the_standard_boards_of_a_biome() -> void:
	var library: LayoutLibrary = LayoutLibrary.new()
	for entry: Array in [["a", "forest", false], ["b", "forest", true], ["c", "village", false]]:
		var layout: BoardLayout = BoardLayout.new()
		layout.id = entry[0]
		layout.biome = entry[1]
		layout.kind = BoardLayout.Kind.BOSS if entry[2] else BoardLayout.Kind.BOARD
		library.layouts.append(layout)
	var forest: Array[String] = []
	for layout: BoardLayout in library.pool("forest"):
		forest.append(layout.id)
	assert_array(forest).is_equal(["a"])
	assert_int(library.boards().size()).is_equal(2)
