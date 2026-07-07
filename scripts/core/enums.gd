extends Node

enum UnitClass { SOLDIER, MAGE, SCOUT, KNIGHT, ELEMENTALIST, BERSERKER, SHIELDBEARER, LANCER, ARCHER, WARLOCK, CLERIC }
enum UnitWeight { LIGHT, HEAVY }
enum ElementType { NONE, FIRE, WIND, WATER, EARTH }
enum Team { PLAYER, ENEMY }
enum AOEType { SINGLE, CLEAVE_SIDES, LINE, SPLASH_ORTHO }
enum AbilityType { NONE, PASSIVE, DEPLOYMENT }

func element_name(elem: int) -> String:
	match elem:
		ElementType.FIRE: return "Fire"
		ElementType.WIND: return "Wind"
		ElementType.WATER: return "Water"
		ElementType.EARTH: return "Earth"
	return ""

func element_color(elem: int) -> Color:
	match elem:
		ElementType.FIRE: return Color(1.0, 0.4, 0.1)
		ElementType.WIND: return Color(0.3, 0.9, 0.6)
		ElementType.WATER: return Color(0.2, 0.5, 1.0)
		ElementType.EARTH: return Color(0.6, 0.4, 0.2)
	return Color.WHITE

func next_element(elem: int) -> int:
	match elem:
		ElementType.FIRE: return ElementType.WIND
		ElementType.WIND: return ElementType.EARTH
		ElementType.EARTH: return ElementType.WATER
		ElementType.WATER: return ElementType.FIRE
	return -1

func element_advantage(attacker: int, defender: int) -> int:
	if attacker == ElementType.NONE or defender == ElementType.NONE:
		return 0
	if next_element(attacker) == defender:
		return 1
	if next_element(defender) == attacker:
		return -1
	return 0
