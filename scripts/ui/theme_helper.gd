class_name ThemeHelper extends RefCounted

const BG_DARK := Color("#0c0a0a")
const BG_PANEL := Color("#141110")
const BG_CARD := Color("#1c1816")
const BORDER := Color("#3a3028")
const BORDER_LIGHT := Color("#5a4a3a")
const GOLD := Color("#d4a854")
const GOLD_BRIGHT := Color("#e8c878")
const TEXT := Color("#e0d8cc")
const TEXT_DIM := Color("#8a8278")
const SUCCESS := Color("#4a8a40")
const DANGER := Color("#8a3030")
const INFO := Color("#4a7a9a")

static func make_bg() -> ColorRect:
	var r := ColorRect.new()
	r.color = BG_DARK
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r

static func make_title(text: String, vs: Vector2, y: float, font_size: int = 28) -> Label:
	var l := Label.new()
	l.text = text
	l.position = Vector2((vs.x - 500) / 2, y)
	l.size = Vector2(500, font_size + 20)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", GOLD)
	l.add_theme_font_size_override("font_size", font_size)
	return l

static func make_label(text: String, pos: Vector2, p_size: Vector2, font_size: int = 14, color: Color = TEXT, align: int = -1) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = p_size
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if align >= 0:
		l.horizontal_alignment = align as HorizontalAlignment
	var style := StyleBoxFlat.new()
	style.bg_color = BG_PANEL
	style.border_color = BORDER
	style.border_width_top = 1
	style.border_width_left = 1
	style.border_width_bottom = 1
	style.border_width_right = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_top = 4
	style.content_margin_left = 6
	l.add_theme_stylebox_override("normal", style)
	return l

static func make_panel(pos: Vector2, p_size: Vector2) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = p_size
	r.color = BG_PANEL
	return r

static func make_btn(text: String, pos: Vector2, p_size: Vector2, color: Color = Color.TRANSPARENT) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = p_size
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_font_size_override("font_size", 16)
	var sn := StyleBoxFlat.new()
	sn.bg_color = color if color.a > 0 else BG_PANEL
	sn.border_color = GOLD
	sn.border_width_top = 1
	sn.border_width_left = 1
	sn.border_width_bottom = 2
	sn.border_width_right = 2
	sn.corner_radius_top_left = 4
	sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4
	sn.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.15)
	sh.border_color = GOLD_BRIGHT
	sh.border_width_top = 1
	sh.border_width_left = 1
	sh.border_width_bottom = 2
	sh.border_width_right = 2
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("hover", sh)
	var sp := StyleBoxFlat.new()
	sp.bg_color = BORDER
	sp.border_color = GOLD
	sp.border_width_top = 2
	sp.border_width_left = 2
	sp.border_width_bottom = 1
	sp.border_width_right = 1
	sp.corner_radius_top_left = 4
	sp.corner_radius_top_right = 4
	sp.corner_radius_bottom_left = 4
	sp.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("pressed", sp)
	var sd := StyleBoxFlat.new()
	sd.bg_color = BG_DARK
	sd.border_color = BORDER
	sd.border_width_top = 1
	sd.border_width_left = 1
	sd.border_width_bottom = 1
	sd.border_width_right = 1
	sd.corner_radius_top_left = 4
	sd.corner_radius_top_right = 4
	sd.corner_radius_bottom_left = 4
	sd.corner_radius_bottom_right = 4
	b.add_theme_stylebox_override("disabled", sd)
	return b

static func style_card(btn: Button, weight: int, dimmed: bool = false):
	if dimmed:
		var sd := StyleBoxFlat.new()
		sd.bg_color = BG_DARK
		sd.border_color = BORDER
		sd.border_width_top = 1
		sd.border_width_left = 1
		sd.border_width_bottom = 1
		sd.border_width_right = 1
		sd.corner_radius_top_left = 4
		sd.corner_radius_top_right = 4
		sd.corner_radius_bottom_left = 4
		sd.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", sd)
		btn.add_theme_stylebox_override("hover", sd)
		return
	var accent := Color(BORDER) if weight == -1 else (INFO if weight == Enums.UnitWeight.LIGHT else DANGER)
	var sn := StyleBoxFlat.new()
	sn.bg_color = BG_CARD
	sn.border_color = accent
	sn.border_width_top = 1
	sn.border_width_left = 3
	sn.border_width_bottom = 1
	sn.border_width_right = 1
	sn.corner_radius_top_left = 4
	sn.corner_radius_top_right = 4
	sn.corner_radius_bottom_left = 4
	sn.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = BG_CARD
	sh.border_color = GOLD
	sh.border_width_top = 1
	sh.border_width_left = 3
	sh.border_width_bottom = 1
	sh.border_width_right = 1
	sh.corner_radius_top_left = 4
	sh.corner_radius_top_right = 4
	sh.corner_radius_bottom_left = 4
	sh.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", sh)
