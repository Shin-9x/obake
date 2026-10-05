extends SceneTree
## Prints a summary of run log files, from players or the balance bot, for `make balance-report`.
##
## Arguments after `--`, each as --name=value: logs (a folder of .jsonl files, relative to the
## project), and optionally source (player or bot) and version, to keep only those lines.


func _init() -> void:
	var arguments: Dictionary[String, String] = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		arguments[parts[0]] = parts[1] if parts.size() > 1 else ""
	var folder: String = ProjectSettings.globalize_path("res://").path_join(
		arguments.get("logs", "reports/balance")
	)
	var source: String = arguments.get("source", "")
	var version: String = arguments.get("version", "")
	var report: RunLogReport = RunLogReport.new()
	var files: PackedStringArray = DirAccess.get_files_at(folder)
	files.sort()
	var read: int = 0
	for file: String in files:
		if file.get_extension() != "jsonl":
			continue
		var content: String = FileAccess.get_file_as_string(folder.path_join(file))
		for text: String in content.split("\n", false):
			var line: Variant = JSON.parse_string(text)
			if not line is Dictionary:
				continue
			if not source.is_empty() and line.get("source") != source:
				continue
			if not version.is_empty() and line.get("version") != version:
				continue
			report.add(line)
			read += 1
	print("%d lines from %s\n" % [read, folder])
	print(report.text())
	quit()
