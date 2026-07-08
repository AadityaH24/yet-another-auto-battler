class_name CombatEngine

static func create_battle(player_data: Array[UnitData], enemy_data: Array[UnitData], grid_w: int = 4, grid_h: int = 4) -> BattleState:
	return _create_battle(player_data, enemy_data, [], grid_w, grid_h)

static func create_battle_with_positions(player_data: Array[UnitData], player_positions: Array[Vector2i], enemy_data: Array[UnitData], grid_w: int = 4, grid_h: int = 4) -> BattleState:
	return _create_battle(player_data, enemy_data, player_positions, grid_w, grid_h)

static func _create_battle(player_data: Array[UnitData], enemy_data: Array[UnitData], player_positions: Array[Vector2i], grid_w: int, grid_h: int) -> BattleState:
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

static func _apply_deployment_abilities(state: BattleState):
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
		for item in u.unit_data.items:
			if item.effect_type == ItemData.EffectType.FORTIFY:
				u.armor += item.effect_value

static func _item_hp(ud: UnitData) -> int:
	var total := 0
	for item in ud.items:
		total += item.hp_bonus
	return total

static func _max_unit_hp(unit: Node2D) -> int:
	return unit.unit_data.base_hp + _item_hp(unit.unit_data)

static func _has_item_effect(ud: UnitData, effect: int) -> bool:
	for item in ud.items:
		if item.effect_type == effect:
			return true
	return false

static func _get_item_value(ud: UnitData, effect: int) -> int:
	for item in ud.items:
		if item.effect_type == effect:
			return item.effect_value
	return 0

static func _apply_item_on_hit(state: BattleState, attacker: Node2D, target: Node2D, dmg: int):
	var ud = attacker.unit_data
	for item in ud.items:
		match item.effect_type:
			ItemData.EffectType.BURN_ON_HIT:
				target.apply_status("burn", item.effect_value)
			ItemData.EffectType.POISON_ON_HIT:
				target.apply_status("poison", item.effect_value)
			ItemData.EffectType.SNARE:
				target.apply_status("root", item.effect_value)
			ItemData.EffectType.LIFESTEAL:
				var heal := mini(item.effect_value, dmg)
				attacker.current_hp = mini(attacker.current_hp + heal, _max_unit_hp(attacker))

static func _apply_item_on_attacked(state: BattleState, attacker: Node2D, target: Node2D):
	var ud = target.unit_data
	for item in ud.items:
		match item.effect_type:
			ItemData.EffectType.THORNS:
				attacker.take_damage(item.effect_value)
				if not attacker.is_alive():
					state.tile_units.erase(attacker.grid_pos)
				EventBus.unit_damaged.emit(attacker, target, item.effect_value)

static func tick_all_statuses(state: BattleState):
	for u in state.units:
		if u.is_alive():
			u.tick_statuses()
	state.tile_infusions.clear()

static func on_turn_start(state: BattleState, unit: Node2D):
	if unit.unit_data.ability_id == "heal_aura":
		for dx in [-1, 1]:
			var adj := Vector2i(unit.grid_pos.x + dx, unit.grid_pos.y)
			if is_tile_valid(adj, state.grid_w, state.grid_h) and state.tile_units.has(adj):
				var ally = state.tile_units[adj]
				if ally.team == unit.team and ally.is_alive():
					ally.current_hp = mini(ally.current_hp + 1, _max_unit_hp(ally))
	if _has_item_effect(unit.unit_data, ItemData.EffectType.REGEN):
		unit.current_hp = mini(unit.current_hp + 1, _max_unit_hp(unit))

static func calculate_turn_order(state: BattleState) -> Array[Node2D]:
	var alive: Array[Node2D] = []
	for u in state.units:
		if u.is_alive():
			alive.append(u)
	alive.sort_custom(func(a: Node2D, b: Node2D): return a.current_speed > b.current_speed)
	return alive

static func execute_action(state: BattleState, actor: Node2D, action: BattleAction):
	match action.action_type:
		BattleAction.ActionType.ATTACK:
			apply_damage(state, actor, action.target_unit)
		BattleAction.ActionType.MOVE:
			_move_unit(state, actor, action.target_tile)
		BattleAction.ActionType.WAIT:
			pass
	actor.has_acted = true

static func _item_atk(ud: UnitData) -> int:
	var total := 0
	for item in ud.items:
		total += item.atk_bonus
	return total

static func _item_range(ud: UnitData) -> int:
	var total := 0
	for item in ud.items:
		total += item.range_bonus
	return total

