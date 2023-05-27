extends Node

const APP_NAME = "GDNShell"
var LOG = []

const GDNSHELL_RES = preload("res://gdnative.gdns")
onready var GDNSHELL = GDNSHELL_RES.new()

var root_node = null
var terminal_node = null
onready var shell_thread = Thread.new()

func _child_process_started():
	print("STARTED!")
	pass
func _child_process_stopped():
	print("STOPPED!")

var is_stopping = false
func _process(delta):
	if is_stopping:
		shell_thread.wait_to_finish()
		is_stopping = false

func GDN_INIT():
	assert(GDNSHELL != null)
	Log.generic(self, "Loading GDNative...")
	GDNSHELL.connect("child_process_started", self, "_child_process_started")
	GDNSHELL.connect("child_process_stopped", self, "_child_process_stopped")

func _THREAD_SUBROUTINE(cmd):
	# this will internally loop and update, function will resume on close
	Log.generic(self, str(":: Entering thread ", shell_thread.get_id()))
	GDNSHELL.spawn(cmd)

	# cleanup thread
	is_stopping = true
	Log.generic(self, str(":: Exiting thread ", shell_thread.get_id()))

var shell_cmd = "E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe"
func start():
	assert(GDNSHELL != null)

	# stop any running session first
	stop()

	# clear terminal & start thread
	terminal_node.text = ""
	shell_thread.start(self, "_THREAD_SUBROUTINE", shell_cmd)
func stop():
	if is_stopping == true:
		return
	assert(GDNSHELL != null)
	assert(shell_thread != null)
	if shell_thread.is_alive():
		Log.generic(self, str("Killing child process on thread ", shell_thread.get_id()))
		GDNSHELL.kill()
	if shell_thread.is_active():
		shell_thread.wait_to_finish()
		is_stopping = false
	else:
		Log.generic(self, "No process is running!")


var SYNC_MODE = 0
func sync_text(line, size):
	assert(GDNSHELL != null)
	var buffer = null
	match SYNC_MODE:
		0:
			buffer = GDNSHELL.fetch_at_line(line, size)
		1:
			buffer = GDNSHELL.fetch_since_last_time()
	return buffer
func get_lines():
	assert(GDNSHELL != null)
	return GDNSHELL.get_lines()

func send_string(s : String):
	if shell_thread != null:
		if GDNSHELL.send_string(s + "\n"):
			print("success!")
		else:
			print("failure...")
func clear():
	assert(terminal_node != null)
	assert(GDNSHELL != null)
	GDNSHELL.clear()
	terminal_node.text = ""

func _exit_tree():
	# close any open session when shutting down
	stop()
