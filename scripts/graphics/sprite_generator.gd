class_name SpriteGenerator extends RefCounted

const SIZE: int = 64
const SCALE: int = 1

# Colors per class: [body, accent, skin, weapon, dark]
const PALETTES: Dictionary = {
	Enums.UnitClass.SOLDIER:       [Color("3a6ea5"), Color("4a8ec5"), Color("e8c8a0"), Color("b0a090"), Color("1a2e40")],
	Enums.UnitClass.MAGE:          [Color("6a3fa0"), Color("8a5fc0"), Color("e8c8a0"), Color("c8a050"), Color("2a1050")],
	Enums.UnitClass.SCOUT:         [Color("3a8a3a"), Color("5aaa5a"), Color("e8c8a0"), Color("b09070"), Color("1a3a1a")],
	Enums.UnitClass.KNIGHT:        [Color("8888a0"), Color("aaaac8"), Color("e8c8a0"), Color("606078"), Color("303040")],
	Enums.UnitClass.ELEMENTALIST:  [Color("30a0a0"), Color("50c8c8"), Color("e8c8a0"), Color("f0e878"), Color("104848")],
	Enums.UnitClass.BERSERKER:     [Color("a03030"), Color("d05050"), Color("e8c8a0"), Color("503030"), Color("481818")],
	Enums.UnitClass.SHIELDBEARER:  [Color("8a6a3a"), Color("b09050"), Color("e8c8a0"), Color("c8b080"), Color("3a2a10")],
	Enums.UnitClass.LANCER:        [Color("b0a030"), Color("d0c050"), Color("e8c8a0"), Color("f0e878"), Color("484810")],
	Enums.UnitClass.ARCHER:        [Color("5a7a3a"), Color("7a9a5a"), Color("e8c8a0"), Color("b8a060"), Color("2a3a18")],
	Enums.UnitClass.WARLOCK:       [Color("503060"), Color("705080"), Color("c8b090"), Color("80ff80"), Color("201030")],
	Enums.UnitClass.CLERIC:        [Color("b0b0c0"), Color("e8e8f0"), Color("e8c8a0"), Color("f0d878"), Color("606070")],
}

