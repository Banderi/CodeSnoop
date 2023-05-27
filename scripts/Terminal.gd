extends RichTextLabel

var DEBUG = false

var scroll = 0
var max_lines = 4
func _process(delta):

	var start_line = -$SpinBox.value if $CheckBox.pressed else get_parent().get_node("VScrollBar").value
	var end_line = 0 if $CheckBox.pressed else start_line + $SpinBox.value
	var buffer = GDNShell.sync_text(start_line, end_line)

	if buffer != null:
		match GDNShell.SYNC_MODE:
			0:
				text = buffer
			1:
				text += buffer

	$Label.text = str(
		GDNShell.shell_thread, "\n",
		GDNShell.shell_thread.is_active(), "\n",
		GDNShell.shell_thread.is_alive(), "\n",
		start_line, " : ", end_line, "\n",
		""
	)


	if DEBUG:
		GDNShell.start()

func _input(event):
	if Input.is_action_just_pressed("debug_step"):
		DEBUG = !DEBUG

