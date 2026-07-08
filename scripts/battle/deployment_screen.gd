class_name DeploymentScreen extends CanvasLayer

signal confirmed(units: Array[UnitData], positions: Array[Vector2i])

const TILE_SIZE: int = 80
const CARD_WIDTH: int = 110
const CARD_HEIGHT: int = 90
const CARD_GAP: int = 10
const BUTTON_WIDTH: int = 200
const BUTTON_HEIGHT: int = 50
const TITLE_AREA_HEIGHT: int = 90
const DRAG_THRESHOLD: int = 8

var _roster: Array[UnitData]
var _enemy_data: Array[UnitData]
var _item_inventory: Array[ItemData]
var _selected_idx: int = -1
var _viewport_size: Vector2
var _grid: Array[int] = []
var _grid_w: int = 4
var _grid_h: int = 4

var _grid_nodes: Dictionary = {}
var _grid_sprite_nodes: Dictionary = {}
var _grid_root: Node2D
var _roster_root: Node2D
var _ready_btn: Button
var _info_label: Label

var _drag_active: bool = false
var _drag_idx: int = -1
var _drag_preview: Control = null
var _drag_press_pos: Vector2 = Vector2.ZERO

var _grid_offset: Vector2

var _item_panel: Panel
var _item_panel_visible: bool = false
var _selected_item: ItemData = null

func _init():
	layer = 2

func start(roster: Array[UnitData], grid_w: int = 4, grid_h: int = 4, enemy_data: Array[UnitData] = [], item_inventory: Array[ItemData] = []):
	_roster = roster
	_enemy_data = enemy_data
	_item_inventory = item_inventory
	_grid_w = grid_w
	_grid_h = grid_h
	_grid.resize(_grid_w * _grid_h)
	for i in _grid_w * _grid_h:
		_grid[i] = -1
	_build_ui()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		if _selected_idx >= 0 or _drag_active:
			_cancel_selection()
			get_viewport().set_input_as_handled()

func _build_ui():
	var vs := Vector2(get_viewport().size)
	_viewport_size = vs
	add_child(ThemeHelper.make_bg())

	var title := ThemeHelper.make_title("Deploy Your Units", vs, 20, 28)
	add_child(title)

	_info_label = Label.new()
	_info_label.position = Vector2((vs.x - 400) / 2, 58)
	_info_label.size = Vector2(400, 20)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	_info_label.add_theme_font_size_override("font_size", 13)
	add_child(_info_label)

	var grid_px_w: int = _grid_w * TILE_SIZE
	var grid_px_h: int = _grid_h * TILE_SIZE
	var roster_area_h: int = CARD_HEIGHT + CARD_GAP * 3
	var grid_top: int = TITLE_AREA_HEIGHT
	var grid_bottom: int = vs.y - roster_area_h - BUTTON_HEIGHT - 20
	var avail_h: int = maxi(0, grid_bottom - grid_top)
	_grid_offset = Vector2(
		(vs.x - grid_px_w) / 2,
		grid_top + (avail_h - grid_px_h) / 2
	)

	_grid_root = Node2D.new()
	add_child(_grid_root)
	_build_grid_tiles()

	_build_zone_labels(grid_px_w)

	_roster_root = Node2D.new()
	add_child(_roster_root)

	_ready_btn = ThemeHelper.make_btn("Ready for Battle", Vector2((vs.x - BUTTON_WIDTH) / 2, vs.y - BUTTON_HEIGHT - 10), Vector2(BUTTON_WIDTH, BUTTON_HEIGHT), ThemeHelper.SUCCESS)
	_ready_btn.disabled = true
	_ready_btn.pressed.connect(_on_ready)
	add_child(_ready_btn)

	var items_btn := ThemeHelper.make_btn("Items (" + str(_item_inventory.size()) + ")", Vector2(10, vs.y - BUTTON_HEIGHT - 10), Vector2(120, BUTTON_HEIGHT), ThemeHelper.INFO)
	items_btn.pressed.connect(_toggle_item_panel)
	items_btn.set_meta("items_btn", true)
	add_child(items_btn)

	_item_panel = Panel.new()
	_item_panel.position = Vector2(10, TITLE_AREA_HEIGHT + 10)
	_item_panel.size = Vector2(vs.x - 20, 120)
	_item_panel.hide()
	_item_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_item_panel)

	_refresh()

