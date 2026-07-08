extends CanvasLayer

signal node_selected(node: MapNodeData)

var _nodes: Array[MapNodeData] = []
var _current_node: MapNodeData
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

func show_map(act: int, nodes: Array[MapNodeData], current: MapNodeData):
	_act = act
	_nodes = nodes
	_current_node = current
	_build_map()

func _build_background():
	add_child(ThemeHelper.make_bg())

	_act_label = Label.new()
	_act_label.position = Vector2(20, 20)
	_act_label.size = Vector2(200, 30)
	_act_label.add_theme_color_override("font_color", ThemeHelper.GOLD)
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
			var line := _make_line(from_pos, to_pos, ThemeHelper.BORDER)
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
	sn.border_color = ThemeHelper.GOLD
	sn.border_width_top = 1
	sn.border_width_left = 1
	sn.border_width_bottom = 1
	sn.border_width_right = 1
	sn.corner_radius_top_left = 4
	sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4
	sn.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = hover_c
	sh.border_color = ThemeHelper.GOLD_BRIGHT
	sh.border_width_top = 2
	sh.border_width_left = 2
	sh.border_width_bottom = 2
	sh.border_width_right = 2
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)

	var sd := StyleBoxFlat.new()
	sd.bg_color = ThemeHelper.BG_DARK
	sd.border_color = ThemeHelper.BORDER
	sd.border_width_top = 1
	sd.border_width_left = 1
	sd.border_width_bottom = 1
	sd.border_width_right = 1
	sd.corner_radius_top_left = 4
	sd.corner_radius_top_right = 4
	sd.corner_radius_bottom_left = 4
	sd.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("disabled", sd)

	b.add_theme_color_override("font_color", ThemeHelper.TEXT)
	b.add_theme_font_size_override("font_size", 12)

	var is_node_connected := false
	if _current_node == null:
		is_node_connected = n.layer == 0
	else:
		is_node_connected = _current_node.connections.has(n)

	is_node_connected = is_node_connected and not n.completed

	var is_current = n == _current_node

	if is_current:
		var sc := StyleBoxFlat.new()
		sc.bg_color = ThemeHelper.SUCCESS
		sc.border_color = Color("#a0e8a0")
		sc.border_width_top = 2
		sc.border_width_left = 2
		sc.border_width_bottom = 2
		sc.border_width_right = 2
		sc.corner_radius_top_left = 4
		sc.corner_radius_top_right = 4
		sc.corner_radius_bottom_left = 4
		sc.corner_radius_bottom_right = 4
		b.add_theme_stylebox_override("normal", sc)

	elif n.completed:
		b.disabled = true

	elif not is_node_connected:
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

func _on_node_pressed(n: MapNodeData):
	n.completed = true
	_current_node = n
	node_selected.emit(n)

func _node_colors(type: int) -> Array[Color]:
	match type:
		MapNodeData.Type.BATTLE:
			return [Color("#1a1a30"), Color("#2a2a50")]
		MapNodeData.Type.ELITE:
			return [Color("#301a1a"), Color("#502a2a")]
		MapNodeData.Type.BOSS:
			return [Color("#3a0a0a"), Color("#5a1a1a")]
		MapNodeData.Type.SHOP:
			return [Color("#1a2a18"), Color("#2a4028")]
		MapNodeData.Type.TREASURE:
			return [Color("#2a2410"), Color("#403820")]
		MapNodeData.Type.REST:
			return [Color("#1a2228"), Color("#2a3840")]
	return [Color("#141414"), Color("#242424")]
