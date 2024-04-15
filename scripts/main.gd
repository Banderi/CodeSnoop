extends Control

# regex & ascii conversion
var bytestream = StreamPeerBuffer.new()
var regex = RegEx.new()
func value_as_ascii(v, escape = false, only_ascii = true):
	if v is Array || v is PoolByteArray:
		bytestream.data_array = v
	else:
		bytestream.data_array = [v]
	var c = bytestream.data_array.get_string_from_ascii()
	if escape:
		return c.c_escape()
	else:
		if only_ascii:
			regex.compile("[ -~]*")
			var r = regex.search(c)
			if r:
				return r.get_string()
			else:
				return ""
		else:
			return c

# settings, configs, caches etc.
const USER_PATH_RECENTFILES = "user://recent_files.var"
func load_user_data():
	recent_file_list = IO.read_as_var(USER_PATH_RECENTFILES)
	if recent_file_list == null:
		recent_file_list = [
			"C:/WINDOWS/system32/notepad.exe" # for testing purposes
		]
		var _r = IO.write(USER_PATH_RECENTFILES, recent_file_list)
	populate_recent()
func save_user_data():
	var _r = IO.write(USER_PATH_RECENTFILES, recent_file_list)
	
# recent files dropdown
var recent_file_list = []
onready var BTN_RECENT = $Top/Buttons/HBoxContainer2/BtnRecent
onready var BTN_RECENT_LIST = $Top/ItemList
onready var BTN_RECENT_SCN = load("res://scenes/BtnRecentFile.tscn")
func clear_recent():
	for node in BTN_RECENT_LIST.get_children():
		node.queue_free()
func populate_recent():
	clear_recent()
	for path in recent_file_list:
		var node = BTN_RECENT_SCN.instance()
		node.text = path
		BTN_RECENT_LIST.add_child(node)
		node.connect("open_file", self, "_on_BtnRecentFile_pressed")
func add_to_recent(path):
	OPEN_DIALOG.current_path = path
	if recent_file_list.find(path) != -1: # already in list!
		if recent_file_list.find(path) == 0: # already on top. no action necessary.
			return
		recent_file_list.erase(path)
	recent_file_list.push_front(path)
	while recent_file_list.size() > 20 && recent_file_list.size() > 0: # maximum n. of recent files in history
		recent_file_list.pop_back()
	populate_recent()
	save_user_data()
func remove_from_recent(path):
	recent_file_list.erase(path)
	populate_recent()
	save_user_data()
func close_recent_dropdown():
	BTN_RECENT.pressed = false
	BTN_RECENT_LIST.hide()
func _on_BtnRecent_toggled(button_pressed):
	BTN_RECENT_LIST.visible = button_pressed
func _on_BtnRecentFile_pressed(path):
	close_recent_dropdown()
	PE_open(path)

# BINARY FILE
onready var OPEN_DIALOG = $OpenDialog
func PE_open(path):
	if !PE.open_file(path):
		remove_from_recent(path)
	else:
		# hex view
		byte_selection = []
		update_hex_scrollbar_size()
		update_hex_view()
		HEXVIEW_SLIDER.value = HEXVIEW_SLIDER.max_value
		
		# asm chunks & disassembler
		fill_ChunkTable()
		update_asm_scrollbar_size()
		update_asm_view()
		
		# move the file path to the most recent spot in file history
		add_to_recent(path)
func _on_OpenDialog_file_selected(path):
	PE_open(path)

# chunks list & chunk data panel
onready var CHUNKS_LIST = $VSplitContainer/Main/Code/Chunks/List
onready var CHUNKS_DATA = $VSplitContainer/Main/Code/Chunks/Data
func fill_ChunkTable():
	CHUNKS_LIST.clear()
	var root = CHUNKS_LIST.create_item()
	root.set_text(0, IO.get_file_name(GDNShell.shell_cmd))
	recursive_fill_ChunkTable(PE.asm_chunks, null, null)