func _build_grid_tiles():
	var player_start_row: int = maxi(0, _grid_h - 2)
	for y in _grid_h:
		for x in _grid_w:
			var pos: Vector2 = _grid_offset + Vector2(x * TILE_SIZE, y * TILE_SIZE)
			var is_player_zone: bool = y >= player_start_row
			var r := ColorRect.new()
			r.position = pos
			r.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
			if is_player_zone:
				r.color = Color("#181e24")
				r.mouse_filter = Control.MOUSE_FILTER_STOP
				r.gui_input.connect(_on_tile_input.bind(x, y, r))
			else:
				r.color = Color("#0a0808")
			_grid_root.add_child(r)
			_grid_nodes[Vector2i(x, y)] = r

			if is_player_zone:
				var lbl := Label.new()
				var col_lbl := str(x + 1)
				var row_lbl: String = ["A", "B", "C", "D", "E", "F"][y]
				lbl.text = "%s%s" % [row_lbl, col_lbl]
				lbl.position = pos + Vector2(TILE_SIZE / 2.0 - 10, TILE_SIZE / 2.0 - 8)
				lbl.size = Vector2(20, 16)
				lbl.add_theme_color_override("font_color", Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.3))
				lbl.add_theme_font_size_override("font_size", 11)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				_grid_root.add_child(lbl)

func _build_zone_labels(grid_px_w: int):
	var e := Label.new()
	e.text = "ENEMY ZONE"
	e.position = _grid_offset + Vector2(0, -18)
	e.size = Vector2(grid_px_w, 16)
	e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.add_theme_color_override("font_color", Color(ThemeHelper.DANGER.r, ThemeHelper.DANGER.g, ThemeHelper.DANGER.b, 0.4))
	e.add_theme_font_size_override("font_size", 10)
	_grid_root.add_child(e)

	var p := Label.new()
	p.text = "YOUR ZONE"
	var grid_px_h: int = _grid_h * TILE_SIZE
	p.position = _grid_offset + Vector2(0, grid_px_h + 4)
	p.size = Vector2(grid_px_w, 16)
	p.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_theme_color_override("font_color", Color(ThemeHelper.INFO.r, ThemeHelper.INFO.g, ThemeHelper.INFO.b, 0.4))
	p.add_theme_font_size_override("font_size", 10)
	_grid_root.add_child(p)

func _toggle_item_panel():
	_item_panel_visible = not _item_panel_visible
	_item_panel.visible = _item_panel_visible
	if _item_panel_visible:
		_refresh_item_panel()

