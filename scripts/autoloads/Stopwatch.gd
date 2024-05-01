extends Node

func start():
	return OS.get_ticks_usec()
func stop(time : int, message : String, precision : int = 0):
	match precision:
		0:
			Log.generic(null,message+" (%d milliseconds)"%[OS.get_ticks_msec() - float(time)*0.001])
		1:
			Log.generic(null,message+" (%d microseconds)"%[OS.get_ticks_msec() - time])
