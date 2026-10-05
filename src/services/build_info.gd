class_name BuildInfo
## Facts about this build of the game.

const VERSION_SETTING: String = "application/config/version"


## The game's version, from the project settings.
static func version() -> String:
	return str(ProjectSettings.get_setting(VERSION_SETTING, ""))