static func apply_damage(state: BattleState, attacker: Node2D, target: Node2D):
	var dmg: int = attacker.unit_data.base_attack + _item_atk(attacker.unit_data)

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
			attacker.current_hp = mini(attacker.current_hp + heal_amt, _max_unit_hp(attacker))

		if attacker.unit_data.ability_id == "focus":
			state.marked_target = t

		_apply_affliction(state, attacker, t)
		_apply_item_on_hit(state, attacker, t, effective_dmg)
		_apply_item_on_attacked(state, attacker, t)

		EventBus.unit_damaged.emit(t, attacker, effective_dmg)
		if not t.is_alive():
			if _has_item_effect(attacker.unit_data, ItemData.EffectType.VAMPIRIC):
				var heal: int = _get_item_value(attacker.unit_data, ItemData.EffectType.VAMPIRIC)
				attacker.current_hp = mini(attacker.current_hp + heal, attacker.unit_data.base_hp + _item_hp(attacker.unit_data))
			state.tile_units.erase(t.grid_pos)
			EventBus.unit_destroyed.emit(t)

	var elem: int = attacker.unit_data.element_affinity
	if elem != Enums.ElementType.NONE:
		var aoe_tiles: Array[Vector2i] = get_aoe_tiles(state, attacker, target)
		for tile in aoe_tiles:
			if state.tile_infusions.has(tile):
				var existing: int = state.tile_infusions[tile]
				var combo: int = Enums.get_zone_combo(elem, existing)
				if combo != Enums.ComboEffect.NONE:
					_resolve_zone_combo(state, tile, combo)
			state.tile_infusions[tile] = elem

	check_win_condition(state)

static func _resolve_zone_combo(state: BattleState, tile: Vector2i, combo: int):
	var unit := state.tile_units.get(tile) as Node2D
	if not unit:
		return
	match combo:
		Enums.ComboEffect.WILDFIRE:
			unit.take_damage(2)
			EventBus.unit_damaged.emit(unit, null, 2)
			unit.apply_status("burn", 1)
		Enums.ComboEffect.STORM:
			var dir: int = 1 if unit.team == 0 else -1
			var push_pos: Vector2i = Vector2i(tile.x, tile.y + dir)
			if is_tile_valid(push_pos, state.grid_w, state.grid_h) and not state.tile_units.has(push_pos):
				state.tile_units.erase(unit.grid_pos)
				unit.grid_pos = push_pos
				state.tile_units[push_pos] = unit
		Enums.ComboEffect.MUD:
			unit.apply_status("root", 1)
			unit.apply_status("chill", 1)
		Enums.ComboEffect.STEAM:
			unit.take_damage(1)
			EventBus.unit_damaged.emit(unit, null, 1)

static func _grid_combo_bonus(state: BattleState, unit: Node2D) -> int:
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

static func _apply_affliction(state: BattleState, attacker: Node2D, target: Node2D):
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

static func _has_guard_boost(state: BattleState, unit: Node2D) -> bool:
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

static func get_aoe_targets(state: BattleState, attacker: Node2D, target: Node2D) -> Array[Node2D]:
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

static func get_aoe_tiles(state: BattleState, attacker: Node2D, target: Node2D) -> Array[Vector2i]:
	var aoe: int = attacker.unit_data.aoe_type
	if aoe == Enums.AOEType.SINGLE:
		return [target.grid_pos]

	var results: Array[Vector2i] = [target.grid_pos]
	var tx: int = target.grid_pos.x
	var ty: int = target.grid_pos.y

	match aoe:
		Enums.AOEType.CLEAVE_SIDES:
			for dx in [-1, 1]:
				var p: Vector2i = Vector2i(tx + dx, ty)
				if is_tile_valid(p, state.grid_w, state.grid_h):
					results.append(p)

		Enums.AOEType.LINE:
			var dir: int = -1 if attacker.team == 0 else 1
			var y: int = ty + dir
			while y >= 0 and y < state.grid_h:
				results.append(Vector2i(tx, y))
				if state.tile_units.has(Vector2i(tx, y)):
					break
				y += dir

		Enums.AOEType.SPLASH_ORTHO:
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var p: Vector2i = target.grid_pos + d
				if is_tile_valid(p, state.grid_w, state.grid_h):
					results.append(p)

	return results

static func _move_unit(state: BattleState, unit: Node2D, to_pos: Vector2i):
	if unit.is_rooted:
		return
	state.tile_units.erase(unit.grid_pos)
	unit.grid_pos = to_pos
	state.tile_units[to_pos] = unit

	if state.tile_infusions.has(to_pos):
		var elem: int = state.tile_infusions[to_pos]
		match elem:
			Enums.ElementType.FIRE:
				unit.apply_status("burn", 1)
			Enums.ElementType.WATER:
				unit.apply_status("chill", 1)
			Enums.ElementType.EARTH:
				unit.apply_status("root", 1)

static func check_win_condition(state: BattleState) -> bool:
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