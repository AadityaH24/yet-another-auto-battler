extends Control

const TILE_SIZE: int = 80
const PADDING := 20
const TOP_BAR_H := 36
const SIDE_W := 240

const RunManager = preload("res://scripts/main/run_manager.gd")
const MapScreen = preload("res://scripts/map/map_screen.gd")
const ShopScreen = preload("res://scripts/shop/shop_screen.gd")

var _state: BattleState
var _ai: AIController
var _running: bool = false
var _run: RunManager
var _map_screen: MapScreen
var _paused: bool = false
var _main_menu_open: bool = false
var _pause_menu_instance: PauseMenu

var _restart_btn: Button
var _result_label: Label
var _turn_label: Label
var _log_label: Label
var _team_info_label: Label
var _battlefield: Node2D
var _infusion_overlays: Node2D
var _ui_layer: CanvasLayer
var _viewport_size: Vector2
var _tooltip_panel: Panel
var _taken_label: Label

var _grid_offset: Vector2
var _cur_grid_w: int = 4
var _cur_grid_h: int = 4

var _sections := {}
var _visual_overlays: Node2D

func _ready():
	EventBus.unit_damaged.connect(_on_unit_damaged)
	_viewport_size = Vector2(get_viewport().size)
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

func _process(_delta: float):
	if _state and _tooltip_panel:
		_update_tooltip()

func _show_main_menu():
	_main_menu_open = true
	var menu := MainMenu.new()
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
	_pause_menu_instance = PauseMenu.new()
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
	EventBus.unit_damaged.disconnect(_on_unit_damaged)
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
	_tooltip_panel.hide()
	_show_main_menu()

func _compute_sections():
	var vs := _viewport_size
	var top_bar := Rect2(PADDING, PADDING, vs.x - 2 * PADDING, TOP_BAR_H)
	var content_top := top_bar.end.y + PADDING
	var content_bot := vs.y - PADDING
	var content_h := content_bot - content_top
	var left_panel := Rect2(PADDING, content_top, SIDE_W, content_h)
	var right_panel := Rect2(vs.x - PADDING - SIDE_W, content_top, SIDE_W, content_h)
	var center_area := Rect2(left_panel.end.x + PADDING, content_top, right_panel.position.x - left_panel.end.x - 2 * PADDING, content_h)
	_sections = {
		top_bar = top_bar,
		left_panel = left_panel,
		right_panel = right_panel,
		center_area = center_area,
	}

func _compute_layout():
	var center := _sections.center_area as Rect2
	var grid_px := _cur_grid_w * TILE_SIZE
	var grid_py := _cur_grid_h * TILE_SIZE
	_grid_offset = Vector2(
		center.position.x + (center.size.x - grid_px) / 2,
		center.position.y + (center.size.y - grid_py) / 2
	)

func _build_background():
	add_child(ThemeHelper.make_bg())

func _build_battlefield():
	_battlefield = Node2D.new()
	add_child(_battlefield)
	_infusion_overlays = Node2D.new()
	_battlefield.add_child(_infusion_overlays)
	_visual_overlays = Node2D.new()
	_visual_overlays.name = "VisualOverlays"
	_battlefield.add_child(_visual_overlays)
	_build_grid_border()
	_build_grid_cells()
	_build_zone_tags()

func _build_grid_border():
	var grid_px := _cur_grid_w * TILE_SIZE
	var grid_py := _cur_grid_h * TILE_SIZE
	var bg := ColorRect.new()
	bg.color = ThemeHelper.BG_PANEL
	bg.position = _grid_offset - Vector2.ONE * 3
	bg.size = Vector2(grid_px + 6, grid_py + 6)
	_battlefield.add_child(bg)
	for side in ["top", "left", "bottom", "right"]:
		var r := ColorRect.new()
		r.color = ThemeHelper.BORDER if side == "top" or side == "left" else ThemeHelper.BG_DARK
		match side:
			"top": r.position = _grid_offset - Vector2.ONE * 3; r.size = Vector2(grid_px + 6, 1)
			"left": r.position = _grid_offset - Vector2.ONE * 3; r.size = Vector2(1, grid_py + 6)
			"bottom": r.position = _grid_offset + Vector2(-3, grid_py + 3); r.size = Vector2(grid_px + 6, 1)
			"right": r.position = _grid_offset + Vector2(grid_px + 3, -3); r.size = Vector2(1, grid_py + 6)
		_battlefield.add_child(r)

