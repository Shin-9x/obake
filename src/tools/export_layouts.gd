extends SceneTree
## Exports every layout source scene to data/layouts. Run with `make layouts`.
## Exits with an error code when a layout has geometry problems.

const SOURCES: String = "res://src/tools/layout_editor/layouts"


func _init() -> void:
	var failures: int = 0
	var files: PackedStringArray = DirAccess.get_files_at(SOURCES)
	files.sort()
	for file: String in files:
		if file.get_extension() != "tscn":
			continue
		var scene: PackedScene = load(SOURCES.path_join(file)) as PackedScene
		var document: LayoutDocument = scene.instantiate() as LayoutDocument
		if document == null or document.export_json() != OK:
			failures += 1
		elif not LayoutChecks.find_problems(document.build_layout(), document.BALANCE).is_empty():
			failures += 1
		if document != null:
			document.free()
	quit(1 if failures > 0 else 0)
