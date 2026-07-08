class_name MainMenu extends CanvasLayer

signal new_game()
signal quit_game()

func _init():
	layer = 3

func _ready():
	var vs := Vector2(get_viewport().size)

	add_child(ThemeHelper.make_bg())

	var title := ThemeHelper.make_title("YAABR", vs, vs.y / 2 - 180, 72)
	add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Yet Another Auto Battler Roguelike"
	subtitle.position = Vector2((vs.x - 500) / 2, vs.y / 2 - 100)
	subtitle.size = Vector2(500, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", ThemeHelper.TEXT_DIM)
	subtitle.add_theme_font_size_override("font_size", 16)
	add_child(subtitle)

	var new_btn := ThemeHelper.make_btn("New Game", Vector2((vs.x - 220) / 2, vs.y / 2), Vector2(220, 54), ThemeHelper.SUCCESS)
	new_btn.pressed.connect(func(): new_game.emit())
	add_child(new_btn)

	var quit_btn := ThemeHelper.make_btn("Quit", Vector2((vs.x - 220) / 2, vs.y / 2 + 70), Vector2(220, 54), ThemeHelper.DANGER)
	quit_btn.pressed.connect(func(): quit_game.emit())
	add_child(quit_btn)
