class_name BattleState extends RefCounted

var turn_number: int = 0
var units: Array = []
var tile_units: Dictionary = {}
var winner: int = -1
var marked_target = null
var grid_w: int = 4
var grid_h: int = 4

func get_units_on_team(team: int) -> Array:
	var result: Array = []
	for u in units:
		if u.team == team and u.is_alive():
			result.append(u)
	return result

func is_over() -> bool:
	return winner != -1