func _refresh_item_panel():
	_update_items_button()
	for c in _item_panel.get_children():
		c.queue_free()
	var cell_w := 100
	var cell_h := 90
	var gap := 6
	var x := 8
	var y := 8
	var all_items: Array[ItemData] = []
	all_items.append_array(_item_inventory)
	for ud in _roster:
		for it in ud.items:
			all_items.append(it)

	if all_items.size() == 0:
		var lbl := Label.new()
		lbl.text = "No items available"
		lbl.position = Vector2(8, 8)
		lbl.size = Vector2(200, 20)
		lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
		lbl.add_theme_font_size_override("font_size", 13)
		_item_panel.add_child(lbl)
		return

	var legend := Label.new()
	legend.text = "Click an item, then click a unit card to equip. Click equipped item to unequip."
	legend.position = Vector2(8, 4)
	legend.size = Vector2(_item_panel.size.x - 16, 16)
	legend.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	legend.add_theme_font_size_override("font_size", 10)
	_item_panel.add_child(legend)

	# Collect [item, roster_idx, item_idx_in_unit] tuples
	# item_inventory items have roster_idx=-1
	var entries: Array = []
	for it in _item_inventory:
		entries.append([it, -1, -1])
	for ri in _roster.size():
		for ii in _roster[ri].items.size():
			entries.append([_roster[ri].items[ii], ri, ii])

	for idx in entries.size():
		var entry = entries[idx]
		var item: ItemData = entry[0]
		var roster_idx: int = entry[1]
		var item_idx: int = entry[2]
		var is_equipped := roster_idx >= 0

		var card := ColorRect.new()
		card.position = Vector2(x, y + 20)
		card.size = Vector2(cell_w, cell_h)
		card.color = ThemeHelper.BG_CARD
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		var sel_col := Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.3)
		if _selected_item == item:
			card.color = sel_col
		_item_panel.add_child(card)

		var icon := Label.new()
		icon.text = item.icon_char
		icon.position = Vector2(4, 4)
		icon.size = Vector2(30, 20)
		icon.add_theme_font_size_override("font_size", 16)
		icon.add_theme_color_override("font_color", Enums.element_color(item.rarity + 2))
		card.add_child(icon)

		var name_lbl := Label.new()
		name_lbl.text = item.item_name
		name_lbl.position = Vector2(36, 4)
		name_lbl.size = Vector2(cell_w - 40, 14)
		name_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
		name_lbl.add_theme_font_size_override("font_size", 10)
		card.add_child(name_lbl)

		var stats := PackedStringArray()
		if item.hp_bonus != 0: stats.append("HP+" + str(item.hp_bonus))
		if item.atk_bonus != 0: stats.append("ATK+" + str(item.atk_bonus))
		if item.spd_bonus != 0: stats.append("SPD+" + str(item.spd_bonus))
		if item.range_bonus != 0: stats.append("RNG+" + str(item.range_bonus))
		var stats_lbl := Label.new()
		stats_lbl.text = "  ".join(stats)
		stats_lbl.position = Vector2(4, 24)
		stats_lbl.size = Vector2(cell_w - 8, 30)
		stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
		stats_lbl.add_theme_font_size_override("font_size", 8)
		stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(stats_lbl)

		var equip_lbl := Label.new()
		if is_equipped:
			equip_lbl.text = _roster[roster_idx].unit_name
		else:
			equip_lbl.text = "[Inventory]"
		equip_lbl.position = Vector2(4, cell_h - 16)
		equip_lbl.size = Vector2(cell_w - 8, 14)
		equip_lbl.add_theme_color_override("font_color", ThemeHelper.INFO if not is_equipped else ThemeHelper.GOLD)
		equip_lbl.add_theme_font_size_override("font_size", 8)
		card.add_child(equip_lbl)

		card.gui_input.connect(_on_item_card_input.bind(entry, idx))

		x += cell_w + gap
		if x + cell_w > _item_panel.size.x:
			x = 8
			y += cell_h + gap