func recursive_is_item_encrypted(item):
	if DataStruct.is_valid(item):
		if "xor" in item:
			return true
	elif item is Dictionary:
		for key in item:
			if !recursive_is_item_encrypted(item[key]):
				return false
		return true
	elif item is Array:
		for child in item:
			if recursive_is_item_encrypted(child):
				return true
	return false
func recursive_fill_ChunkTable(item, parent, itemname):
	# create a new table item and determine its name & name-based params
	var table_item = null
	if itemname != null:
		table_item = CHUNKS_LIST.create_item(parent)
		table_item.collapsed = true
		if itemname.begins_with("unk"):
			itemname = "??"
			table_item.set_custom_color(0, Color(1,1,1,0.3))
		elif itemname.begins_with("unused"):
			table_item.set_custom_color(0, Color(1,0.7,0.7,0.5))
		if itemname == "_SECTIONS":
			table_item.collapsed = false
	
	# determine the object size, recursively going through the childs if necessary
	var total_bytes = 0
	if DataStruct.is_valid(item):
		total_bytes += item.size
	else:
		if item is Dictionary && item.has("value"):
			item = item.value
		if item is Dictionary:
			for k in item:
				if k == "offset" || k == "schema_index" || k == "xor":
					continue
				total_bytes += recursive_fill_ChunkTable(item[k], table_item, str(k))
		elif item is Array:
			for e in item.size():
				total_bytes += recursive_fill_ChunkTable(item[e], table_item, str("[",e,"]"))
	
	# set item name & size
	if itemname != null:
		if (item is Dictionary && ("compressed_size" in item)) || recursive_is_item_encrypted(item):
			table_item.set_text(0, str(itemname," (",total_bytes,") **"))
			table_item.set_custom_color(0, Color(0.8,0.8,0))
		else:
			table_item.set_text(0, str(itemname," (",total_bytes,")"))
	
		if item is Dictionary && item.has("type") && item.type == "addr":
			table_item.set_custom_color(0, Color(0.0,0.4,0.8))
		
	
	# add metadata to the first cell:
	# name text, data obj (reference), total obj size in bytes
	if table_item != null:
		table_item.set_metadata(0, [itemname,item,total_bytes])
	return total_bytes
func _on_ChunkTable_cell_selected():
	var selection = CHUNKS_LIST.get_selected()
	var metadata = selection.get_metadata(0)
	CHUNKS_DATA.clear()
	if metadata == null:
		return
	CHUNKS_DATA.present(metadata[0], metadata[1])
	
	# get the chunk offset in memory
	var offset = null
	var data = metadata[1]
	while true:
		if data is Dictionary:
			offset = data.get("offset", null)
			if offset == null:
				data = data[data.keys()[0]]
			else:
				break
		elif data is Array:
			data = data[0]
		else:
			break
	
	# found a valid offset?
	if offset != null:
		hex_scroll_to(offset, offset + metadata[2])
func _on_ChunkTable_item_activated():
	var selection = CHUNKS_LIST.get_selected()
	selection.collapsed = !selection.collapsed
	var metadata = selection.get_metadata(0)
	var data = metadata[1]
	if data is Dictionary && "type" in data && data.type == "addr":
		hex_scroll_to(data.value, data.value + 4)

##### CODING / MAIN PANELS
var code_height = 0
onready var CODE = $VSplitContainer/Main/Code
func update_code_panel_height():
	# use the hex view slider as an arbitrary reference point for height
	if code_height != CODE.rect_size.y:
		code_height = CODE.rect_size.y
		update_hex_scrollbar_size()
		update_hex_view()
func _on_VSplitContainer_dragged(offset):
	update_code_panel_height()

