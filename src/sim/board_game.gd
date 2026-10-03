@tool
class_name BoardGame
## One board played under the GDD rules: coloured lanterns, shots scored as points x mult,
## a limited number of shots, and victory by score target or by Matsuri.
##
## The board seed and the list of shot inputs fully determine a game, which makes it replayable.

enum Outcome { PLAYING, TARGET_REACHED, MATSURI, FAILED }
enum Role { BLUE, RED, GREEN, GOLD }

const _PERMILLE: int = FixedMath.PERMILLE

var simulation: BoardSimulation
## Shared with [member simulation]: physics events followed by the scoring events they caused.
var events: SimEventQueue
var shots_left: int = 0
var target: int = 0
var total: int = 0
var shot_points: int = 0
## Mult of the current shot, in permille.
var shot_mult: int = _PERMILLE
var outcome: Outcome = Outcome.PLAYING
## [enum Role] of each peg, by peg index.
var roles: PackedInt32Array = PackedInt32Array()

var _config: BalanceConfig
var _rng: Pcg32
var _definitions: Array[PegDefinition] = []
var _scored: PackedByteArray = PackedByteArray()
var _candidates: PackedInt32Array = PackedInt32Array()
var _gold: int = -1
var _refunded: bool = false


## [param board] must already hold its pegs. [param rng] is the board's own random stream.
func _init(board: BoardSimulation, config: BalanceConfig, base_pegs: BasePegs, rng: Pcg32) -> void:
	simulation = board
	events = board.events
	_config = config
	_rng = rng
	_definitions = [base_pegs.blue, base_pegs.red, base_pegs.green, base_pegs.gold]
	shots_left = config.shots_per_board
	target = config.first_board_target
	_assign_roles()


func definition_of(peg: int) -> PegDefinition:
	return _definitions[roles[peg]]


func red_remaining() -> int:
	var count: int = 0
	for peg: int in roles.size():
		if roles[peg] == Role.RED and not simulation.pegs[peg].removed:
			count += 1
	return count


func can_shoot() -> bool:
	return outcome == Outcome.PLAYING and shots_left > 0 and not simulation.is_shot_active()


## Starts a shot. Returns false when the board is over or a shot is already in flight.
func shoot(input: ShotInput) -> bool:
	if not can_shoot():
		return false
	shot_points = 0
	shot_mult = _PERMILLE
	_scored.fill(0)
	_refunded = false
	shots_left -= 1
	simulation.launch(input)
	return true


## Advances the board clock between shots; see [method BoardSimulation.idle_step].
func idle_step() -> void:
	simulation.idle_step()


## Advances the simulation one tick and applies the board rules to what happened.
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
				score_hit(event.target, event.tick)
			SimEvent.Kind.BUCKET_CATCH:
				# GDD: a ball caught by the bucket returns to the bag, so the shot is free.
				if not _refunded:
					_refunded = true
					shots_left += 1
			SimEvent.Kind.SHOT_RESOLVED:
				_resolve_shot(event.tick)


## Applies the scoring of a hit on [param peg], once per shot. Called for every PEG_HIT; effects
## that hit pegs without touching them (such as Explosive or Onibi) will call it too.
func score_hit(peg: int, tick: int) -> void:
	if _scored[peg] == 1:
		return
	_scored[peg] = 1
	var definition: PegDefinition = definition_of(peg)
	var where: SimPeg = simulation.pegs[peg]
	if definition.points != 0:
		shot_points += definition.points
		events.push(SimEvent.Kind.SCORE_POINTS, tick, -1, peg, where.x, where.y, definition.points)
	if definition.mult_add != 0:
		shot_mult += definition.mult_add
		events.push(
			SimEvent.Kind.SCORE_MULT_ADD, tick, -1, peg, where.x, where.y, definition.mult_add
		)
	if definition.mult_factor != _PERMILLE:
		shot_mult = FixedMath.div_round(shot_mult * definition.mult_factor, _PERMILLE)
		events.push(
			SimEvent.Kind.SCORE_MULT_TIMES, tick, -1, peg, where.x, where.y, definition.mult_factor
		)


func _assign_roles() -> void:
	var count: int = simulation.pegs.size()
	roles.resize(count)
	roles.fill(Role.BLUE)
	_scored.resize(count)
	_candidates.resize(count)
	var reds: int = mini(count, FixedMath.div_round(count * _config.red_permille, _PERMILLE))
	_assign_reds_by_zone(reds)
	var available: int = 0
	for peg: int in count:
		if roles[peg] == Role.BLUE:
			_candidates[available] = peg
			available += 1
	_candidates = _shuffled(_candidates, available)
	for i: int in mini(available, _config.green_count):
		roles[_candidates[i]] = Role.GREEN
	_move_gold()


## GDD: reds are stratified by zones so they spread across the board. Each zone gets the floor
## of its proportional share; the reds left over go to the largest remainders, lowest zone first.
func _assign_reds_by_zone(reds: int) -> void:
	var count: int = roles.size()
	if count == 0 or reds == 0:
		return
	var columns: int = maxi(1, _config.colour_zone_columns)
	var rows: int = maxi(1, _config.colour_zone_rows)
	var zone_pegs: Array[PackedInt32Array] = []
	for zone: int in columns * rows:
		zone_pegs.append(PackedInt32Array())
	for peg_index: int in count:
		var peg: SimPeg = simulation.pegs[peg_index]
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


func _resolve_shot(tick: int) -> void:
	var score: int = FixedMath.div_round(shot_points * shot_mult, _PERMILLE)
	total += score
	events.push(SimEvent.Kind.SHOT_SCORED, tick, -1, -1, 0, 0, score)
	if red_remaining() == 0:
		total = FixedMath.div_round(total * _config.matsuri_total_factor, _PERMILLE)
		outcome = Outcome.MATSURI
	elif total >= target:
		outcome = Outcome.TARGET_REACHED
	elif shots_left == 0:
		outcome = Outcome.FAILED
	else:
		_move_gold()
	if outcome != Outcome.PLAYING:
		events.push(SimEvent.Kind.BOARD_ENDED, tick, -1, -1, 0, 0, outcome)
