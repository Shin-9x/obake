@tool
class_name BoardGame
## One board played under the GDD rules: coloured lanterns, shots scored as points x mult, a bag
## of balls, items acting through effects, a limited number of shots, and victory by score
## target or by Matsuri.
##
## The board seed, the loadout, the rules and the shot inputs fully determine a game, which makes
## it replayable. Effects change the game only through the methods of the effect API below; hooks
## run for the shot's ball, the hit peg, the character, the boss, then the omamori in slot order.

enum Outcome { PLAYING, TARGET_REACHED, MATSURI, FAILED }
## SPECIAL marks a purchased peg, which carries its own definition.
enum Role { BLUE, RED, GREEN, GOLD, SPECIAL }

const _PERMILLE: int = FixedMath.PERMILLE
## Entries per queued explosion: x, y, radius and source.
const _AREA_STRIDE: int = 4
## Later than any real tick: makes every pending fire due.
const _FLUSH: int = 1 << 62

var simulation: BoardSimulation
## Shared with [member simulation]: physics events followed by the events they caused.
var events: SimEventQueue
var bag: BallBag
var carry: RunCarry
var shots_left: int = 0
var target: int = 0
var total: int = 0
var shot_points: int = 0
## Mult of the current shot, in permille.
var shot_mult: int = _PERMILLE
var outcome: Outcome = Outcome.PLAYING
## [enum Role] of each peg, by peg index.
var roles: PackedInt32Array = PackedInt32Array()
## Set once the board has ended.
var result: BoardResult
## Ball fired by the current or last shot; null when the bag is empty.
var shot_ball: BagBall
## Shots fired on this board, free ones included.
var shots_fired: int = 0
var mon_earned: int = 0
## Highest score of a single shot on this board.
var best_shot: int = 0
## Mult added when the next shot starts, in permille.
var next_shot_mult_bonus: int = 0
## Copies placed of every purchased peg.
var purchased_copies: int = 1
var shot_pegs_hit: int = 0
var shot_red_hits: int = 0
var shot_wall_bounces: int = 0
## The shot's ball, or one of its splits, was caught by the bucket.
var shot_caught: bool = false
## Lowest mult a shot can drop to, in permille.
var mult_floor: int = 0
## Shots still to come that show the extended aim guide, and how many contacts it follows.
var extended_guide_shots: int = 0
var extended_guide_contacts: int = 1

var _config: BalanceConfig
var _rng: Pcg32
var _definitions: Array[PegDefinition] = []
var _peg_definitions: Array[PegDefinition] = []
var _peg_effects: Array[Effect] = []
var _purchased: Array[PegDefinition] = []
## Character, boss, then omamori in slot order: the effects that act on every hit.
var _effects: Array[Effect] = []
var _scored: PackedByteArray = PackedByteArray()
var _candidates: PackedInt32Array = PackedInt32Array()
var _gold: int = -1
var _refunded: bool = false
var _hit: PegHit = PegHit.new()
## Filled when the board ends, so ending a board inside a tick allocates nothing.
var _result: BoardResult = BoardResult.new()
var _end_mult_factor: int = _PERMILLE
var _keep_on_top: bool = false
var _near: PackedInt32Array = PackedInt32Array()
var _burn_near: PackedInt32Array = PackedInt32Array()
var _areas: PackedInt32Array = PackedInt32Array()
var _area_head: int = 0
var _area_count: int = 0
var _acting: bool = false
var _burning: PackedInt32Array = PackedInt32Array()
var _burn_due: PackedInt32Array = PackedInt32Array()
var _burn_count: int = 0
var _due: PackedInt32Array = PackedInt32Array()
var _is_burning: PackedByteArray = PackedByteArray()