func _build_grid_cells():
	for y in _cur_grid_h:
		for x in _cur_grid_w:
			var cell := Node2D.new()
			cell.position = _grid_offset + Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var is_dark := (x + y) % 2 == 0
			var base := Color("#141810") if is_dark else Color("#1a1e14")
			var bg := ColorRect.new()
			bg.size = Vector2(TILE_SIZE, TILE_SIZE)
			bg.color = base
			cell.add_child(bg)
			for edge in ["hl", "vl", "sh", "sv"]:
				var ln := ColorRect.new()
				match edge:
					"hl": ln.size = Vector2(TILE_SIZE, 1); ln.color = base.lightened(0.08)
					"vl": ln.size = Vector2(1, TILE_SIZE); ln.color = base.lightened(0.08)
					"sh": ln.size = Vector2(TILE_SIZE, 1); ln.position = Vector2(0, TILE_SIZE - 1); ln.color = base.darkened(0.1)
					"sv": ln.size = Vector2(1, TILE_SIZE); ln.position = Vector2(TILE_SIZE - 1, 0); ln.color = base.darkened(0.1)
				cell.add_child(ln)
			_battlefield.add_child(cell)

func _build_zone_tags():
	var grid_px := _cur_grid_w * TILE_SIZE
	var grid_py := _cur_grid_h * TILE_SIZE
	var tag_h := 18
	var tag_margin := 4
	var enemy_side := true
	for tag in ["enemy", "player"]:
		var col := ThemeHelper.DANGER if enemy_side else ThemeHelper.INFO
		var panel := ColorRect.new()
		panel.color = Color(col.r, col.g, col.b, 0.4 if enemy_side else 0.3)
		panel.position = _grid_offset + Vector2(0, -(tag_h + tag_margin) if enemy_side else grid_py + tag_margin)
		panel.size = Vector2(grid_px, tag_h)
		_battlefield.add_child(panel)
		var lbl := Label.new()
		lbl.text = "ENEMY" if enemy_side else "PLAYER"
		lbl.position = _grid_offset + Vector2(0, -(tag_h + tag_margin - 1) if enemy_side else grid_py + tag_margin + 1)
		lbl.size = Vector2(grid_px, tag_h - 2)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(col.r, col.g, col.b, 0.8))
		lbl.add_theme_font_size_override("font_size", 11)
		_battlefield.add_child(lbl)
		enemy_side = false

