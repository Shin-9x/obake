extends Node
## Reads and writes the player's files as JSON: the profile, the run in progress and the
## settings. A file is written beside its final name and then renamed over it, so a crash never
## leaves half a file. An unreadable profile is kept aside as a backup before a fresh one
## replaces it.
##
## It also appends to the local run log, JSON lines kept for balancing that never leave the
## device; past a size limit the log moves aside, replacing the previous older log.

const PROFILE_FILE: String = "profile.json"
const RUN_FILE: String = "run.json"
const SETTINGS_FILE: String = "settings.json"
const BACKUP_SUFFIX: String = ".bak"
const RUN_LOG_DIR: String = "run_logs"
const RUN_LOG_FILE: String = "runs.jsonl"
const OLD_RUN_LOG_FILE: String = "runs.old.jsonl"
const RUN_LOG_LIMIT: int = 1_048_576

## Where the files live; tests point it elsewhere.
var directory: String = "user://"
## Size in bytes past which the run log moves aside; tests lower it.
var run_log_limit: int = RUN_LOG_LIMIT


func load_profile() -> Profile:
	var path: String = _path(PROFILE_FILE)
	if not FileAccess.file_exists(path):
		return Profile.new()
	var profile: Profile = ProfileCodec.decode(_read(path))
	if profile == null:
		DirAccess.copy_absolute(path, path + BACKUP_SUFFIX)
		return Profile.new()
	return profile


func save_profile(profile: Profile) -> Error:
	return _write(_path(PROFILE_FILE), ProfileCodec.encode(profile))


func load_settings() -> GameSettings:
	var path: String = _path(SETTINGS_FILE)
	return GameSettings.from_dictionary(_read(path) if FileAccess.file_exists(path) else null)


func save_settings(settings: GameSettings) -> Error:
	return _write(_path(SETTINGS_FILE), settings.to_dictionary())


func has_run() -> bool:
	return FileAccess.file_exists(_path(RUN_FILE))


## The saved run, or an empty dictionary when there is none or it cannot be read.
func load_run() -> Dictionary:
	var data: Variant = _read(_path(RUN_FILE)) if has_run() else null
	return data if data is Dictionary else {}


func save_run(data: Dictionary) -> Error:
	return _write(_path(RUN_FILE), data)


func clear_run() -> void:
	if has_run():
		DirAccess.remove_absolute(_path(RUN_FILE))


func run_log_path() -> String:
	return _path(RUN_LOG_DIR).path_join(RUN_LOG_FILE)


func append_run_log(line: Dictionary) -> Error:
	var path: String = run_log_path()
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var mode: FileAccess.ModeFlags = FileAccess.WRITE
	if FileAccess.file_exists(path):
		mode = FileAccess.READ_WRITE
		if FileAccess.get_size(path) >= run_log_limit:
			var old: String = path.get_base_dir().path_join(OLD_RUN_LOG_FILE)
			DirAccess.remove_absolute(old)
			DirAccess.rename_absolute(path, old)
			mode = FileAccess.WRITE
	var file: FileAccess = FileAccess.open(path, mode)
	if file == null:
		return FileAccess.get_open_error()
	file.seek_end()
	file.store_line(JSON.stringify(line))
	return OK


func _path(file: String) -> String:
	return directory.path_join(file)


## The parsed file, or null when it is not JSON.
func _read(path: String) -> Variant:
	var json: JSON = JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data


func _write(path: String, data: Dictionary) -> Error:
	DirAccess.make_dir_recursive_absolute(directory)
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data))
	file.close()
	return DirAccess.rename_absolute(temporary, path)
