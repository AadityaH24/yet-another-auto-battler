extends Node

func create_battle(player_data: Array[UnitData], enemy_data: Array[UnitData], grid_w: int = 4, grid_h: int = 4) -> BattleState:
	return _create_battle(player_data, enemy_data, [], grid_w, grid_h)

func create_battle_with_positions(player_data: Array[UnitData], player_positions: Array[Vector2i], enemy_data: Array[UnitData], grid_w: int = 4, grid_h: int = 4) -> BattleState:
	return _create_battle(player_data, enemy_data, player_positions, grid_w, grid_h)

func _create_battle(player_data: Array[UnitData], enemy_data: Array[UnitData], player_positions: Array[Vector2i], grid_w: int, grid_h: int) -> BattleState:
	var state := BattleState.new()
	state.grid_w = grid_w
	state.grid_h = grid_h

	var unit_instance_scene := preload("res://scenes/battle/unit_instance.tscn")

	for i in player_data.size():
		var u := unit_instance_scene.instantiate()
		u.unit_data = player_data[i]
		u.team = 0
		if i < player_positions.size():
			u.grid_pos = player_positions[i]
		else:
			var start_row: int = max(0, state.grid_h - 2)
			u.grid_pos = Vector2i(i % state.grid_w, start_row + i / state.grid_w)
		u.name = "PlayerUnit_%d" % i
		state.units.append(u)
		state.tile_units[u.grid_pos] = u

	for i in enemy_data.size():
		var u := unit_instance_scene.instantiate()
		u.unit_data = enemy_data[i]
		u.team = 1
		var grid_w_max: int = maxi(1, state.grid_w)
		u.grid_pos = Vector2i(i % grid_w_max, i / grid_w_max)
		u.name = "EnemyUnit_%d" % i
		state.units.append(u)
		state.tile_units[u.grid_pos] = u

	_apply_deployment_abilities(state)
	return state

func _apply_deployment_abilities(state: BattleState):
	for u in state.units:
		match u.unit_data.ability_id:
			"shield_wall":
				var behind := Vector2i(u.grid_pos.x, u.grid_pos.y + 1)
				if behind.y < state.grid_h and state.tile_units.has(behind):
					var target = state.tile_units[behind]
					if target.team == u.team:
						target.armor += 2
			"impale":
				for y in range(u.grid_pos.y - 1, -1, -1):
					var check := Vector2i(u.grid_pos.x, y)
					if state.tile_units.has(check):
						var target = state.tile_units[check]
						if target.team != u.team:
							target.take_damage(1)
							if not target.is_alive():
								state.tile_units.erase(target.grid_pos)
							break

func on_turn_start(state: BattleState, unit):
	for u in state.units:
		if u.is_alive():
			u.tick_statuses()

	if unit.unit_data.ability_id == "heal_aura":
		for dx in [-1, 1]:
			var adj := Vector2i(unit.grid_pos.x + dx, unit.grid_pos.y)
			if is_tile_valid(adj, state.grid_w, state.grid_h) and state.tile_units.has(adj):
				var ally = state.tile_units[adj]
				if ally.team == unit.team and ally.is_alive():
					ally.current_hp = mini(ally.current_hp + 1, ally.unit_data.base_hp)

func calculate_turn_order(state: BattleState) -> Array:
	var alive: Array = []
	for u in state.units:
		if u.is_alive():
			alive.append(u)
	alive.sort_custom(func(a, b): return a.current_speed > b.current_speed)
	return alive

func execute_action(state: BattleState, actor, action: BattleAction):
	match action.action_type:
		BattleAction.ActionType.ATTACK:
			apply_damage(state, actor, action.target_unit)
		BattleAction.ActionType.MOVE:
			_move_unit(state, actor, action.target_tile)
		BattleAction.ActionType.WAIT:
			pass
	actor.has_acted = true

func apply_damage(state: BattleState, attacker, target):
	var dmg: int = attacker.unit_data.base_attack

	if attacker.unit_data.ability_id == "bloodrage" and attacker.current_hp <= attacker.unit_data.base_hp / 2:
		dmg += 1

	if attacker.unit_data.ability_id == "flanking" and attacker.grid_pos.x != target.grid_pos.x:
		dmg += 1

	if state.marked_target == target:
		dmg += 1

	dmg += _grid_combo_bonus(state, attacker)

	var elem_adv: int = Enums.element_advantage(attacker.unit_data.element_affinity, target.unit_data.element_affinity)
	dmg += elem_adv

	var targets: Array = get_aoe_targets(state, attacker, target)
	for t in targets:
		var final_dmg: int = dmg

		if _has_guard_boost(state, t):
			final_dmg = max(0, final_dmg - 1)

		var effective_dmg: int = max(0, final_dmg - t.armor)
		t.take_damage(effective_dmg)

		if attacker.unit_data.ability_id == "soul_leech":
			var heal_amt: int = ceili(effective_dmg * 0.5)
			attacker.current_hp = mini(attacker.current_hp + heal_amt, attacker.unit_data.base_hp)

		if attacker.unit_data.ability_id == "focus":
			state.marked_target = t

		_apply_affliction(state, attacker, t)

		EventBus.unit_damaged.emit(t, attacker, effective_dmg)
		if not t.is_alive():
			state.tile_units.erase(t.grid_pos)
			EventBus.unit_destroyed.emit(t)

	check_win_condition(state)

