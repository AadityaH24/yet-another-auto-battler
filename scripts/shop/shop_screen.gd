extends CanvasLayer

signal closed(gold: int, roster: Array[UnitData])

var _gold: int
var _roster: Array[UnitData]
var _stock: Array[Dictionary] = []
var _card_w: int = 140
var _card_h: int = 110

var _gold_label: Label
var _container: Node2D

func _init():
	layer = 2

func start(gold: int, roster: Array[UnitData]):
	_gold = gold
	_roster = []
	for u in roster:
		_roster.append(u)
	_stock = _generate_stock()
	_build_ui()

func _generate_stock() -> Array[Dictionary]:
	var pool: Array[int] = [
		Enums.UnitClass.SOLDIER,
		Enums.UnitClass.MAGE,
		Enums.UnitClass.SCOUT,
		Enums.UnitClass.KNIGHT,
		Enums.UnitClass.BERSERKER,
		Enums.UnitClass.SHIELDBEARER,
		Enums.UnitClass.LANCER,
		Enums.UnitClass.ARCHER,
		Enums.UnitClass.WARLOCK,
		Enums.UnitClass.CLERIC,
		Enums.UnitClass.ELEMENTALIST,
	]
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in min(4, pool.size()):
		result.append(_make_shop_unit(pool[i]))
	return result

func _make_shop_unit(cls: int) -> Dictionary:
	var ud := _make_unit_by_class(cls)
	return {"unit": ud, "price": ud.cost * 2 + 2}

func _random_element() -> int:
	if randi() % 10 < 7:
		return Enums.ElementType.NONE
	return [Enums.ElementType.FIRE, Enums.ElementType.WIND, Enums.ElementType.WATER, Enums.ElementType.EARTH].pick_random()

func _make_unit_by_class(cls: int) -> UnitData:
	var elem: int = _random_element()
	match cls:
		Enums.UnitClass.SOLDIER:
			return _make_unit("Soldier", cls, Enums.UnitWeight.LIGHT, 3, 2, 2, elem, 2, 1, Enums.AOEType.SINGLE, Enums.AbilityType.NONE, "")
		Enums.UnitClass.MAGE:
			return _make_unit("Mage", cls, Enums.UnitWeight.LIGHT, 2, 2, 2, elem, 4, 2, Enums.AOEType.SPLASH_ORTHO, Enums.AbilityType.NONE, "")
		Enums.UnitClass.SCOUT:
			return _make_unit("Scout", cls, Enums.UnitWeight.LIGHT, 2, 1, 3, elem, 3, 1, Enums.AOEType.SINGLE, Enums.AbilityType.PASSIVE, "flanking")
		Enums.UnitClass.KNIGHT:
			return _make_unit("Knight", cls, Enums.UnitWeight.HEAVY, 5, 2, 1, elem, 3, 1, Enums.AOEType.SINGLE, Enums.AbilityType.PASSIVE, "guard")
		Enums.UnitClass.ELEMENTALIST:
			return _make_unit("Elementalist", cls, Enums.UnitWeight.HEAVY, 4, 3, 1, elem, 4, 2, Enums.AOEType.SPLASH_ORTHO, Enums.AbilityType.NONE, "")
		Enums.UnitClass.BERSERKER:
			return _make_unit("Berserker", cls, Enums.UnitWeight.HEAVY, 3, 3, 2, elem, 3, 1, Enums.AOEType.CLEAVE_SIDES, Enums.AbilityType.PASSIVE, "bloodrage")
		Enums.UnitClass.SHIELDBEARER:
			return _make_unit("Shieldbearer", cls, Enums.UnitWeight.HEAVY, 4, 1, 1, elem, 3, 1, Enums.AOEType.SINGLE, Enums.AbilityType.DEPLOYMENT, "shield_wall")
		Enums.UnitClass.LANCER:
			return _make_unit("Lancer", cls, Enums.UnitWeight.HEAVY, 3, 2, 2, elem, 3, 1, Enums.AOEType.LINE, Enums.AbilityType.DEPLOYMENT, "impale")
		Enums.UnitClass.ARCHER:
			return _make_unit("Archer", cls, Enums.UnitWeight.LIGHT, 2, 2, 2, elem, 3, 2, Enums.AOEType.SINGLE, Enums.AbilityType.PASSIVE, "focus")
		Enums.UnitClass.WARLOCK:
			return _make_unit("Warlock", cls, Enums.UnitWeight.LIGHT, 3, 2, 2, elem, 3, 2, Enums.AOEType.SINGLE, Enums.AbilityType.PASSIVE, "soul_leech")
		Enums.UnitClass.CLERIC:
			return _make_unit("Cleric", cls, Enums.UnitWeight.LIGHT, 3, 1, 2, elem, 3, 1, Enums.AOEType.SINGLE, Enums.AbilityType.PASSIVE, "heal_aura")
	return _make_unit("Soldier", Enums.UnitClass.SOLDIER, Enums.UnitWeight.LIGHT, 3, 2, 2, elem, 2, 1, Enums.AOEType.SINGLE, Enums.AbilityType.NONE, "")

func _make_unit(uname: String, cls: int, w: int, hp: int, atk: int, spd: int, elem: int, cost: int, range: int, aoe: int, abil_type: int, abil_id: String) -> UnitData:
	var d := UnitData.new()
	d.unit_name = uname
	d.unit_class = cls
	d.weight = w
	d.base_hp = hp
	d.base_attack = atk
	d.base_speed = spd
	d.element_affinity = elem
	d.cost = cost
	d.base_range = range
	d.aoe_type = aoe
	d.ability_type = abil_type
	d.ability_id = abil_id
	return d