# Each class sprite: array of [x, y, w, h, palette_index]
# palette_index: 0=body, 1=accent, 2=skin, 3=weapon, 4=dark
const SPRITE_DATA: Dictionary = {
	Enums.UnitClass.SOLDIER: [
		[24, 0, 16, 12, 0], [26, 2, 12, 2, 1], [22, 12, 20, 4, 2],
		[24, 15, 16, 2, 1], [22, 16, 20, 2, 0],
		[14, 16, 8, 16, 0], [18, 16, 4, 14, 4],
		[42, 14, 10, 4, 0], [44, 18, 8, 14, 0],
		[8, 16, 6, 22, 1], [8, 18, 6, 18, 4], [6, 22, 2, 12, 1],
		[46, 12, 6, 6, 3], [48, 6, 8, 6, 3], [49, 2, 6, 4, 3],
		[42, 32, 8, 4, 4], [22, 32, 10, 4, 4],
		[20, 34, 10, 18, 0], [34, 34, 10, 18, 0],
		[18, 34, 2, 14, 4], [44, 34, 2, 14, 4],
		[18, 48, 12, 8, 4], [34, 48, 12, 8, 4],
		[20, 56, 10, 6, 4], [34, 56, 10, 6, 4],
		[22, 30, 20, 4, 1],
	],
	Enums.UnitClass.MAGE: [
		[20, 0, 24, 4, 1], [24, 0, 16, 2, 0], [26, 4, 12, 2, 1],
		[24, 6, 16, 8, 0], [26, 8, 12, 4, 2],
		[18, 12, 28, 2, 0], [16, 14, 32, 4, 1],
		[14, 18, 36, 18, 0], [16, 18, 32, 16, 4],
		[14, 36, 36, 4, 1], [16, 40, 32, 4, 0],
		[18, 44, 28, 10, 0],
		[26, 44, 6, 8, 4], [32, 44, 6, 8, 4],
		[20, 54, 10, 6, 4], [34, 54, 10, 6, 4],
		[10, 18, 4, 8, 3], [12, 18, 2, 6, 4],
		[50, 16, 6, 6, 3], [52, 22, 4, 12, 3],
		[50, 18, 2, 14, 4],
		[48, 12, 4, 4, 0], [50, 8, 8, 4, 1],
	],
	Enums.UnitClass.SCOUT: [
		[22, 0, 20, 4, 1], [24, 4, 16, 6, 0],
		[26, 6, 12, 4, 2],
		[20, 10, 24, 2, 1], [18, 12, 28, 14, 0],
		[18, 16, 24, 8, 4],
		[12, 14, 6, 10, 0], [14, 14, 4, 8, 4],
		[46, 14, 6, 10, 0], [46, 14, 4, 8, 4],
		[8, 10, 4, 6, 3], [48, 10, 4, 6, 3],
		[18, 26, 28, 2, 1], [20, 28, 24, 14, 0],
		[20, 32, 20, 8, 4],
		[22, 42, 8, 10, 0], [34, 42, 8, 10, 0],
		[22, 48, 8, 4, 4], [34, 48, 8, 4, 4],
		[20, 52, 10, 8, 4], [34, 52, 10, 8, 4],
		[22, 56, 8, 6, 4], [34, 56, 8, 6, 4],
	],
	Enums.UnitClass.KNIGHT: [
		[20, 0, 24, 2, 0], [22, 2, 20, 2, 1], [24, 4, 16, 2, 0],
		[22, 6, 20, 8, 0], [24, 8, 16, 4, 1],
		[26, 6, 12, 2, 2],
		[16, 12, 32, 4, 0], [18, 14, 28, 2, 1],
		[14, 16, 36, 14, 0], [16, 16, 32, 12, 4],
		[18, 16, 28, 10, 1],
		[10, 18, 4, 10, 0], [50, 18, 4, 10, 0],
		[10, 18, 2, 8, 4], [52, 18, 2, 8, 4],
		[14, 30, 36, 4, 0], [16, 34, 32, 14, 0],
		[16, 38, 28, 8, 4],
		[20, 48, 10, 8, 0], [34, 48, 10, 8, 0],
		[20, 52, 10, 4, 4], [34, 52, 10, 4, 4],
		[18, 56, 12, 6, 4], [34, 56, 12, 6, 4],
	],
	Enums.UnitClass.ELEMENTALIST: [
		[24, 0, 16, 4, 0], [26, 4, 12, 2, 1], [24, 6, 16, 2, 2],
		[22, 8, 20, 4, 0], [20, 12, 24, 2, 1],
		[18, 14, 28, 20, 0], [18, 18, 24, 14, 4],
		[20, 34, 24, 4, 1], [22, 38, 20, 12, 0],
		[18, 50, 28, 8, 0],
		[12, 16, 6, 12, 1], [14, 18, 4, 8, 4],
		[46, 16, 6, 12, 1], [46, 18, 4, 8, 4],
		[54, 10, 8, 8, 3], [54, 18, 6, 14, 3],
		[56, 12, 4, 16, 4],
		[50, 6, 8, 4, 0], [52, 2, 10, 4, 1],
		[20, 34, 24, 2, 4],
		[24, 50, 6, 6, 4], [34, 50, 6, 6, 4],
		[22, 56, 8, 6, 4], [34, 56, 8, 6, 4],
	],
	Enums.UnitClass.BERSERKER: [
		[22, 0, 20, 4, 0], [24, 4, 16, 2, 1], [24, 6, 16, 2, 2],
		[22, 8, 20, 4, 0],
		[18, 12, 28, 2, 2], [16, 14, 32, 18, 0],
		[16, 14, 28, 16, 4],
		[8, 14, 8, 14, 2], [10, 14, 6, 12, 0],
		[48, 14, 8, 14, 2], [48, 14, 6, 12, 0],
		[52, 8, 10, 6, 3], [54, 14, 8, 18, 3],
		[52, 10, 6, 20, 4],
		[56, 4, 8, 4, 3], [58, 2, 6, 2, 4],
		[18, 32, 28, 2, 1], [20, 34, 24, 14, 0],
		[20, 36, 20, 10, 4],
		[22, 48, 8, 8, 0], [34, 48, 8, 8, 0],
		[24, 48, 4, 6, 1],
		[20, 56, 10, 6, 4], [34, 56, 10, 6, 4],
	],
	Enums.UnitClass.SHIELDBEARER: [
		[24, 0, 16, 4, 0], [26, 4, 12, 2, 2],
		[24, 6, 16, 4, 0], [24, 8, 16, 2, 1],
		[20, 10, 24, 4, 0], [18, 14, 28, 2, 0],
		[4, 4, 16, 28, 1], [4, 6, 14, 24, 4],
		[6, 8, 12, 20, 0],
		[44, 4, 16, 28, 1], [44, 6, 14, 24, 4],
		[46, 8, 12, 20, 0],
		[18, 16, 8, 16, 0], [38, 16, 8, 16, 0],
		[20, 30, 24, 4, 0],
		[22, 34, 20, 14, 0],
		[22, 36, 16, 10, 4],
		[24, 48, 8, 8, 0], [32, 48, 8, 8, 0],
		[22, 56, 10, 6, 4], [32, 56, 10, 6, 4],
	],
	Enums.UnitClass.LANCER: [
		[24, 0, 16, 4, 1], [26, 4, 12, 2, 2],
		[24, 6, 16, 4, 0], [26, 8, 12, 2, 1],
		[22, 10, 20, 2, 0],
		[18, 12, 28, 16, 0], [18, 12, 24, 14, 4],
		[14, 14, 4, 12, 0], [46, 14, 4, 12, 0],
		[12, 26, 40, 2, 1],
		[14, 28, 36, 14, 0],
		[14, 30, 32, 10, 4],
		[50, 4, 4, 4, 3], [52, 8, 4, 22, 3],
		[54, 8, 2, 20, 4],
		[20, 42, 10, 10, 0], [34, 42, 10, 10, 0],
		[22, 46, 6, 6, 4], [34, 46, 6, 6, 4],
		[20, 52, 10, 8, 4], [34, 52, 10, 8, 4],
		[18, 56, 12, 6, 4], [34, 56, 12, 6, 4],
	],
	Enums.UnitClass.ARCHER: [
		[24, 0, 16, 4, 1], [26, 4, 12, 4, 0],
		[26, 6, 12, 2, 2],
		[22, 8, 20, 2, 1], [20, 10, 24, 14, 0],
		[20, 12, 20, 10, 4],
		[14, 10, 6, 12, 0], [44, 10, 6, 12, 0],
		[8, 6, 6, 16, 3], [10, 8, 4, 12, 4],
		[50, 8, 6, 16, 3], [50, 10, 4, 12, 4],
		[6, 22, 4, 4, 1], [54, 22, 4, 4, 1],
		[18, 24, 28, 2, 1],
		[20, 26, 24, 14, 0],
		[20, 30, 20, 8, 4],
		[22, 40, 8, 10, 0], [34, 40, 8, 10, 0],
		[22, 46, 8, 4, 4], [34, 46, 8, 4, 4],
		[20, 50, 10, 8, 4], [34, 50, 10, 8, 4],
		[22, 56, 8, 6, 4], [34, 56, 8, 6, 4],
	],
	Enums.UnitClass.WARLOCK: [
		[24, 0, 16, 4, 1], [26, 4, 12, 4, 0],
		[28, 0, 8, 2, 4], [26, 8, 12, 2, 2],
		[22, 10, 20, 2, 0],
		[18, 12, 28, 2, 4], [16, 14, 32, 20, 0],
		[16, 16, 28, 16, 4],
		[12, 16, 4, 12, 0], [48, 16, 4, 12, 0],
		[14, 16, 2, 10, 4], [48, 16, 2, 10, 4],
		[8, 18, 4, 8, 3], [52, 18, 4, 8, 3],
		[16, 34, 32, 4, 1],
		[18, 38, 28, 12, 0],
		[18, 40, 24, 8, 4],
		[24, 50, 8, 8, 0], [32, 50, 8, 8, 0],
		[26, 50, 4, 6, 4], [34, 50, 4, 6, 4],
		[22, 56, 10, 6, 4], [32, 56, 10, 6, 4],
	],
	Enums.UnitClass.CLERIC: [
		[26, 0, 12, 2, 1], [24, 2, 16, 4, 0],
		[26, 6, 12, 2, 2],
		[28, 0, 8, 2, 3], [24, 8, 16, 2, 1],
		[22, 10, 20, 2, 0],
		[18, 12, 28, 16, 0], [18, 14, 24, 12, 4],
		[14, 14, 4, 12, 0], [46, 14, 4, 12, 0],
		[12, 26, 40, 2, 1],
		[14, 28, 36, 14, 0],
		[14, 30, 32, 10, 4],
		[52, 10, 6, 4, 3], [54, 14, 6, 16, 3],
		[50, 14, 4, 14, 4],
		[20, 42, 10, 10, 0], [34, 42, 10, 10, 0],
		[22, 46, 6, 6, 4], [34, 46, 6, 6, 4],
		[20, 52, 10, 8, 4], [34, 52, 10, 8, 4],
		[18, 56, 12, 6, 4], [34, 56, 12, 6, 4],
	],
}

