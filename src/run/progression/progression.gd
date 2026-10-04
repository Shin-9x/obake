class_name Progression
## Meta-progression rules: which items a new run may offer, which feats a board achieves, and
## what a finished run adds to the profile: completion marks and statistics. Discoveries are
## merged in whenever the profile is updated. Runs on a chosen seed earn no feat and no mark.


## Ids of the items a new run may offer: every item of [param content] except those whose
## feat the profile has not achieved yet.
static func pool(
	content: RunContent, definition: ProgressionDefinition, profile: Profile
) -> Array[StringName]:
	var locked: Dictionary[StringName, bool] = {}
	for feat: FeatDefinition in definition.feats:
		if not profile.has_feat(feat.id):
			locked[feat.unlocks.id] = true
	var ids: Array[StringName] = []
	for items: Array in [content.balls, content.omamori, content.pegs]:
		for item: ItemDefinition in items:
			if not locked.has(item.id):
				ids.append(item.id)
	return ids


## Feats achieved by the board [param run] just finished, in definition order, now recorded
## in [param profile]. The board's result must already be settled by the run.
static func check_board(
	definition: ProgressionDefinition, profile: Profile, run: Run
) -> Array[FeatDefinition]:
	var achieved: Array[FeatDefinition] = []
	merge_discoveries(profile, run)
	if run.run_log.options.custom_seed:
		return achieved
	for feat: FeatDefinition in definition.feats:
		if not profile.has_feat(feat.id) and achieves(feat, run):
			profile.feats.append(feat.id)
			achieved.append(feat)
	return achieved


## Whether the board [param run] just finished meets [param feat].
static func achieves(feat: FeatDefinition, run: Run) -> bool:
	var result: BoardResult = run.game.result
	var boss: BossDefinition = run.board.rules.boss
	match feat.condition:
		FeatDefinition.Condition.PEGS_IN_SHOT:
			return result.best_shot_pegs >= feat.threshold
		FeatDefinition.Condition.BUCKETS_IN_BOARD:
			return result.bucket_catches >= feat.threshold
		FeatDefinition.Condition.ONE_SHOT_WIN:
			return result.won() and result.shots_fired == 1
		FeatDefinition.Condition.BOSS_WITHOUT_SPECIALS:
			return result.won() and boss != null and result.special_balls_fired == 0
		FeatDefinition.Condition.REDS_IN_SHOT:
			return result.best_shot_reds >= feat.threshold
		FeatDefinition.Condition.LAST_SHOT_WIN:
			return result.won_on_last_shot()
		FeatDefinition.Condition.POINTS_IN_SHOT:
			return result.best_shot >= feat.threshold
		FeatDefinition.Condition.MULT_IN_SHOT:
			return result.best_shot_mult >= feat.threshold
		FeatDefinition.Condition.MATSURI:
			return result.outcome == BoardGame.Outcome.MATSURI
		FeatDefinition.Condition.MATSURI_IN_RUN:
			return run.state.matsuri_count >= feat.threshold
		FeatDefinition.Condition.PEGS_BOUGHT_IN_RUN:
			return run.state.inventory.loadout.purchased_pegs.size() >= feat.threshold
		FeatDefinition.Condition.BOSS_DEFEATED:
			return result.won() and boss != null and boss == feat.boss
	return false


## Records a finished run in [param profile]: statistics, and the completion marks a won run
## earns. Returns the marks newly earned.
static func finish_run(
	definition: ProgressionDefinition, profile: Profile, run: Run
) -> Array[Profile.Mark]:
	merge_discoveries(profile, run)
	var state: RunState = run.state
	var character: StringName = state.inventory.loadout.character.id
	profile.runs += 1
	profile.runs_by_character[character] = profile.runs_by_character.get(character, 0) + 1
	profile.best_shot = maxi(profile.best_shot, state.best_shot)
	profile.matsuri += state.matsuri_count
	profile.boards_won += state.boards_won
	var earned: Array[Profile.Mark] = []
	if run.phase != Run.Phase.VICTORY:
		return earned
	profile.wins_by_character[character] = profile.wins_by_character.get(character, 0) + 1
	if run.run_log.options.custom_seed:
		return earned
	var marks: Array[Profile.Mark] = [Profile.Mark.SHUTEN]
	if run.run_log.options.hard:
		marks.append(Profile.Mark.HARD)
	if state.matsuri_count >= definition.festival_matsuri:
		marks.append(Profile.Mark.FESTIVAL)
	for mark: Profile.Mark in marks:
		if profile.add_mark(character, mark):
			earned.append(mark)
	return earned


static func merge_discoveries(profile: Profile, run: Run) -> void:
	for id: StringName in run.seen:
		profile.discovered[id] = true