# hex view panel
onready var HEXVIEW_BYTES = $VSplitContainer/Main/Hex/Top/Bytes
onready var HEXVIEW_ASCII = $VSplitContainer/Main/Hex/Top/Ascii
onready var HEXVIEW_SLIDER = $VSplitContainer/Main/Hex/Top/VSlider
onready var HEXVIEW_ADDRESS = $VSplitContainer/Main/Hex/Top/Offsets
onready var HEXVIEW_INFO = $VSplitContainer/Main/Hex/Info/Control/Txt
onready var HEXVIEW = HEXVIEW_BYTES
var byte_selection = []
var just_scrolled = false
func hex_view_visible_lines():
	return floor(code_height / (16 + HEXVIEW.get("custom_constants/line_spacing"))) - 4
func update_hex_scrollbar_size():
	if PE.file != null:
		# remember the previous relative position/scroll percentage
		var perc = float(HEXVIEW_SLIDER.value) / float(HEXVIEW_SLIDER.max_value)
		HEXVIEW_SLIDER.editable = true
		var file_length = PE.file.get_len()
		if HEXVIEW == HEXVIEW_BYTES:
			var lines_count = ceil(float(file_length) / 8.0)
			var line_start = lines_count - hex_view_visible_lines()
			HEXVIEW_SLIDER.max_value = line_start
		elif HEXVIEW == HEXVIEW_ASCII:
			var lines_count = ceil(float(file_length) / 24.0)
			var line_start = lines_count - hex_view_visible_lines()
			HEXVIEW_SLIDER.max_value = line_start
		HEXVIEW_SLIDER.value = perc * float(HEXVIEW_SLIDER.max_value)
		
		# for some reason, the above... breaks? if the view is all the way at the bottom of the file.
		# soooo...
		HEXVIEW_SLIDER.value += 1
		HEXVIEW_SLIDER.value -= 1
	else:
		HEXVIEW_SLIDER.value = HEXVIEW_SLIDER.max_value
		HEXVIEW_SLIDER.editable = false
func update_hex_view():
	var temp_offsets = ""
	var temp_bytes = ""
	if PE.file != null:
		if HEXVIEW == HEXVIEW_BYTES:
			var byte_start = (HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value) * 8
			var byte_length = min(8 * hex_view_visible_lines(), PE.file.get_len() - byte_start)
			PE.file.seek(byte_start)
			var buffer = PE.file.get_buffer(byte_length)
			var l = 0
			var b = 0
			temp_offsets += "%08X" % [byte_start]
			for byte in buffer:
				temp_bytes += str("%02X " % [byte])
				b += 1
				if b >= 8 && l < hex_view_visible_lines() - 1:
					b = 0
					l += 1
					temp_offsets += "\n%08X" % [byte_start + l * 8 + b]
		elif HEXVIEW == HEXVIEW_ASCII:
			var byte_start = (HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value) * 24
			var byte_length = min(24 * hex_view_visible_lines(), PE.file.get_len() - byte_start)
			PE.file.seek(byte_start)
			var buffer = PE.file.get_buffer(byte_length)
			var l = 0
			var b = 0
			temp_offsets += "%08X" % [byte_start]
			for byte in buffer:
				var c = value_as_ascii(byte)
				if c == "":
					c = "."
				if c == " ":
					c = " " # <-- U+00A0 (no-break space)
				temp_bytes += str(c)
				b += 1
				if b >= 24 && l < hex_view_visible_lines() - 1:
					b = 0
					l += 1
					temp_offsets += "\n%08X" % [byte_start + l * 24 + b]
		
	HEXVIEW.text = temp_bytes
	HEXVIEW_ADDRESS.text = temp_offsets
	update_hex_selection_from_code()
