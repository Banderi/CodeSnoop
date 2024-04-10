extends TextEdit

onready var scrollbar = get_parent().get_node("VScrollBar")
onready var input_box = get_parent().get_node("Input")
onready var checkbox = $CheckBox
onready var spinbox = $SpinBox

func set_color(color):
	set("custom_colors/default_color", color)
	set("custom_colors/font_color", color)
	set("custom_colors/font_color_readonly", color)

var scroll = 0
var lines_visible = 14
var scroll_jump = 4
var autoscroll = false
func _process(delta):
	# update scrollbar
	var lines_count = GDNShell.get_lines_count()
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
	var buffer = GDNShell.get_text(start_line, end_line)

	if buffer != null:
		match GDNShell.SYNC_MODE:
			0:
				if text != buffer + GDNShell.temp_input_string:
					text = buffer + GDNShell.temp_input_string
					release_focus()
			1:
				text += buffer + GDNShell.temp_input_string

	# debug info
	if $Label.visible:
		$Label.text = str(
			GDNShell.shell_thread, "\n",
			GDNShell.shell_thread.is_active(), "\n",
			GDNShell.shell_thread.is_alive(), "\n",
			start_line, " : ", end_line, " (", lines_count, ")\n",
			get_local_mouse_position(), "\n"
		)

func _input(event):
	if Input.is_action_just_pressed("debug_step"):
		if Input.is_action_pressed("shift"):
			GDNShell.step_back()
		else:
			GDNShell.step_forward()
	if Input.is_action_just_pressed("debug_back"):
		GDNShell.step_back()
	if Input.is_action_just_pressed("debug_pause_resume"):
		GDNShell.resume() if GDNShell.is_paused else GDNShell.pause()
	
	# scroll when mouse is over the box
	if Rect2(Vector2(), rect_size).has_point(get_local_mouse_position()):
		var prev_scroll = scrollbar.value
		if Input.is_action_just_pressed("scroll_up"):
			scrollbar.value -= scroll_jump
		if Input.is_action_just_pressed("scroll_down"):
			scrollbar.value += scroll_jump
		if prev_scroll != scrollbar.value:
			checkbox.pressed = false
			autoscroll = false
	
	# intercept terminal key inputs
	if !readonly && event is InputEventKey && event.pressed:
		if event.scancode == KEY_BACKSPACE:
			var l = GDNShell.temp_input_string.length()
			if l > 0:
				GDNShell.temp_input_string = GDNShell.temp_input_string.substr(0, l - 1)
				text = text.substr(0, text.length() - 1)
				cursor_set_line(99999)
				cursor_set_column(99999)
		if event.scancode == KEY_ENTER:
			GDNShell.send_string(GDNShell.temp_input_string)
		else:
			var c = char(event.unicode)
			if c == " " || c.strip_edges() != "":
				text += c
				GDNShell.temp_input_string += c
				cursor_set_line(99999)
				cursor_set_column(99999)
		get_tree().set_input_as_handled()

func _on_VScrollBar_scrolling():
	checkbox.pressed = false
