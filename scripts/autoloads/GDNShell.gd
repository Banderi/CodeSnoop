extends Node

const APP_NAME = "GDNShell"
var LOG = []

const GDNSHELL_RES = preload("res://gdnative.gdns")
var GDNSHELL = null

var root_node = null
var terminal_node = null
var shell_thread = null

func thread_subroutine():
	Log.generic(self, "Spawning child process...")
	GDNSHELL = GDNSHELL_RES.new()
	GDNSHELL.connect("child_process_started", terminal_node, "_child_process_started")
	GDNSHELL.connect("waiting_for_inputs", terminal_node, "_waiting_for_inputs")
	GDNSHELL.spawn(terminal_node) # this will internally loop and update, function will resume on close
	GDNSHELL = null
	terminal_node._child_process_stopped()

func start():
	# stop any running session first
	if GDNSHELL != null:
		stop()

	# clear terminal & start thread
	clear()
	shell_thread = Thread.new()
	shell_thread.start(self, "thread_subroutine")
func stop():
	if GDNSHELL != null:
		Log.generic(self, "Killing child process...")
		GDNSHELL.kill()
		shell_thread.wait_to_finish()
	else:
		Log.generic(self, "No process is running!")

func _exit_tree():
	# close any open session when shutting down
	stop()

func send_string(s : String):
	if shell_thread != null:
		if GDNSHELL.send_string(s):
			print("success!")
		else:
			print("failure...")
func clear():
	terminal_node.text = ""