# ── Class icons ───────────────────────────────────────────
const ICON_SZ: int = 32

# Each class icon: [[x, y, w, h, color_idx], ...]
# color_idx: 0=accent(palette[1]), 1=weapon(palette[3])
const ICON_DATA: Dictionary = {
	Enums.UnitClass.SOLDIER: [
		[13, 2, 6, 18, 0],
		[8, 16, 16, 4, 1],
		[13, 20, 6, 8, 0],
	],
	Enums.UnitClass.MAGE: [
		[14, 8, 4, 18, 0],
		[9, 4, 14, 6, 0],
		[12, 2, 8, 3, 0],
		[16, 0, 2, 2, 1],
	],
	Enums.UnitClass.SCOUT: [
		[13, 2, 6, 14, 0],
		[8, 14, 16, 3, 1],
		[13, 17, 6, 10, 0],
	],
	Enums.UnitClass.KNIGHT: [
		[6, 4, 20, 18, 0],
		[8, 6, 16, 14, 1],
		[14, 6, 4, 14, 0],
	],
	Enums.UnitClass.ELEMENTALIST: [
		[12, 2, 8, 10, 0],
		[10, 10, 12, 4, 0],
		[8, 14, 16, 6, 0],
		[10, 20, 12, 4, 0],
		[14, 8, 4, 4, 1],
	],
	Enums.UnitClass.BERSERKER: [
		[14, 2, 8, 14, 0],
		[8, 10, 8, 6, 0],
		[14, 16, 4, 10, 0],
	],
	Enums.UnitClass.SHIELDBEARER: [
		[4, 2, 24, 22, 0],
		[6, 4, 20, 18, 1],
		[14, 4, 4, 18, 0],
	],
	Enums.UnitClass.LANCER: [
		[14, 2, 4, 24, 0],
		[10, 2, 12, 4, 0],
		[8, 4, 16, 4, 1],
		[12, 26, 8, 4, 0],
	],
	Enums.UnitClass.ARCHER: [
		[14, 2, 4, 18, 0],
		[8, 2, 16, 4, 0],
		[12, 20, 8, 4, 1],
	],
	Enums.UnitClass.WARLOCK: [
		[8, 4, 16, 8, 0],
		[6, 8, 20, 10, 0],
		[8, 10, 16, 6, 1],
		[14, 11, 4, 4, 0],
	],
	Enums.UnitClass.CLERIC: [
		[6, 10, 20, 4, 0],
		[14, 2, 4, 24, 0],
	],
}

