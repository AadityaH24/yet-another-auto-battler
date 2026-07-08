class_name UnitInstance extends Node2D

var unit_data: UnitData
var team: int
var grid_pos: Vector2i
var current_hp: int
var current_speed: int
var current_attack: int
var current_range: int
var has_acted: bool = false
var armor: int = 0
var status_effects: Dictionary = {}
var is_rooted: bool = false

var _max_hp: int
var _original_speed: int = 0
var _sprite: Sprite2D
var _death_tween: Tween

const TILE_SIZE: int = 80
const SIZE: float = 60.0

func _ready():
	if not unit_data:
		return
	_max_hp = unit_data.base_hp
	current_attack = unit_data.base_attack
	current_speed = unit_data.base_speed
	current_range = unit_data.base_range
	for item in unit_data.items:
		_max_hp += item.hp_bonus
		current_attack += item.atk_bonus
		current_speed += item.spd_bonus
		current_range += item.range_bonus
	current_hp = _max_hp
	_original_speed = current_speed
	_sprite = Sprite2D.new()
	_sprite.texture = SpriteGenerator.generate(unit_data.unit_class, team, unit_data.element_affinity, unit_data.star_level)
	_sprite.scale = Vector2(SpriteGenerator.SCALE, SpriteGenerator.SCALE)
	add_child(_sprite)
	var icon_s := Sprite2D.new()
	icon_s.texture = SpriteGenerator.make_class_icon(unit_data.unit_class)
	var isc := SpriteGenerator.SCALE * 0.35
	icon_s.scale = Vector2(isc, isc)
	icon_s.position = Vector2(-SpriteGenerator.SIZE / 2.0, SpriteGenerator.SIZE / 2.0 - SpriteGenerator.ICON_SZ * isc)
	_sprite.add_child(icon_s)

func is_alive() -> bool:
	return current_hp > 0

func take_damage(amount: int):
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	_hit_flash()
	queue_redraw()

func apply_status(effect: String, turns: int):
	status_effects[effect] = turns
	if effect == "chill":
		current_speed = maxi(1, _original_speed - 1)
	if effect == "root":
		is_rooted = true
	queue_redraw()

func tick_statuses():
	var had_burn := status_effects.has("burn")
	var had_poison := status_effects.has("poison")
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
		_hit_flash()
	if had_poison and is_alive():
		current_hp = maxi(0, current_hp - 1)
		_hit_flash()
	queue_redraw()

func animate_move(to_world: Vector2) -> Tween:
	var t: Tween = create_tween().set_trans(Tween.TRANS_SINE)
	t.tween_property(self, "position", to_world, 0.25)
	return t

func animate_attack(target_world: Vector2) -> Tween:
	var origin := position
	var lunge := origin + (target_world - origin).normalized() * 20.0
	var t: Tween = create_tween().set_trans(Tween.TRANS_QUINT)
	t.tween_property(self, "position", lunge, 0.1)
	t.tween_property(self, "position", origin, 0.12)
	return t

func animate_death() -> Tween:
	if _death_tween and _death_tween.is_valid():
		return _death_tween
	_death_tween = create_tween().set_trans(Tween.TRANS_QUINT)
	_death_tween.tween_property(_sprite, "modulate:a", 0.0, 0.35)
	_death_tween.parallel().tween_property(_sprite, "scale", Vector2.ZERO, 0.35)
	return _death_tween

func _hit_flash():
	if not _sprite:
		return
	var t := create_tween()
	t.tween_property(_sprite, "modulate", Color(3, 1.5, 1.5, 1), 0.06)
	t.tween_property(_sprite, "modulate", Color.WHITE, 0.1)

func update_visual():
	queue_redraw()

func _draw():
	if not unit_data:
		return
	if not is_alive():
		return
	var half := SIZE / 2.0
	var bar_w: float = SIZE - 4
	var bar_h: float = 5
	var bar_y: float = -half - 20
	var bar_x: float = -half + 2
	var hp_ratio := float(current_hp) / float(_max_hp)
	var bg_rect := Rect2(Vector2(bar_x, bar_y), Vector2(bar_w, bar_h))
	draw_rect(bg_rect, ThemeHelper.BG_DARK, true)
	var hp_color := Color("#4a8a40")
	if hp_ratio < 0.5:
		hp_color = Color("#c8a840")
	if hp_ratio < 0.25:
		hp_color = Color("#8a3030")
	var hp_w := bar_w * hp_ratio
	if hp_w > 0:
		draw_rect(Rect2(Vector2(bar_x, bar_y), Vector2(hp_w, bar_h)), hp_color, true)
	var hp_text := "%d/%d" % [current_hp, _max_hp]
	var font := ThemeDB.fallback_font
	var hp_font_size := 8
	if font:
		var hp_text_size := font.get_string_size(hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, hp_font_size)
		draw_string(font, Vector2(-hp_text_size.x / 2.0, bar_y + bar_h + hp_font_size + 2), hp_text, HORIZONTAL_ALIGNMENT_CENTER, -1, hp_font_size, Color(1, 1, 1, 0.9))
	var status_y := bar_y - 10
	var status_x := -half + 2
	for effect in status_effects.keys():
		var dot_color := Color.WHITE
		match effect:
			"burn": dot_color = Color(1.0, 0.3, 0.0)
			"chill": dot_color = Color(0.3, 0.6, 1.0)
			"root": dot_color = Color(0.5, 0.3, 0.1)
			"poison": dot_color = Color(0.4, 0.8, 0.2)
		draw_rect(Rect2(Vector2(status_x, status_y), Vector2(4, 4)), dot_color, true)
		status_x += 6
