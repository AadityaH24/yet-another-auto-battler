extends RefCounted

const MapNodeData = preload("res://scripts/map/map_node_data.gd")
const MapGenerator = preload("res://scripts/map/map_generator.gd")

var act: int = 1
var nodes: Array = []
var current_node
var player_roster: Array[UnitData] = []
var gold: int = 10

func start_run(roster: Array[UnitData], starting_gold: int = 10):
	player_roster = []
	for u in roster:
		player_roster.append(u)
	act = 1
	gold = starting_gold
	_advance_act()

func _advance_act():
	nodes = MapGenerator.generate(act)
	current_node = null

func get_map_screen_data() -> Dictionary:
	return {
		"act": act,
		"nodes": nodes,
		"current": current_node,
	}

func on_node_completed():
	if current_node != null and current_node.node_type == MapNodeData.Type.BOSS:
		act += 1
		if act > 3:
			return "victory"
		_advance_act()
		return "next_act"
	return "continue"
