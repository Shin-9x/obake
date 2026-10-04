extends Node
## Reads and writes the player's files as JSON: the profile and the run in progress. A file is
## written beside its final name and then renamed over it, so a crash never leaves half a file.
## An unreadable profile is kept aside as a backup before a fresh one replaces it.

const PROFILE_FILE: String = "profile.json"
const RUN_FILE: String = "run.json"
const BACKUP_SUFFIX: String = ".bak"

## Where the files live; tests point it elsewhere.
var directory: String = "user://"


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
