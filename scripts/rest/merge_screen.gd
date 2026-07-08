class_name MergeScreen extends CanvasLayer

signal closed(roster: Array[UnitData])

const MERGE_COUNT: int = 3
const MAX_STAR: int = 3
const CARD_W: int = 160
const CARD_H: int = 100
const GAP: int = 16

var _roster: Array[UnitData]
var _ui_root: Node2D
var _continue_btn: Button
var _info_label: Label
var _viewport_size: Vector2

func _init():
	layer = 2

func start(roster: Array[UnitData]):
	_roster = roster
	_build_ui()
	_refresh()

func _build_ui():
	_viewport_size = Vector2(get_viewport().size)
	var vs := _viewport_size
	add_child(ThemeHelper.make_bg())

	var title := ThemeHelper.make_title("Rest — Merge Units", vs, 20, 28)
	add_child(title)

	_info_label = Label.new()
	_info_label.position = Vector2((vs.x - 500) / 2, 60)
	_info_label.size = Vector2(500, 20)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	_info_label.add_theme_font_size_override("font_size", 13)
	add_child(_info_label)

	_ui_root = Node2D.new()
	add_child(_ui_root)

	_continue_btn = ThemeHelper.make_btn("Continue to Map", Vector2((vs.x - 200) / 2, vs.y - 70), Vector2(200, 50), ThemeHelper.SUCCESS)
	_continue_btn.pressed.connect(_on_continue)
	add_child(_continue_btn)

func _refresh():
	var vs := _viewport_size
	for c in _ui_root.get_children():
		_ui_root.remove_child(c)
		c.queue_free()

	var groups: Dictionary = {}
	for u in _roster:
		var key := u.unit_class * 10 + u.star_level
		if not groups.has(key):
			groups[key] = []
		groups[key].append(u)

	var card_idx: int = 0
	var has_mergeable: bool = false

	for key in groups.keys():
		var units = groups[key]
		var cls: int = int(key / 10)
		var star: int = key % 10
		var count: int = units.size()
		var can_merge: bool = count >= MERGE_COUNT

		if can_merge:
			has_mergeable = true

		var card := _make_group_card(units, star, count, can_merge)
		var row: int = card_idx / 3
		var col: int = card_idx % 3
		card.position = Vector2(60 + col * (CARD_W + GAP), 110 + row * (CARD_H + GAP + 30))
		_ui_root.add_child(card)

		if can_merge and star < 3:
			var merge_btn := ThemeHelper.make_btn("MERGE x3 → ★%d" % (star + 1), Vector2(60 + col * (CARD_W + GAP), 110 + row * (CARD_H + GAP + 30) + CARD_H + 4), Vector2(CARD_W, 24), ThemeHelper.SUCCESS)
			merge_btn.add_theme_font_size_override("font_size", 11)
			merge_btn.pressed.connect(_do_merge.bind(cls, units))
			_ui_root.add_child(merge_btn)

		card_idx += 1

	if not has_mergeable:
		_info_label.text = "No groups of 3 same-class units to merge"
	else:
		_info_label.text = "Select a group of 3 identical units to merge into a stronger ★ unit"

func _make_group_card(units: Array, star: int, count: int, can_merge: bool) -> Button:
	var ud: UnitData = units[0]
	var b := Button.new()
	b.size = Vector2(CARD_W, CARD_H)
	b.disabled = true

	if can_merge:
		ThemeHelper.style_card(b, ud.weight)
	else:
		ThemeHelper.style_card(b, -1, true)

	var portrait := UnitFactory.make_portrait(ud, 0, 0.75)
	portrait.position = Vector2(4, 4)
	b.add_child(portrait)

	var px: int = 56
	var pw: int = CARD_W - px - 8

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(star) + ud.unit_name
	name_lbl.position = Vector2(px, 2)
	name_lbl.size = Vector2(pw, 18)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD if star > 1 else ThemeHelper.TEXT)
	name_lbl.add_theme_font_size_override("font_size", 13)
	b.add_child(name_lbl)

	var stats := Label.new()
	stats.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats.position = Vector2(px, 20)
	stats.size = Vector2(pw, 14)
	stats.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	stats.add_theme_font_size_override("font_size", 10)
	b.add_child(stats)

	var elem := Enums.element_name(ud.element_affinity)
	var elem_str := elem if elem != "" else "—"
	var extra := Label.new()
	extra.text = "x%d  %s" % [count, elem_str]
	extra.position = Vector2(px, 36)
	extra.size = Vector2(pw, 14)
	extra.add_theme_color_override("font_color", ThemeHelper.INFO)
	extra.add_theme_font_size_override("font_size", 10)
	b.add_child(extra)

	if can_merge and star < MAX_STAR:
		var preview := Label.new()
		var new_mult: float = _star_mult(star + 1)
		var ratio: float = new_mult / _star_mult(star)
		var preview_hp := ceili(ud.base_hp * ratio)
		var preview_atk := ceili(ud.base_attack * ratio)
		preview.text = "→ HP:%d ATK:%d" % [preview_hp, preview_atk]
		preview.position = Vector2(px, 54)
		preview.size = Vector2(pw, 14)
		preview.add_theme_color_override("font_color", ThemeHelper.SUCCESS)
		preview.add_theme_font_size_override("font_size", 10)
		b.add_child(preview)

	return b

func _do_merge(cls: int, units: Array):
	var star: int = units[0].star_level
	if star >= MAX_STAR:
		return

	var ud: UnitData = units[0]
	var new_mult: float = _star_mult(star + 1)
	var old_mult: float = _star_mult(star)

	var merged := UnitData.new()
	merged.unit_name = ud.unit_name
	merged.unit_class = ud.unit_class
	merged.weight = ud.weight
	merged.base_hp = ceili(ud.base_hp * new_mult / old_mult)
	merged.base_attack = ceili(ud.base_attack * new_mult / old_mult)
	merged.base_speed = ud.base_speed
	merged.cost = ud.cost
	merged.base_range = ud.base_range
	merged.aoe_type = ud.aoe_type
	merged.ability_type = ud.ability_type
	merged.ability_id = ud.ability_id
	merged.element_affinity = ud.element_affinity
	merged.star_level = star + 1
	if ud.items.size() > 0:
		for it in ud.items:
			merged.items.append(it)

	for i in 3:
		var idx: int = _roster.find(units[i])
		if idx >= 0:
			_roster.remove_at(idx)

	_roster.append(merged)
	_refresh()

func _star_mult(level: int) -> float:
	match level:
		2: return 1.5
		3: return 2.0
	return 1.0

func _on_continue():
	closed.emit(_roster)
	queue_free()