## [param board] must already hold its pegs. [param rng] is the board's own random stream.
## Without a [param loadout] the bag is empty and every shot fires a plain ball.
func _init(
	board: BoardSimulation,
	config: BalanceConfig,
	base_pegs: BasePegs,
	rng: Pcg32,
	loadout: LoadoutDefinition = null,
	run_carry: RunCarry = null,
	rules: BoardRules = null
) -> void:
	simulation = board
	events = board.events
	_config = config
	_rng = rng
	carry = run_carry if run_carry != null else RunCarry.new()
	_definitions = [base_pegs.blue, base_pegs.red, base_pegs.green, base_pegs.gold, null]
	shots_left = config.shots_per_board
	target = config.first_board_target
	if rules != null:
		target = rules.target if rules.target > 0 else target
		shots_left += rules.shot_delta
	var count: int = board.pegs.size()
	_peg_definitions.resize(count)
	_peg_effects.resize(count)
	_near.resize(count)
	_burn_near.resize(count)
	_burning.resize(count)
	_burn_due.resize(count)
	_due.resize(count)
	_is_burning.resize(count)
	_areas.resize(_AREA_STRIDE * (count + 1))
	_assign_roles()
	var balls: Array[BagBall] = []
	if loadout != null:
		for index: int in loadout.balls.size():
			balls.append(BagBall.new(loadout.balls[index], loadout.level_of(index)))
		_add_effect(Effect.create(loadout.character, 1, Effect.CHARACTER_SLOT))
	if rules != null:
		_add_effect(Effect.create(rules.boss, 1, Effect.BOSS_SLOT))
	if loadout != null:
		for slot: int in loadout.omamori.size():
			_add_effect(Effect.create(loadout.omamori[slot], 1, slot))
	bag = BallBag.new(balls, rng)
	for ball: BagBall in balls:
		if ball.effect != null:
			ball.effect.on_board_start(self)
	for effect: Effect in _effects:
		effect.on_board_start(self)
	shots_left = maxi(1, shots_left)
	if loadout != null:
		_purchased = loadout.purchased_pegs
	_place_purchased(_purchased)
	_refresh_attractors()


func definition_of(peg: int) -> PegDefinition:
	if roles[peg] == Role.SPECIAL:
		return _peg_definitions[peg]
	return _definitions[roles[peg]]


func red_remaining() -> int:
	var count: int = 0
	for peg: int in roles.size():
		if roles[peg] == Role.RED and not simulation.pegs[peg].removed:
			count += 1
	return count


func is_burning(peg: int) -> bool:
	return _is_burning[peg] == 1


func can_shoot() -> bool:
	return outcome == Outcome.PLAYING and shots_left > 0 and not simulation.is_shot_active()


## Starts a shot with the next ball of the bag. Returns false when the board is over or a shot
## is already in flight.
func shoot(input: ShotInput) -> bool:
	if not can_shoot():
		return false
	var bonus: int = next_shot_mult_bonus
	next_shot_mult_bonus = 0
	shot_points = 0
	shot_mult = _PERMILLE + bonus
	shot_pegs_hit = 0
	shot_red_hits = 0
	shot_wall_bounces = 0
	shot_caught = false
	_scored.fill(0)
	_refunded = false
	_end_mult_factor = _PERMILLE
	_keep_on_top = false
	shots_left -= 1
	shots_fired += 1
	extended_guide_shots = maxi(0, extended_guide_shots - 1)
	shot_ball = bag.draw()
	simulation.launch(input)
	var ball: SimBall = launched_ball()
	events.push(
		SimEvent.Kind.BALL_DRAWN, simulation.tick, simulation.launched_ball, -1, ball.x, ball.y
	)
	if bonus != 0:
		events.push(SimEvent.Kind.SCORE_MULT_ADD, simulation.tick, -1, -1, ball.x, ball.y, bonus)
	if shot_ball != null and shot_ball.effect != null:
		shot_ball.effect.on_shot_start(self)
	for effect: Effect in _effects:
		effect.on_shot_start(self)
	return true


## Advances the board clock between shots; see [method BoardSimulation.idle_step].
func idle_step() -> void:
	simulation.idle_step()


