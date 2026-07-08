extends CanvasLayer

signal closed(gold: int, roster: Array[UnitData])

const SELL_AMOUNT: int = 1
const MAX_ROSTER: int = 6

var _gold: int
var _roster: Array[UnitData]
var _stock: Array[Dictionary] = []
var _card_w: int = 140
var _card_h: int = 110
var _roster_card_w: int = 130
var _roster_card_h: int = 80

var _gold_label: Label
var _roster_count_label: Label
var _scroll: ScrollContainer
var _body_container: VBoxContainer
var _stock_container: HBoxContainer
var _roster_container: HBoxContainer
var _viewport_size: Vector2

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
	var pool: Array[int] = UnitFactory.ALL_CLASSES.duplicate()
	pool.shuffle()
	var result: Array[Dictionary] = []
	for i in min(4, pool.size()):
		result.append(_make_shop_unit(pool[i]))
	return result

func _make_shop_unit(cls: int) -> Dictionary:
	var ud := _make_unit_by_class(cls)
	return {"unit": ud, "price": ud.cost * 2 + 2}

func _make_unit_by_class(cls: int) -> UnitData:
	return UnitFactory.make_unit_by_class(cls)

func _build_ui():
	_viewport_size = Vector2(get_viewport().size)
	var vs := _viewport_size
	add_child(ThemeHelper.make_bg())
	add_child(ThemeHelper.make_title("Shop", vs, 14, 28))
	_build_info_labels()
	_build_scroll_area(vs)
	var leave_btn := ThemeHelper.make_btn("Leave", Vector2((vs.x - 200) / 2, vs.y - 60), Vector2(200, 50), ThemeHelper.DANGER)
	leave_btn.pressed.connect(_on_leave)
	add_child(leave_btn)
	_refresh()

func _build_info_labels():
	_gold_label = Label.new()
	_gold_label.position = Vector2(24, 50)
	_gold_label.size = Vector2(200, 26)
	_gold_label.add_theme_color_override("font_color", ThemeHelper.GOLD)
	_gold_label.add_theme_font_size_override("font_size", 18)
	add_child(_gold_label)
	_roster_count_label = Label.new()
	_roster_count_label.position = Vector2(24, 74)
	_roster_count_label.size = Vector2(200, 18)
	_roster_count_label.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	_roster_count_label.add_theme_font_size_override("font_size", 13)
	add_child(_roster_count_label)

func _build_scroll_area(vs: Vector2):
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(0, 100)
	_scroll.size = Vector2(vs.x, vs.y - 100 - 70)
	add_child(_scroll)
	_body_container = VBoxContainer.new()
	_body_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_body_container)
	var stock_header := Label.new()
	stock_header.text = "Available Units"
	stock_header.size = Vector2(vs.x, 24)
	stock_header.add_theme_color_override("font_color", ThemeHelper.INFO)
	stock_header.add_theme_font_size_override("font_size", 18)
	_body_container.add_child(stock_header)
	_stock_container = HBoxContainer.new()
	_stock_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_container.add_child(_stock_container)
	var spacer := ColorRect.new()
	spacer.color = Color.TRANSPARENT
	spacer.size = Vector2(0, 16)
	_body_container.add_child(spacer)
	var sell_header := Label.new()
	sell_header.text = "Sell Units"
	sell_header.add_theme_color_override("font_color", ThemeHelper.GOLD)
	sell_header.add_theme_font_size_override("font_size", 18)
	_body_container.add_child(sell_header)
	_roster_container = HBoxContainer.new()
	_roster_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_roster_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_body_container.add_child(_roster_container)

func _refresh():
	_gold_label.text = "Gold: %d" % [_gold]
	_roster_count_label.text = "Roster: %d / %d" % [_roster.size(), MAX_ROSTER]

	for c in _stock_container.get_children():
		c.queue_free()
	for c in _roster_container.get_children():
		c.queue_free()

	var vs := _viewport_size

	var stock_units := 0
	for i in _stock.size():
		var item: Dictionary = _stock[i]
		var card := _make_stock_card(item)
		_stock_container.add_child(card)
		stock_units += 1

	if stock_units == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "  Nothing left to buy"
		empty_lbl.size = Vector2(200, 30)
		empty_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
		empty_lbl.add_theme_font_size_override("font_size", 13)
		_stock_container.add_child(empty_lbl)

	if _roster.size() == 0:
		var empty_lbl := Label.new()
		empty_lbl.text = "  No units to sell"
		empty_lbl.size = Vector2(200, 30)
		empty_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
		empty_lbl.add_theme_font_size_override("font_size", 13)
		_roster_container.add_child(empty_lbl)
	else:
		for i in _roster.size():
			var ud: UnitData = _roster[i]
			var card := _make_roster_card(ud, i)
			_roster_container.add_child(card)

