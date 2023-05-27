extends RichTextLabel

var DEBUG = false

onready var scrollbar = get_parent().get_node("VScrollBar")
onready var checkbox = $CheckBox
onready var spinbox = $SpinBox

var scroll = 0
var lines_visible = 14
var scroll_jump = 4
var autoscroll = false
func _process(delta):
	# update scrollbar
	var lines_count = GDNShell.get_lines()
	scrollbar.max_value = lines_count - lines_visible
	if scrollbar.value >= scrollbar.max_value:
		checkbox.pressed = true
		autoscroll = true
	if autoscroll:
		scrollbar.value = scrollbar.max_value

	# update from UI
	lines_visible = spinbox.value
	autoscroll = checkbox.pressed
	scroll = scrollbar.value

	var start_line = scroll
	var end_line = start_line + lines_visible
	var buffer = GDNShell.sync_text(start_line, end_line)

	if buffer != null:
		match GDNShell.SYNC_MODE:
			0:
				if text != buffer:
					text = buffer
			1:
				text += buffer

	$Label.text = str(
		GDNShell.shell_thread, "\n",
		GDNShell.shell_thread.is_active(), "\n",
		GDNShell.shell_thread.is_alive(), "\n",
		start_line, " : ", end_line, " (", lines_count, ")\n",
		get_local_mouse_position(),
		""
	)


	if DEBUG:
		GDNShell.start()

func _input(event):
	if Input.is_action_just_pressed("debug_step"):
		DEBUG = !DEBUG
	if Rect2(Vector2(), rect_size).has_point(get_local_mouse_position()):
		var prev_scroll = scrollbar.value
		if Input.is_action_just_pressed("scroll_up"):
			scrollbar.value -= scroll_jump
		if Input.is_action_just_pressed("scroll_down"):
			scrollbar.value += scroll_jump
		if prev_scroll != scrollbar.value:
			checkbox.pressed = false
			autoscroll = false

func _on_VScrollBar_scrolling():
	checkbox.pressed = false