## Advances the simulation one tick and applies the board rules and effects to what happened.
func step() -> void:
	if not simulation.is_shot_active():
		return
	var first: int = events.size()
	simulation.step()
	var last: int = events.size()
	for index: int in range(first, last):
		var event: SimEvent = events.at(index)
		match event.kind:
			SimEvent.Kind.PEG_HIT:
				score_hit(event.target, PegHit.Source.BALL, event.ball)
			SimEvent.Kind.WALL_BOUNCE:
				shot_wall_bounces += 1
				_dispatch_wall_bounce()
			SimEvent.Kind.BUCKET_CATCH:
				shot_caught = true
				# GDD: a ball caught by the bucket returns to the bag, so the shot is free.
				if not _refunded:
					_refunded = true
					shots_left += 1
				_dispatch_bucket()
			SimEvent.Kind.SHOT_RESOLVED:
				_resolve_shot()
	if simulation.is_shot_active():
		_burn_due_pegs(simulation.tick)


## Lights and scores [param peg], once per shot, running every effect's [method Effect.on_peg_hit].
## Physics calls it for each touch; effects reach it through explosions and fire.
func score_hit(peg: int, source: PegHit.Source = PegHit.Source.BALL, ball: int = -1) -> void:
	var outer: bool = not _acting
	_acting = true
	_score(peg, source, ball)
	if outer:
		_drain_areas()
		_acting = false


## The ball fired by the current shot. Effect API, like everything up to [method trigger].
func launched_ball() -> SimBall:
	return simulation.balls[simulation.launched_ball]


func add_points(amount: int, x: int, y: int) -> void:
	shot_points += amount
	events.push(SimEvent.Kind.SCORE_POINTS, simulation.tick, -1, -1, x, y, amount)


## [param factor] in permille.
func multiply_points(factor: int, x: int, y: int) -> void:
	shot_points = FixedMath.div_round(shot_points * factor, _PERMILLE)
	events.push(SimEvent.Kind.SCORE_POINTS_TIMES, simulation.tick, -1, -1, x, y, factor)


## [param amount] in permille.
func add_mult(amount: int, x: int, y: int) -> void:
	shot_mult = maxi(mult_floor, shot_mult + amount)
	events.push(SimEvent.Kind.SCORE_MULT_ADD, simulation.tick, -1, -1, x, y, amount)


## [param factor] in permille.
func multiply_mult(factor: int, x: int, y: int) -> void:
	shot_mult = maxi(mult_floor, FixedMath.div_round(shot_mult * factor, _PERMILLE))
	events.push(SimEvent.Kind.SCORE_MULT_TIMES, simulation.tick, -1, -1, x, y, factor)


## Multiplies the mult once every end-of-shot effect has added to it; [param factor] in permille.
func multiply_final_mult(factor: int) -> void:
	_end_mult_factor = FixedMath.div_round(_end_mult_factor * factor, _PERMILLE)


func add_mon(amount: int, x: int, y: int) -> void:
	mon_earned += amount
	events.push(SimEvent.Kind.MON_GAINED, simulation.tick, -1, -1, x, y, amount)


## Hits every peg whose surface lies within [param radius] of ([param x], [param y]). Inside a
## hit, the explosion waits until that hit is scored.
func hit_pegs_near(x: int, y: int, radius: int, source: PegHit.Source) -> void:
	if (_area_count + 1) * _AREA_STRIDE > _areas.size():
		_areas.resize(_areas.size() * 2)
	var base: int = _area_count * _AREA_STRIDE
	_areas[base] = x
	_areas[base + 1] = y
	_areas[base + 2] = radius
	_areas[base + 3] = source
	_area_count += 1
	if not _acting:
		_acting = true
		_drain_areas()
		_acting = false


## Sets fire to the [param count] nearest pegs within [param radius] of [param peg] that have not
## been hit; each is hit by fire after [param delay] ticks, or when the shot ends if sooner.
func burn_neighbours(peg: int, count: int, radius: int, delay: int) -> void:
	var origin: SimPeg = simulation.pegs[peg]
	var found: int = simulation.pegs_within(origin.x, origin.y, radius, _burn_near)
	for pick: int in count:
		var best: int = -1
		var best_squared: int = 0
		for index: int in found:
			var candidate: int = _burn_near[index]
			if candidate == peg or _scored[candidate] == 1 or _is_burning[candidate] == 1:
				continue
			var dx: int = simulation.pegs[candidate].x - origin.x
			var dy: int = simulation.pegs[candidate].y - origin.y
			var squared: int = dx * dx + dy * dy
			if best < 0 or squared < best_squared or (squared == best_squared and candidate < best):
				best = candidate
				best_squared = squared
		if best < 0:
			return
		_is_burning[best] = 1
		_burning[_burn_count] = best
		_burn_due[_burn_count] = simulation.tick + delay
		_burn_count += 1
		var where: SimPeg = simulation.pegs[best]
		events.push(SimEvent.Kind.PEG_BURNING, simulation.tick, -1, best, where.x, where.y)


