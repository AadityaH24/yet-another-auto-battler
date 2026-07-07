class_name UnitInstance extends Node2D

var unit_data: UnitData
var team: int
var grid_pos: Vector2i
var current_hp: int
var current_speed: int
var has_acted: bool = false
var armor: int = 0
var status_effects: Dictionary = {}
var is_rooted: bool = false

var _max_hp: int
var _flash_timer: float = 0.0
var _is_flashing: bool = false
var _original_speed: int = 0

const TILE_SIZE: int = 80
const SIZE: float = 60.0

func _ready():
	current_hp = unit_data.base_hp
	_max_hp = unit_data.base_hp
	current_speed = unit_data.base_speed
	_original_speed = unit_data.base_speed

func _process(delta: float):
	if _is_flashing:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			_is_flashing = false
			queue_redraw()

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int):
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	_is_flashing = true
	_flash_timer = 0.15
	queue_redraw()

func apply_status(effect: String, turns: int):
	status_effects[effect] = turns
	if effect == "chill":
		current_speed = maxi(1, _original_speed - 1)
	if effect == "root":
		is_rooted = true

func tick_statuses():
	var had_burn := status_effects.has("burn")
	for effect in status_effects.keys():
		var t: int = status_effects[effect] - 1
		if t <= 0:
			status_effects.erase(effect)
			if effect == "chill":
				current_speed = _original_speed
			if effect == "root":
				is_rooted = false
		else:
			status_effects[effect] = t
	if had_burn and is_alive():
		current_hp = maxi(0, current_hp - 1)
		_is_flashing = true
		_flash_timer = 0.1
		queue_redraw()

func update_visual():
	queue_redraw()

func _draw():
	if not unit_data:
		return

	var alive := is_alive()
	var alpha := 1.0 if alive else 0.35
	var half := SIZE / 2.0
	var pos := Vector2(-half, -half)
	var rect := Rect2(pos, Vector2(SIZE, SIZE))

	var team_color := Color(0.25, 0.5, 0.9) if team == 0 else Color(0.9, 0.25, 0.25)

	if _is_flashing:
		team_color = Color.WHITE

	team_color.a = alpha

	draw_rect(rect, team_color, true)

	var weight_color := Color(0.8, 0.8, 0.9, alpha)
	match unit_data.weight:
		Enums.UnitWeight.LIGHT:
			weight_color = Color(0.4, 0.7, 1.0, alpha)
		Enums.UnitWeight.HEAVY:
			weight_color = Color(1.0, 0.4, 0.3, alpha)

	var bw := 2
	var border_rect := Rect2(pos + Vector2(bw, bw), Vector2(SIZE - bw * 2, SIZE - bw * 2))
	draw_rect(border_rect, weight_color, false, 2.0)

	if unit_data.element_affinity != Enums.ElementType.NONE:
		var elem_color: Color = Enums.element_color(unit_data.element_affinity)
		elem_color.a = alpha * 0.7
		var inner := Rect2(pos + Vector2(4, 4), Vector2(SIZE - 8, SIZE - 8))
		draw_rect(inner, elem_color, false, 1.5)

	var symbol := _get_class_symbol()
	var font := ThemeDB.fallback_font
	var font_size := 24
	var f_color := Color(1, 1, 1, alpha)
	if font:
		var text_size := font.get_string_size(symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos := Vector2(-text_size.x / 2.0, text_size.y / 4.0)
		draw_string(font, text_pos, symbol, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, f_color)

	if alive:
		var bar_w: float = SIZE - 4
		var bar_h: float = 5
		var bar_y: float = -half - 8
		var bar_x: float = -half + 2
		var hp_ratio := float(current_hp) / float(_max_hp)

		var bg_rect := Rect2(Vector2(bar_x, bar_y), Vector2(bar_w, bar_h))
		draw_rect(bg_rect, Color(0.1, 0.1, 0.1, 0.8), true)

		var hp_color := Color(0.2, 0.9, 0.2)
		if hp_ratio < 0.5:
			hp_color = Color(0.9, 0.7, 0.1)
		if hp_ratio < 0.25:
			hp_color = Color(0.9, 0.2, 0.1)

		var hp_w := bar_w * hp_ratio
		if hp_w > 0:
			var hp_rect := Rect2(Vector2(bar_x, bar_y), Vector2(hp_w, bar_h))
			draw_rect(hp_rect, hp_color, true)

		var hp_text := "%d/%d" % [current_hp, _max_hp]
		var hp_font_size := 8
		if font:
			var hp_text_size := font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, hp_font_size)
			var hp_text_pos := Vector2(-hp_text_size.x / 2.0, bar_y + bar_h + hp_font_size + 2)
			draw_string(font, hp_text_pos, hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, hp_font_size, Color(1, 1, 1, alpha))

		var status_y := bar_y - 10
		var status_x := -half + 2
		for effect in status_effects.keys():
			var dot_color := Color.WHITE
			match effect:
				"burn": dot_color = Color(1.0, 0.3, 0.0)
				"chill": dot_color = Color(0.3, 0.6, 1.0)
				"root": dot_color = Color(0.5, 0.3, 0.1)
			draw_rect(Rect2(Vector2(status_x, status_y), Vector2(4, 4)), dot_color, true)
			status_x += 6

func _get_class_symbol() -> String:
	match unit_data.unit_class:
		Enums.UnitClass.SOLDIER: return "S"
		Enums.UnitClass.MAGE: return "M"
		Enums.UnitClass.SCOUT: return "Sc"
		Enums.UnitClass.KNIGHT: return "K"
		Enums.UnitClass.ELEMENTALIST: return "E"
		Enums.UnitClass.BERSERKER: return "B"
		Enums.UnitClass.SHIELDBEARER: return "Sh"
		Enums.UnitClass.LANCER: return "L"
		Enums.UnitClass.ARCHER: return "A"
		Enums.UnitClass.WARLOCK: return "W"
		Enums.UnitClass.CLERIC: return "C"
	return "?"