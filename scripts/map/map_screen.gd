extends CanvasLayer

signal node_selected(node)

const MapNodeData = preload("res://scripts/map/map_node_data.gd")

var _nodes: Array = []
var _current_node
var _act: int
var _node_btns: Dictionary = {}

var _act_label: Label
var _line_nodes: Node2D

const NODE_W: int = 120
const NODE_H: int = 50
const LAYER_GAP: int = 110

func _init():
	layer = 2

func _ready():
	_build_background()

func show_map(act: int, nodes: Array, current):
	_act = act
	_nodes = nodes
	_current_node = current
	_build_map()

func _build_background():
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_act_label = Label.new()
	_act_label.position = Vector2(20, 20)
	_act_label.size = Vector2(200, 30)
	_act_label.add_theme_color_override("font_color", Color.WHITE)
	_act_label.add_theme_font_size_override("font_size", 24)
	add_child(_act_label)

	_line_nodes = Node2D.new()
	add_child(_line_nodes)

func _build_map():
	var vs := Vector2(get_viewport().size)
	_act_label.text = "Act %d" % _act

	for child in _line_nodes.get_children():
		child.queue_free()
	for btn in _node_btns.values():
		btn.queue_free()
	_node_btns.clear()

	var layers_dict: Dictionary = {}
	for n in _nodes:
		if not layers_dict.has(n.layer):
			layers_dict[n.layer] = []
		layers_dict[n.layer].append(n)

	var max_slots := 0
	for layer_nodes in layers_dict.values():
		if layer_nodes.size() > max_slots:
			max_slots = layer_nodes.size()

	var slot_w := floori(vs.x * 0.14)
	if slot_w < 140:
		slot_w = 140

	var layout_w := (max_slots - 1) * slot_w + NODE_W
	var start_x := (vs.x - layout_w) / 2

	var layer_count := layers_dict.size()
	var layout_h := (layer_count - 1) * LAYER_GAP + NODE_H
	var start_y := (vs.y - layout_h) / 2

	for n in _nodes:
		var pos := Vector2(start_x + n.slot * slot_w, start_y + n.layer * LAYER_GAP)
		var btn := _make_node_button(n, pos)
		_line_nodes.add_child(btn)
		_node_btns[n] = btn

	for n in _nodes:
		if not _node_btns.has(n):
			continue
		var from_pos: Vector2 = _node_btns[n].position + Vector2(NODE_W / 2, NODE_H)
		for conn in n.connections:
			if not _node_btns.has(conn):
				continue
			var to_pos: Vector2 = _node_btns[conn].position + Vector2(NODE_W / 2, 0)
			var line := _make_line(from_pos, to_pos, Color(0.3, 0.3, 0.35, 0.5))
			_line_nodes.add_child(line)

func _make_node_button(n, pos: Vector2) -> Button:
	var b := Button.new()
	b.position = pos
	b.size = Vector2(NODE_W, NODE_H)
	b.text = n.node_name

	var colors := _node_colors(n.node_type)
	var norm_c = colors[0]
	var hover_c = colors[1]

	var sn := StyleBoxFlat.new()
	sn.bg_color = norm_c
	sn.corner_radius_top_left = 6
	sn.corner_radius_top_right = 6
	sn.corner_radius_bottom_left = 6
	sn.corner_radius_bottom_right = 6
	sn.border_width_left = 1
	sn.border_width_right = 1
	sn.border_width_top = 1
	sn.border_width_bottom = 1
	sn.border_color = Color(0.5, 0.5, 0.6, 0.3)
	b.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = hover_c
	sh.corner_radius_top_left = 6
	sh.corner_radius_top_right = 6
	sh.corner_radius_bottom_left = 6
	sh.corner_radius_bottom_right = 6
	sh.border_width_left = 2
	sh.border_width_right = 2
	sh.border_width_top = 2
	sh.border_width_bottom = 2
	sh.border_color = Color(0.8, 0.8, 1.0, 0.5)
	b.add_theme_stylebox_override("hover", sh)

	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.15, 0.15, 0.18)
	sd.corner_radius_top_left = 6
	sd.corner_radius_top_right = 6
	sd.corner_radius_bottom_left = 6
	sd.corner_radius_bottom_right = 6
	b.add_theme_stylebox_override("disabled", sd)

	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_font_size_override("font_size", 12)

	var is_connected := false
	if _current_node == null:
		is_connected = n.layer == 0
	else:
		is_connected = _current_node.connections.has(n)

	is_connected = is_connected and not n.completed

	var is_current = n == _current_node

	if is_current:
		var sc := StyleBoxFlat.new()
		sc.bg_color = Color(0.3, 0.6, 0.3)
		sc.corner_radius_top_left = 6
		sc.corner_radius_top_right = 6
		sc.corner_radius_bottom_left = 6
		sc.corner_radius_bottom_right = 6
		sc.border_width_left = 2
		sc.border_width_right = 2
		sc.border_width_top = 2
		sc.border_width_bottom = 2
		sc.border_color = Color(0.6, 1.0, 0.6)
		b.add_theme_stylebox_override("normal", sc)

	elif n.completed:
		b.disabled = true

	elif not is_connected:
		b.disabled = true

	else:
		b.pressed.connect(_on_node_pressed.bind(n))

	return b

func _make_line(from: Vector2, to: Vector2, color: Color) -> Node2D:
	var n := Node2D.new()
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.width = 2
	line.default_color = color
	n.add_child(line)
	return n

func _on_node_pressed(n):
	n.completed = true
	_current_node = n
	node_selected.emit(n)

func _node_colors(type: int) -> Array:
	match type:
		MapNodeData.Type.BATTLE:
			return [Color(0.25, 0.3, 0.45), Color(0.35, 0.4, 0.55)]
		MapNodeData.Type.ELITE:
			return [Color(0.45, 0.25, 0.3), Color(0.55, 0.35, 0.4)]
		MapNodeData.Type.BOSS:
			return [Color(0.5, 0.15, 0.15), Color(0.6, 0.25, 0.25)]
		MapNodeData.Type.SHOP:
			return [Color(0.3, 0.4, 0.25), Color(0.4, 0.55, 0.35)]
		MapNodeData.Type.TREASURE:
			return [Color(0.4, 0.35, 0.2), Color(0.55, 0.5, 0.3)]
		MapNodeData.Type.REST:
			return [Color(0.25, 0.35, 0.4), Color(0.35, 0.45, 0.55)]
	return [Color(0.2, 0.2, 0.2), Color(0.3, 0.3, 0.3)]
