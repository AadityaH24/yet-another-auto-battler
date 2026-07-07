class_name DraftScreen extends CanvasLayer

signal confirmed(roster: Array[UnitData], remaining_gold: int)

const MIN_UNITS: int = 4
const MAX_UNITS: int = 5

var _selected: Array[UnitData] = []
var _all_units: Array[UnitData] = []
var _budget: int = 10
var _spent: int = 0

var _pool_container: Node2D
var _roster_container: Node2D
var _count_label: Label
var _gold_label: Label
var _ready_btn: Button
var _card_width: int = 140
var _card_height: int = 100

func _init():
	layer = 2

func _ready():
	_build_ui()

func start(available: Array[UnitData], budget: int = 10):
	_all_units = available
	_budget = budget
	_spent = 0
	_selected = []
	_refresh()

func _build_ui():
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Choose Your Roster"
	title.position = Vector2(340, 30)
	title.size = Vector2(600, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	var pool_header := Label.new()
	pool_header.text = "Available Units"
	pool_header.position = Vector2(80, 100)
	pool_header.size = Vector2(500, 30)
	pool_header.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	pool_header.add_theme_font_size_override("font_size", 20)
	add_child(pool_header)

	_pool_container = Node2D.new()
	add_child(_pool_container)

	var roster_header := Label.new()
	roster_header.text = "Your Roster"
	roster_header.position = Vector2(680, 100)
	roster_header.size = Vector2(500, 30)
	roster_header.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	roster_header.add_theme_font_size_override("font_size", 20)
	add_child(roster_header)

	_roster_container = Node2D.new()
	add_child(_roster_container)

	_count_label = Label.new()
	_count_label.position = Vector2(540, 530)
	_count_label.size = Vector2(200, 30)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_color_override("font_color", Color.WHITE)
	_count_label.add_theme_font_size_override("font_size", 18)
	add_child(_count_label)

	_gold_label = Label.new()
	_gold_label.position = Vector2(540, 555)
	_gold_label.size = Vector2(200, 20)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_gold_label.add_theme_font_size_override("font_size", 14)
	add_child(_gold_label)

	_ready_btn = _make_btn("Ready for Battle", Vector2(540, 590), Vector2(200, 50))
	_ready_btn.disabled = true
	_ready_btn.pressed.connect(_on_ready)
	add_child(_ready_btn)

func _make_btn(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_color_override("font_color", Color.WHITE)
	var sn := StyleBoxFlat.new()
	sn.bg_color = Color(0.2, 0.5, 0.3)
	sn.corner_radius_top_left = 4
	sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4
	sn.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0.25, 0.6, 0.35)
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)
	var sp := StyleBoxFlat.new()
	sp.bg_color = Color(0.15, 0.4, 0.25)
	sp.corner_radius_top_left = 4
	sp.corner_radius_top_right = 4
	sp.corner_radius_bottom_left = 4
	sp.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("pressed", sp)
	var sd := StyleBoxFlat.new()
	sd.bg_color = Color(0.12, 0.12, 0.15)
	sd.corner_radius_top_left = 4
	sd.corner_radius_top_right = 4
	sd.corner_radius_bottom_left = 4
	sd.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("disabled", sd)
	return b

func _refresh():
	_clear_container(_pool_container)
	_clear_container(_roster_container)

	var remaining: int = _budget - _spent

	for i in _all_units.size():
		var ud: UnitData = _all_units[i]
		var already: bool = _selected.has(ud)
		var can_afford: bool = ud.cost <= remaining
		var dimmed: bool = already or (not can_afford and not _selected.has(ud))
		var card := _make_unit_card(ud, dimmed)
		card.position = Vector2(80 + (i % 3) * (_card_width + 20), 140 + (i / 3) * (_card_height + 10))
		if not already and can_afford:
			card.pressed.connect(_add_unit.bind(ud))
		_pool_container.add_child(card)

	for i in _selected.size():
		var ud = _selected[i]
		var card := _make_unit_card(ud, false)
		card.position = Vector2(680 + (i % 3) * (_card_width + 20), 140 + (i / 3) * (_card_height + 10))
		var remove_btn: Button = Button.new()
		remove_btn.text = "X"
		remove_btn.position = Vector2(_card_width - 24, 4)
		remove_btn.size = Vector2(20, 20)
		remove_btn.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color(0.5, 0.1, 0.1)
		remove_btn.add_theme_stylebox_override("normal", sb)
		var sbh: StyleBoxFlat = StyleBoxFlat.new()
		sbh.bg_color = Color(0.7, 0.2, 0.2)
		remove_btn.add_theme_stylebox_override("hover", sbh)
		remove_btn.pressed.connect(_remove_unit.bind(ud))
		card.add_child(remove_btn)
		_roster_container.add_child(card)

	_count_label.text = "%d / %d selected (need %d)" % [_selected.size(), MAX_UNITS, MIN_UNITS]
	_gold_label.text = "Gold: %d / %d" % [_spent, _budget]
	var meets_min: bool = _selected.size() >= MIN_UNITS
	_ready_btn.disabled = not meets_min