func _make_stock_card(item: Dictionary) -> Button:
	var ud: UnitData = item.unit
	var price: int = item.price
	var can_afford := _gold >= price
	var has_room := _roster.size() < MAX_ROSTER

	var b := Button.new()
	b.size = Vector2(_card_w, _card_h)

	if can_afford and has_room:
		ThemeHelper.style_card(b, ud.weight)
	else:
		ThemeHelper.style_card(b, -1, true)

	b.add_theme_color_override("font_color", ThemeHelper.TEXT)

	var portrait := UnitFactory.make_portrait(ud, 0, 0.5)
	portrait.position = Vector2(4, 6)
	b.add_child(portrait)

	var px: int = 38
	var pw: int = _card_w - px - 6

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(ud.star_level) + ud.unit_name
	name_lbl.position = Vector2(px, 4)
	name_lbl.size = Vector2(pw, 18)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT)
	name_lbl.add_theme_font_size_override("font_size", 13)
	b.add_child(name_lbl)

	var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [UnitData.total_hp(ud), UnitData.total_atk(ud), UnitData.total_spd(ud)]
	stats_lbl.position = Vector2(px, 22)
	stats_lbl.size = Vector2(pw, 14)
	stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	stats_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(stats_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "[%s]" % [cls_str]
	type_lbl.position = Vector2(px, 36)
	type_lbl.size = Vector2(pw, 14)
	type_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	type_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(type_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(px, 50)
	elem_lbl.size = Vector2(pw, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var extra_lbl := Label.new()
	extra_lbl.text = "RNG:%d Cost:%d" % [UnitData.total_rng(ud), ud.cost]
	extra_lbl.position = Vector2(px, 64)
	extra_lbl.size = Vector2(pw, 14)
	extra_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	extra_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(extra_lbl)

	if ud.items.size() > 0:
		var icons := PackedStringArray()
		for it in ud.items:
			icons.append(it.icon_char)
		var ilbl := Label.new()
		ilbl.text = "[" + ", ".join(icons) + "]"
		ilbl.position = Vector2(px, 76)
		ilbl.size = Vector2(pw, 12)
		ilbl.add_theme_color_override("font_color", ThemeHelper.INFO)
		ilbl.add_theme_font_size_override("font_size", 8)
		b.add_child(ilbl)

	var price_lbl := Label.new()
	price_lbl.text = "%d Gold" % [price]
	var price_y := 80
	if ud.items.size() > 0:
		price_y = 88
	price_lbl.position = Vector2(px, price_y)
	price_lbl.size = Vector2(pw, 20)
	price_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	price_lbl.add_theme_font_size_override("font_size", 14)
	b.add_child(price_lbl)

	if not has_room:
		var full_lbl := Label.new()
		full_lbl.text = "ROSTER FULL"
		full_lbl.position = Vector2(px, 94)
		full_lbl.size = Vector2(pw, 14)
		full_lbl.add_theme_color_override("font_color", ThemeHelper.DANGER)
		full_lbl.add_theme_font_size_override("font_size", 10)
		b.add_child(full_lbl)

	if can_afford and has_room:
		b.pressed.connect(_buy.bind(item))

	return b

func _make_roster_card(ud: UnitData, idx: int) -> Button:
	var sell_price := maxi(SELL_AMOUNT, ud.cost)

	var b := Button.new()
	b.size = Vector2(_roster_card_w, _roster_card_h)
	ThemeHelper.style_card(b, ud.weight)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var portrait := UnitFactory.make_portrait(ud, 0, 0.5)
	portrait.position = Vector2(4, 4)
	b.add_child(portrait)

	var px: int = 38
	var pw: int = _roster_card_w - px - 6

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(ud.star_level) + ud.unit_name
	name_lbl.position = Vector2(px, 2)
	name_lbl.size = Vector2(pw, 16)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT)
	name_lbl.add_theme_font_size_override("font_size", 11)
	b.add_child(name_lbl)

	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d" % [UnitData.total_hp(ud), UnitData.total_atk(ud)]
	stats_lbl.position = Vector2(px, 18)
	stats_lbl.size = Vector2(pw, 14)
	stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	stats_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(stats_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(px, 32)
	elem_lbl.size = Vector2(pw, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	var sell_lbl := Label.new()
	sell_lbl.text = "Sell: +%dg" % [sell_price]
	sell_lbl.position = Vector2(px, 52)
	sell_lbl.size = Vector2(pw, 20)
	sell_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	sell_lbl.add_theme_font_size_override("font_size", 12)
	b.add_child(sell_lbl)

	if ud.items.size() > 0:
		var icons := PackedStringArray()
		for it in ud.items:
			icons.append(it.icon_char)
		var ilbl := Label.new()
		ilbl.text = "[" + ", ".join(icons) + "]"
		ilbl.position = Vector2(px, 66)
		ilbl.size = Vector2(pw, 12)
		ilbl.add_theme_color_override("font_color", ThemeHelper.INFO)
		ilbl.add_theme_font_size_override("font_size", 8)
		b.add_child(ilbl)

	b.pressed.connect(_sell.bind(idx))
	return b

func _sell(idx: int):
	var ud: UnitData = _roster[idx]
	var sell_price := maxi(SELL_AMOUNT, ud.cost)
	_gold += sell_price
	_roster.remove_at(idx)
	_refresh()

func _buy(item: Dictionary):
	var ud: UnitData = item.unit
	var price: int = item.price

	if _gold < price:
		return
	if _roster.size() >= MAX_ROSTER:
		return

	_gold -= price
	_roster.append(ud)
	_stock.erase(item)
	_refresh()

func _on_leave():
	closed.emit(_gold, _roster)
	queue_free()
