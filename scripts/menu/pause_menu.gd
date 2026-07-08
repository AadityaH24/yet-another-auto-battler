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

	var title := ThemeHelper.make_title("PAUSED", vs, vs.y / 2 - 160, 52)
	add_child(title)

	var resume_btn := ThemeHelper.make_btn("Resume", Vector2((vs.x - 220) / 2, vs.y / 2 - 40), Vector2(220, 50), ThemeHelper.SUCCESS)
	resume_btn.name = "PauseResume"
	resume_btn.pressed.connect(func(): _on_resume())
	add_child(resume_btn)

	var menu_btn := ThemeHelper.make_btn("Main Menu", Vector2((vs.x - 220) / 2, vs.y / 2 + 30), Vector2(220, 50))
	menu_btn.name = "PauseMenu"
	menu_btn.pressed.connect(func(): _on_main_menu())
	add_child(menu_btn)

	var quit_btn := ThemeHelper.make_btn("Quit", Vector2((vs.x - 220) / 2, vs.y / 2 + 100), Vector2(220, 50), ThemeHelper.DANGER)
	quit_btn.name = "PauseQuit"
	quit_btn.pressed.connect(func(): get_tree().quit())
	add_child(quit_btn)

func hide_pause():
	for c in get_children():
		c.queue_free()
	_paused = false

func _on_resume():
	resume.emit()
	hide_pause.call_deferred()

func _on_main_menu():
	main_menu.emit()
	hide_pause.call_deferred()
