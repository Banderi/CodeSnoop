extends Node

const GDNSHELL_RES = preload("res://gdnative.gdns")
var GDNSHELL = null

var root_node = null
var terminal_node = null
var shell_thread = null

func send_string(s : String):
	if shell_thread != null:
		if GDNSHELL.send_string(s):
			print("success!")
		else:
			print("failure...")

func thread_exec():
	Log.generic(null, "starting child process...")
	GDNSHELL = GDNSHELL_RES.new()
	GDNSHELL.connect("child_process_started", root_node, "_child_process_started")
	GDNSHELL.spawn(terminal_node) # this will internally loop and update, and exit on process close
	shell_thread = null
	GDNSHELL = null
	root_node._child_process_stopped()

func start():
	# stop previous session!
	stop()

	# clear terminal
	terminal_node.clear()
	shell_thread = Thread.new()
	shell_thread.start(self, "thread_exec")
func stop():
	if shell_thread != null:
		Log.generic(null, "killing child process...")
		GDNSHELL.kill()
		shell_thread.wait_to_finish()
	shell_thread = null
	GDNSHELL = null

func _exit_tree():
	# close any open session when shutting down the program
	stop()