## Splits [param ball] into [param count] balls; the new ones are plain and fan out by
## [param spread] centidegrees each, alternating sides.
func split_ball(ball: int, count: int, spread: int) -> void:
	for child: int in range(1, count):
		var parent: SimBall = simulation.balls[ball]
		var side: int = 1 if child % 2 == 1 else -1
		var angle: int = side * spread * ((child + 1) / 2)
		var cosine: int = Trig.cos_cd(angle)
		var sine: int = Trig.sin_cd(angle)
		var vx: int = FixedMath.div_round(parent.vx * cosine - parent.vy * sine, FixedMath.UNIT)
		var vy: int = FixedMath.div_round(parent.vx * sine + parent.vy * cosine, FixedMath.UNIT)
		var index: int = simulation.spawn_ball(parent.x, parent.y, vx, vy)
		events.push(SimEvent.Kind.BALL_SPLIT, simulation.tick, index, ball, parent.x, parent.y)


## Turns [param peg] into a [param definition] peg, such as a purchased one.
func place_special(peg: int, definition: PegDefinition) -> void:
	roles[peg] = Role.SPECIAL
	_peg_definitions[peg] = definition
	_peg_effects[peg] = Effect.create(definition, 1, Effect.PEG_SLOT)
	var sim_peg: SimPeg = simulation.pegs[peg]
	sim_peg.restitution = definition.restitution if definition.restitution > 0 else -1
	sim_peg.persistent = definition.persistent
	sim_peg.attractor = false


## Turns up to [param count] random [param role] pegs that are still unlit into
## [param definition] pegs, and returns how many it turned.
func transform_random(role: Role, count: int, definition: PegDefinition) -> int:
	var turned: int = 0
	for pick: int in count:
		var available: int = 0
		for peg: int in roles.size():
			var candidate: SimPeg = simulation.pegs[peg]
			if (
				roles[peg] == role
				and not candidate.lit
				and not candidate.removed
				and not candidate.illusion
			):
				_candidates[available] = peg
				available += 1
		if available == 0:
			break
		var chosen: int = _candidates[_rng.next_below(available)]
		place_special(chosen, definition)
		var where: SimPeg = simulation.pegs[chosen]
		events.push(SimEvent.Kind.PEG_TRANSFORMED, simulation.tick, -1, chosen, where.x, where.y)
		turned += 1
	return turned


## Makes [param count] random unlit blue lanterns illusions, after clearing the previous ones,
## and returns how many it made. Balls pass through illusions, which vanish without scoring.
func scatter_illusions(count: int) -> int:
	for peg: SimPeg in simulation.pegs:
		peg.illusion = false
	var made: int = 0
	for pick: int in count:
		var available: int = 0
		for peg: int in roles.size():
			var candidate: SimPeg = simulation.pegs[peg]
			if (
				roles[peg] == Role.BLUE
				and not candidate.lit
				and not candidate.removed
				and not candidate.illusion
			):
				_candidates[available] = peg
				available += 1
		if available == 0:
			break
		simulation.pegs[_candidates[_rng.next_below(available)]].illusion = true
		made += 1
	return made


## Number of pegs still on the board.
func pegs_in_play() -> int:
	var count: int = 0
	for peg: SimPeg in simulation.pegs:
		if not peg.removed:
			count += 1
	return count


