class_name DeploymentScreen extends CanvasLayer

signal confirmed(units: Array[UnitData], positions: Array[Vector2i])

const TILE_SIZE: int = 80
const CARD_WIDTH: int = 110
const CARD_HEIGHT: int = 90
const CARD_GAP: int = 10
const BUTTON_WIDTH: int = 200
const BUTTON_HEIGHT: int = 50
const TITLE_AREA_HEIGHT: int = 90

var _roster: Array[UnitData]
var _selected_idx: int = -1
var _grid: Array[int] = []
var _grid_w: int = 4
var _grid_h: int = 4

var _grid_nodes: Dictionary = {}
var _grid_root: Node2D
var _roster_root: Node2D
var _ready_btn: Button
var _info_label: Label

func _init():
	layer = 2

func start(roster: Array[UnitData], grid_w: int = 4, grid_h: int = 4):
	_roster = roster
	_grid_w = grid_w
	_grid_h = grid_h
	_grid.resize(_grid_w * _grid_h)
	for i in _grid_w * _grid_h:
		_grid[i] = -1
	_build_ui()

func _build_ui():
	var vs := Vector2(get_viewport().size)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# --- Title & Info ---
	var title := _make_title(vs)
	add_child(title)
	_info_label = _make_info_label(vs)
	add_child(_info_label)

	# --- Grid (centered in remaining space) ---
	var grid_px_w: int = _grid_w * TILE_SIZE
	var grid_px_h: int = _grid_h * TILE_SIZE
	var roster_area_h: int = CARD_HEIGHT + CARD_GAP * 3
	var grid_top: int = TITLE_AREA_HEIGHT
	var grid_bottom: int = vs.y - roster_area_h - BUTTON_HEIGHT - 20
	var avail_h: int = maxi(0, grid_bottom - grid_top)
	var grid_ofs: Vector2 = Vector2(
		(vs.x - grid_px_w) / 2,
		grid_top + (avail_h - grid_px_h) / 2
	)

	_grid_root = Node2D.new()
	add_child(_grid_root)
	_build_grid_tiles(grid_ofs)

	# --- Zone labels ---
	_build_zone_labels(grid_ofs, grid_px_w)

	# --- Roster cards ---
	_roster_root = Node2D.new()
	add_child(_roster_root)

	# --- Ready button ---
	_ready_btn = _make_btn("Ready for Battle", Color(0.2, 0.5, 0.3))
	_ready_btn.position = Vector2((vs.x - BUTTON_WIDTH) / 2, vs.y - BUTTON_HEIGHT - 10)
	_ready_btn.size = Vector2(BUTTON_WIDTH, BUTTON_HEIGHT)
	_ready_btn.disabled = true
	_ready_btn.pressed.connect(_on_ready)
	add_child(_ready_btn)

	_refresh()

func _make_title(vs: Vector2) -> Label:
	var l := Label.new()
	l.text = "Deploy Your Units"
	l.position = Vector2((vs.x - 400) / 2, 20)
	l.size = Vector2(400, 36)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_font_size_override("font_size", 28)
	return l

func _make_info_label(vs: Vector2) -> Label:
	var l := Label.new()
	l.position = Vector2((vs.x - 400) / 2, 60)
	l.size = Vector2(400, 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	l.add_theme_font_size_override("font_size", 13)
	return l

func _build_grid_tiles(grid_ofs: Vector2):
	var player_start_row: int = maxi(0, _grid_h - 2)
	for y in _grid_h:
		for x in _grid_w:
			var pos: Vector2 = grid_ofs + Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var is_player_zone: bool = y >= player_start_row
			var r := ColorRect.new()
			r.position = pos
			r.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
			if is_player_zone:
				r.color = Color(0.2, 0.28, 0.35)
				r.mouse_filter = Control.MOUSE_FILTER_STOP
				r.gui_input.connect(_on_tile_input.bind(x, y))
			else:
				r.color = Color(0.15, 0.15, 0.18)
			_grid_root.add_child(r)
			_grid_nodes[Vector2i(x, y)] = r

			if is_player_zone:
				var lbl := Label.new()
				var col_lbl := str(x + 1)
				var row_lbl: String = ["A", "B", "C", "D", "E", "F"][y]
				lbl.text = "%s%s" % [row_lbl, col_lbl]
				lbl.position = pos + Vector2(TILE_SIZE / 2.0 - 10, TILE_SIZE / 2.0 - 8)
				lbl.size = Vector2(20, 16)
				lbl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7, 0.5))
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_grid_root.add_child(lbl)

func _build_zone_labels(grid_ofs: Vector2, grid_px_w: int):
	var e := Label.new()
	e.text = "ENEMY ZONE"
	e.position = grid_ofs + Vector2(0, -18)
	e.size = Vector2(grid_px_w, 16)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 0.4))
	e.add_theme_font_size_override("font_size", 10)
	_grid_root.add_child(e)

	var p := Label.new()
	p.text = "YOUR ZONE"
	var grid_px_h: int = _grid_h * TILE_SIZE
	p.position = grid_ofs + Vector2(0, grid_px_h + 4)
	p.size = Vector2(grid_px_w, 16)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0, 0.4))
	p.add_theme_font_size_override("font_size", 10)
	_grid_root.add_child(p)