func _build_ui():
	_compute_sections()
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 1
	add_child(_ui_layer)

	var vs := _viewport_size

	_restart_btn = ThemeHelper.make_btn("Restart", Vector2(vs.x / 2 - 100, vs.y - 120), Vector2(200, 50))
	_restart_btn.pressed.connect(_on_restart)
	_restart_btn.hide()
	_ui_layer.add_child(_restart_btn)

	_result_label = ThemeHelper.make_label("", Vector2(vs.x / 2 - 300, 60), Vector2(600, 60), 40, ThemeHelper.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_result_label.hide()
	_ui_layer.add_child(_result_label)

	var tb := _sections.top_bar as Rect2
	_turn_label = ThemeHelper.make_label("", tb.position, tb.size, 20, ThemeHelper.GOLD)
	_turn_label.hide()
	_ui_layer.add_child(_turn_label)

	var lp := _sections.left_panel as Rect2
	_team_info_label = ThemeHelper.make_label("", lp.position, lp.size, 12, ThemeHelper.TEXT_DIM)
	_team_info_label.hide()
	_ui_layer.add_child(_team_info_label)

	var rp := _sections.right_panel as Rect2
	_log_label = ThemeHelper.make_label("", rp.position, rp.size, 14, ThemeHelper.TEXT)
	_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log_label.hide()
	_ui_layer.add_child(_log_label)

	_tooltip_panel = Panel.new()
	_tooltip_panel.hide()
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui_layer.add_child(_tooltip_panel)

func _build_tooltip_content(unit: UnitInstance) -> Control:
	var container := VBoxContainer.new()
	container.position = Vector2(8, 6)
	container.add_theme_constant_override("separation", 2)

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(unit.unit_data.star_level) + unit.unit_data.unit_name
	name_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	name_lbl.add_theme_font_size_override("font_size", 15)
	container.add_child(name_lbl)

	var elem_str := Enums.element_name(unit.unit_data.element_affinity)
	var elem_col := Enums.element_color(unit.unit_data.element_affinity)
	var elem_lbl := Label.new()
	elem_lbl.text = elem_str if elem_str != "" else "No Element"
	elem_lbl.add_theme_color_override("font_color", elem_col)
	elem_lbl.add_theme_font_size_override("font_size", 12)
	container.add_child(elem_lbl)

	var stats_lbl := Label.new()
	var cls_str := "Light" if unit.unit_data.weight == Enums.UnitWeight.LIGHT else "Heavy"
	stats_lbl.text = "%s  HP:%d/%d  ATK:%d  SPD:%d" % [cls_str, unit.current_hp, UnitData.total_hp(unit.unit_data), unit.current_attack, unit.current_speed]
	stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT)
	stats_lbl.add_theme_font_size_override("font_size", 11)
	container.add_child(stats_lbl)

	var extra_lbl := Label.new()
	extra_lbl.text = "RNG:%d  Cost:%d" % [unit.current_range, unit.unit_data.cost]
	extra_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	extra_lbl.add_theme_font_size_override("font_size", 10)
	container.add_child(extra_lbl)

	if unit.unit_data.ability_id != "":
		var abil_lbl := Label.new()
		abil_lbl.text = unit.unit_data.ability_id.replace("_", " ").capitalize()
		abil_lbl.add_theme_color_override("font_color", ThemeHelper.SUCCESS)
		abil_lbl.add_theme_font_size_override("font_size", 10)
		container.add_child(abil_lbl)

	if unit.status_effects.size() > 0:
		var statuses := PackedStringArray()
		for e in unit.status_effects:
			statuses.append(e.capitalize())
		var status_lbl := Label.new()
		status_lbl.text = "Status: " + ", ".join(statuses)
		status_lbl.add_theme_color_override("font_color", Color("#c8a840"))
		status_lbl.add_theme_font_size_override("font_size", 10)
		container.add_child(status_lbl)

	container.size = container.get_combined_minimum_size()
	return container

func _update_tooltip():
	var mouse_pos := get_viewport().get_mouse_position()
	var hovered_unit: UnitInstance = null

	for u in _state.units:
		if not u.is_alive() or not u.visible:
			continue
		var center := _grid_to_world(u.grid_pos)
		var half := TILE_SIZE / 2.0
		var rect := Rect2(center.x - half, center.y - half, TILE_SIZE, TILE_SIZE)
		if rect.has_point(mouse_pos):
			hovered_unit = u
			break

	if hovered_unit:
		var style := _tooltip_panel.get_theme_stylebox("panel", "TooltipPanel")
		if not style:
			style = StyleBoxFlat.new()
			(style as StyleBoxFlat).bg_color = ThemeHelper.BG_PANEL
			(style as StyleBoxFlat).border_color = ThemeHelper.GOLD
			(style as StyleBoxFlat).border_width_top = 1
			(style as StyleBoxFlat).border_width_left = 1
			(style as StyleBoxFlat).border_width_bottom = 1
			(style as StyleBoxFlat).border_width_right = 1
			(style as StyleBoxFlat).corner_radius_top_left = 4
			(style as StyleBoxFlat).corner_radius_top_right = 4
			(style as StyleBoxFlat).corner_radius_bottom_left = 4
			(style as StyleBoxFlat).corner_radius_bottom_right = 4
			_tooltip_panel.add_theme_stylebox_override("panel", style)

		for c in _tooltip_panel.get_children():
			c.queue_free()
		var content := _build_tooltip_content(hovered_unit)
		_tooltip_panel.add_child(content)
		_tooltip_panel.size = content.size + Vector2(16, 12)

		var tip_pos := mouse_pos + Vector2(16, 16)
		var vs := _viewport_size
		if tip_pos.x + _tooltip_panel.size.x > vs.x:
			tip_pos.x = mouse_pos.x - _tooltip_panel.size.x - 8
		if tip_pos.y + _tooltip_panel.size.y > vs.y:
			tip_pos.y = mouse_pos.y - _tooltip_panel.size.y - 8
		_tooltip_panel.position = tip_pos
		_tooltip_panel.show()
	else:
		_tooltip_panel.hide()