func hex_scroll_to(offset, end_offset):
	
	# convert byte offset to scroll line
	var start_line = 0
	var end_line = 0
	if HEXVIEW == HEXVIEW_BYTES:
		start_line = floor(float(offset) / 8.0)
		end_line = floor(float(end_offset - 1) / 8.0)
	elif HEXVIEW == HEXVIEW_ASCII:
		start_line = floor(float(offset) / 24.0)
		end_line = floor(float(end_offset - 1) / 24.0)
	
	# move the view to the line
	byte_selection = [] # this is to prevent the slider's .value change to accidentally triffer an update!
	var curr_start_line = HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value
	var curr_end_line = curr_start_line + hex_view_visible_lines() - 1
	if start_line < curr_start_line:
		HEXVIEW_SLIDER.value -= (start_line - curr_start_line)
	elif end_line > curr_end_line:
		HEXVIEW_SLIDER.value -= (end_line - curr_end_line)

	# update the highlight!
	byte_selection = [offset, end_offset]
	update_hex_selection_from_code()
func update_hex_selection_from_code():
	var columns_to_highlight = []
	if byte_selection != []:
		if byte_selection.size() == 1:
			byte_selection = [
				byte_selection[0],
				byte_selection[0]+1
			]
		if HEXVIEW == HEXVIEW_BYTES:
			var curr_start_byte = (HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value) * 8 * 3
			var start = byte_selection[0] * 3 - curr_start_byte
			var end = byte_selection[1] * 3 - 1 - curr_start_byte
			columns_to_highlight = [start, end]
		elif HEXVIEW == HEXVIEW_ASCII:
			var curr_start_byte = (HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value) * 24
			var start = byte_selection[0] - curr_start_byte
			var end = byte_selection[1] - curr_start_byte
			columns_to_highlight = [start, end]
	
	if columns_to_highlight != []:
		HEXVIEW.select(0, columns_to_highlight[0], 0, columns_to_highlight[1])
	else:
		HEXVIEW.deselect()
	update_hex_infobox()
func update_hex_infobox():
	HEXVIEW_INFO.text = ""
	if PE.file != null && byte_selection != []:
		# byte offsets
		var start_byte = byte_selection[0]
		var end_byte = start_byte
		if byte_selection.size() == 2 && byte_selection[1] != start_byte + 1:
			end_byte = byte_selection[1] - 1
		
		# offset text
		var size = end_byte - start_byte + 1
		var start_offs_strip = "%08X" % [start_byte]
		var end_offs_strip = "%08X" % [end_byte]
		var temp = end_offs_strip
		for c in temp.length():
			if end_offs_strip[c] == start_offs_strip[c]:
				temp = temp.substr(1)
			else:
				break
		if end_byte != start_byte:
			HEXVIEW_INFO.text = "0x%s-%s (%d)" % [start_offs_strip, temp, size]
		else:
			HEXVIEW_INFO.text = "0x%s (%d)" % [start_offs_strip, size]
		
		# int
		var decimal = "??"
		if size >= 1:
			PE.file.seek(start_byte)
			var d = PE.file.get_8()
			PE.file.seek(start_byte)
			var c = value_as_ascii(PE.file.get_buffer(size))
			decimal = str("int8: ", d, " char: ", c)
		if size >= 2:
			PE.file.seek(start_byte)
			decimal += str("\nint16: ", PE.file.get_16())
		if size >= 4:
			PE.file.seek(start_byte)
			decimal += str(" int32: ", PE.file.get_32())
		HEXVIEW_INFO.text += str("\n", decimal)
func get_byte_offsets_from_selection():
	var curr_start_line = HEXVIEW_SLIDER.max_value - HEXVIEW_SLIDER.value
	if HEXVIEW == HEXVIEW_BYTES:
		var line_byte_offset = curr_start_line * 8
		if !HEXVIEW.is_selection_active():
			var clicked_byte = (HEXVIEW.cursor_get_column() / 3)
			var sel_column = clicked_byte * 3
			HEXVIEW.select(0, sel_column, 0, sel_column + 2)
			return [
				clicked_byte + line_byte_offset
			]
		else:
			return [
				HEXVIEW.get_selection_from_column() / 3 + line_byte_offset,
				HEXVIEW.get_selection_to_column() / 3 + 1 + line_byte_offset,
			]
	elif HEXVIEW == HEXVIEW_ASCII:
		var line_byte_offset = curr_start_line * 24
		if !HEXVIEW.is_selection_active():
			var clicked_byte = (HEXVIEW.cursor_get_column())
			var sel_column = clicked_byte
			HEXVIEW.select(0, sel_column, 0, sel_column)
			return [
				clicked_byte + line_byte_offset
			]
		else:
			return [
				HEXVIEW.get_selection_from_column() + line_byte_offset,
				HEXVIEW.get_selection_to_column() + line_byte_offset,
			]