func _on_tile_input(event: InputEvent, x: int, y: int):
	if _selected_idx < 0:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var idx := y * _grid_w + x
	if _grid[idx] >= 0:
		return
	_grid[idx] = _selected_idx
	_selected_idx = -1
	_refresh()

func _refresh():
	var vs := Vector2(get_viewport().size)

	for c in _roster_root.get_children():
		c.queue_free()

	var total_w: int = _roster.size() * CARD_WIDTH + (_roster.size() - 1) * CARD_GAP
	var roster_x: int = maxi(10, (vs.x - total_w) / 2)
	var roster_y: int = vs.y - CARD_HEIGHT - CARD_GAP * 2 - BUTTON_HEIGHT - 10

	for i in _roster.size():
		var is_placed := false
		for g in _grid:
			if g == i:
				is_placed = true
				break
		var b := _make_unit_card(i, is_placed)
		b.position = Vector2(roster_x + i * (CARD_WIDTH + CARD_GAP), roster_y)
		b.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		_roster_root.add_child(b)

	for y in _grid_h:
		for x in _grid_w:
			var idx := y * _grid_w + x
			var r = _grid_nodes.get(Vector2i(x, y))
			if not r:
				continue
			if _grid[idx] >= 0:
				var u_idx := _grid[idx]
				var ud := _roster[u_idx]
				r.color = Color(0.25, 0.4, 0.6)
				r.tooltip_text = ud.unit_name
			elif y >= max(0, _grid_h - 2):
				r.color = Color(0.2, 0.28, 0.35)
			else:
				r.color = Color(0.15, 0.15, 0.18)

	var placed := 0
	for g in _grid:
		if g >= 0:
			placed += 1

	_info_label.text = "Click a unit below, then click a tile on your zone"
	if _selected_idx >= 0:
		_info_label.text = "Placing: " + _roster[_selected_idx].unit_name + " (click a tile)"
	_ready_btn.disabled = placed == 0

func _make_unit_card(idx: int, is_placed: bool) -> Button:
	var ud := _roster[idx]
	var b := Button.new()
	b.text = ""
	b.disabled = is_placed

	var body := Color(0.2, 0.3, 0.4) if not is_placed else Color(0.12, 0.12, 0.15)
	var sn := StyleBoxFlat.new()
	sn.bg_color = body
	sn.corner_radius_top_left = 5; sn.corner_radius_top_right = 5
	sn.corner_radius_bottom_left = 5; sn.corner_radius_bottom_right = 5
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = body.lightened(0.3)
	sh.corner_radius_top_left = 5; sh.corner_radius_top_right = 5
	sh.corner_radius_bottom_left = 5; sh.corner_radius_bottom_right = 5
	b.add_theme_stylebox_override("hover", sh)

	var name_lbl := Label.new()
	var star_prefix := "" if ud.star_level <= 1 else ("★★ " if ud.star_level == 2 else "★★★ ")
	name_lbl.text = star_prefix + ud.unit_name
	name_lbl.position = Vector2(4, 4)
	name_lbl.size = Vector2(CARD_WIDTH - 10, 18)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 12)
	b.add_child(name_lbl)

	var stats := Label.new()
	stats.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats.position = Vector2(4, 22)
	stats.size = Vector2(CARD_WIDTH - 10, 14)
	stats.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	stats.add_theme_font_size_override("font_size", 9)
	b.add_child(stats)

	var range_lbl := Label.new()
	range_lbl.text = "RNG:%d Cost:%d" % [ud.base_range, ud.cost]
	range_lbl.position = Vector2(4, 36)
	range_lbl.size = Vector2(CARD_WIDTH - 10, 14)
	range_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	range_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(range_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(4, 50)
	elem_lbl.size = Vector2(CARD_WIDTH - 10, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var ability_lbl := Label.new()
	var abil_name := _ability_display_name(ud.ability_id)
	ability_lbl.text = abil_name
	ability_lbl.position = Vector2(4, 64)
	ability_lbl.size = Vector2(CARD_WIDTH - 10, 14)
	ability_lbl.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
	ability_lbl.add_theme_font_size_override("font_size", 8)
	b.add_child(ability_lbl)

	if not is_placed:
		b.pressed.connect(func():
			_selected_idx = idx
			_refresh()
		)

	return b

func _ability_display_name(id: String) -> String:
	match id:
		"guard": return "Guard"
		"bloodrage": return "Bloodrage"
		"flanking": return "Flanking"
		"focus": return "Focus"
		"soul_leech": return "Soul Leech"
		"heal_aura": return "Heal Aura"
		"shield_wall": return "Shield Wall"
		"impale": return "Impale"
	return ""

func _on_ready():
	var units: Array[UnitData] = []
	var positions: Array[Vector2i] = []
	for y in _grid_h:
		for x in _grid_w:
			var idx := y * _grid_w + x
			if _grid[idx] >= 0:
				units.append(_roster[_grid[idx]])
				positions.append(Vector2i(x, y))
	confirmed.emit(units, positions)
	queue_free()

func _make_btn(text: String, color: Color = Color(0.2, 0.5, 0.3)) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_color_override("font_color", Color.WHITE)
	var sn := StyleBoxFlat.new()
	sn.bg_color = color; sn.corner_radius_top_left = 4; sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4; sn.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = color.lightened(0.15)
	sh.corner_radius_top_left = 4; sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4; sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)
	return b