func _grid_combo_bonus(state: BattleState, unit) -> int:
	var elem: int = unit.unit_data.element_affinity
	if elem == Enums.ElementType.NONE:
		return 0
	var combo_elem: int = Enums.next_element(elem)
	for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		var adj: Vector2i = unit.grid_pos + d
		if state.tile_units.has(adj):
			var ally = state.tile_units[adj]
			if ally.team == unit.team and ally.unit_data.element_affinity == combo_elem:
				return 1
	return 0

func _apply_affliction(state: BattleState, attacker, target):
	var elem: int = attacker.unit_data.element_affinity
	match elem:
		Enums.ElementType.FIRE:
			target.apply_status("burn", 2)
		Enums.ElementType.WIND:
			var dir: int = 1 if attacker.team == 0 else -1
			var push_pos: Vector2i = Vector2i(target.grid_pos.x, target.grid_pos.y + dir)
			if is_tile_valid(push_pos, state.grid_w, state.grid_h) and not state.tile_units.has(push_pos):
				state.tile_units.erase(target.grid_pos)
				target.grid_pos = push_pos
				state.tile_units[push_pos] = target
		Enums.ElementType.WATER:
			target.apply_status("chill", 2)
		Enums.ElementType.EARTH:
			target.apply_status("root", 1)

func _has_guard_boost(state: BattleState, unit) -> bool:
	for dx in [-1, 1]:
		var adj: Vector2i = Vector2i(unit.grid_pos.x + dx, unit.grid_pos.y)
		if state.tile_units.has(adj):
			var ally = state.tile_units[adj]
			if ally.team == unit.team and ally.unit_data.ability_id == "guard":
				return true
	for dy in [-1, 1]:
		var adj: Vector2i = Vector2i(unit.grid_pos.x, unit.grid_pos.y + dy)
		if state.tile_units.has(adj):
			var ally = state.tile_units[adj]
			if ally.team == unit.team and ally.unit_data.ability_id == "guard":
				return true
	return false

func get_aoe_targets(state: BattleState, attacker, target) -> Array:
	var aoe: int = attacker.unit_data.aoe_type
	if aoe == Enums.AOEType.SINGLE:
		return [target]

	var results: Array = [target]
	var tx: int = target.grid_pos.x
	var ty: int = target.grid_pos.y

	match aoe:
		Enums.AOEType.CLEAVE_SIDES:
			for dx in [-1, 1]:
				var p: Vector2i = Vector2i(tx + dx, ty)
				if is_tile_valid(p, state.grid_w, state.grid_h) and state.tile_units.has(p):
					var u = state.tile_units[p]
					if u.team != attacker.team:
						results.append(u)

		Enums.AOEType.LINE:
			var dir: int = -1 if attacker.team == 0 else 1
			var y: int = ty + dir
			while y >= 0 and y < state.grid_h:
				var p: Vector2i = Vector2i(tx, y)
				if state.tile_units.has(p):
					var u = state.tile_units[p]
					if u.team != attacker.team:
						results.append(u)
				y += dir

		Enums.AOEType.SPLASH_ORTHO:
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var p: Vector2i = target.grid_pos + d
				if is_tile_valid(p, state.grid_w, state.grid_h) and state.tile_units.has(p):
					var u = state.tile_units[p]
					if u.team != attacker.team:
						results.append(u)

	return results

func _move_unit(state: BattleState, unit, to_pos: Vector2i):
	if unit.is_rooted:
		return
	state.tile_units.erase(unit.grid_pos)
	unit.grid_pos = to_pos
	state.tile_units[to_pos] = unit

func check_win_condition(state: BattleState) -> bool:
	var player_alive := false
	var enemy_alive := false
	for u in state.units:
		if not u.is_alive():
			continue
		if u.team == 0:
			player_alive = true
		else:
			enemy_alive = true

	if not player_alive:
		state.winner = 1
		return true
	if not enemy_alive:
		state.winner = 0
		return true
	return false

static func is_tile_valid(pos: Vector2i, grid_w: int, grid_h: int) -> bool:
	return pos.x >= 0 and pos.x < grid_w and pos.y >= 0 and pos.y < grid_h