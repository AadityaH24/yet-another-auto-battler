extends Control

const TILE_SIZE: int = 80

const RunManager = preload("res://scripts/main/run_manager.gd")
const MapScreen = preload("res://scripts/map/map_screen.gd")
const MapNodeData = preload("res://scripts/map/map_node_data.gd")
const ShopScreen = preload("res://scripts/shop/shop_screen.gd")
const DeploymentScreen = preload("res://scripts/battle/deployment_screen.gd")

var _state: BattleState
var _ai: AIController
var _running: bool = false
var _run
var _map_screen
var _paused: bool = false
var _main_menu_open: bool = false
var _pause_menu_instance = null

var _restart_btn: Button
var _result_label: Label
var _turn_label: Label
var _log_label: Label
var _team_info_label: Label
var _battlefield: Node2D
var _ui_layer: CanvasLayer

var _grid_offset: Vector2
var _cur_grid_w: int = 4
var _cur_grid_h: int = 4

func _ready():
	_ai = AIController.new()
	_build_background()
	_build_ui()
	_show_main_menu()

func _input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if _main_menu_open:
			return
		if _paused:
			_hide_pause_menu()
		else:
			_show_pause_menu()

func _show_main_menu():
	_main_menu_open = true
	var menu := preload("res://scripts/menu/main_menu.gd").new()
	menu.new_game.connect(func():
		_main_menu_open = false
		menu.queue_free()
		_start_game()
	)
	menu.quit_game.connect(func(): get_tree().quit())
	add_child(menu)

func _start_game():
	_show_draft()

func _show_pause_menu():
	_paused = true
	_pause_menu_instance = preload("res://scripts/menu/pause_menu.gd").new()
	_pause_menu_instance.resume.connect(func(): _paused = false)
	_pause_menu_instance.main_menu.connect(func():
		_paused = false
		_pause_menu_instance.queue_free()
		_pause_menu_instance = null
		_return_to_main_menu()
	)
	add_child(_pause_menu_instance)
	_pause_menu_instance.show_pause()

func _hide_pause_menu():
	if _pause_menu_instance:
		_pause_menu_instance.hide_pause()
		_pause_menu_instance.queue_free()
		_pause_menu_instance = null
	_paused = false

func _return_to_main_menu():
	for c in get_children():
		if c != _ui_layer:
			c.queue_free()
	if _battlefield:
		_battlefield = null
	_run = null
	_state = null
	_running = false
	_restart_btn.hide()
	_result_label.hide()
	_turn_label.hide()
	_log_label.hide()
	_team_info_label.hide()
	_show_main_menu()

func _compute_layout():
	var vs := Vector2(get_viewport().size)
	var grid_px := _cur_grid_w * TILE_SIZE
	var grid_py := _cur_grid_h * TILE_SIZE
	_grid_offset = Vector2((vs.x - grid_px) / 2, (vs.y - grid_py) / 2)

func _make_label(text: String, pos: Vector2, p_size: Vector2, font_size: int = 16, color: Color = Color.WHITE, align: int = -1) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = p_size
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if align >= 0:
		l.horizontal_alignment = align as HorizontalAlignment
	return l

func _make_btn(text: String, pos: Vector2, p_size: Vector2, color: Color = Color(0.2, 0.5, 0.3)) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = p_size
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
	var sp := StyleBoxFlat.new()
	sp.bg_color = color.darkened(0.15)
	sp.corner_radius_top_left = 4
	sp.corner_radius_top_right = 4
	sp.corner_radius_bottom_left = 4
	sp.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("pressed", sp)
	return b