func _on_unit_damaged(unit: Node2D, attacker: Node2D, amount: int):
	if not _battlefield:
		return
	var num := DamageNumber.new()
	var world_pos := _grid_to_world(unit.grid_pos)
	var is_crit := false
	if attacker and unit.unit_data.element_affinity != Enums.ElementType.NONE:
		is_crit = Enums.element_advantage(attacker.unit_data.element_affinity, unit.unit_data.element_affinity) > 0
	num.start(amount, world_pos, is_crit)
	_battlefield.add_child(num)

func _show_aoe_preview(attacker: Node2D, target: Node2D):
	if not _state or not _visual_overlays:
		return
	var tiles := CombatEngine.get_aoe_tiles(_state, attacker, target)
	var color := Color(ThemeHelper.DANGER.r, ThemeHelper.DANGER.g, ThemeHelper.DANGER.b, 0.35)
	for tile in tiles:
		var overlay := ColorRect.new()
		overlay.position = _grid_offset + Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
		overlay.size = Vector2(TILE_SIZE, TILE_SIZE)
		overlay.color = color
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_visual_overlays.add_child(overlay)

func _clear_visual_overlays():
	if _visual_overlays:
		for c in _visual_overlays.get_children():
			c.queue_free()

func _show_hit_effect(tile: Vector2i):
	if not _visual_overlays:
		return
	var flash := ColorRect.new()
	flash.position = _grid_offset + Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
	flash.size = Vector2(TILE_SIZE, TILE_SIZE)
	flash.color = Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.5)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_overlays.add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.25)
	tween.tween_callback(flash.queue_free)

func _show_draft():
	var draft := DraftScreen.new()
	draft.confirmed.connect(_on_draft_confirmed)
	add_child(draft)
	draft.start(_get_available_units(), 10)

func _get_available_units() -> Array[UnitData]:
	var result: Array[UnitData] = []
	for cls in UnitFactory.ALL_CLASSES:
		result.append(_make_unit_by_class(cls))
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

func _on_map_node_selected(node: MapNodeData):
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

func _do_shop(_node: MapNodeData):
	var shop := ShopScreen.new()
	shop.closed.connect(_on_shop_closed)
	add_child(shop)
	shop.start(_run.gold, _run.player_roster)

func _on_shop_closed(gold: int, roster: Array[UnitData]):
	_run.gold = gold
	_run.player_roster = roster
	_after_node()

