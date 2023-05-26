extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	GDNShell.root_node = self
	GDNShell.terminal_node = $Console/Terminal
	GDNShell.GDN_INIT()
	$LogPrinter.text = ""
	GDNShell.clear()
#	$Console/Input.editable = false

var logger_lines = 0
var logger_autoscroll = true
func log_scroll():
	if Log.LOG_CHANGED:
		$LogPrinter.bbcode_text = ""
		logger_lines = Log.LOG_EVERYTHING.size()
		for l in Log.LOG_EVERYTHING:
			$LogPrinter.bbcode_text += l + "\n"
		if logger_autoscroll:
			$LogPrinter.scroll_to_line(logger_lines-1)
		Log.LOG_CHANGED = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	log_scroll()
	$Label.text = str(Engine.get_frames_per_second())

func _input(event):
	if Input.is_action_just_pressed("debug_start"):
		GDNShell.start()
		$Console/Input.grab_focus()
	if Input.is_action_just_pressed("debug_stop"):
		GDNShell.stop()
	if Input.is_action_just_pressed("clear_console"):
		GDNShell.clear()

func _on_BtnOpen_pressed():

#	var gdns = load("res://gdnative.gdns").new()
#	GDNShell.start()


#	Log.generic(null, "test")
#	Shell.run("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe", $Console, funcref(self, "test"))
#	Shell.run_sync("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe", $Console, true, true)
#	Shell.run("CMD.exe /C echo test", $Console, funcref(self, "test"))
	pass # Replace with function body.
func _on_BtnSave_pressed():
	pass # Replace with function body.
func _on_BtnClose_pressed():
	pass # Replace with function body.

func _on_BtnRun_pressed():
	GDNShell.start()
func _on_BtnStop_pressed():
	GDNShell.stop()

func _on_BtnBreak_pressed():
	pass # Replace with function body.
func _on_BtnBack_pressed():
	pass # Replace with function body.
func _on_BtnStep_pressed():
	pass # Replace with function body.


func _on_Input_text_entered(new_text):
	GDNShell.send_string(new_text)
	$Console/Input.clear()
