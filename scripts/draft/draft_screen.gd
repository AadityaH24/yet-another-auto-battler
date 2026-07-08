class_name DraftScreen extends CanvasLayer

signal confirmed(roster: Array[UnitData], remaining_gold: int)

const MIN_UNITS: int = 3
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
	add_child(ThemeHelper.make_bg())

	var vs := Vector2(get_viewport().size)

	var title := ThemeHelper.make_title("Choose Your Roster", vs, 30, 36)
	add_child(title)

	var pool_header := Label.new()
	pool_header.text = "Available Units"
	pool_header.position = Vector2(80, 100)
	pool_header.size = Vector2(500, 30)
	pool_header.add_theme_color_override("font_color", ThemeHelper.INFO)
	pool_header.add_theme_font_size_override("font_size", 20)
	add_child(pool_header)

	_pool_container = Node2D.new()
	add_child(_pool_container)

	var roster_header := Label.new()
	roster_header.text = "Your Roster"
	roster_header.position = Vector2(680, 100)
	roster_header.size = Vector2(500, 30)
	roster_header.add_theme_color_override("font_color", ThemeHelper.GOLD)
	roster_header.add_theme_font_size_override("font_size", 20)
	add_child(roster_header)

	_roster_container = Node2D.new()
	add_child(_roster_container)

	_count_label = Label.new()
	_count_label.position = Vector2(540, 530)
	_count_label.size = Vector2(200, 30)
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_color_override("font_color", ThemeHelper.TEXT)
	_count_label.add_theme_font_size_override("font_size", 18)
	add_child(_count_label)

	_gold_label = Label.new()
	_gold_label.position = Vector2(540, 555)
	_gold_label.size = Vector2(200, 20)
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.add_theme_color_override("font_color", ThemeHelper.GOLD)
	_gold_label.add_theme_font_size_override("font_size", 14)
	add_child(_gold_label)

	_ready_btn = ThemeHelper.make_btn("Ready for Battle", Vector2(540, 590), Vector2(200, 50), ThemeHelper.SUCCESS)
	_ready_btn.disabled = true
	_ready_btn.pressed.connect(_on_ready)
	add_child(_ready_btn)

func _refresh():
	_clear_container(_pool_container)
	_clear_container(_roster_container)

	var remaining: int = _budget - _spent

	for i in _all_units.size():
		var ud: UnitData = _all_units[i]
		var can_afford: bool = ud.cost <= remaining
		var card := _make_unit_card(ud, can_afford)
		card.position = Vector2(80 + (i % 3) * (_card_width + 20), 140 + (i / 3) * (_card_height + 10))
		if can_afford:
			card.pressed.connect(_add_unit.bind(ud))
		_pool_container.add_child(card)

	for i in _selected.size():
		var ud = _selected[i]
		var card := _make_unit_card(ud, true)
		card.position = Vector2(680 + (i % 3) * (_card_width + 20), 140 + (i / 3) * (_card_height + 10))
		var remove_btn := Button.new()
		remove_btn.text = "X"
		remove_btn.position = Vector2(_card_width - 24, 4)
		remove_btn.size = Vector2(20, 20)
		remove_btn.add_theme_color_override("font_color", ThemeHelper.DANGER)
		var sb := StyleBoxFlat.new()
		sb.bg_color = ThemeHelper.BG_PANEL
		sb.border_color = ThemeHelper.DANGER
		sb.border_width_top = 1
		sb.border_width_left = 1
		sb.border_width_bottom = 1
		sb.border_width_right = 1
		remove_btn.add_theme_stylebox_override("normal", sb)
		var sbh := sb.duplicate() as StyleBoxFlat
		sbh.bg_color = ThemeHelper.DANGER
		remove_btn.add_theme_stylebox_override("hover", sbh)
		remove_btn.pressed.connect(_remove_unit.bind(ud))
		card.add_child(remove_btn)
		_roster_container.add_child(card)

	_count_label.text = "%d / %d selected (need %d)" % [_selected.size(), MAX_UNITS, MIN_UNITS]
	_gold_label.text = "Gold: %d / %d" % [_spent, _budget]
	var meets_min: bool = _selected.size() >= MIN_UNITS
	_ready_btn.disabled = not meets_min

func _make_unit_card(ud: UnitData, available: bool) -> Button:
	var b := Button.new()
	b.size = Vector2(_card_width, _card_height)

	if not available:
		ThemeHelper.style_card(b, -1, true)
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
		b.add_theme_stylebox_override("normal", sd)
		b.add_theme_stylebox_override("hover", sd)
	else:
		ThemeHelper.style_card(b, ud.weight)

	var portrait := UnitFactory.make_portrait(ud, 0, 0.5)
	portrait.position = Vector2(4, 6)
	b.add_child(portrait)

	var px: int = 38
	var pw: int = _card_width - px - 6

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(ud.star_level) + ud.unit_name
	name_lbl.position = Vector2(px, 4)
	name_lbl.size = Vector2(pw, 18)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT if available else ThemeHelper.TEXT_DIM)
	name_lbl.add_theme_font_size_override("font_size", 13)
	b.add_child(name_lbl)

	var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats_lbl.position = Vector2(px, 22)
	stats_lbl.size = Vector2(pw, 14)
	stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM if not available else Color(ThemeHelper.TEXT.r, ThemeHelper.TEXT.g, ThemeHelper.TEXT.b, 0.8))
	stats_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(stats_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "[%s]" % cls_str
	type_lbl.position = Vector2(px, 36)
	type_lbl.size = Vector2(pw, 14)
	type_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	type_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(type_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(px, 50)
	elem_lbl.size = Vector2(pw, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity) if available else ThemeHelper.TEXT_DIM)
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "Cost: %d  RNG:%d" % [ud.cost, ud.base_range]
	cost_lbl.position = Vector2(px, 64)
	cost_lbl.size = Vector2(pw, 14)
	cost_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD if available else Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.3))
	cost_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(cost_lbl)

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
	return UnitFactory.clone_unit(ud)

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
