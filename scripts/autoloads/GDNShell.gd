extends Node

const GDNSHELL_RES = preload("res://gdnative.gdns")
var GDNSHELL = null

var shell_thread = null

func send(s):
	if shell_thread != null:
		if GDNSHELL.send_input(null):
#		if GDNSHELL.send_line(str(s)):
			print("success!")
		else:
			print("failure...")
	else:
		print("no shell is running!")

#func async_test(arg):
#	Log.generic(null, arg)

func thread_exec():
	Log.generic(null, "started!")
	GDNSHELL = GDNSHELL_RES.new()
#	connect(GDNSHELL.test_signal, self, "async_test")
	Log.generic(null, GDNSHELL.spawn())

#	while true:
#		var output
#		break

	Log.generic(null, "exiting shell thread...")



func stop():
	if shell_thread != null:
		print("stopping...")
		shell_thread.wait_to_finish()
	shell_thread = null
	GDNSHELL = null

func start():
	stop()

	print("starting...")
	shell_thread = Thread.new()
	shell_thread.start(self, "thread_exec")

func _exit_tree():
	stop()