func _on_item_card_input(event: InputEvent, entry: Array, idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var item: ItemData = entry[0]
		var roster_idx: int = entry[1]
		var item_idx: int = entry[2]

		if roster_idx >= 0:
			_roster[roster_idx].items.remove_at(item_idx)
			_item_inventory.append(item)
			_selected_item = null
		else:
			if _selected_item == item:
				_selected_item = null
			else:
				_selected_item = item
		_refresh()
		_refresh_item_panel()

func _draw_enemies():
	for c in _grid_root.get_children():
		if c.has_meta("enemy_label"):
			c.queue_free()
	if _enemy_data.size() == 0:
		return
	var grid_w_max: int = maxi(1, _grid_w)
	for i in _enemy_data.size():
		var ex: int = i % grid_w_max
		var ey: int = i / grid_w_max
		if ey >= _grid_h:
			break
		var pos: Vector2 = _grid_offset + Vector2(ex * TILE_SIZE, ey * TILE_SIZE)
		var bg := ColorRect.new()
		bg.position = pos
		bg.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
		bg.color = Color(ThemeHelper.DANGER.r, ThemeHelper.DANGER.g, ThemeHelper.DANGER.b, 0.12)
		bg.set_meta("enemy_label", true)
		_grid_root.add_child(bg)
		var portrait := UnitFactory.make_portrait(_enemy_data[i], 1, 0.7)
		portrait.position = pos + Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		portrait.set_meta("enemy_label", true)
		_grid_root.add_child(portrait)
		var lbl := Label.new()
		lbl.text = _enemy_data[i].unit_name
		lbl.position = pos + Vector2(2, TILE_SIZE - 14)
		lbl.size = Vector2(TILE_SIZE - 4, 12)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.add_theme_color_override("font_color", Color(ThemeHelper.DANGER.r, ThemeHelper.DANGER.g, ThemeHelper.DANGER.b, 0.7))
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.set_meta("enemy_label", true)
		_grid_root.add_child(lbl)
		if _enemy_data[i].items.size() > 0:
			var item_icons := PackedStringArray()
			for it in _enemy_data[i].items:
				item_icons.append(it.icon_char)
			var ilbl := Label.new()
			ilbl.text = "[" + ", ".join(item_icons) + "]"
			ilbl.position = pos + Vector2(2, TILE_SIZE + 2)
			ilbl.size = Vector2(TILE_SIZE - 4, 10)
			ilbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ilbl.add_theme_color_override("font_color", Color(ThemeHelper.DANGER.r, ThemeHelper.DANGER.g, ThemeHelper.DANGER.b, 0.5))
			ilbl.add_theme_font_size_override("font_size", 7)
			ilbl.set_meta("enemy_label", true)
			_grid_root.add_child(ilbl)

func _on_tile_input(event: InputEvent, x: int, y: int, tile: ColorRect):
	var idx := y * _grid_w + x

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if _grid[idx] >= 0:
			_grid[idx] = -1
			_selected_idx = -1
			_refresh()
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_idx >= 0:
			if _grid[idx] >= 0:
				var existing := _grid[idx]
				_grid[idx] = _selected_idx
				_selected_idx = existing
			else:
				_grid[idx] = _selected_idx
				_selected_idx = -1
			_refresh()
		else:
			if _grid[idx] >= 0:
				_selected_idx = _grid[idx]
				_grid[idx] = -1
				_refresh()

func _on_card_gui_input(event: InputEvent, card_idx: int, card: Control, is_placed: bool):
	if _selected_item != null and _item_inventory.has(_selected_item):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_roster[card_idx].items.append(_selected_item)
			_item_inventory.erase(_selected_item)
			_selected_item = null
			_refresh()
			_refresh_item_panel()
		return
	if is_placed:
		return
	if _handle_card_mouse_press(event, card_idx):
		return
	if _handle_card_mouse_move(event, card_idx):
		return
	_handle_card_mouse_release(event, card_idx)

func _handle_card_mouse_press(event: InputEvent, card_idx: int) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_drag_press_pos = get_viewport().get_mouse_position()
		_drag_active = true
		_drag_idx = card_idx
		return true
	return false

func _handle_card_mouse_move(event: InputEvent, card_idx: int) -> bool:
	if event is InputEventMouseMotion and _drag_active and _drag_idx == card_idx:
		var dist := get_viewport().get_mouse_position().distance_to(_drag_press_pos)
		if dist > DRAG_THRESHOLD and not _drag_preview:
			_start_drag(card_idx)
		elif _drag_preview:
			_update_drag()
		return true
	return false

func _handle_card_mouse_release(event: InputEvent, card_idx: int):
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _drag_active and _drag_idx == card_idx:
			if _drag_preview:
				_end_drag()
			else:
				_selected_idx = card_idx
				_refresh()
			_drag_active = false

func _start_drag(idx: int):
	_drag_preview = _make_drag_preview(idx)
	add_child(_drag_preview)
	_update_drag()

func _update_drag():
	if _drag_preview:
		_drag_preview.position = get_viewport().get_mouse_position() - Vector2(TILE_SIZE / 2, TILE_SIZE / 2)
		_highlight_drop_target()

func _end_drag():
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null

	var mouse_pos := get_viewport().get_mouse_position()
	var rel := mouse_pos - _grid_offset
	var tx := int(rel.x / TILE_SIZE)
	var ty := int(rel.y / TILE_SIZE)
	var player_start := maxi(0, _grid_h - 2)

	if tx >= 0 and tx < _grid_w and ty >= 0 and ty < _grid_h and ty >= player_start:
		var cell_idx := ty * _grid_w + tx
		if _grid[cell_idx] >= 0:
			var existing := _grid[cell_idx]
			_grid[cell_idx] = _drag_idx
			_selected_idx = existing
		else:
			_grid[cell_idx] = _drag_idx
			_selected_idx = -1
		_refresh()

	_clear_drop_highlight()
	_drag_idx = -1

func _make_drag_preview(idx: int) -> Control:
	var c := ColorRect.new()
	c.size = Vector2(TILE_SIZE, TILE_SIZE)
	c.color = Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.2)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var portrait := UnitFactory.make_portrait(_roster[idx], 0, 1.0)
	portrait.position = Vector2((TILE_SIZE - 64) / 2, (TILE_SIZE - 64) / 2)
	c.add_child(portrait)

	var lbl := Label.new()
	lbl.text = _roster[idx].unit_name
	lbl.position = Vector2(2, TILE_SIZE - 14)
	lbl.size = Vector2(TILE_SIZE - 4, 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	lbl.add_theme_font_size_override("font_size", 9)
	c.add_child(lbl)

	return c

func _highlight_drop_target():
	_clear_drop_highlight()
	var mouse_pos := get_viewport().get_mouse_position()
	var rel := mouse_pos - _grid_offset
	var tx := int(rel.x / TILE_SIZE)
	var ty := int(rel.y / TILE_SIZE)
	var player_start := maxi(0, _grid_h - 2)

	if tx >= 0 and tx < _grid_w and ty >= 0 and ty < _grid_h and ty >= player_start:
		var tile := _grid_nodes.get(Vector2i(tx, ty)) as ColorRect
		if tile:
			tile.color = Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.15)