func _build_ui():
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "Shop"
	title.position = Vector2(340, 30)
	title.size = Vector2(600, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	_gold_label = Label.new()
	_gold_label.position = Vector2(40, 30)
	_gold_label.size = Vector2(200, 30)
	_gold_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_gold_label.add_theme_font_size_override("font_size", 20)
	add_child(_gold_label)

	var roster_label := Label.new()
	roster_label.text = "Roster: %d / 6" % [_roster.size()]
	roster_label.position = Vector2(40, 60)
	roster_label.size = Vector2(200, 20)
	roster_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	roster_label.add_theme_font_size_override("font_size", 14)
	add_child(roster_label)

	_container = Node2D.new()
	add_child(_container)

	_refresh()

	var leave_btn := _make_btn("Leave", Vector2(540, 580), Vector2(200, 50), Color(0.4, 0.3, 0.3))
	leave_btn.pressed.connect(_on_leave)
	add_child(leave_btn)

func _refresh():
	for child in _container.get_children():
		child.queue_free()

	_gold_label.text = "Gold: %d" % [_gold]

	var vs := Vector2(get_viewport().size)
	var total_w := _stock.size() * _card_w + (_stock.size() - 1) * 20
	var start_x := (vs.x - total_w) / 2
	var start_y := 140

	for i in _stock.size():
		var item: Dictionary = _stock[i]
		var card := _make_card(item, start_x + i * (_card_w + 20), start_y)
		_container.add_child(card)

func _make_card(item: Dictionary, x: float, y: float) -> Button:
	var ud: UnitData = item.unit
	var price: int = item.price
	var can_afford := _gold >= price
	var has_room := _roster.size() < 6

	var b := Button.new()
	b.position = Vector2(x, y)
	b.size = Vector2(_card_w, _card_h)

	var body_color := Color(0.2, 0.2, 0.25)
	if has_room and can_afford:
		body_color = Color(0.25, 0.35, 0.55)

	var sn := StyleBoxFlat.new()
	sn.bg_color = body_color
	sn.corner_radius_top_left = 6
	sn.corner_radius_top_right = 6
	sn.corner_radius_bottom_left = 6
	sn.corner_radius_bottom_right = 6
	sn.border_width_left = 1
	sn.border_width_right = 1
	sn.border_width_top = 1
	sn.border_width_bottom = 1
	sn.border_color = Color(0.4, 0.4, 0.5, 0.3)
	b.add_theme_stylebox_override("normal", sn)

	var sh := StyleBoxFlat.new()
	sh.bg_color = body_color.lightened(0.2)
	sh.corner_radius_top_left = 6
	sh.corner_radius_top_right = 6
	sh.corner_radius_bottom_left = 6
	sh.corner_radius_bottom_right = 6
	b.add_theme_stylebox_override("hover", sh)

	b.add_theme_color_override("font_color", Color.WHITE)

	var name_lbl := Label.new()
	name_lbl.text = ("★★★ " if ud.star_level == 3 else "★★ " if ud.star_level == 2 else "") + ud.unit_name
	name_lbl.position = Vector2(6, 6)
	name_lbl.size = Vector2(_card_w - 12, 20)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	name_lbl.add_theme_font_size_override("font_size", 14)
	b.add_child(name_lbl)

	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats_lbl.position = Vector2(6, 28)
	stats_lbl.size = Vector2(_card_w - 12, 16)
	stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	stats_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(stats_lbl)

	var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
	var type_lbl := Label.new()
	type_lbl.text = "[%s]" % [cls_str]
	type_lbl.position = Vector2(6, 46)
	type_lbl.size = Vector2(_card_w - 12, 16)
	type_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	type_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(type_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(6, 64)
	elem_lbl.size = Vector2(_card_w - 12, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var extra_lbl := Label.new()
	extra_lbl.text = "RNG:%d Cost:%d" % [ud.base_range, ud.cost]
	extra_lbl.position = Vector2(6, 80)
	extra_lbl.size = Vector2(_card_w - 12, 14)
	extra_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	extra_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(extra_lbl)

	var price_lbl := Label.new()
	price_lbl.text = "%d Gold" % [price]
	price_lbl.position = Vector2(6, 94)
	price_lbl.size = Vector2(_card_w - 12, 20)
	price_lbl.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	price_lbl.add_theme_font_size_override("font_size", 14)
	b.add_child(price_lbl)

	if not has_room:
		var full_lbl := Label.new()
		full_lbl.text = "ROSTER FULL"
		full_lbl.position = Vector2(6, 102)
		full_lbl.size = Vector2(_card_w - 12, 16)
		full_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		full_lbl.add_theme_font_size_override("font_size", 10)
		b.add_child(full_lbl)

	if can_afford and has_room:
		b.pressed.connect(_buy.bind(item))

	return b

func _buy(item: Dictionary):
	var ud: UnitData = item.unit
	var price: int = item.price

	if _gold < price:
		return
	if _roster.size() >= 6:
		return

	_gold -= price
	_roster.append(ud)
	_stock.erase(item)
	_refresh()

func _on_leave():
	closed.emit(_gold, _roster)
	queue_free()

func _make_btn(text: String, pos: Vector2, size: Vector2, color: Color = Color(0.2, 0.5, 0.3)) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_color_override("font_color", Color.WHITE)
	var sn := StyleBoxFlat.new()
	sn.bg_color = color
	sn.corner_radius_top_left = 4
	sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4
	sn.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = color.lightened(0.15)
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)
	return b
