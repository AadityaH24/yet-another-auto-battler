class_name ItemData extends Resource

enum EffectType { NONE, POISON_ON_HIT, THORNS, LIFESTEAL, BURN_ON_HIT, REGEN, FORTIFY, SNARE, VAMPIRIC }
enum Rarity { COMMON, RARE, EPIC }

var item_name: String
var effect_type: int = EffectType.NONE
var effect_value: int = 0
var hp_bonus: int = 0
var atk_bonus: int = 0
var spd_bonus: int = 0
var rarity: int = Rarity.COMMON
var description: String
var cost: int = 3
var icon_char: String = "◇"
var range_bonus: int = 0
