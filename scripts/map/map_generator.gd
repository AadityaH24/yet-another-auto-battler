extends RefCounted

static func generate(act: int) -> Array[MapNodeData]:
	var layers := _get_layer_count(act)
	var all_nodes: Array[MapNodeData] = []

	for l in range(layers):
		var count := _rng(l, 2, 4)
		for s in range(count):
			var n := MapNodeData.new()
			n.layer = l
			n.slot = s
			if l == layers - 1:
				n.node_type = MapNodeData.Type.BOSS
				n.node_name = _boss_name(act)
				n.grid_w = 5
				n.grid_h = 5
			elif l == 0:
				n.node_type = MapNodeData.Type.BATTLE
				n.node_name = "Entry"
			else:
				n.node_type = _pick_node_type(act, l)
				n.node_name = _type_name(n.node_type)
				if n.node_type == MapNodeData.Type.ELITE:
					n.grid_w = 3
					n.grid_h = 4
			n.enemy_budget = _calc_budget(act, l, n.node_type)
			all_nodes.append(n)

	for n in all_nodes:
		if n.layer + 1 >= layers:
			continue
		var next_nodes: Array[MapNodeData] = []
		for other in all_nodes:
			if other.layer == n.layer + 1:
				next_nodes.append(other)

		if next_nodes.size() == 0:
			continue

		var connect_count := mini(2, next_nodes.size())
		var pool := next_nodes.duplicate()
		pool.shuffle()
		for i in range(connect_count):
			n.connections.append(pool[i])

		if n.connections.size() == 0:
			n.connections.append(next_nodes[randi() % next_nodes.size()])

	return all_nodes

static func _calc_budget(act: int, layer: int, node_type: int) -> int:
	var base: int = 5 + act * 2
	var layer_bonus: int = layer * 2
	var type_bonus: int = 0
	match node_type:
		MapNodeData.Type.ELITE:
			type_bonus = 4
		MapNodeData.Type.BOSS:
			type_bonus = 8
	return base + layer_bonus + type_bonus

static func _rng(seed_val: int, min_v: int, max_v: int) -> int:
	var s := seed_val * 7 + 13
	return min_v + (s % (max_v - min_v + 1))

static func _get_layer_count(act: int) -> int:
	return act + 3

static func _pick_node_type(act: int, layer: int) -> int:
	var roll := randi() % 100
	var battle_w := 45
	var elite_w := 12
	var shop_w := 15
	var treasure_w := 15

	if act >= 2:
		battle_w = 35
		elite_w = 20
	if act >= 3:
		battle_w = 30
		elite_w = 25

	if roll < battle_w:
		return MapNodeData.Type.BATTLE
	roll -= battle_w
	if roll < elite_w:
		return MapNodeData.Type.ELITE
	roll -= elite_w
	if roll < shop_w:
		return MapNodeData.Type.SHOP
	roll -= shop_w
	if roll < treasure_w:
		return MapNodeData.Type.TREASURE
	return MapNodeData.Type.REST

static func _type_name(t: int) -> String:
	match t:
		MapNodeData.Type.BATTLE:
			return "Battle"
		MapNodeData.Type.ELITE:
			return "Elite"
		MapNodeData.Type.BOSS:
			return "Boss"
		MapNodeData.Type.SHOP:
			return "Shop"
		MapNodeData.Type.TREASURE:
			return "Treasure"
		MapNodeData.Type.REST:
			return "Rest"
	return "?"

static func _boss_name(act: int) -> String:
	var names := ["Goblin Chief", "Wraith Lord", "Ancient Dragon"]
	return names[act - 1] if act <= names.size() else "Final Boss"