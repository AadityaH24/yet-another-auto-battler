class_name AIController extends RefCounted

func decide_action(state: BattleState, unit) -> BattleAction:
	var range_dist: int = unit.unit_data.base_range
	var in_range := get_enemies_in_range(state, unit, range_dist)
	if in_range.size() > 0:
		var target = in_range[0]
		var best_score: int = -999
		for e in in_range:
			var score: int = -e.current_hp
			if unit.unit_data.aoe_type != Enums.AOEType.SINGLE:
				var splash_count: int = _count_splash_targets(state, unit, e)
				score += splash_count * 3
			if score > best_score:
				best_score = score
				target = e
		var action := BattleAction.new()
		action.action_type = BattleAction.ActionType.ATTACK
		action.target_unit = target
		return action

	var nearest = find_nearest_enemy(state, unit)
	if nearest != null:
		var tile = get_next_tile_toward(unit.grid_pos, nearest.grid_pos, state, state.grid_w, state.grid_h)
		if tile != null:
			var action := BattleAction.new()
			action.action_type = BattleAction.ActionType.MOVE
			action.target_tile = tile
			return action

	var action := BattleAction.new()
	action.action_type = BattleAction.ActionType.WAIT
	return action

func get_enemies_in_range(state: BattleState, unit, range_dist: int) -> Array:
	var enemies: Array = []
	for u in state.units:
		if not u.is_alive() or u.team == unit.team:
			continue
		var d: int = abs(u.grid_pos.x - unit.grid_pos.x) + abs(u.grid_pos.y - unit.grid_pos.y)
		if d <= range_dist:
			enemies.append(u)
	return enemies

func find_nearest_enemy(state: BattleState, unit):
	var nearest = null
	var min_dist: int = 999
	for u in state.units:
		if not u.is_alive() or u.team == unit.team:
			continue
		var d: int = abs(u.grid_pos.x - unit.grid_pos.x) + abs(u.grid_pos.y - unit.grid_pos.y)
		if d < min_dist:
			min_dist = d
			nearest = u
	return nearest

func get_next_tile_toward(from: Vector2i, to: Vector2i, state: BattleState, grid_w: int, grid_h: int):
	var dx := to.x - from.x
	var dy := to.y - from.y

	var candidates: Array[Vector2i] = []
	if abs(dx) >= abs(dy):
		candidates.append(Vector2i(from.x + sign(dx), from.y))
		candidates.append(Vector2i(from.x, from.y + sign(dy)))
	else:
		candidates.append(Vector2i(from.x, from.y + sign(dy)))
		candidates.append(Vector2i(from.x + sign(dx), from.y))

	for c in candidates:
		if CombatEngine.is_tile_valid(c, grid_w, grid_h) and not state.tile_units.has(c):
			return c

	if abs(dx) >= abs(dy):
		candidates.append(Vector2i(from.x, from.y + sign(dy)))
		candidates.append(Vector2i(from.x + sign(dx), from.y))
	else:
		candidates.append(Vector2i(from.x + sign(dx), from.y))
		candidates.append(Vector2i(from.x, from.y + sign(dy)))

	for c in candidates:
		if CombatEngine.is_tile_valid(c, grid_w, grid_h) and not state.tile_units.has(c):
			return c

	return null

func _count_splash_targets(state: BattleState, attacker, target) -> int:
	var count: int = 0
	var tx: int = target.grid_pos.x
	var ty: int = target.grid_pos.y
	match attacker.unit_data.aoe_type:
		Enums.AOEType.CLEAVE_SIDES:
			for dx in [-1, 1]:
				var p: Vector2i = Vector2i(tx + dx, ty)
				if CombatEngine.is_tile_valid(p, state.grid_w, state.grid_h) and state.tile_units.has(p):
					if state.tile_units[p].team != attacker.team:
						count += 1
		Enums.AOEType.SPLASH_ORTHO:
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var p: Vector2i = target.grid_pos + d
				if CombatEngine.is_tile_valid(p, state.grid_w, state.grid_h) and state.tile_units.has(p):
					if state.tile_units[p].team != attacker.team:
						count += 1
	return count