class_name DamageNumber extends Node2D

func start(amount: int, world_pos: Vector2, is_critical: bool = false):
	var lbl := Label.new()
	var text := str(amount)
	if is_critical:
		text += "!"
		lbl.add_theme_color_override("font_color", Color("#e8c878"))
		lbl.add_theme_font_size_override("font_size", 22)
	else:
		lbl.add_theme_color_override("font_color", Color("#e0d8cc"))
		lbl.add_theme_font_size_override("font_size", 18)
	lbl.text = text
	var size := lbl.get_theme_font_size("font_size")
	var font := lbl.get_theme_font("font")
	if font:
		var ts := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, size)
		lbl.size = ts + Vector2(4, 2)
	else:
		lbl.size = Vector2(60, 24)
	lbl.position = -lbl.size / 2
	add_child(lbl)

	position = world_pos + Vector2(0, -20)

	var tween := create_tween().set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position", position + Vector2(0, -40), 0.6)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.15)
	tween.tween_callback(queue_free)