func _build_background():
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _build_battlefield():
	_battlefield = Node2D.new()
	add_child(_battlefield)

	var grid_px := _cur_grid_w * TILE_SIZE
	var grid_py := _cur_grid_h * TILE_SIZE

	var border := ColorRect.new()
	border.color = Color(0.3, 0.3, 0.35)
	border.position = _grid_offset - Vector2.ONE * 2
	border.size = Vector2(grid_px + 4, grid_py + 4)
	_battlefield.add_child(border)

	for y in _cur_grid_h:
		for x in _cur_grid_w:
			var r := ColorRect.new()
			r.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
			r.position = _grid_offset + Vector2(x * TILE_SIZE, y * TILE_SIZE) + Vector2.ONE * 0.5
			var is_dark := (x + y) % 2 == 0
			r.color = Color(0.18, 0.2, 0.25) if is_dark else Color(0.22, 0.25, 0.3)
			_battlefield.add_child(r)

	var row_labels := ["A", "B", "C", "D", "E", "F"]
	for y in _cur_grid_h:
		var lbl := Label.new()
		lbl.text = row_labels[y]
		lbl.position = _grid_offset + Vector2(-20, y * TILE_SIZE + TILE_SIZE * 0.5 - 8)
		lbl.size = Vector2(16, 16)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_battlefield.add_child(lbl)

	for x in _cur_grid_w:
		var lbl := Label.new()
		lbl.text = str(x + 1)
		lbl.position = _grid_offset + Vector2(x * TILE_SIZE + TILE_SIZE * 0.5 - 8, -20)
		lbl.size = Vector2(16, 16)
		lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_battlefield.add_child(lbl)

	var enemy_tag := Label.new()
	enemy_tag.text = "ENEMY"
	enemy_tag.position = _grid_offset + Vector2(0, -38)
	enemy_tag.size = Vector2(grid_px, 16)
	enemy_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_tag.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 0.6))
	enemy_tag.add_theme_font_size_override("font_size", 11)
	_battlefield.add_child(enemy_tag)

	var player_tag := Label.new()
	player_tag.text = "PLAYER"
	player_tag.position = _grid_offset + Vector2(0, grid_py + 4)
	player_tag.size = Vector2(grid_px, 16)
	player_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_tag.add_theme_color_override("font_color", Color(0.3, 0.6, 1.0, 0.6))
	player_tag.add_theme_font_size_override("font_size", 11)
	_battlefield.add_child(player_tag)

