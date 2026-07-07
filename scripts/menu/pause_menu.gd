class_name PauseMenu extends CanvasLayer

signal resume()
signal main_menu()

var _paused: bool = false

func _init():
	layer = 4
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_pause():
	_paused = true
	var vs := Vector2(get_viewport().size)

	var bg := ColorRect.new()
	bg.name = "PauseBg"
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.name = "PauseTitle"
	title.text = "PAUSED"
	title.position = Vector2((vs.x - 400) / 2, vs.y / 2 - 140)
	title.size = Vector2(400, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 48)
	add_child(title)

	var resume_btn := _make_btn("Resume", Vector2((vs.x - 220) / 2, vs.y / 2 - 40), Vector2(220, 50), Color(0.2, 0.5, 0.3))
	resume_btn.name = "PauseResume"
	resume_btn.pressed.connect(func(): _on_resume())
	add_child(resume_btn)

	var menu_btn := _make_btn("Main Menu", Vector2((vs.x - 220) / 2, vs.y / 2 + 30), Vector2(220, 50), Color(0.3, 0.3, 0.2))
	menu_btn.name = "PauseMenu"
	menu_btn.pressed.connect(func(): _on_main_menu())
	add_child(menu_btn)

	var quit_btn := _make_btn("Quit", Vector2((vs.x - 220) / 2, vs.y / 2 + 100), Vector2(220, 50), Color(0.4, 0.15, 0.15))
	quit_btn.name = "PauseQuit"
	quit_btn.pressed.connect(func(): get_tree().quit())
	add_child(quit_btn)

func hide_pause():
	for c in get_children():
		c.queue_free()
	_paused = false

func _on_resume():
	resume.emit()
	hide_pause()

func _on_main_menu():
	main_menu.emit()
	hide_pause()

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