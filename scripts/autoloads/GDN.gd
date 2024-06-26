extends Node

const APP_NAME = "GDN"
var LOG = []

const MODULE_RES = preload("res://gdnative.gdns")
onready var MODULE = MODULE_RES.new()

var root_node = null
var terminal_node = null
onready var shell_thread = Thread.new()

func _child_process_started():
	print("STARTED!")
	pass
func _child_process_stopped():
	print("STOPPED!")

var is_stopping = false
func has_started_process_attached():
	if !shell_thread.is_active():
		return false
	if !shell_thread.is_alive():
		return false
	if is_stopping:
		return false
	return true

func _process(_delta):
	if is_stopping:
		shell_thread.wait_to_finish()
		is_stopping = false

func GDN_INIT():
	assert(MODULE != null)
	Log.generic(null, "Loading GDNative...")
	MODULE.connect("child_process_started", self, "_child_process_started")
	MODULE.connect("child_process_stopped", self, "_child_process_stopped")

func _THREAD_SUBROUTINE(cmd):
	# this will internally loop and update, function will resume on close
	Log.generic(self, str(":: Entering thread ", shell_thread.get_id()))
	var r = MODULE.spawn(cmd, hidden_process_window)
	if r != 0:
		Log.error(self, r, "Could not start process!", true)
		

	# cleanup thread
	is_stopping = true
	Log.generic(self, str(":: Exiting thread ", shell_thread.get_id()))

var shell_cmd = null
var hidden_process_window = false
func start():
	assert(MODULE != null)
	if shell_cmd == null:
		return # no valid shell command given!

	# stop any running session first
	stop()

	# clear terminal & start thread
	terminal_node.text = ""
	shell_thread.start(self, "_THREAD_SUBROUTINE", shell_cmd)
func stop():
	if is_stopping == true:
		return
	assert(MODULE != null)
	assert(shell_thread != null)
	is_paused = false
	if shell_thread.is_alive():
		Log.generic(self, str("Killing child process on thread ", shell_thread.get_id()))
		MODULE.kill()
	if shell_thread.is_active():
		shell_thread.wait_to_finish()
		is_stopping = false

var is_paused = false
func pause():
	if is_paused || !has_started_process_attached():
		return
	is_paused = true
	Log.generic(self, "Pausing process execution...")
	pass #todo
func resume():
	if !is_paused || !has_started_process_attached():
		return
	is_paused = false
	Log.generic(self, "Resuming execution...")
	pass # todo
func step_forward():
	if !is_paused || !has_started_process_attached():
		return
	Log.generic(self, "Stepped 1 line")
	pass # todo
func step_back():
	if !is_paused || !has_started_process_attached():
		return
	Log.generic(self, "Stepped back 1 line")
	pass # todo

func disassemble(bytes : PoolByteArray, address : int):
	var disas = MODULE.disassemble(bytes, 2 if PE.is_PE32_64() else 1, address)
	return disas

var SYNC_MODE = 0
func get_text(line, size):
	assert(MODULE != null)
	var buffer = null
	match SYNC_MODE:
		0:
			buffer = MODULE.get_text(line, size)
		1:
			buffer = MODULE.get_all_text() # this fetches ALL THE TEXT!!
	return buffer
func get_lines_count():
	assert(MODULE != null)
	return MODULE.get_lines_count()

var temp_input_string = ""
func send_string(s : String):
	if shell_thread != null:
		temp_input_string = ""
		if MODULE.send_string(s + "\n"):
			print("success!")
		else:
			print("failure...")
func clear():
	assert(terminal_node != null)
	assert(MODULE != null)
	MODULE.clear()
	terminal_node.text = ""

func _exit_tree():
	# close any open session when shutting down
	stop()
