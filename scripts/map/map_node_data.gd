class_name MapNodeData extends RefCounted

enum Type { BATTLE, ELITE, BOSS, SHOP, TREASURE, REST }

var node_type: int
var node_name: String
var connections: Array[MapNodeData] = []
var layer: int
var slot: int
var completed: bool = false
var grid_w: int = 4
var grid_h: int = 4
var enemy_budget: int = 8