func _build_ui():
	var vs := Vector2(get_viewport().size)
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 1
	add_child(_ui_layer)

	var btn_x := vs.x / 2 - 100
	var btn_y := vs.y - 120

	_restart_btn = _make_btn("Restart", Vector2(btn_x, btn_y), Vector2(200, 50), Color(0.3, 0.3, 0.3))
	_restart_btn.pressed.connect(_on_restart)
	_restart_btn.hide()
	_ui_layer.add_child(_restart_btn)

	_result_label = _make_label("", Vector2(vs.x / 2 - 300, 60), Vector2(600, 60), 40, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	_result_label.hide()
	_ui_layer.add_child(_result_label)

	_turn_label = _make_label("", Vector2(20, 20), Vector2(200, 30), 20)
	_turn_label.hide()
	_ui_layer.add_child(_turn_label)

	_log_label = _make_label("", Vector2(20, vs.y - 220), Vector2(vs.x - 400, 200), 14)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.hide()
	_ui_layer.add_child(_log_label)

	_team_info_label = _make_label("", Vector2(20, 60), Vector2(400, vs.y - 300), 12, Color(0.7, 0.7, 0.8))
	_team_info_label.hide()
	_ui_layer.add_child(_team_info_label)

func _show_draft():
	var draft := DraftScreen.new()
	draft.confirmed.connect(_on_draft_confirmed)
	add_child(draft)
	draft.start(_get_available_units(), 10)

func _get_available_units() -> Array[UnitData]:
	var result: Array[UnitData] = []
	result.append(_make_unit_by_class(Enums.UnitClass.SOLDIER))
	result.append(_make_unit_by_class(Enums.UnitClass.MAGE))
	result.append(_make_unit_by_class(Enums.UnitClass.SCOUT))
	result.append(_make_unit_by_class(Enums.UnitClass.KNIGHT))
	result.append(_make_unit_by_class(Enums.UnitClass.BERSERKER))
	result.append(_make_unit_by_class(Enums.UnitClass.SHIELDBEARER))
	result.append(_make_unit_by_class(Enums.UnitClass.LANCER))
	result.append(_make_unit_by_class(Enums.UnitClass.ARCHER))
	result.append(_make_unit_by_class(Enums.UnitClass.WARLOCK))
	result.append(_make_unit_by_class(Enums.UnitClass.CLERIC))
	result.append(_make_unit_by_class(Enums.UnitClass.ELEMENTALIST))
	return result

func _on_draft_confirmed(roster: Array[UnitData], remaining: int):
	_run = RunManager.new()
	_run.start_run(roster, remaining)
	_show_map()

func _show_map():
	_turn_label.hide()
	_log_label.hide()
	_team_info_label.hide()

	_map_screen = MapScreen.new()
	_map_screen.node_selected.connect(_on_map_node_selected)
	add_child(_map_screen)

	var data = _run.get_map_screen_data()
	_map_screen.show_map(data.act, data.nodes, data.current)

func _on_map_node_selected(node):
	_run.current_node = node
	_map_screen.queue_free()
	_map_screen = null

	match node.node_type:
		MapNodeData.Type.BATTLE, MapNodeData.Type.ELITE, MapNodeData.Type.BOSS:
			_show_deployment(node)
		MapNodeData.Type.SHOP:
			_do_shop(node)
		MapNodeData.Type.TREASURE:
			_do_treasure(node)
		MapNodeData.Type.REST:
			_do_rest(node)

func _on_restart():
	get_tree().reload_current_scene()

func _do_shop(_node):
	var shop := ShopScreen.new()
	shop.closed.connect(_on_shop_closed)
	add_child(shop)
	shop.start(_run.gold, _run.player_roster)

func _on_shop_closed(gold: int, roster: Array[UnitData]):
	_run.gold = gold
	_run.player_roster = roster
	_after_node()

func _do_treasure(_node):
	var vs := Vector2(get_viewport().size)
	_run.gold += 5
	var popup := _make_label("Treasure! +5 Gold", Vector2(vs.x / 2 - 300, vs.y / 2 - 100), Vector2(600, 50), 28, Color(1.0, 0.8, 0.3), HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(popup)
	var btn := _make_btn("Continue", Vector2(vs.x / 2 - 100, vs.y / 2), Vector2(200, 50))
	btn.pressed.connect(func():
		popup.queue_free()
		btn.queue_free()
		_after_node()
	)
	_ui_layer.add_child(btn)

func _do_rest(_node):
	var merge := preload("res://scripts/rest/merge_screen.gd").new()
	merge.closed.connect(_on_rest_closed)
	add_child(merge)
	merge.start(_run.player_roster)

func _on_rest_closed(roster: Array[UnitData]):
	_run.player_roster = roster
	_after_node()

func _show_deployment(node):
	_turn_label.hide()
	_log_label.hide()
	_team_info_label.hide()

	var enemy_data: Array[UnitData] = _generate_enemy_team_from_budget(node.enemy_budget)

	var dep := DeploymentScreen.new()
	dep.confirmed.connect(func(units: Array[UnitData], positions: Array[Vector2i]):
		_start_battle(node, units, positions, enemy_data)
	)
	add_child(dep)
	dep.start(_run.player_roster, node.grid_w, node.grid_h)

func _start_battle(node, player_units: Array[UnitData], player_positions: Array[Vector2i], enemy_data: Array[UnitData]):
	_turn_label.show()
	_log_label.show()
	_team_info_label.show()

	_cur_grid_w = node.grid_w
	_cur_grid_h = node.grid_h
	_compute_layout()

	_state = CombatEngine.create_battle_with_positions(player_units, player_positions, enemy_data, _cur_grid_w, _cur_grid_h)

	if _battlefield:
		_battlefield.queue_free()
	_build_battlefield()
	_battlefield.show()
	for u in _state.units:
		_battlefield.add_child(u)
		u.position = _grid_to_world(u.grid_pos)

	EventBus.battle_started.emit()
	_update_team_info()
	await get_tree().create_timer(0.5).timeout
	await _run_battle_loop()

func _generate_enemy_team_from_budget(budget: int) -> Array[UnitData]:
	var class_pool: Array[Dictionary] = [
		{"cls": Enums.UnitClass.SOLDIER, "cost": 2},
		{"cls": Enums.UnitClass.MAGE, "cost": 4},
		{"cls": Enums.UnitClass.SCOUT, "cost": 3},
		{"cls": Enums.UnitClass.KNIGHT, "cost": 3},
		{"cls": Enums.UnitClass.ELEMENTALIST, "cost": 4},
		{"cls": Enums.UnitClass.BERSERKER, "cost": 3},
		{"cls": Enums.UnitClass.SHIELDBEARER, "cost": 4},
		{"cls": Enums.UnitClass.LANCER, "cost": 3},
		{"cls": Enums.UnitClass.ARCHER, "cost": 3},
		{"cls": Enums.UnitClass.WARLOCK, "cost": 3},
		{"cls": Enums.UnitClass.CLERIC, "cost": 3},
	]
	class_pool.shuffle()

	var units: Array[UnitData] = []
	var remaining: int = budget
	var max_units: int = mini(5, 3 + budget / 4)
	for entry in class_pool:
		if remaining < 2 or units.size() >= max_units:
			break
		if entry.cost <= remaining:
			units.append(_make_unit_by_class(entry.cls))
			remaining -= entry.cost
	if units.size() == 0:
		units.append(_make_unit_by_class(Enums.UnitClass.SOLDIER))
	return units

func _run_battle_loop():
	while not _state.is_over():
		_state.turn_number += 1
		_turn_label.text = "Turn %d" % _state.turn_number
		await get_tree().create_timer(0.4).timeout

		var order := CombatEngine.calculate_turn_order(_state)
		for unit in order:
			if not unit.is_alive():
				continue

			_highlight_unit(unit, true)
			await get_tree().create_timer(0.2).timeout

			CombatEngine.on_turn_start(_state, unit)
			var action := _ai.decide_action(_state, unit)
			CombatEngine.execute_action(_state, unit, action)
			unit.position = _grid_to_world(unit.grid_pos)
			unit.update_visual()

			var msg := _describe_action(unit, action)
			_log(msg)
			_highlight_unit(unit, false)
			_update_team_info()

			if _state.is_over():
				break

			await get_tree().create_timer(0.25).timeout

	_running = false
	EventBus.battle_ended.emit(_state.winner)
	await get_tree().create_timer(0.5).timeout

	if _state.winner == 0:
		_run.gold += 2
		_clear_battlefield()
		await _show_reward()
	else:
		_clear_battlefield()
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		_result_label.show()
		_restart_btn.show()

func _on_next_act():
	var vs := Vector2(get_viewport().size)
	var msg := _make_label("Act %d Complete!" % (_run.act - 1), Vector2(vs.x / 2 - 300, vs.y / 2 - 150), Vector2(600, 60), 36, Color(0.3, 1.0, 0.3), HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(msg)
	var btn := _make_btn("Continue to Act %d" % _run.act, Vector2(vs.x / 2 - 125, vs.y / 2 - 50), Vector2(250, 50))
	btn.pressed.connect(func():
		msg.queue_free()
		btn.queue_free()
		_show_map()
	)
	_ui_layer.add_child(btn)

func _clear_battlefield():
	if _battlefield:
		_battlefield.queue_free()
		_battlefield = null

func _after_node():
	var res = _run.on_node_completed()
	if res == "victory":
		_result_label.text = "YOU WIN!"
		_result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		_result_label.show()
		_restart_btn.show()
	elif res == "next_act":
		_on_next_act()
	else:
		_show_map()

func _show_reward():
	var pool := _get_reward_pool()
	pool.shuffle()
	var count := mini(3, pool.size())

	var vs := Vector2(get_viewport().size)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.1, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(bg)

	var title := _make_label("Choose a Reward", Vector2(vs.x / 2 - 300, 60), Vector2(600, 40), 28, Color(0.3, 1.0, 0.3), 1)
	_ui_layer.add_child(title)

	var card_w := 140
	var card_h := 100
	var total_w := count * card_w + (count - 1) * 20
	var start_x := (vs.x - total_w) / 2
	var start_y := 180
	var chosen := [false]

	var skip_btn := _make_btn("Skip", Vector2(vs.x / 2 - 70, 400), Vector2(140, 40), Color(0.3, 0.3, 0.3))
	skip_btn.pressed.connect(func():
		if chosen[0]: return
		chosen[0] = true
		bg.queue_free(); title.queue_free(); skip_btn.queue_free()
		for c in _ui_layer.get_children():
			if c is Button and c != skip_btn and c.has_meta("reward_card"):
				c.queue_free()
		_after_reward()
	)
	_ui_layer.add_child(skip_btn)

	for i in count:
		var ud: UnitData = pool[i]
		var b := Button.new()
		b.set_meta("reward_card", true)
		b.position = Vector2(start_x + i * (card_w + 20), start_y)
		b.size = Vector2(card_w, card_h)

		var body_color := Color(0.2, 0.35, 0.55) if ud.weight == Enums.UnitWeight.LIGHT else Color(0.45, 0.15, 0.15)
		var sn := StyleBoxFlat.new()
		sn.bg_color = body_color
		sn.corner_radius_top_left = 6; sn.corner_radius_top_right = 6
		sn.corner_radius_bottom_left = 6; sn.corner_radius_bottom_right = 6
		b.add_theme_stylebox_override("normal", sn)
		var sh := StyleBoxFlat.new()
		sh.bg_color = body_color.lightened(0.3)
		sh.corner_radius_top_left = 6; sh.corner_radius_top_right = 6
		sh.corner_radius_bottom_left = 6; sh.corner_radius_bottom_right = 6
		b.add_theme_stylebox_override("hover", sh)

		var name_lbl := Label.new()
		var star_pre := "" if ud.star_level <= 1 else ("★★ " if ud.star_level == 2 else "★★★ ")
		name_lbl.text = star_pre + ud.unit_name; name_lbl.position = Vector2(6, 6)
		name_lbl.size = Vector2(card_w - 12, 20)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
		name_lbl.add_theme_font_size_override("font_size", 14)
		b.add_child(name_lbl)

		var stats_lbl := Label.new()
		stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
		stats_lbl.position = Vector2(6, 28); stats_lbl.size = Vector2(card_w - 12, 16)
		stats_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
		stats_lbl.add_theme_font_size_override("font_size", 10)
		b.add_child(stats_lbl)

		var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
		var type_lbl := Label.new()
		type_lbl.text = "[%s]" % cls_str; type_lbl.position = Vector2(6, 46)
		type_lbl.size = Vector2(card_w - 12, 16)
		type_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		type_lbl.add_theme_font_size_override("font_size", 10)
		b.add_child(type_lbl)

		var elem_lbl := Label.new()
		elem_lbl.text = Enums.element_name(ud.element_affinity)
		elem_lbl.position = Vector2(6, 62)
		elem_lbl.size = Vector2(card_w - 12, 14)
		elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
		elem_lbl.add_theme_font_size_override("font_size", 9)
		b.add_child(elem_lbl)

		b.pressed.connect(func():
			if chosen[0]: return
			chosen[0] = true
			_run.player_roster.append(ud)
			bg.queue_free(); title.queue_free(); skip_btn.queue_free()
			for c in _ui_layer.get_children():
				if c is Button and c.has_meta("reward_card"):
					c.queue_free()
			var taken := _make_label("+ " + ud.unit_name, Vector2(vs.x / 2 - 100, vs.y / 2 - 20), Vector2(200, 40), 24, Color(0.3, 1.0, 0.3), 1)
			_ui_layer.add_child(taken)
			await get_tree().create_timer(1.0).timeout
			taken.queue_free()
			_after_reward()
		)
		_ui_layer.add_child(b)

func _after_reward():
	var res = _run.on_node_completed()
	if res == "victory":
		_result_label.text = "YOU WIN!"
		_result_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		_result_label.show()
		_restart_btn.show()
	elif res == "next_act":
		_on_next_act()
	else:
		_show_map()

func _get_reward_pool() -> Array[UnitData]:
	var result: Array[UnitData] = []
	result.append(_make_unit_by_class(Enums.UnitClass.SOLDIER))
	result.append(_make_unit_by_class(Enums.UnitClass.MAGE))
	result.append(_make_unit_by_class(Enums.UnitClass.SCOUT))
	result.append(_make_unit_by_class(Enums.UnitClass.KNIGHT))
	result.append(_make_unit_by_class(Enums.UnitClass.BERSERKER))
	result.append(_make_unit_by_class(Enums.UnitClass.SHIELDBEARER))
	result.append(_make_unit_by_class(Enums.UnitClass.LANCER))
	result.append(_make_unit_by_class(Enums.UnitClass.ARCHER))
	result.append(_make_unit_by_class(Enums.UnitClass.WARLOCK))
	result.append(_make_unit_by_class(Enums.UnitClass.CLERIC))
	result.append(_make_unit_by_class(Enums.UnitClass.ELEMENTALIST))
	return result

func _update_team_info():
	if not _state:
		return
	var txt := ""
	for team_id in [0, 1]:
		var team_name := "PLAYER" if team_id == 0 else "ENEMY"
		txt += "--- " + team_name + " ---\n"
		for u in _state.units:
			if u.team != team_id:
				continue
			var elem_name := Enums.element_name(u.unit_data.element_affinity)
			var status := "HP:%d/%d" % [u.current_hp, u.unit_data.base_hp]
			var dead_str := " [DEAD]" if not u.is_alive() else ""
			txt += " %s[%s] %s%s\n" % [u.unit_data.unit_name, elem_name, status, dead_str]
		txt += "\n"
	_team_info_label.text = txt

func _describe_action(unit, action: BattleAction) -> String:
	var prefix := "P" if unit.team == 0 else "E"
	var unit_name: String = unit.unit_data.unit_name
	var u_elem := Enums.element_name(unit.unit_data.element_affinity)
	match action.action_type:
		BattleAction.ActionType.ATTACK:
			var target_name: String = action.target_unit.unit_data.unit_name
			var tprefix := "P" if action.target_unit.team == 0 else "E"
			var t_elem := Enums.element_name(action.target_unit.unit_data.element_affinity)
			return "%s[%s(%s)] attacks %s[%s(%s)] for %d dmg" % [prefix, unit_name, u_elem, tprefix, target_name, t_elem, unit.unit_data.base_attack]
		BattleAction.ActionType.MOVE:
			return "%s[%s(%s)] moves" % [prefix, unit_name, u_elem]
		BattleAction.ActionType.WAIT:
			return "%s[%s(%s)] waits" % [prefix, unit_name, u_elem]
	return ""

func _highlight_unit(unit, on: bool):
	if on:
		unit.scale = Vector2(1.15, 1.15)
	else:
		unit.scale = Vector2(1.0, 1.0)

func _log(msg: String):
	_log_label.text += msg + "\n"
	if _log_label.get_line_count() > 25:
		var lines := _log_label.text.split("\n")
		_log_label.text = "\n".join(lines.slice(lines.size() - 25))

func _grid_to_world(pos: Vector2i) -> Vector2:
	return _grid_offset + Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE) + Vector2(TILE_SIZE * 0.5, TILE_SIZE * 0.5)

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