func _make_unit_card(ud: UnitData, dimmed: bool) -> Button:
	var b := Button.new()
	b.size = Vector2(_card_width, _card_height)

	var body_color := Color.WHITE
	match ud.weight:
		Enums.UnitWeight.LIGHT:
			body_color = Color(0.2, 0.35, 0.55)
		Enums.UnitWeight.HEAVY:
			body_color = Color(0.45, 0.15, 0.15)

	var s := StyleBoxFlat.new()
	s.bg_color = body_color if not dimmed else Color(0.12, 0.12, 0.15)
	s.corner_radius_top_left = 4
	s.corner_radius_top_right = 4
	s.corner_radius_bottom_left = 4
	s.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", s)

	var sh := StyleBoxFlat.new()
	sh.bg_color = body_color.lightened(0.3)
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)

	var name_lbl := Label.new()
	var star_pre := "" if ud.star_level <= 1 else ("★★ " if ud.star_level == 2 else "★★★ ")
	name_lbl.text = star_pre + ud.unit_name
	name_lbl.position = Vector2(6, 6)
	name_lbl.size = Vector2(_card_width - 12, 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 14)
	b.add_child(name_lbl)

	var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats_lbl.position = Vector2(6, 28)
	stats_lbl.size = Vector2(_card_width - 12, 16)
	stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	stats_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(stats_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "[%s]" % cls_str
	type_lbl.position = Vector2(6, 46)
	type_lbl.size = Vector2(_card_width - 12, 16)
	type_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	type_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(type_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(6, 62)
	elem_lbl.size = Vector2(_card_width - 12, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %d  RNG:%d" % [ud.cost, ud.base_range]
	cost_lbl.position = Vector2(6, 78)
	cost_lbl.size = Vector2(_card_width - 12, 14)
	cost_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	cost_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(cost_lbl)

	if dimmed:
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		stats_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		type_lbl.add_theme_color_override("font_color", Color(0.25, 0.25, 0.3))
		cost_lbl.add_theme_color_override("font_color", Color(0.3, 0.25, 0.0))
		elem_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))

	return b

func _add_unit(ud: UnitData):
	if _selected.size() >= MAX_UNITS:
		return
	var remaining: int = _budget - _spent
	if ud.cost > remaining:
		return
	_spent += ud.cost
	var copy := _clone_unit(ud)
	copy.element_affinity = _random_element()
	_selected.append(copy)
	_refresh()

func _remove_unit(ud: UnitData):
	_spent -= ud.cost
	_selected.erase(ud)
	_refresh()

func _clone_unit(ud: UnitData) -> UnitData:
	var c := UnitData.new()
	c.unit_name = ud.unit_name
	c.unit_class = ud.unit_class
	c.weight = ud.weight
	c.base_hp = ud.base_hp
	c.base_attack = ud.base_attack
	c.base_speed = ud.base_speed
	c.cost = ud.cost
	c.base_range = ud.base_range
	c.aoe_type = ud.aoe_type
	c.ability_type = ud.ability_type
	c.ability_id = ud.ability_id
	c.element_affinity = ud.element_affinity
	c.star_level = ud.star_level
	return c

func _random_element() -> int:
	if randi() % 10 < 7:
		return Enums.ElementType.NONE
	return [Enums.ElementType.FIRE, Enums.ElementType.WIND, Enums.ElementType.WATER, Enums.ElementType.EARTH].pick_random()

func _clear_container(c: Node2D):
	for child in c.get_children():
		child.queue_free()

func _on_ready():
	var remaining: int = _budget - _spent
	confirmed.emit(_selected, remaining)
	queue_free()