static func make_class_icon(cls: int) -> ImageTexture:
	var img := Image.create(ICON_SZ, ICON_SZ, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var wood := Color("7a5a30")
	var dark_wood := Color("2a1a08")
	var highlight := Color("9a7a50")
	var palette = PALETTES[cls]
	var rects = ICON_DATA.get(cls, [])

	_fill_rect(img, 0, 0, ICON_SZ, ICON_SZ, wood)
	_fill_rect(img, 0, 0, ICON_SZ, 1, dark_wood)
	_fill_rect(img, 0, ICON_SZ - 1, ICON_SZ, 1, dark_wood)
	_fill_rect(img, 0, 0, 1, ICON_SZ, dark_wood)
	_fill_rect(img, ICON_SZ - 1, 0, 1, ICON_SZ, dark_wood)
	_fill_rect(img, 1, 1, ICON_SZ - 2, 1, highlight)
	_fill_rect(img, 1, ICON_SZ - 2, ICON_SZ - 2, 1, highlight)
	_fill_rect(img, 1, 1, 1, ICON_SZ - 2, highlight)
	_fill_rect(img, ICON_SZ - 2, 1, 1, ICON_SZ - 2, highlight)

	for r in rects:
		var col: Color = palette[1] if r[4] == 0 else palette[3]
		_fill_rect(img, r[0], r[1], r[2], r[3], col)

	return ImageTexture.create_from_image(img)

static func _get_cache_key(cls: int, team: int, element: int, star: int) -> String:
	return "%d_%d_%d_%d" % [cls, team, element, star]

static func generate(cls: int, team: int, element: int, star: int) -> ImageTexture:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var palette = PALETTES[cls]
	var rects: Array = SPRITE_DATA[cls]

	for r in rects:
		var col: Color = palette[r[4]]
		if r[4] == 0:
			col = _team_tint(col, team)
		_fill_rect(img, r[0], r[1], r[2], r[3], col)

	if element != Enums.ElementType.NONE:
		_draw_aura(img, Enums.element_color(element), team)

	if star > 0:
		_draw_stars(img, star)

	return ImageTexture.create_from_image(img)

static func _team_tint(c: Color, team: int) -> Color:
	if team == 0:
		return c
	var avg: float = (c.r + c.g + c.b) / 3.0
	return Color(avg * 0.6 + 0.3, avg * 0.4 + 0.1, avg * 0.4 + 0.1, c.a)

static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color):
	for px in range(x, x + w):
		for py in range(y, y + h):
			if px >= 0 and px < SIZE and py >= 0 and py < SIZE:
				img.set_pixel(px, py, color)

static func _draw_aura(img: Image, color: Color, team: int):
	var alpha: float = 0.25
	var c := Color(color.r, color.g, color.b, alpha)
	for x in range(SIZE):
		for y in range(SIZE):
			var existing := img.get_pixel(x, y)
			if existing.a > 0.0:
				img.set_pixel(x, y, Color(
					existing.r * (1.0 - alpha) + c.r * alpha,
					existing.g * (1.0 - alpha) + c.g * alpha,
					existing.b * (1.0 - alpha) + c.b * alpha,
					existing.a
				))

static func _draw_stars(img: Image, star: int):
	var star_colors := [Color.TRANSPARENT, Color("ffd700"), Color("ffa500")]
	var sc: Color = star_colors[mini(star, 2)]
	var sw: int = 14
	var sh: int = 6
	for i in range(star):
		var sx: int = 4 + i * 24
		_fill_rect(img, sx, 0, sw, sh, sc)
		img.set_pixel(sx + 4, 0, Color.TRANSPARENT)
		img.set_pixel(sx + 6, 2, Color.TRANSPARENT)
