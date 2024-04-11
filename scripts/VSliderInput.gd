extends VSlider

signal scrolled

func _input(event):
	var parent = get_parent()
	var parent_rect = Rect2(Vector2(), parent.rect_size + Vector2(-20,0))
	if parent_rect.has_point(parent.get_local_mouse_position()):
		if Input.is_action_just_pressed("scroll_up"):
			value += 4
#			emit_signal("scrolled")
		if Input.is_action_just_pressed("scroll_down"):
			value -= 4
#			emit_signal("scrolled")

func _on_VSlider_value_changed(value):
	emit_signal("scrolled")