## Brings layout layer [param layer] into play: the pegs still on the board leave, the pegs of
## that layer arrive coloured as on a new board, and the purchased pegs are placed again.
func switch_layer(layer: int) -> void:
	for peg: int in roles.size():
		var sim_peg: SimPeg = simulation.pegs[peg]
		sim_peg.illusion = false
		if sim_peg.layer == layer:
			simulation.restore_peg(peg)
			roles[peg] = Role.BLUE
			_peg_definitions[peg] = null
			_peg_effects[peg] = null
			sim_peg.restitution = -1
			sim_peg.persistent = false
		elif not sim_peg.removed:
			simulation.remove_peg(peg)
	_gold = -1
	_colour_pegs()
	_place_purchased(_purchased)
	_refresh_attractors()
	events.push(SimEvent.Kind.LAYOUT_CHANGED, simulation.tick, -1, -1, 0, 0, layer)


## Shows the aim guide up to [param contacts] contacts for the next [param shots] shots, on top
## of any extension still running.
func extend_guide(shots: int, contacts: int) -> void:
	extended_guide_shots += shots
	extended_guide_contacts = maxi(extended_guide_contacts, contacts)


## Contacts the aim guide follows for the shot being aimed.
func guide_contacts() -> int:
	return extended_guide_contacts if extended_guide_shots > 0 else 1


## The shot's ball goes back on top of the bag instead of being discarded.
func keep_ball_on_top() -> void:
	_keep_on_top = true


## Uniform draw in [0, [param bound]) from the board stream.
func random_below(bound: int) -> int:
	return _rng.next_below(bound)


## Tells presentation that [param effect] just acted.
func trigger(effect: Effect) -> void:
	events.push(SimEvent.Kind.EFFECT_TRIGGERED, simulation.tick, -1, effect.slot, 0, 0)


func _score(peg: int, source: PegHit.Source, ball: int) -> void:
	if _scored[peg] == 1:
		return
	if simulation.pegs[peg].illusion:
		_vanish(peg)
		return
	_scored[peg] = 1
	simulation.mark_hit(peg)
	var definition: PegDefinition = definition_of(peg)
	var hit: PegHit = _hit
	hit.peg = peg
	hit.ball = ball
	hit.source = source
	hit.role = roles[peg] as Role
	hit.definition = definition
	hit.first_of_shot = shot_pegs_hit == 0
	hit.points = definition.points
	hit.bonus_points = carry.role_bonus_points[hit.role]
	hit.points_factor = _PERMILLE
	hit.mult_add = definition.mult_add
	hit.mult_factor = definition.mult_factor
	hit.mon = definition.mon
	shot_pegs_hit += 1
	if hit.role == Role.RED:
		shot_red_hits += 1
	if shot_ball != null and shot_ball.effect != null:
		shot_ball.effect.on_peg_hit(self, hit)
	if _peg_effects[peg] != null:
		_peg_effects[peg].on_peg_hit(self, hit)
	for effect: Effect in _effects:
		effect.on_peg_hit(self, hit)
	var where: SimPeg = simulation.pegs[peg]
	var tick: int = simulation.tick
	var points: int = FixedMath.div_round(
		(hit.points + hit.bonus_points) * hit.points_factor, _PERMILLE
	)
	if points != 0:
		shot_points += points
		events.push(SimEvent.Kind.SCORE_POINTS, tick, -1, peg, where.x, where.y, points)
	if hit.mult_add != 0:
		shot_mult = maxi(mult_floor, shot_mult + hit.mult_add)
		events.push(SimEvent.Kind.SCORE_MULT_ADD, tick, -1, peg, where.x, where.y, hit.mult_add)
	if hit.mult_factor != _PERMILLE:
		shot_mult = maxi(mult_floor, FixedMath.div_round(shot_mult * hit.mult_factor, _PERMILLE))
		events.push(
			SimEvent.Kind.SCORE_MULT_TIMES, tick, -1, peg, where.x, where.y, hit.mult_factor
		)
	if hit.mon != 0:
		add_mon(hit.mon, where.x, where.y)
	if hit.role == Role.GREEN:
		for effect: Effect in _effects:
			effect.on_power(self, hit)


func _vanish(peg: int) -> void:
	var where: SimPeg = simulation.pegs[peg]
	where.illusion = false
	simulation.remove_peg(peg)
	events.push(SimEvent.Kind.PEG_VANISHED, simulation.tick, -1, peg, where.x, where.y)


