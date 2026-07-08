class_name UnitFactory extends RefCounted

const ALL_CLASSES: Array[int] = [
	Enums.UnitClass.SOLDIER,
	Enums.UnitClass.MAGE,
	Enums.UnitClass.SCOUT,
	Enums.UnitClass.KNIGHT,
	Enums.UnitClass.ELEMENTALIST,
	Enums.UnitClass.BERSERKER,
	Enums.UnitClass.SHIELDBEARER,
	Enums.UnitClass.LANCER,
	Enums.UnitClass.ARCHER,
	Enums.UnitClass.WARLOCK,
	Enums.UnitClass.CLERIC,
]

const CLASS_COSTS: Dictionary[int, int] = {
	Enums.UnitClass.SOLDIER: 2,
	Enums.UnitClass.MAGE: 4,
	Enums.UnitClass.SCOUT: 3,
	Enums.UnitClass.KNIGHT: 3,
	Enums.UnitClass.ELEMENTALIST: 4,
	Enums.UnitClass.BERSERKER: 3,
	Enums.UnitClass.SHIELDBEARER: 4,
	Enums.UnitClass.LANCER: 3,
	Enums.UnitClass.ARCHER: 3,
	Enums.UnitClass.WARLOCK: 3,
	Enums.UnitClass.CLERIC: 3,
}

static func make_unit_by_class(cls: int) -> UnitData:
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

static func clone_unit(ud: UnitData) -> UnitData:
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

const ELEMENT_ROLL_MAX: int = 10
const ELEMENT_THRESHOLD: int = 7

static func _random_element() -> int:
	if randi() % ELEMENT_ROLL_MAX < ELEMENT_THRESHOLD:
		return Enums.ElementType.NONE
	return [Enums.ElementType.FIRE, Enums.ElementType.WIND, Enums.ElementType.WATER, Enums.ElementType.EARTH].pick_random()

static func make_portrait(ud: UnitData, team: int = 0, scale: float = 3.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = SpriteGenerator.generate(ud.unit_class, team, ud.element_affinity, ud.star_level)
	s.scale = Vector2(scale, scale)
	var icon_scale := scale * 0.35
	var ic := SpriteGenerator.make_class_icon(ud.unit_class)
	var ic_sprite := Sprite2D.new()
	ic_sprite.texture = ic
	ic_sprite.scale = Vector2(icon_scale, icon_scale)
	ic_sprite.position = Vector2(-SpriteGenerator.SIZE * scale / 2.0, SpriteGenerator.SIZE * scale / 2.0 - SpriteGenerator.ICON_SZ * icon_scale)
	s.add_child(ic_sprite)
	return s

static func make_class_icon(cls: int, scale: float = 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = SpriteGenerator.make_class_icon(cls)
	s.scale = Vector2(scale, scale)
	return s

static func add_card_labels(b: Button, ud: UnitData, label_width: int) -> Button:
	var portrait := make_portrait(ud, 0, 0.5)
	portrait.position = Vector2(4, 6)
	b.add_child(portrait)

	var px: int = 44
	var pw: int = label_width - px - 6

	var name_lbl := Label.new()
	name_lbl.text = UnitData.star_prefix(ud.star_level) + ud.unit_name
	name_lbl.position = Vector2(px, 4)
	name_lbl.size = Vector2(pw, 20)
	name_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT)
	name_lbl.add_theme_font_size_override("font_size", 14)
	b.add_child(name_lbl)

	var cls_str := "Light" if ud.weight == Enums.UnitWeight.LIGHT else "Heavy"
	var stats_lbl := Label.new()
	stats_lbl.text = "HP:%d ATK:%d SPD:%d" % [ud.base_hp, ud.base_attack, ud.base_speed]
	stats_lbl.position = Vector2(px, 26)
	stats_lbl.size = Vector2(pw, 16)
	stats_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	stats_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(stats_lbl)

	var type_lbl := Label.new()
	type_lbl.text = "[%s]" % cls_str
	type_lbl.position = Vector2(px, 44)
	type_lbl.size = Vector2(pw, 16)
	type_lbl.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	type_lbl.add_theme_font_size_override("font_size", 10)
	b.add_child(type_lbl)

	var elem_lbl := Label.new()
	elem_lbl.text = Enums.element_name(ud.element_affinity)
	elem_lbl.position = Vector2(px, 62)
	elem_lbl.size = Vector2(pw, 14)
	elem_lbl.add_theme_color_override("font_color", Enums.element_color(ud.element_affinity))
	elem_lbl.add_theme_font_size_override("font_size", 9)
	b.add_child(elem_lbl)

	return b

static func _make_unit(uname: String, cls: int, w: int, hp: int, atk: int, spd: int, elem: int, cost: int, range: int, aoe: int, abil_type: int, abil_id: String) -> UnitData:
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
