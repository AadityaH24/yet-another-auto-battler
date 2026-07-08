class_name BattleState extends RefCounted

var turn_number: int = 0
var units: Array[UnitInstance] = []
var tile_units: Dictionary = {}
var winner: int = -1
var marked_target: Node2D
var grid_w: int = 4
var grid_h: int = 4
var tile_infusions: Dictionary = {}

func get_units_on_team(team: int) -> Array[UnitInstance]:
	var result: Array[UnitInstance] = []
	for u in units:
		if u.team == team and u.is_alive():
			result.append(u)
	return result

func is_over() -> bool:
	return winner != -1
