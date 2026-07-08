class_name BattleAction extends RefCounted

enum ActionType { MOVE, ATTACK, WAIT }

var action_type: ActionType
var target_tile: Vector2i
var target_unit: Node2D
