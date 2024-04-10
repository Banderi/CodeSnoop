extends VSlider

signal scrolled

var parent_rect = null
func _ready():
	parent_rect = Rect2(Vector2(), get_parent().rect_size + Vector2(-20,50))
func _input(event):
	if parent_rect.has_point(get_parent().get_local_mouse_position()):
		if Input.is_action_just_pressed("scroll_up"):
			value += 4
			emit_signal("scrolled")
		if Input.is_action_just_pressed("scroll_down"):
			value -= 4
			emit_signal("scrolled")

func _on_VSlider_value_changed(value):
	emit_signal("scrolled")