func _clear_drop_highlight():
	for y in _grid_h:
		var player_start := maxi(0, _grid_h - 2)
		for x in _grid_w:
			if y >= player_start:
				var tile := _grid_nodes.get(Vector2i(x, y)) as ColorRect
				if tile:
					var cell_idx := y * _grid_w + x
					if _grid[cell_idx] >= 0:
						tile.color = Color("#1a2228")
					else:
						tile.color = Color("#181e24")

func _cancel_selection():
	_selected_idx = -1
	if _drag_preview:
		_drag_preview.queue_free()
		_drag_preview = null
	_drag_active = false
	_clear_drop_highlight()
	_refresh()

func _refresh():
	var vs := _viewport_size
	_clear_roster_cards()
	_clear_grid_sprites()
	_populate_roster_cards(vs)
	_populate_grid_sprites()
	_update_info_label()
	_update_items_button()
	_draw_enemies()

func _update_items_button():
	for c in get_children():
		if c.has_meta("items_btn"):
			(c as Button).text = "Items (" + str(_item_inventory.size()) + ")"

func _clear_roster_cards():
	for c in _roster_root.get_children():
		c.queue_free()

func _clear_grid_sprites():
	for key in _grid_sprite_nodes:
		var sn := _grid_sprite_nodes[key] as Node
		if sn:
			sn.queue_free()
	_grid_sprite_nodes.clear()
	for c in _grid_root.get_children():
		if c.has_meta("player_label"):
			c.queue_free()

func _populate_roster_cards(vs: Vector2):
	var total_w: int = _roster.size() * CARD_WIDTH + (_roster.size() - 1) * CARD_GAP
	var roster_x: int = maxi(10, (vs.x - total_w) / 2)
	var roster_y: int = vs.y - CARD_HEIGHT - CARD_GAP * 2 - BUTTON_HEIGHT - 10
	for i in _roster.size():
		var is_placed := false
		for g in _grid:
			if g == i:
				is_placed = true
				break
		var c := _make_unit_card(i, is_placed)
		c.position = Vector2(roster_x + i * (CARD_WIDTH + CARD_GAP), roster_y)
		_roster_root.add_child(c)

func _populate_grid_sprites():
	for y in _grid_h:
		for x in _grid_w:
			var cell_idx := y * _grid_w + x
			var r = _grid_nodes.get(Vector2i(x, y))
			if not r:
				continue
			if _grid[cell_idx] >= 0:
				_update_occupied_cell(r, x, y, _roster[_grid[cell_idx]])
			elif y >= max(0, _grid_h - 2):
				r.color = Color("#181e24")
			else:
				r.color = Color("#0a0808")

func _update_occupied_cell(tile: ColorRect, x: int, y: int, ud: UnitData):
	tile.color = Color("#1a2228")
	tile.tooltip_text = ud.unit_name
	var sprite := UnitFactory.make_portrait(ud, 0, 1.0)
	sprite.position = _grid_offset + Vector2(x * TILE_SIZE + TILE_SIZE / 2, y * TILE_SIZE + TILE_SIZE / 2)
	_grid_root.add_child(sprite)
	_grid_sprite_nodes[Vector2i(x, y)] = sprite
	if ud.items.size() > 0:
		var icons := PackedStringArray()
		for it in ud.items:
			icons.append(it.icon_char)
		var ilbl := Label.new()
		ilbl.text = "[" + ", ".join(icons) + "]"
		ilbl.position = _grid_offset + Vector2(x * TILE_SIZE + 2, y * TILE_SIZE + TILE_SIZE + 2)
		ilbl.size = Vector2(TILE_SIZE - 4, 10)
		ilbl.add_theme_color_override("font_color", Color(ThemeHelper.GOLD.r, ThemeHelper.GOLD.g, ThemeHelper.GOLD.b, 0.6))
		ilbl.add_theme_font_size_override("font_size", 7)
		ilbl.set_meta("player_label", true)
		_grid_root.add_child(ilbl)

