extends GdUnitTestSuite
## Guards the project-wide rendering and scripting rules that the whole codebase relies on.

const BASE_WIDTH: int = 640
const BASE_HEIGHT: int = 360
const RENDERER: String = "gl_compatibility"
## Value of GDScript's internal WarnLevel.ERROR, which the engine does not expose as a constant.
const WARNING_LEVEL_ERROR: int = 2


func test_base_resolution_is_640x360() -> void:
	assert_that(_setting("display/window/size/viewport_width")).is_equal(BASE_WIDTH)
	assert_that(_setting("display/window/size/viewport_height")).is_equal(BASE_HEIGHT)


func test_stretch_scales_whole_viewport_by_integer_factors() -> void:
	assert_that(_setting("display/window/stretch/mode")).is_equal("viewport")
	assert_that(_setting("display/window/stretch/aspect")).is_equal("expand")
	assert_that(_setting("display/window/stretch/scale_mode")).is_equal("integer")


func test_canvas_textures_use_nearest_filter() -> void:
	assert_that(_setting("rendering/textures/canvas_textures/default_texture_filter")).is_equal(
		Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	)


func test_renderer_is_compatibility_on_desktop_and_mobile() -> void:
	assert_that(_setting("rendering/renderer/rendering_method")).is_equal(RENDERER)
	assert_that(_setting("rendering/renderer/rendering_method.mobile")).is_equal(RENDERER)


func test_untyped_declarations_are_errors() -> void:
	assert_that(_setting("debug/gdscript/warnings/untyped_declaration")).is_equal(
		WARNING_LEVEL_ERROR
	)


func _setting(key: String) -> Variant:
	return ProjectSettings.get_setting(key)
