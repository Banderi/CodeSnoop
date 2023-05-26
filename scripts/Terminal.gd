extends RichTextLabel

#var sel_txt = ""
#var sel_len = 0
#var sel_col_from = -1
#var sel_col_to = -1
#var sel_line_from = -1
#var sel_line_to = -1

func _process(delta):
	GDNShell.sync_text()

#	if is_selection_active():
#		sel_txt = get_selection_text()
#		sel_len = sel_txt.length()
#		sel_col_from = get_selection_from_column()
#		sel_col_to = get_selection_to_column()
#		sel_line_from = get_selection_from_line()
#		sel_line_to = get_selection_to_line()
#	else:
#		sel_txt = ""
#		sel_len = 0
#		sel_col_from = -1
#		sel_col_to = -1
#		sel_line_from = -1
#		sel_line_to = -1
#
#	$Label.text = str(
#		terminal_history_len, "/", text.length()," \"", terminal_buffer, "\"\n",
#		sel_len, " \"", sel_txt.replace("\n"," "), "\"\n",
#		sel_line_from, " ", sel_line_to, "\n",
#		sel_col_from, " ", sel_col_to)

var terminal_history_len = 0
var terminal_buffer = ""
var terminal_lastline = 0

#var waiting_for_inputs = false
#func _waiting_for_inputs(): # signal received from the GDNShell module
#	waiting_for_inputs = true
#	caret_blink = true

var HISTORY = []
const MAX_LINES = 100
func _receive_text(txt):
	var trimmed_txt = txt.replace("\r","") # convert CRLF to LF
#	text += trimmed_txt
	text = trimmed_txt
#	insert_text_at_cursor(trimmed_txt)
	terminal_history_len += trimmed_txt.length()
#	scroll_vertical = get_line_count()

#	var lines_overflow = get_line_count() - MAX_LINES

#	if lines_overflow > 0:
#		var temp = text
#		for n in lines_overflow:
#			var newl = temp.find("\n") + 1
#			temp.erase(0, newl)
#		text = temp


func _child_process_started():
	pass
func _child_process_stopped():
	pass

signal input_redirect
func attempt_erase_characters(n):

	pass
func _input(event):
	if has_focus() && event is InputEventKey:

#		if !waiting_for_inputs:
#			get_tree().get_root().set_input_as_handled()
#			emit_signal("input_redirect", event)
#			Input.parse_input_event(event) # do NOT use this, it will throw an infinite loop (obviously).

		# modify backspace behavior so that it doesn't erase previous lines
		if Input.is_key_pressed(KEY_BACKSPACE):

			# force update on the selection quickvars
			_process(0)


#			if sel_len > terminal_buffer.length():
#				select()


#			if is_selection_active():
#				print(2)

#			if text.length() <= terminal_history_len:
#				get_tree().get_root().set_input_as_handled()

		# send command to child process
		if Input.is_key_pressed(KEY_ENTER):
			GDNShell.send_string(terminal_buffer)
			terminal_history_len = text.length() + 1
#			waiting_for_inputs = false
#			caret_blink = false

		# clear terminal
		if Input.is_action_just_pressed("clear_console"):
			text = ""
func _on_Terminal_text_changed():
	terminal_buffer = text.substr(terminal_history_len)

func clear():
	text = ""
	terminal_history_len = 0
	terminal_buffer = ""
	terminal_lastline = 0


func _on_Input_text_entered(new_text):
	GDNShell.send_string(new_text)
	$Input.clear()
