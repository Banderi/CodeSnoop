extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	GDNShell.root_node = self
	GDNShell.terminal_node = $Console/Terminal
	$LogPrinter.text = ""
	GDNShell.terminal_node.clear()
	$Console/Input.clear()
	$Console/Input.editable = false

var logger_lines = 0
var logger_autoscroll = true
func log_scroll():
	if Log.LOG_ENGINE.size() != logger_lines:
		$LogPrinter.bbcode_text = ""
		logger_lines = Log.LOG_ENGINE.size()
		for l in Log.LOG_ENGINE:
			$LogPrinter.bbcode_text += l + "\n"
		if logger_autoscroll:
			$LogPrinter.scroll_to_line(logger_lines-1)

var console_lines = 0
var console_autoscroll = true
func console_catch():
	if GDNShell.terminal_node.get_line_count() != console_lines:
		console_lines = GDNShell.terminal_node.get_line_count()
		if console_autoscroll:
			GDNShell.terminal_node.scroll_to_line(console_lines-1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	log_scroll()
	console_catch()

func _input(event):
	pass

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

func _child_process_started():
	$Console/Input.editable = true
func _child_process_stopped():
	$Console/Input.editable = false

func _on_BtnBreak_pressed():
	pass # Replace with function body.
func _on_BtnBack_pressed():
	pass # Replace with function body.
func _on_BtnStep_pressed():
	pass # Replace with function body.


var console_last_idx = 0
func _on_ConsoleInput_text_entered(text):
#	if text != "":
	GDNShell.terminal_node.text += str(text,"\n")
	GDNShell.send_string(text)
	$Console/Input.clear()
func _on_ConsoleInput_gui_input(event):
	if Input.is_action_just_pressed("clear_console"):
		GDNShell.terminal_node.clear()