func _do_treasure(_node: MapNodeData):
	var vs := _viewport_size
	_run.gold += 5
	var popup := ThemeHelper.make_label("Treasure! +5 Gold", Vector2(vs.x / 2 - 300, vs.y / 2 - 100), Vector2(600, 50), 28, ThemeHelper.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(popup)
	var btn := ThemeHelper.make_btn("Continue", Vector2(vs.x / 2 - 100, vs.y / 2), Vector2(200, 50), ThemeHelper.SUCCESS)
	btn.pressed.connect(func():
		popup.queue_free()
		btn.queue_free()
		_after_node()
	)
	_ui_layer.add_child(btn)

func _do_rest(_node: MapNodeData):
	var merge := MergeScreen.new()
	merge.closed.connect(_on_rest_closed)
	add_child(merge)
	merge.start(_run.player_roster)

func _on_rest_closed(roster: Array[UnitData]):
	_run.player_roster = roster
	_after_node()

func _show_deployment(node: MapNodeData):
	_turn_label.hide()
	_log_label.hide()
	_team_info_label.hide()

	var enemy_data: Array[UnitData] = _generate_enemy_team_from_budget(node.enemy_budget)

	var dep := DeploymentScreen.new()
	dep.confirmed.connect(func(units: Array[UnitData], positions: Array[Vector2i]):
		_start_battle(node, units, positions, enemy_data)
	)
	add_child(dep)
	dep.start(_run.player_roster, node.grid_w, node.grid_h, enemy_data, _run.item_inventory)

func _start_battle(node: MapNodeData, player_units: Array[UnitData], player_positions: Array[Vector2i], enemy_data: Array[UnitData]):
	_turn_label.show()
	_log_label.show()
	_team_info_label.show()

	_cur_grid_w = node.grid_w
	_cur_grid_h = node.grid_h
	_compute_sections()
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
	var class_pool: Array[int] = UnitFactory.ALL_CLASSES.duplicate()
	class_pool.shuffle()

	var units: Array[UnitData] = []
	var remaining: int = budget
	var max_units: int = mini(5, 3 + budget / 4)
	for cls in class_pool:
		var cost: int = UnitFactory.CLASS_COSTS[cls]
		if remaining < 2 or units.size() >= max_units:
			break
		if cost <= remaining:
			units.append(_make_unit_by_class(cls))
			remaining -= cost
	if units.size() == 0:
		units.append(_make_unit_by_class(Enums.UnitClass.SOLDIER))
	return units

func _run_battle_loop():
	while _state and not _state.is_over():
		_state.turn_number += 1
		_turn_label.text = "Turn %d" % _state.turn_number
		await get_tree().create_timer(0.4).timeout
		if not _state:
			return
		CombatEngine.tick_all_statuses(_state)
		_update_infusion_visuals()
		CombatEngine.check_win_condition(_state)
		if _state.is_over():
			break
		var order := CombatEngine.calculate_turn_order(_state)
		for unit in order:
			if not unit.is_alive():
				continue
			if await _execute_unit_turn(unit):
				break
	_running = false
	if _state:
		EventBus.battle_ended.emit(_state.winner)
		await get_tree().create_timer(0.5).timeout
		await _handle_battle_end()

func _execute_unit_turn(unit: Node2D) -> bool:
	_highlight_unit(unit, true)
	await get_tree().create_timer(0.2).timeout
	if not _state:
		return true
	CombatEngine.on_turn_start(_state, unit)
	var action := _ai.decide_action(_state, unit)

	if action.action_type == BattleAction.ActionType.ATTACK and action.target_unit and action.target_unit.is_alive():
		_show_aoe_preview(unit, action.target_unit)
		await get_tree().create_timer(0.25).timeout
		if not _state:
			return true
		_clear_visual_overlays()
		if not await _animate_tween(unit.animate_attack(_grid_to_world(action.target_unit.grid_pos))):
			return true
	elif action.action_type == BattleAction.ActionType.MOVE:
		if not await _animate_tween(unit.animate_move(_grid_to_world(action.target_tile))):
			return true

	CombatEngine.execute_action(_state, unit, action)
	if action.action_type == BattleAction.ActionType.ATTACK and action.target_unit:
		var aoe_tiles := CombatEngine.get_aoe_tiles(_state, unit, action.target_unit)
		for t in aoe_tiles:
			_show_hit_effect(t)
	unit.position = _grid_to_world(unit.grid_pos)
	unit.update_visual()
	_update_infusion_visuals()
	_handle_dead_units()
	unit.position = _grid_to_world(unit.grid_pos)
	unit.update_visual()
	_update_team_info()

	var msg := _describe_action(unit, action)
	_log(msg)
	_highlight_unit(unit, false)
	if not _state or _state.is_over():
		return true
	await get_tree().create_timer(0.2).timeout
	return not _state

func _animate_tween(tw: Tween) -> bool:
	while tw and tw.is_valid() and not tw.finished:
		await get_tree().process_frame
	return _state != null

func _handle_dead_units():
	var dead: Array[Node2D] = []
	for u in _state.units:
		if not u.is_alive() and u.visible:
			dead.append(u)
	for u in dead:
		_animate_tween(u.animate_death())
		u.visible = false

func _handle_battle_end():
	if not _state:
		return
	if _state.winner == 0:
		_run.gold += 2
		_clear_battlefield()
		await _show_reward()
	else:
		_clear_battlefield()
		_result_label.text = "DEFEAT"
		_result_label.add_theme_color_override("font_color", ThemeHelper.DANGER)
		_result_label.show()
		_restart_btn.show()

func _on_next_act():
	var vs := _viewport_size
	var msg := ThemeHelper.make_label("Act %d Complete!" % (_run.act - 1), Vector2(vs.x / 2 - 300, vs.y / 2 - 150), Vector2(600, 60), 36, ThemeHelper.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(msg)
	var btn := ThemeHelper.make_btn("Continue to Act %d" % _run.act, Vector2(vs.x / 2 - 125, vs.y / 2 - 50), Vector2(250, 50), ThemeHelper.SUCCESS)
	btn.pressed.connect(func():
		msg.queue_free()
		btn.queue_free()
		_show_map()
	)
	_ui_layer.add_child(btn)

func _update_infusion_visuals():
	for c in _infusion_overlays.get_children():
		c.queue_free()
	if not _state:
		return
	for tile in _state.tile_infusions:
		var elem: int = _state.tile_infusions[tile]
		var overlay := ColorRect.new()
		overlay.position = _grid_offset + Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)
		overlay.size = Vector2(TILE_SIZE, TILE_SIZE)
		var col := Enums.element_color(elem)
		col.a = 0.25
		overlay.color = col
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_infusion_overlays.add_child(overlay)

func _clear_battlefield():
	_state = null
	if _battlefield:
		_battlefield.queue_free()
		_battlefield = null

func _after_node():
	var res = _run.on_node_completed()
	if res == "victory":
		_result_label.text = "YOU WIN!"
		_result_label.add_theme_color_override("font_color", ThemeHelper.GOLD)
		_result_label.show()
		_restart_btn.show()
	elif res == "next_act":
		_on_next_act()
	else:
		_show_map()

func _show_reward():
	var vs := _viewport_size
	var bg := ColorRect.new()
	bg.color = Color(ThemeHelper.BG_DARK.r, ThemeHelper.BG_DARK.g, ThemeHelper.BG_DARK.b, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui_layer.add_child(bg)

	var title := ThemeHelper.make_label("Choose a Reward", Vector2(vs.x / 2 - 300, 60), Vector2(600, 40), 28, ThemeHelper.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(title)

	var card_w := 140
	var card_h := 100
	var start_x := 0
	var start_y := 180
	var chosen := [false]

	var rewards := _build_reward_pool()
	var skip_btn := ThemeHelper.make_btn("Skip", Vector2(vs.x / 2 - 70, 400), Vector2(140, 40))
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

	var card_area_w: int = rewards.size() * card_w + (rewards.size() - 1) * 20
	start_x = int((vs.x - card_area_w) / 2)

	for i in rewards.size():
		var entry = rewards[i]
		var b := Button.new()
		b.set_meta("reward_card", true)
		b.position = Vector2(start_x + i * (card_w + 20), start_y)
		b.size = Vector2(card_w, card_h)
		_ui_layer.add_child(b)

		if entry is UnitData:
			ThemeHelper.style_card(b, entry.weight)
			UnitFactory.add_card_labels(b, entry, card_w)
			_connect_reward_unit(b, entry, chosen, bg, title, skip_btn)
		elif entry is ItemData:
			_make_item_card(b, entry)
			_connect_reward_item(b, entry, chosen, bg, title, skip_btn)


func _connect_reward_unit(b: Button, ud: UnitData, chosen: Array, bg: ColorRect, title: Label, skip_btn: Button):
	b.pressed.connect(func():
		if chosen[0]: return
		chosen[0] = true
		_run.player_roster.append(ud)
		_cleanup_rewards(bg, title, skip_btn)
		_show_reward_taken("+ " + ud.unit_name)
		await get_tree().create_timer(1.0).timeout
		_after_reward()
	)

func _connect_reward_item(b: Button, item: ItemData, chosen: Array, bg: ColorRect, title: Label, skip_btn: Button):
	b.pressed.connect(func():
		if chosen[0]: return
		chosen[0] = true
		_equip_item_to_roster(item)
		_cleanup_rewards(bg, title, skip_btn)
		_show_reward_taken("+ " + item.item_name)
		await get_tree().create_timer(1.0).timeout
		_after_reward()
	)

func _build_reward_pool() -> Array:
	var pool: Array = []
	var units: Array[UnitData] = []
	var classes := UnitFactory.ALL_CLASSES.duplicate()
	classes.shuffle()
	for i in mini(2, classes.size()):
		units.append(_make_unit_by_class(classes[i]))
	for u in units:
		pool.append(u)
	var items := ItemDatabase.get_random(2)
	for it in items:
		pool.append(it)
	pool.shuffle()
	return pool

func _cleanup_rewards(bg: ColorRect, title: Label, skip_btn: Button):
	bg.queue_free(); title.queue_free(); skip_btn.queue_free()
	for c in _ui_layer.get_children():
		if c is Button and c.has_meta("reward_card"):
			c.queue_free()
	if _taken_label:
		_taken_label.queue_free()
		_taken_label = null

func _show_reward_taken(text: String):
	if _taken_label:
		_taken_label.queue_free()
	var vs := _viewport_size
	_taken_label = ThemeHelper.make_label(text, Vector2(vs.x / 2 - 100, vs.y / 2 - 20), Vector2(200, 40), 24, ThemeHelper.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_ui_layer.add_child(_taken_label)

func _make_item_card(b: Button, item: ItemData):
	ThemeHelper.style_card(b, -1)
	b.add_theme_color_override("font_color", Enums.element_color(item.rarity + 2))
	var bg := ColorRect.new()
	bg.size = Vector2(140, 100)
	bg.color = Color.TRANSPARENT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bg)
	var icon := Label.new()
	icon.text = item.icon_char
	icon.position = Vector2(8, 8)
	icon.size = Vector2(60, 40)
	icon.add_theme_font_size_override("font_size", 22)
	icon.add_theme_color_override("font_color", Enums.element_color(item.rarity + 2))
	bg.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = item.item_name
	name_lbl.position = Vector2(8, 50)
	name_lbl.size = Vector2(124, 18)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	name_lbl.add_theme_font_size_override("font_size", 12)
	bg.add_child(name_lbl)
	var desc := Label.new()
	desc.text = item.description
	desc.position = Vector2(8, 68)
	desc.size = Vector2(124, 28)
	desc.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	desc.add_theme_font_size_override("font_size", 9)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bg.add_child(desc)

func _equip_item_to_roster(item: ItemData):
	_run.item_inventory.append(item)

func _after_reward():
	if _taken_label:
		_taken_label.queue_free()
		_taken_label = null
	var res = _run.on_node_completed()
	if res == "victory":
		_result_label.text = "YOU WIN!"
		_result_label.add_theme_color_override("font_color", ThemeHelper.GOLD)
		_result_label.show()
		_restart_btn.show()
	elif res == "next_act":
		_on_next_act()
	else:
		_show_map()

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

func _describe_action(unit: Node2D, action: BattleAction) -> String:
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

func _highlight_unit(unit: Node2D, on: bool):
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

func _make_unit_by_class(cls: int) -> UnitData:
	return UnitFactory.make_unit_by_class(cls)
