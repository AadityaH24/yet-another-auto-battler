class_name MainMenu extends CanvasLayer

signal new_game()
signal quit_game()

func _init():
	layer = 3

func _ready():
	var vs := Vector2(get_viewport().size)

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.08, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "YAABR"
	title.position = Vector2((vs.x - 500) / 2, vs.y / 2 - 160)
	title.size = Vector2(500, 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	title.add_theme_font_size_override("font_size", 64)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Yet Another Auto Battler Roguelike"
	subtitle.position = Vector2((vs.x - 500) / 2, vs.y / 2 - 90)
	subtitle.size = Vector2(500, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	subtitle.add_theme_font_size_override("font_size", 16)
	add_child(subtitle)

	var new_btn := _make_btn("New Game", Vector2((vs.x - 220) / 2, vs.y / 2), Vector2(220, 54), Color(0.2, 0.5, 0.3))
	new_btn.pressed.connect(func(): new_game.emit())
	add_child(new_btn)

	var quit_btn := _make_btn("Quit", Vector2((vs.x - 220) / 2, vs.y / 2 + 70), Vector2(220, 54), Color(0.4, 0.15, 0.15))
	quit_btn.pressed.connect(func(): quit_game.emit())
	add_child(quit_btn)

func _make_btn(text: String, pos: Vector2, size: Vector2, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_color_override("font_color", Color.WHITE)
	var sn := StyleBoxFlat.new()
	sn.bg_color = color
	sn.corner_radius_top_left = 6; sn.corner_radius_top_right = 6
	sn.corner_radius_bottom_left = 6; sn.corner_radius_bottom_right = 6
	b.add_theme_stylebox_override("normal", sn)
	var sh := StyleBoxFlat.new()
	sh.bg_color = color.lightened(0.2)
	sh.corner_radius_top_left = 6; sh.corner_radius_top_right = 6
	sh.corner_radius_bottom_left = 6; sh.corner_radius_bottom_right = 6
	b.add_theme_stylebox_override("hover", sh)
	return b