func _drain_areas() -> void:
	while _area_head < _area_count:
		var base: int = _area_head * _AREA_STRIDE
		_area_head += 1
		_explode(
			_areas[base], _areas[base + 1], _areas[base + 2], _areas[base + 3] as PegHit.Source
		)
	_area_head = 0
	_area_count = 0


func _explode(x: int, y: int, radius: int, source: PegHit.Source) -> void:
	events.push(SimEvent.Kind.AREA_HIT, simulation.tick, -1, -1, x, y, radius)
	var found: int = simulation.pegs_within(x, y, radius, _near)
	for index: int in found:
		var peg: int = _near[index]
		if _scored[peg] == 1 or simulation.pegs[peg].removed:
			continue
		_score(peg, source, -1)


## Hits, by fire, every burning peg due by [param now], in the order they caught fire.
func _burn_due_pegs(now: int) -> void:
	var due: int = 0
	var kept: int = 0
	for index: int in _burn_count:
		if _burn_due[index] <= now:
			_due[due] = _burning[index]
			due += 1
		else:
			_burning[kept] = _burning[index]
			_burn_due[kept] = _burn_due[index]
			kept += 1
	_burn_count = kept
	for index: int in due:
		var peg: int = _due[index]
		_is_burning[peg] = 0
		if _scored[peg] == 1 or simulation.pegs[peg].removed:
			continue
		score_hit(peg, PegHit.Source.FIRE, -1)


func _add_effect(effect: Effect) -> void:
	if effect != null:
		_effects.append(effect)


func _dispatch_wall_bounce() -> void:
	if shot_ball != null and shot_ball.effect != null:
		shot_ball.effect.on_wall_bounce(self)
	for effect: Effect in _effects:
		effect.on_wall_bounce(self)


func _dispatch_bucket() -> void:
	if shot_ball != null and shot_ball.effect != null:
		shot_ball.effect.on_bucket(self)
	for effect: Effect in _effects:
		effect.on_bucket(self)


func _resolve_shot() -> void:
	# Fire still pending when the last ball leaves lands now, before the shot is scored.
	_burn_due_pegs(_FLUSH)
	simulation.remove_lit_pegs()
	if shot_ball != null and shot_ball.effect != null:
		shot_ball.effect.on_shot_end(self)
	for effect: Effect in _effects:
		effect.on_shot_end(self)
	var tick: int = simulation.tick
	if _end_mult_factor != _PERMILLE:
		shot_mult = maxi(mult_floor, FixedMath.div_round(shot_mult * _end_mult_factor, _PERMILLE))
		events.push(SimEvent.Kind.SCORE_MULT_TIMES, tick, -1, -1, 0, 0, _end_mult_factor)
	var score: int = FixedMath.div_round(shot_points * shot_mult, _PERMILLE)
	total += score
	best_shot = maxi(best_shot, score)
	events.push(SimEvent.Kind.SHOT_SCORED, tick, -1, -1, 0, 0, score)
	_return_ball()
	if red_remaining() == 0:
		total = FixedMath.div_round(total * _config.matsuri_total_factor, _PERMILLE)
		outcome = Outcome.MATSURI
	elif total >= target:
		outcome = Outcome.TARGET_REACHED
	elif shots_left == 0:
		outcome = Outcome.FAILED
	else:
		_move_gold()
		for effect: Effect in _effects:
			effect.on_shot_scored(self)
	if outcome != Outcome.PLAYING:
		_finish_board(tick)


func _return_ball() -> void:
	if shot_ball == null:
		return
	if _keep_on_top:
		bag.push_top(shot_ball)
	elif shot_caught:
		bag.return_after_next(shot_ball)
	else:
		bag.discard(shot_ball)


func _finish_board(tick: int) -> void:
	result = _result
	result.outcome = outcome
	result.total = total
	result.shots_left = shots_left
	result.best_shot = best_shot
	result.interest_cap = _config.interest_cap
	for effect: Effect in _effects:
		effect.on_board_end(self, result)
	result.mon_earned = mon_earned
	events.push(SimEvent.Kind.BOARD_ENDED, tick, -1, -1, 0, 0, outcome)