func _on_Bytes_gui_input(_event):
	# no need to change the highlights from the code here.
	# the highlights HAVE ALREADY changed from user input, hence why this signal!
	if Input.is_action_just_pressed("LMB"):
		HEXVIEW.deselect()
		byte_selection = []
	if Input.is_action_pressed("LMB") || Input.is_action_just_released("LMB"):
		if PE.file == null:
			byte_selection = []
		else:
			byte_selection = get_byte_offsets_from_selection()
			update_hex_infobox()
			if Input.is_action_just_released("LMB"):
				update_hex_selection_from_code()
func _on_Bytes_cursor_changed():
	if !just_scrolled:
		byte_selection = get_byte_offsets_from_selection()
		update_hex_infobox()
	else:
		just_scrolled = false
func _on_VScrollBarHexView_scrolling():
	just_scrolled = true
	update_hex_view()
func _on_AsciiMode_toggled(button_pressed):
	HEXVIEW.hide()
	if button_pressed:
		HEXVIEW = HEXVIEW_ASCII
	else:
		HEXVIEW = HEXVIEW_BYTES
	HEXVIEW.show()
	update_hex_view()
	update_hex_scrollbar_size()

# asm / disassembler
onready var ASM = $VSplitContainer/Main/Code/Asm
onready var ASM_SLIDER = $VSplitContainer/Main/Code/Asm/VSlider
func update_asm_scrollbar_size():
	if PE.file != null:
		pass
	else:
		ASM_SLIDER.max_value = 0
func update_asm_view():
	ASM.clear()
	ASM.create_item()
	if PE.file != null:
		var tree_item = ASM.create_item()
		tree_item.set_text(0,"asda")
func _on_VSlider_asm_scrolled():
	update_asm_view()

############

# bottom-right log window
var logger_lines = 0
var logger_autoscroll = true
onready var LOG_BOX = $VSplitContainer/Footer/LogPrinter/Text
func log_do_scroll():
	if Log.LOG_CHANGED:
		LOG_BOX.bbcode_text = ""
		logger_lines = Log.LOG_EVERYTHING.size()
		for l in Log.LOG_EVERYTHING:
			LOG_BOX.bbcode_text += l + "\n"
		if logger_autoscroll:
			LOG_BOX.scroll_to_line(logger_lines - 1)
		Log.LOG_CHANGED = false
func clear_log():
	Log.LOG_EVERYTHING = []
	Log.LOG_ENGINE = []
	Log.LOG_ERRORS = []
	LOG_BOX.bbcode_text = "Log cleared."
	GDNShell.clear() # also clear the console terminal...?

# Called when the node enters the scene tree for the first time.
func _ready():
	var _r
	_r = load_user_data()
	_r = get_viewport().connect("gui_focus_changed", self, "_on_focus_change_intercept")
	_r = get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	Log.generic(null, "Initializing...")
	GDNShell.root_node = self
	GDNShell.terminal_node = CONSOLE_TERMINAL
	GDNShell.GDN_INIT()
	LOG_BOX.bbcode_text = ""
	GDNShell.clear()
	_on_BtnClose_pressed()
	PE.load_prodid_enums()
	update_code_panel_height()

