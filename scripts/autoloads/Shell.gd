extends Node

## --- Code for asynchronous shell commands by FeralBytes on github.com ---
## https://github.com/godotengine/godot/issues/18919#issuecomment-416114718

var thread_for_execute = null
var queue_for_execute = []

######## Begin # OS.execute() Threaded ########
func _requires_previous_to_complete(task):
	if task.semaphore.has("requires"):
		for t in queue_for_execute:
			if t.semaphore.name == task.semaphore.requires:
				return true
	return false
func run_sync(cmd, node : Node, printcmd = true, printout = false):
	if printcmd:
		Log.generic(node, 'sh# ' + cmd)#, Color(0.5,1,1,0.5))
	else:
		print('sh# \"', cmd, '\"')
	cmd = cmd.split(" ")
	var bin = cmd[0]
	cmd.remove(0)

	# invoke OS function & get results back!
	var output = []

	var _r = OS.execute(bin, cmd, true, output)
	if printout && output.size() > 0 && output[0].length() > 0:
		var txt = str(output[0]).substr(0,str(output[0]).length() - 1)
		for line in txt.split("\n"):
			Log.generic(node, "    " + line)
	return output
func run(cmd, node : Node, callback : FuncRef, printcmd = true, printout = false, semaphore = {}):
	if thread_for_execute == null:
		thread_for_execute = Thread.new()
	var state = 'waiting'
	var task = {
		"cmd":cmd,
		"node":node,
		"callback":callback,
		"state":state,
		"semaphore":semaphore,
		"printcmd":printcmd,
		"printout":printout
	}
	queue_for_execute.append(task)
	if queue_for_execute.size() == 1:
		# Only item in the list so start the task.
		call_deferred('_deferred_execute_stack_top')

func _deferred_execute_stack_top():
	queue_for_execute[0].state = 'executing'
	thread_for_execute.start(self, '_threaded_execute', queue_for_execute[0])

func _threaded_execute(args):
	if args.printcmd:
		Log.generic(args.node, 'sh# ' + args.cmd + '')#, Color(0.5,1,1,0.5))
	else:
		print('sh# \"', args.cmd, '\"')
	if args.cmd == "": # Empty command!!
		call_deferred('_clean_up_execute_thread')
		return args

	# get properly formatted shell command
	var cmd = args.cmd.split(" ")
	var bin = cmd[0]
	cmd.remove(0)

	# invoke OS function & get results back!
	var output = []
	var _r = OS.execute(bin, cmd, true, output)
	args["output"] = output
	if args.printout && output.size() > 0 && output[0].length() > 0:
		var txt = str(output[0]).substr(0,str(output[0]).length() - 1)
		for line in txt.split("\n"):
			Log.generic(args.node, "    " + line)
	call_deferred('_clean_up_execute_thread')
	return args

func _clean_up_execute_thread():
	var args = thread_for_execute.wait_to_finish()
	args.callback.call_funcv(args.output if args.has("output") else [])
#	args.node.call(args.callback, args.output[0] if (args.has("output") && args.output.size() > 0) else null)
#	var callable_func = funcref(args.node, args.callback)
#	callable_func.call_func(args.output[0] if (args.has("output") && args.output.size() > 0) else null)
	queue_for_execute.pop_front()
	if queue_for_execute.size() > 0:
		# Start the next task.
		call_deferred('_deferred_execute_stack_top')
	elif queue_for_execute.size() == 0:
		thread_for_execute = null
######## End # OS.execute() Threaded ########