## Purchased pegs replace random blue lanterns, never the gold one.
func _place_purchased(pegs: Array[PegDefinition]) -> void:
	for definition: PegDefinition in pegs:
		for copy: int in purchased_copies:
			var available: int = 0
			for peg: int in roles.size():
				if roles[peg] == Role.BLUE and not simulation.pegs[peg].removed:
					_candidates[available] = peg
					available += 1
			if available == 0:
				return
			place_special(_candidates[_rng.next_below(available)], definition)


func _refresh_attractors() -> void:
	for peg: int in roles.size():
		simulation.pegs[peg].attractor = roles[peg] == Role.RED


func _assign_roles() -> void:
	var count: int = simulation.pegs.size()
	roles.resize(count)
	roles.fill(Role.BLUE)
	_scored.resize(count)
	_candidates.resize(count)
	_colour_pegs()


## Colours the pegs in play, which are all blue so far: reds, then greens, then the gold.
func _colour_pegs() -> void:
	var in_play: int = pegs_in_play()
	var reds: int = mini(in_play, FixedMath.div_round(in_play * _config.red_permille, _PERMILLE))
	_assign_reds_by_zone(reds, in_play)
	var available: int = 0
	for peg: int in roles.size():
		if roles[peg] == Role.BLUE and not simulation.pegs[peg].removed:
			_candidates[available] = peg
			available += 1
	_candidates = _shuffled(_candidates, available)
	for i: int in mini(available, _config.green_count):
		roles[_candidates[i]] = Role.GREEN
	_move_gold()


## GDD: reds are stratified by zones so they spread across the board. Each zone gets the floor
## of its proportional share; the reds left over go to the largest remainders, lowest zone first.
func _assign_reds_by_zone(reds: int, count: int) -> void:
	if count == 0 or reds == 0:
		return
	var columns: int = maxi(1, _config.colour_zone_columns)
	var rows: int = maxi(1, _config.colour_zone_rows)
	var zone_pegs: Array[PackedInt32Array] = []
	for zone: int in columns * rows:
		zone_pegs.append(PackedInt32Array())
	for peg_index: int in roles.size():
		var peg: SimPeg = simulation.pegs[peg_index]
		if peg.removed:
			continue
		var column: int = clampi(peg.base_x * columns / _config.board_width, 0, columns - 1)
		var row: int = clampi(peg.base_y * rows / _config.board_height, 0, rows - 1)
		zone_pegs[row * columns + column].append(peg_index)
	var quotas: PackedInt32Array = PackedInt32Array()
	var remainders: PackedInt32Array = PackedInt32Array()
	var assigned: int = 0
	for members: PackedInt32Array in zone_pegs:
		quotas.append(reds * members.size() / count)
		remainders.append(reds * members.size() % count)
		assigned += quotas[quotas.size() - 1]
	for extra: int in reds - assigned:
		var best: int = 0
		for zone: int in remainders.size():
			if remainders[zone] > remainders[best]:
				best = zone
		quotas[best] += 1
		remainders[best] = -1
	for zone: int in zone_pegs.size():
		var members: PackedInt32Array = _shuffled(zone_pegs[zone], zone_pegs[zone].size())
		for i: int in quotas[zone]:
			roles[members[i]] = Role.RED


## Fisher-Yates over the first [param length] entries, drawing from the board stream. Packed
## arrays are copied on write, so the shuffled array is returned rather than changed in place.
func _shuffled(values: PackedInt32Array, length: int) -> PackedInt32Array:
	for i: int in range(length - 1, 0, -1):
		var j: int = _rng.next_below(i + 1)
		var swapped: int = values[i]
		values[i] = values[j]
		values[j] = swapped
	return values


## GDD: the single gold lantern moves to another blue lantern every shot.
func _move_gold() -> void:
	var available: int = 0
	for peg: int in roles.size():
		if roles[peg] == Role.BLUE and not simulation.pegs[peg].removed:
			_candidates[available] = peg
			available += 1
	if _gold >= 0 and not simulation.pegs[_gold].removed:
		roles[_gold] = Role.BLUE
	_gold = -1
	if available == 0:
		return
	_gold = _candidates[_rng.next_below(available)]
	roles[_gold] = Role.GOLD
