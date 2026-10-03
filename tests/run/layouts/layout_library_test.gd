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
