class_name StatisticsScreen
extends Control
## What the profile remembers: runs, wins per character, records, feats and discoveries.

signal closed


func open(content: RunContent, progression: ProgressionDefinition, profile: Profile) -> void:
	UiKit.clear(self)
	var page: Control = UiKit.page(self)
	var body: VBoxContainer = UiKit.body(page, 12)
	body.add_child(UiKit.label("STATS_TITLE", UiKit.TITLE_SIZE))
	var entries: int = 0
	for items: Array in [content.balls, content.omamori, content.pegs, content.floor_bosses]:
		entries += items.size()
	var lines: Array[String] = [
		tr("STATS_RUNS") % profile.runs,
		tr("STATS_WINS") % profile.wins(),
	]
	for character: CharacterDefinition in content.characters:
		lines.append(
			(
				tr("STATS_CHARACTER")
				% [
					tr(character.name_key),
					profile.runs_by_character.get(character.id, 0),
					profile.wins_by_character.get(character.id, 0)
				]
			)
		)
	(
		lines
		. append_array(
			[
				tr("STATS_BEST_SHOT") % profile.best_shot,
				tr("STATS_MATSURI") % profile.matsuri,
				tr("STATS_BOARDS") % profile.boards_won,
				tr("STATS_FEATS") % [profile.feats.size(), progression.feats.size()],
				tr("STATS_DISCOVERED") % [_discovered(content, profile), entries],
			]
		)
	)
	for line: String in lines:
		body.add_child(UiKit.label(line, 0, UiKit.TEXT, false))
	var back: Button = UiKit.button("BUTTON_BACK", true, AudioService.UI_BACK)
	back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	back.pressed.connect(closed.emit)
	body.add_child(back)


func back() -> void:
	closed.emit()


static func _discovered(content: RunContent, profile: Profile) -> int:
	var count: int = 0
	for items: Array in [content.balls, content.omamori, content.pegs, content.floor_bosses]:
		for item: ItemDefinition in items:
			count += 1 if profile.discovered.has(item.id) else 0
	return count