func _update_info_label():
	var placed := 0
	for g in _grid:
		if g >= 0:
			placed += 1
	if _selected_item != null:
		_info_label.text = "Click a unit card below to equip the selected item"
	elif _selected_idx >= 0:
		_info_label.text = "Placing: " + _roster[_selected_idx].unit_name + " (click a tile, or right-click to cancel)"
	elif placed > 0:
		_info_label.text = "Click a placed unit to pick it up, right-click to remove | Items button to manage equipment"
	else:
		_info_label.text = "Click a unit, or drag it to a tile on YOUR ZONE | Items button to manage equipment"
	_ready_btn.disabled = placed == 0

func _make_unit_card(idx: int, is_placed: bool) -> Control:
	var ud := _roster[idx]

	var card := ColorRect.new()
	card.color = ThemeHelper.BG_CARD if not is_placed else ThemeHelper.BG_DARK
	card.size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.gui_input.connect(_on_card_gui_input.bind(idx, card, is_placed))

	if not is_placed:
		card.mouse_entered.connect(func(): card.color = Color(ThemeHelper.BORDER.r, ThemeHelper.BORDER.g, ThemeHelper.BORDER.b, 0.5))
		card.mouse_exited.connect(func(): card.color = ThemeHelper.BG_CARD)

	var portrait := UnitFactory.make_portrait(ud, 0, 0.5)
	portrait.position = Vector2(4, 4)
	card.add_child(portrait)

	var px: int = 38
	var pw: int = CARD_WIDTH - px - 6

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(ud.star_level) + ud.unit_name
	name_lbl.position = Vector2(px, 2)
	name_lbl.size = Vector2(pw, 16)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD if not is_placed else ThemeHelper.TEXT_DIM)
	name_lbl.add_theme_font_size_override("font_size", 11)
	card.add_child(name_lbl)

	var stats := Label.new()
	stats.text = "HP:%d ATK:%d SPD:%d" % [UnitData.total_hp(ud), UnitData.total_atk(ud), UnitData.total_spd(ud)]
	stats.position = Vector2(px, 18)
	stats.size = Vector2(pw, 12)
	stats.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	stats.add_theme_font_size_override("font_size", 9)
	card.add_child(stats)

	var range_lbl := Label.new()
	range_lbl.text = "RNG:%d Cost:%d" % [UnitData.total_rng(ud), ud.cost]
	range_lbl.position = Vector2(px, 30)
	range_lbl.size = Vector2(pw, 12)
	range_lbl.add_theme_color_override("font_color", ThemeHelper.GOLD)
	range_lbl.add_theme_font_size_override("font_size", 9)
	card.add_child(range_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(px, 42)
	elem_lbl.size = Vector2(pw, 12)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	card.add_child(elem_lbl)

	var ability_lbl := Label.new()
	var abil_name := _ability_display_name(ud.ability_id)
	ability_lbl.text = abil_name
	ability_lbl.position = Vector2(px, 54)
	ability_lbl.size = Vector2(pw, 12)
	ability_lbl.add_theme_color_override("font_color", ThemeHelper.SUCCESS)
	ability_lbl.add_theme_font_size_override("font_size", 8)
	card.add_child(ability_lbl)

	if ud.items.size() > 0:
		var items_lbl := Label.new()
		var icons := PackedStringArray()
		for it in ud.items:
			icons.append(it.icon_char)
		items_lbl.text = "[" + ", ".join(icons) + "]"
		items_lbl.position = Vector2(px, 64)
		items_lbl.size = Vector2(pw, 12)
		items_lbl.add_theme_color_override("font_color", Enums.element_color(ItemData.Rarity.RARE + 2))
		items_lbl.add_theme_font_size_override("font_size", 7)
		card.add_child(items_lbl)

	return card

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
