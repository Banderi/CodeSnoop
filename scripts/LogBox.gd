extends RichTextLabel

# bottom-right log window
var logger_lines = 0
var logger_autoscroll = true
func update():
	bbcode_text = ""
	logger_lines = Log.LOG_EVERYTHING.size()
	for l in Log.LOG_EVERYTHING:
		bbcode_text += l + "\n"
	if logger_autoscroll:
		scroll_to_line(logger_lines - 1)
func clear():
	Log.LOG_EVERYTHING = []
	Log.LOG_ENGINE = []
	Log.LOG_ERRORS = []
	bbcode_text = "Log cleared."
	GDN.clear() # also clear the console terminal...?
