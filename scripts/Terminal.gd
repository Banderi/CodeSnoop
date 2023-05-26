extends RichTextLabel

var DEBUG = false

var scroll = 0
var max_lines = 4
func _process(delta):
	var buffer = GDNShell.sync_text(-1 if $CheckBox.pressed else $VScrollBar.value, $SpinBox.value)
	if buffer != null && buffer != "":
		text += buffer


	$Label.text = str(
		GDNShell.shell_thread, "\n",
		GDNShell.shell_thread.is_active(), "\n",
		GDNShell.shell_thread.is_alive(), "\n",

		""
	)


	if DEBUG:
		GDNShell.start()

func _input(event):
	if Input.is_action_just_pressed("debug_step"):
		DEBUG = !DEBUG

