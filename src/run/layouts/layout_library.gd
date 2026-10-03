@tool
class_name LayoutLibrary
## The board layouts shipped with the game, read once from disk in id order.

const DIRECTORY: String = "res://data/layouts"

var layouts: Array[BoardLayout] = []


static func load_from(directory: String = DIRECTORY) -> LayoutLibrary:
	var library: LayoutLibrary = LayoutLibrary.new()
	var files: PackedStringArray = DirAccess.get_files_at(directory)
	files.sort()
	for file: String in files:
		if file.get_extension() != "json":
			continue
		var errors: Array[String] = []
		var text: String = FileAccess.get_file_as_string(directory.path_join(file))
		var layout: BoardLayout = LayoutCodec.from_json(text, errors)
		if layout == null:
			push_error("Invalid layout %s: %s" % [file, "; ".join(errors)])
			continue
		library.layouts.append(layout)
	return library


func find(id: String) -> BoardLayout:
	for layout: BoardLayout in layouts:
		if layout.id == id:
			return layout
	return null
