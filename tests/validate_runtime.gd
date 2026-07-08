extends SceneTree

func _initialize():
	var errors := 0

	var test_item := ItemData.new()
	test_item.range_bonus = 0
	test_item.hp_bonus = 1
	test_item.atk_bonus = 2
	test_item.spd_bonus = 3
	test_item.item_name = "x"
	test_item.cost = 1
	test_item.icon_char = "x"
	test_item.description = "x"
	print("ItemData: all property assignments OK")

	var items := ItemDatabase.get_random(3)
	assert(items.size() > 0, "get_random should return items")
	print("ItemDatabase.get_random(3): %d items" % items.size())

	for it in items:
		assert(it is ItemData, "each item is ItemData")
		assert(it.item_name.length() > 0, "item has name")

	var helm := ItemDatabase.get_item("Iron Helm")
	assert(helm != null, "Iron Helm found")
	assert(helm.hp_bonus == 2, "Iron Helm HP +2")
	print("ItemDatabase.get_item('Iron Helm'): hp_bonus=%d OK" % helm.hp_bonus)

	var ud := UnitData.new()
	ud.items = []
	ud.items.append(test_item)
	assert(ud.items.size() == 1, "UnitData items array works")
	ud.unit_name = "Test"
	ud.base_hp = 10
	ud.base_attack = 5
	ud.base_speed = 3
	ud.base_range = 1
	ud.cost = 2
	ud.weight = Enums.UnitWeight.LIGHT
	ud.element_affinity = Enums.ElementType.NONE
	ud.ability_id = ""
	ud.aoe_type = Enums.AOEType.SINGLE
	assert(ud.star_prefix(1) == "★★ ", "star_prefix works")
	assert(ud.star_prefix(0) == "", "star_prefix 0 is empty")
	print("UnitData: all properties OK, star_prefix='%s'" % ud.star_prefix(1))

	assert(Enums.element_name(Enums.ElementType.FIRE) == "Fire", "element_name FIRE")
	assert(Enums.element_name(Enums.ElementType.NONE) == "", "element_name NONE empty")
	assert(Enums.element_advantage(Enums.ElementType.FIRE, Enums.ElementType.WIND) == 1, "FIRE > WIND")
	assert(Enums.element_advantage(Enums.ElementType.WIND, Enums.ElementType.FIRE) == -1, "FIRE < WIND")
	assert(Enums.element_advantage(Enums.ElementType.NONE, Enums.ElementType.FIRE) == 0, "NONE no adv")
	assert(Enums.next_element(Enums.ElementType.FIRE) == Enums.ElementType.WIND, "next_element FIRE->WIND")
	assert(Enums.next_element(Enums.ElementType.NONE) == Enums.ElementType.NONE, "next_element NONE->NONE")
	assert(Enums.get_zone_combo(Enums.ElementType.FIRE, Enums.ElementType.WIND) == Enums.ComboEffect.STORM, "combo FIRE+WIND=STORM")
	assert(Enums.get_zone_combo(Enums.ElementType.NONE, Enums.ElementType.FIRE) == Enums.ComboEffect.NONE, "combo NONE = NONE")
	assert(typeof(Enums.element_color(Enums.ElementType.FIRE)) == TYPE_COLOR, "element_color returns Color")
	print("Enums: all static funcs OK")

	assert(CombatEngine.is_tile_valid(Vector2i(0, 0), 4, 4) == true, "valid tile")
	assert(CombatEngine.is_tile_valid(Vector2i(-1, 0), 4, 4) == false, "invalid tile")
	print("CombatEngine: is_tile_valid OK")

	assert(UnitFactory.ALL_CLASSES.size() > 0, "ALL_CLASSES not empty")
	assert(UnitFactory.CLASS_COSTS.size() > 0, "CLASS_COSTS not empty")
	var unit_by_class := UnitFactory.make_unit_by_class(Enums.UnitClass.SOLDIER)
	assert(unit_by_class != null, "make_unit_by_class returns UnitData")
	assert(unit_by_class.unit_name.length() > 0, "generated unit has name")
	print("UnitFactory: make_unit_by_class(SOLDIER)=%s OK" % unit_by_class.unit_name)

	print("\n=== ALL RUNTIME VALIDATIONS PASSED ===")
	quit()
