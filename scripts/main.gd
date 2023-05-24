extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
#	var gdns = load("res://gdnative.gdns").new()
	pass # Replace with function body.


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
	if $Console.LOG.size() != console_lines:
		$Console.bbcode_text = ""
		console_lines = $Console.LOG.size()
		for l in $Console.LOG:
			var stripped = l.split("[Console]: ", false, 1)
			$Console.bbcode_text += stripped[1] + "\n"
		if console_autoscroll:
			$Console.scroll_to_line(console_lines-1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	log_scroll()
	console_catch()

func _input(event):
	# TODO: keyboard shortcuts
	pass


func test(output):
	print(output)
	pass

func _on_BtnOpen_pressed():

#	var gdns = load("res://gdnative.gdns").new()


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

	pass # Replace with function body.
func _on_BtnStop_pressed():
	pass # Replace with function body.

func _on_BtnBreak_pressed():
	pass # Replace with function body.
func _on_BtnBack_pressed():
	pass # Replace with function body.
func _on_BtnStep_pressed():
	pass # Replace with function body.


func _on_Terminal_key_pressed(data, event):
	print(str(data, " ", event))
	pass # Replace with function body.
