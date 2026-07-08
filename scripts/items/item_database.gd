class_name ItemDatabase extends RefCounted

static var _loaded := false
static var ALL: Array[ItemData] = []

static func _ensure():
	if _loaded:
		return
	_loaded = true
	ALL = [
		_make("Iron Helm", 2, ItemData.EffectType.NONE, 0, 2, 0, 0, "HP +2", 3, "IH"),
		_make("Steelblade", 2, ItemData.EffectType.NONE, 0, 0, 2, 0, "ATK +2", 3, "SB"),
		_make("Swift Boots", 2, ItemData.EffectType.NONE, 0, 0, 0, 1, "SPD +1", 3, "SBt"),
		_make("Longshot Lens", 2, ItemData.EffectType.NONE, 0, 0, 0, 0, "Range +1", 4, "LL", 1),
		_make("Burning Blade", 3, ItemData.EffectType.BURN_ON_HIT, 2, 0, 1, 0, "ATK +1, attacks Burn for 2 turns", 5, "BB"),
		_make("Venom Fang", 3, ItemData.EffectType.POISON_ON_HIT, 2, 0, 0, 0, "Attacks Poison for 2 turns", 5, "VF"),
		_make("Vampiric Scepter", 3, ItemData.EffectType.LIFESTEAL, 1, 0, 0, 0, "Heal 1 HP per hit dealt", 6, "VS"),
		_make("Thornmail Armor", 3, ItemData.EffectType.THORNS, 1, 1, 0, 0, "HP +1, attacker takes 1 dmg", 5, "TA"),
		_make("Regrowth Amulet", 3, ItemData.EffectType.REGEN, 1, 0, 0, 0, "Heal 1 HP per turn", 6, "RA"),
		_make("Root Tether", 2, ItemData.EffectType.SNARE, 1, 0, 0, 0, "Attacks Root for 1 turn", 4, "RT"),
		_make("Fortress Shield", 3, ItemData.EffectType.FORTIFY, 1, 2, 0, 0, "HP +2, +1 armor always", 6, "FS"),
		_make("Soul Reaper", 4, ItemData.EffectType.VAMPIRIC, 2, 0, 2, 0, "ATK +2, heal 2 on kill", 7, "SR"),
		_make("Crystal Heart", 4, ItemData.EffectType.NONE, 0, 5, 0, 0, "HP +5", 7, "CH"),
		_make("Berserker Axe", 4, ItemData.EffectType.NONE, 0, 0, 4, 0, "ATK +4", 8, "BA"),
		_make("Windstrider Cape", 4, ItemData.EffectType.NONE, 0, 0, 0, 2, "SPD +2", 7, "WC"),
	]

static func _make(name: String, rarity: int, effect: int, effect_val: int, hp: int, atk: int, spd: int, desc: String, cost: int, icon: String, range_bonus: int = 0) -> ItemData:
	var d := ItemData.new()
	d.item_name = name
	d.rarity = rarity
	d.effect_type = effect
	d.effect_value = effect_val
	d.hp_bonus = hp
	d.atk_bonus = atk
	d.spd_bonus = spd
	d.range_bonus = range_bonus
	d.description = desc
	d.cost = cost
	d.icon_char = icon
	return d

static func get_random(count: int, min_rarity: int = ItemData.Rarity.COMMON, max_rarity: int = ItemData.Rarity.EPIC) -> Array[ItemData]:
	_ensure()
	var pool: Array[ItemData] = []
	for it in ALL:
		if it.rarity >= min_rarity and it.rarity <= max_rarity:
			pool.append(it)
	pool.shuffle()
	var result: Array[ItemData] = []
	for i in mini(count, pool.size()):
		result.append(pool[i])
	return result

static func get_item(name: String) -> ItemData:
	_ensure()
	for it in ALL:
		if it.item_name == name:
			return it
	return null
