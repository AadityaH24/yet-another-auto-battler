class_name UnitData extends Resource

@export var unit_name: String
@export var unit_class: int
@export var weight: int
@export var base_hp: int
@export var base_attack: int
@export var base_speed: int
@export var element_affinity: int
@export var cost: int
@export var base_range: int
@export var aoe_type: int
@export var ability_type: int
@export var ability_id: String
@export var star_level: int = 1
var items: Array[ItemData] = []

static func star_prefix(star_level: int) -> String:
	if star_level >= 3:
		return "★★★ "
	if star_level == 2:
		return "★★ "
	return ""

static func total_hp(ud) -> int:
	var v = ud.base_hp
	for it in ud.items: v += it.hp_bonus
	return v

static func total_atk(ud) -> int:
	var v = ud.base_attack
	for it in ud.items: v += it.atk_bonus
	return v

static func total_spd(ud) -> int:
	var v = ud.base_speed
	for it in ud.items: v += it.spd_bonus
	return v

static func total_rng(ud) -> int:
	var v = ud.base_range
	for it in ud.items: v += it.range_bonus
	return v