# Called every frame. 'delta' is the elapsed time since the previous frame.
onready var CONSOLE_TERMINAL = $VSplitContainer/Footer/Console/Terminal
onready var FPS = $Top/FPS
onready var BTN_OPEN = $Top/Buttons/HBoxContainer2/BtnOpen
onready var BTN_CLOSE = $Top/Buttons/HBoxContainer2/BtnClose
onready var BTN_SAVE = $Top/Buttons/HBoxContainer2/BtnSave
onready var BTN_RUN = $Top/Buttons/HBoxContainer3/BtnRun
onready var BTN_STOP = $Top/Buttons/HBoxContainer3/BtnStop
onready var BTN_PAUSE = $Top/Buttons/HBoxContainer/BtnBreak
onready var BTN_STEP_BACK = $Top/Buttons/HBoxContainer/BtnBack
onready var BTN_STEP_FORWARD = $Top/Buttons/HBoxContainer/BtnStep
onready var BTN_VISIBLE_PROGRAM = $Top/Buttons/Control/BtnVisibleProgram
func _process(_delta):
	log_do_scroll()
	FPS.text = str(Engine.get_frames_per_second(), " FPS")
	
	# has file open?
	if PE.file != null:
		BTN_CLOSE.disabled = false
		BTN_RUN.disabled = false
	else:
		BTN_CLOSE.disabled = true
		BTN_RUN.disabled = true
		BTN_STOP.disabled = true
	
	# has an active child process running?
	if GDNShell.has_started_process_attached():
		BTN_VISIBLE_PROGRAM.disabled = true
		BTN_STOP.disabled = false
		BTN_PAUSE.disabled = false
		BTN_STEP_BACK.disabled = false
		BTN_STEP_FORWARD.disabled = false
		if GDNShell.is_paused: # paused / debugging
			CONSOLE_TERMINAL.readonly = true
			BTN_STEP_BACK.disabled = false
			BTN_STEP_FORWARD.disabled = false
		else: # running!
			CONSOLE_TERMINAL.readonly = false
			BTN_STEP_BACK.disabled = true
			BTN_STEP_FORWARD.disabled = true
	else: # no process / stopped
		BTN_VISIBLE_PROGRAM.disabled = false
		BTN_STOP.disabled = true
		CONSOLE_TERMINAL.readonly = true
		BTN_PAUSE.disabled = true
		BTN_STEP_BACK.disabled = true
		BTN_STEP_FORWARD.disabled = true
	
	# button text when paused
	if GDNShell.is_paused:
		BTN_PAUSE.text = "Resume"
	else:
		BTN_PAUSE.text = "Break"

func _input(_event):
	if Input.is_action_just_pressed("debug_start"):
		GDNShell.start()
	if Input.is_action_just_pressed("debug_stop"):
		GDNShell.stop()
	if Input.is_action_just_pressed("clear_console"):
		clear_log()
	if Input.is_action_just_pressed("ui_cancel"):
		if OPEN_DIALOG.visible:
			OPEN_DIALOG.hide()

func _on_focus_change_intercept(node):
	if node != BTN_RECENT && node.get_parent() != BTN_RECENT_LIST:
		close_recent_dropdown()

func _on_viewport_size_changed():
	update_code_panel_height()

func _on_BtnOpen_pressed():
	OPEN_DIALOG.popup_centered()
func _on_BtnSave_pressed():
	pass # Replace with function body.
func _on_BtnClose_pressed():
	PE.close_file()
	update_hex_scrollbar_size()
	update_hex_view()
	CHUNKS_LIST.clear()
	CHUNKS_DATA.clear()

func _on_BtnRun_pressed():
	GDNShell.start()
func _on_BtnStop_pressed():
	GDNShell.stop()

func _on_BtnBreak_pressed():
	if GDNShell.is_paused:
		GDNShell.resume()
	else:
		GDNShell.pause()
func _on_BtnBack_pressed():
	GDNShell.step_back()
func _on_BtnStep_pressed():
	GDNShell.step_forward()

func _on_BtnClearLog_pressed():
	clear_log()

func _on_BtnVisibleProgram_toggled(button_pressed):
	GDNShell.hidden_process_window = !button_pressed







