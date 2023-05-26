extends RichTextLabel

func clear():
	text = ""

var DEBUG = false

var scroll = 0
var max_lines = 4
func _process(delta):
	var buffer = GDNShell.sync_text(-1 if $CheckBox.pressed else $VScrollBar.value, $SpinBox.value)
	if buffer != null:
		text = buffer

	if DEBUG:
		GDNShell.start()

func _input(event):
	if Input.is_action_just_pressed("debug_step"):
		DEBUG = !DEBUG
func _on_Input_text_entered(new_text):
	GDNShell.send_string(new_text)
	$Input.clear()
