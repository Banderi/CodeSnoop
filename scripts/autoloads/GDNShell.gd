extends Node

const GDNSHELL_RES = preload("res://gdnative.gdns")
var GDNSHELL = null

var console_node = null
var shell_thread = null

func send_string(s : String):
	if shell_thread != null:
		if GDNSHELL.send_string(s):
			print("success!")
		else:
			print("failure...")
func send(event):
	if shell_thread != null:
		var scancode = event.get_scancode_with_modifiers()
		if GDNSHELL.send_input(scancode):
			print("success!")
		else:
			print("failure...")

func thread_exec():
	Log.generic(null, "started!")
	GDNSHELL = GDNSHELL_RES.new()
	GDNSHELL.spawn(console_node) # this will internally loop and update, and exit on process close
	Log.generic(null, "exiting shell thread...")
	shell_thread = null
	GDNSHELL = null

func start():
	stop()

	print("starting...")
	shell_thread = Thread.new()
	shell_thread.start(self, "thread_exec")
func stop():
	if shell_thread != null:
		print("stopping...")
#		var th_id = shell_thread.get_id()
#		var caller_id = OS.get_thread_caller_id()
#		if int(th_id) != caller_id:
		GDNSHELL.kill()
		shell_thread.wait_to_finish()
	shell_thread = null
	GDNSHELL = null


func _exit_tree():
	stop()
