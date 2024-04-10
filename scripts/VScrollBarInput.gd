extends VScrollBar

signal scrolled
func _on_VScrollBar_scrolling():
	if Input.is_action_just_pressed("scroll_up"):
		value -= 4
	if Input.is_action_just_pressed("scroll_down"):
		value += 4
	emit_signal("scrolled")
