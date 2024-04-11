extends Node

var LOG_EVERYTHING = []
var LOG_ENGINE = []
var LOG_ERRORS = []

var LOG_CHANGED = false

const MAX_LINES_IN_CONSOLE = 200
func limit_array(arr, limit = MAX_LINES_IN_CONSOLE):
	if arr.size() > limit:
		arr.pop_front()

func get_enum_string(enums, value):
	var e = value
	var keys = enums.keys()
	while enums[keys[e]] != value && enums[keys[e]] > value:
		e -= 1
	return keys[e]
func get_timestamp(from):
	var d = OS.get_datetime()
	var date = "%04d/%02d/%02d %02d:%02d:%02d" % [d.year, d.month, d.day, d.hour, d.minute, d.second]
	if from == null:
		return date + " -- "
	else:
		return date + str(" -- [", from.APP_NAME, "]: ")
func generic(from, text):
	var msg = str(get_timestamp(from), text)

	var bb_msg = msg
	LOG_EVERYTHING.push_back(bb_msg)
	limit_array(LOG_EVERYTHING)
	if from != null:
		from.LOG.push_back(bb_msg)
		limit_array(from.LOG)
	else:
		LOG_ENGINE.push_back(bb_msg)
		limit_array(LOG_ENGINE)
	print(msg)
	LOG_CHANGED = true
func error(from, err, text, windows_errors = false):
	var msg = str(get_timestamp(from), "ERROR: ", text)
	if err != null:
		if windows_errors:
			msg += str(" (", err, ":", get_enum_string(GlobalScope.WinError, err), ")")
		else:
			msg += str(" (", err, ":", get_enum_string(GlobalScope.Error, err), ")")

	var bb_msg = str("[color=#ee1100]", msg, "[/color]")
	LOG_EVERYTHING.push_back(bb_msg)
	limit_array(LOG_EVERYTHING)
	LOG_ERRORS.push_back(bb_msg)
	limit_array(LOG_ERRORS)
	if from != null:
		from.LOG.push_back(bb_msg)
		limit_array(from.LOG)
	else:
		LOG_ENGINE.push_back(bb_msg)
		limit_array(LOG_ENGINE)
	print(msg)
	push_error(msg)
	LOG_CHANGED = true
