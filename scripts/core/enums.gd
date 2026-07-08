class_name Enums

enum UnitClass { SOLDIER, MAGE, SCOUT, KNIGHT, ELEMENTALIST, BERSERKER, SHIELDBEARER, LANCER, ARCHER, WARLOCK, CLERIC }
enum UnitWeight { LIGHT, HEAVY }
enum ElementType { NONE, FIRE, WIND, WATER, EARTH }
enum Team { PLAYER, ENEMY }
enum AOEType { SINGLE, CLEAVE_SIDES, LINE, SPLASH_ORTHO }
enum AbilityType { NONE, PASSIVE, DEPLOYMENT }

static func element_name(elem: int) -> String:
	match elem:
		Enums.ElementType.FIRE: return "Fire"
		Enums.ElementType.WIND: return "Wind"
		Enums.ElementType.WATER: return "Water"
		Enums.ElementType.EARTH: return "Earth"
	return ""

static func element_color(elem: int) -> Color:
	match elem:
		Enums.ElementType.FIRE: return Color(1.0, 0.4, 0.1)
		Enums.ElementType.WIND: return Color(0.3, 0.9, 0.6)
		Enums.ElementType.WATER: return Color(0.2, 0.5, 1.0)
		Enums.ElementType.EARTH: return Color(0.6, 0.4, 0.2)
	return Color.WHITE

static func next_element(elem: int) -> int:
	match elem:
		Enums.ElementType.FIRE: return Enums.ElementType.WIND
		Enums.ElementType.WIND: return Enums.ElementType.EARTH
		Enums.ElementType.EARTH: return Enums.ElementType.WATER
		Enums.ElementType.WATER: return Enums.ElementType.FIRE
	return -1

enum ComboEffect { NONE, WILDFIRE, STORM, MUD, STEAM }

static func get_zone_combo(elem1: int, elem2: int) -> int:
	if elem1 == ElementType.NONE or elem2 == ElementType.NONE:
		return ComboEffect.NONE
	if elem1 == elem2:
		return ComboEffect.NONE
	if (elem1 == ElementType.FIRE and elem2 == ElementType.WIND) or (elem1 == ElementType.WIND and elem2 == ElementType.FIRE):
		return ComboEffect.WILDFIRE
	if (elem1 == ElementType.WIND and elem2 == ElementType.EARTH) or (elem1 == ElementType.EARTH and elem2 == ElementType.WIND):
		return ComboEffect.STORM
	if (elem1 == ElementType.EARTH and elem2 == ElementType.WATER) or (elem1 == ElementType.WATER and elem2 == ElementType.EARTH):
		return ComboEffect.MUD
	if (elem1 == ElementType.WATER and elem2 == ElementType.FIRE) or (elem1 == ElementType.FIRE and elem2 == ElementType.WATER):
		return ComboEffect.STEAM
	return ComboEffect.NONE

static func element_advantage(attacker: int, defender: int) -> int:
	if attacker == Enums.ElementType.NONE or defender == Enums.ElementType.NONE:
		return 0
	if Enums.next_element(attacker) == defender:
		return 1
	if Enums.next_element(defender) == attacker:
		return -1
	return 0
