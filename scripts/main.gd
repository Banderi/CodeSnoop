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
func bin_string(bytes : PoolByteArray):
	var ret_str = ""
	for b in bytes:
		var n = int(b)
		for _i in range(0,8):
			ret_str = String(n&1) + ret_str
			n = n>>1
	return ret_str

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
func close_and_clear_all():
	PE.close_file()
	update_hex_scrollbar_size()
	update_hex_view()
	update_asm_scrollbar_size()
	update_asm_view()
	CHUNKS_LIST.clear()
	CHUNKS_DATA.clear()
	EXPORTS_TABLE.clear()
	IMPORTS_TABLE.clear()
	FUNCS_TABLE.clear()
	COFF_SYMBOLS_TABLE.clear() # TODO
	LABELS_TABLE.clear() # TODO
	selected_asm_address = null
	focused_function_rva = null
func PE_open(path):
	close_and_clear_all()
	var CLOCK = Stopwatch.start()
	if !PE.open_file(path):
		remove_from_recent(path)
	else:
		Stopwatch.stop(CLOCK, "Read PE file chunks!")
		
		PE.analyze_file()
		
		# hex view
		byte_selection = []
		update_hex_scrollbar_size()
		update_hex_view()
		HEXVIEW_SLIDER.value = HEXVIEW_SLIDER.max_value
		
		# asm chunks, disassembler, imports/exports, info panels etc
		fill_ChunkTable()
		fill_ImportExportEtcTables()
		update_asm_scrollbar_size()
		update_asm_view()
		update_info_extra_panels()
		
		# move the file path to the most recent spot in file history
		add_to_recent(path)
		
		# go to entry point
		go_to_function(PE.get_image_entrypoint_rva())
func _on_OpenDialog_file_selected(path):
	PE_open(path)

# chunks list & chunk data panel
onready var CHUNKS_LIST = $VSplitContainer/Main/Middle/Chunks/List
onready var CHUNKS_DATA = $VSplitContainer/Main/Middle/Chunks/Data
func fill_ChunkTable():
	CHUNKS_LIST.clear()
	var root = CHUNKS_LIST.create_item()
	root.set_text(0, IO.get_file_name(GDN.shell_cmd))
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
		if itemname.begins_with("unk") || itemname.begins_with("unmapped"):
			itemname = "??"
			table_item.set_custom_color(0, Color(1,1,1,0.3))
		elif itemname.begins_with("unused"):
			table_item.set_custom_color(0, Color(1,0.7,0.7,0.5))
	
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
			var array_size = item.size()
			if array_size > 1000:
				total_bytes = array_size * recursive_fill_ChunkTable(item[0], table_item, str("[...]"))
			else:
				for e in array_size:
					total_bytes += recursive_fill_ChunkTable(item[e], table_item, str("[",e,"]"))
	
	# set item name & size
	if itemname != null:
		if (item is Dictionary && ("compressed_size" in item)) || recursive_is_item_encrypted(item):
			table_item.set_text(0, str(itemname," (",total_bytes,") **"))
			table_item.set_custom_color(0, Color(0.8,0.8,0))
		else:
			table_item.set_text(0, str(itemname," (",total_bytes,")"))
	
		if DataStruct.is_valid(item):
			match item.type:
				"addr":
					table_item.set_custom_color(0, Color(0.0,0.4,0.8))
				"rva":
					table_item.set_custom_color(0, Color(0.2,0.6,0.7))
		
	
	# add metadata to the first cell:
	# name text, data obj (reference), total obj size in bytes
	if table_item != null:
		table_item.set_metadata(0, [itemname,item,total_bytes])
	
	# uncollapse _SECTIONS chunks in the table by default
	if itemname == "_SECTIONS":
		table_item.collapsed = false
		var child = table_item.get_children()
		while child != null:
#			child.collapsed = false
			child.set_custom_color(0, Color(0.9,0.8,0.7,0.5))
			child = child.get_next()
	
	return total_bytes
func _on_ChunkTable_cell_selected():
	if Input.is_action_pressed("ctrl"):
		return _on_ChunkTable_item_activated()
	var selection = CHUNKS_LIST.get_selected()
	var metadata = selection.get_metadata(0)
	CHUNKS_DATA.clear()
	if metadata == null:
		return
	if metadata[2] == 0:
		return
	
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
	
	# present inner chunk data in the detailed list table
	CHUNKS_DATA.present(metadata[0], metadata[1])
func _on_ChunkTable_item_activated():
	var selection = CHUNKS_LIST.get_selected()
	selection.collapsed = !selection.collapsed
	var metadata = selection.get_metadata(0)
	var data = metadata[1]
	if DataStruct.is_valid(data):
		match data.type:
			"addr":
				hex_scroll_to(data.value, data.value + 4)
			"rva":
				var file_offset = PE.RVA_to_file_offset(data.value)
				if file_offset != null:
					hex_scroll_to(file_offset, file_offset + 4)

# imports / exports / data directories / etc. tables
onready var IMPORTS_TABLE = $VSplitContainer/Main/TabContainer/Externals/Imports
onready var EXPORTS_TABLE = $VSplitContainer/Main/TabContainer/Externals/Exports
onready var BUTTON_IAT_MODE = $VSplitContainer/Main/TabContainer/Externals/Imports/IATMode
onready var FUNCS_TABLE = $VSplitContainer/Main/TabContainer/Functions/Functions
onready var LABELS_TABLE = $VSplitContainer/Main/TabContainer/Symbols/Labels
onready var COFF_SYMBOLS_TABLE = $VSplitContainer/Main/TabContainer/Symbols/COFF
onready var INFO_PANEL = $VSplitContainer/Main/TabContainer/Info
func fill_ImportExportEtcTables():
	# imports
	IMPORTS_TABLE.clear()
	IMPORTS_TABLE.create_item()
	if PE.IMPORT_TABLES.IMPORT.offset != -1 && PE.IMPORT_TABLES.IMPORT.raw_chunks.size() != 0:
		var dll_names_tree_items = {}
		for dll_name in PE.IMPORT_TABLES.IMPORT.raw_chunks:
			if dll_name == "__empty_end": # the last one is empty.
				continue
			var parent_item = null
			if !dll_names_tree_items.has(dll_name):
				parent_item = IMPORTS_TABLE.create_item()
				parent_item.collapsed = true
				dll_names_tree_items[dll_name] = parent_item
			else:
				parent_item = dll_names_tree_items[dll_name]
			
			var num_imports_in_parent = 0
			var table_name = "IAT" if BUTTON_IAT_MODE.pressed else "ILT"
			for thunk_fn_name in PE.IMPORT_TABLES.ILT.formatted[dll_name]:
				var formatted = PE.get_import_thunk(table_name, dll_name, thunk_fn_name, true)
				var item = IMPORTS_TABLE.create_item(parent_item)
				for key in formatted:
					var subitem = IMPORTS_TABLE.create_item(item)
					subitem.set_text(0, "%s: %s" % [key, formatted[key]])
				item.collapsed = true
				IMPORTS_TABLE.set_column_min_width(0, 4)
				if formatted.is_ordinal:
					item.set_custom_color(0, Color(0.8,0.8,0))
					item.set_text(0, str(formatted.ordinal))
				else:
					item.set_text(0, str(formatted.fn_name))
				num_imports_in_parent += 1
			
			parent_item.set_text(0,"%s (%d)" % [dll_name, num_imports_in_parent])
	
	# exports
	EXPORTS_TABLE.clear()
	EXPORTS_TABLE.create_item()
	if PE.EXPORT_TABLES.EXPORT.offset != -1 && PE.EXPORT_TABLES.EXPORT.raw_chunks.size() != 0:
		var parent_item = EXPORTS_TABLE.create_item()
#		parent_item.collapsed = true
		var num_exports_in_parent = 0
		for export_name in PE.EXPORT_TABLES.NPT.raw_chunks:
			var item = EXPORTS_TABLE.create_item(parent_item)
			item.set_text(0, str(export_name))
			num_exports_in_parent += 1
		var name_rva = PE.EXPORT_TABLES.EXPORT.raw_chunks.NameRVA.value
		var dll_name = PE.file.get_null_terminated_string(PE.RVA_to_file_offset(name_rva))
		parent_item.set_text(0,"%s (%d)" % [dll_name, num_exports_in_parent])
	
	# functions
	FUNCS_TABLE.clear()
	FUNCS_TABLE.create_item()
	for section_name in PE.ANALYSIS.fn_rvas_by_section:
		var section_item = FUNCS_TABLE.create_item()
		section_item.set_text(0, section_name)
		for fn_rva in PE.ANALYSIS.fn_rvas_by_section[section_name]:
			recursive_add_fn_tree_item(fn_rva, section_item, 0)
func recursive_add_fn_tree_item(fn_rva, parent, level):
	if !(fn_rva in PE.ANALYSIS.functions):
		return
	var func_info = PE.ANALYSIS.functions[fn_rva]
	var is_thunk = "is_thunk" in func_info
	if is_thunk && level == 0:
		return
	var tree_item = FUNCS_TABLE.create_item(parent)
	if is_thunk:
		if "symbol" in func_info.calls[0]:
			tree_item.set_text(0, func_info.calls[0].symbol)
			tree_item.set_custom_color(0, Color(0.8,0.8,0))
		else:
			tree_item.set_text(0, "THUNK_%08X"%[fn_rva])
	elif fn_rva == PE.get_image_entrypoint_rva():
		tree_item.set_text(0, "EntryPoint")
		tree_item.set_custom_color(0, Color(0.8,1,0.8))
	else:
		tree_item.set_text(0, "FUN_%08X"%[fn_rva])
	
	tree_item.set_metadata(0, fn_rva)
	tree_item.collapsed = true
	
	# child function calls
	if !is_thunk && "calls" in func_info && level < 1:
		for call_params in func_info.calls:
			var call_item = recursive_add_fn_tree_item(call_params.jump_to, tree_item, level + 1)
			if call_item != null:
				call_item.set_metadata(0, call_params)
			else:
				call_item = FUNCS_TABLE.create_item(tree_item)
				call_item.set_metadata(0, call_params)
				if call_params.jump_to == -1:
					call_item.set_text(0, "dynamic call")
					call_item.set_custom_color(0, Color(0.4,0.4,0.4))
				elif call_params.jump_to == -2:
					call_item.set_text(0, "todo...")
					call_item.set_custom_color(0, Color(0.4,0.4,0.4))
				elif call_params.jump_to == -3:
					call_item.set_text(0, "const dereferenced call")
					call_item.set_custom_color(0, Color(0.4,0.4,0.4))
				elif "symbol" in call_params:
					call_item.set_text(0, call_params.symbol)
					call_item.set_custom_color(0, Color(0.8,0.8,0))
				else:
					call_item.set_text(0, "??")
					call_item.set_custom_color(0, Color(0.8,0.8,0))
			
	return tree_item
func update_info_extra_panels():
	INFO_PANEL.text = ""
	if PE.file != null:
		INFO_PANEL.text += "Target platform: %s\n" % [
			Log.get_enum_string(PE.MACHINE_TYPES, PE.asm_chunks._IMAGE_NT_HEADERS.FileHeader.Machine.value)
		]
		INFO_PANEL.text += "Format: %s (%s)\n" % [
			DataStruct.as_text(PE.asm_chunks._IMAGE_NT_HEADERS.Signature),
			DataStruct.as_text(PE.asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.Magic),
		]
func _on_IATMode_toggled(_button_pressed):
	fill_ImportExportEtcTables()
func _on_Functions_cell_selected():
	focused_function_rva = null
	var selection = FUNCS_TABLE.get_selected()
	var parent = selection.get_parent()
	
	var metadata = selection.get_metadata(0)
	if metadata is Dictionary:
		var parent_rva = parent.get_metadata(0)
		if parent_rva in PE.ANALYSIS.functions:
			go_to_function(parent_rva, metadata.address)
	elif metadata is int:
		go_to_function(metadata)
func _on_Functions_item_activated():
	var selection = FUNCS_TABLE.get_selected()
	selection.collapsed = !selection.collapsed 
	var parent = selection.get_parent()
	var metadata = selection.get_metadata(0)
	if metadata is Dictionary:
		if !("symbol" in metadata) && metadata.jump_to > 0:
			go_to_function(metadata.jump_to)

##### CODING / MAIN PANELS
var middle_height = 0
onready var MIDDLE = $VSplitContainer/Main/Middle
func update_middle_panel_height():
	# use the hex view slider as an arbitrary reference point for height
	if middle_height != MIDDLE.rect_size.y:
		middle_height = MIDDLE.rect_size.y
		update_hex_scrollbar_size()
		update_asm_scrollbar_size()
	update_hex_view()
	update_asm_view()
func _on_VSplitContainer_dragged(_offset):
	update_middle_panel_height()

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
	return floor(middle_height / (16 + HEXVIEW.get("custom_constants/line_spacing"))) - 4
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
			if byte_length > 0:
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
			if byte_length > 0:
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
	BTN_CHANGE_ADDR.hide()
	if PE.file != null && byte_selection != []:
		BTN_CHANGE_ADDR.show()
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
	# BUG: in the ASCII view panel, you can not drag-select the last character of any line.
	# this is due to the text wrapping which in Godot prevents the cursor from registering
	# past the last character - it requires the \n character to be present at the end of a line.
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
onready var ASM = $VSplitContainer/Main/Middle/Code/ASM/Disassembler
onready var ASM_SLIDER = $VSplitContainer/Main/Middle/Code/ASM/VSlider
var selected_asm_address = null
var focused_function_rva = null
func asm_panel_visible_lines():
	return floor((ASM.rect_size.y) / (14 + ASM.get("custom_constants/vseparation")) - 4)
func update_asm_scrollbar_size():
	if PE.file != null && focused_function_rva != null:
		# remember the previous relative position/scroll percentage
		var perc = 0
		if ASM_SLIDER.min_value != 0:
			perc = float(ASM_SLIDER.value) / float(ASM_SLIDER.min_value)
		ASM_SLIDER.editable = true
		var func_info = PE.ANALYSIS.functions[focused_function_rva]
		var lines_count = func_info.icount # this assumes the .size is VALID!
		ASM_SLIDER.min_value = min(0, -lines_count + asm_panel_visible_lines())
		ASM_SLIDER.value = perc * float(ASM_SLIDER.min_value)
	else:
		ASM_SLIDER.value = 0
		ASM_SLIDER.editable = false
func update_asm_view():
	
	# reset table
	ASM.clear()
	ASM.create_item()
	ASM.set_column_min_width(0,12) # address
	ASM.set_column_min_width(1,25) # hex bytes
	ASM.set_column_min_width(2,25) # labels / symbols
	ASM.set_column_min_width(3,80) # opcode (mnemonics) + operands

	if PE.file != null && focused_function_rva != null:
		var num_lines = asm_panel_visible_lines()
		var slider_scroll = -ASM_SLIDER.value
		
		# for now, just display the first (entry point) function
		var start_offset = PE.RVA_to_file_offset(focused_function_rva)
		if start_offset == null:
			return
		
		PE.file.seek(start_offset)
		var buf = PE.file.get_buffer(PE.ANALYSIS.functions[focused_function_rva].size) # this assumes the .size is VALID!
		var disas = GDN.disassemble(buf, focused_function_rva)
		
		for line in num_lines:
			var i = line + slider_scroll
			if i < 0 || i > disas.size() - 1:
				continue # cut off at last disassembled/visible line reached

			var tree_item = ASM.create_item()
			
			var asm_instr = disas[i]
			var address = asm_instr.offset
			
			# raw hex bytes
			var hex_bytes = ""
			for b in range(0, asm_instr.hex.length(), 2):
				hex_bytes += asm_instr.hex.substr(b, 2).to_upper() + " "
			
			
			tree_item.set_metadata(0, [PE.RVA_to_file_offset(address), PE.RVA_to_file_offset(address) + asm_instr.size, asm_instr.size, address])
			tree_item.set_metadata(1, hex_bytes)
#			tree_item.set_metadata(1, symbols)
			tree_item.set_metadata(3, [asm_instr.mnemonic, asm_instr.operands])
			if selected_asm_address != null && address == selected_asm_address:
				tree_item.select(0)
			
			match ASM.get_column_title(0):
				"VA":
					tree_item.set_text(0, "%08X" % [PE.get_image_base() + address])
				"RVA":
					tree_item.set_text(0, "%08X" % [address])
				"Raw":
					tree_item.set_text(0, "%08X" % [PE.RVA_to_file_offset(address)])
			
			tree_item.set_custom_color(0, Color(1,1,1,0.3))
			tree_item.set_text_align(0, TreeItem.ALIGN_RIGHT)
			tree_item.set_cell_mode(1,TreeItem.CELL_MODE_CUSTOM)
			tree_item.set_custom_draw(1, self, "_custom_asm_bytes_draw")
			tree_item.set_text_align(2, TreeItem.ALIGN_RIGHT)
			tree_item.set_cell_mode(3,TreeItem.CELL_MODE_CUSTOM)
			tree_item.set_custom_draw(3, self, "_custom_asm_opcodes_draw")
func asm_scroll_to_address(address):
	update_asm_view()
func _on_VSlider_asm_scrolled():
	update_asm_view()
func _on_Disassembler_column_title_pressed(column):
	if column == 0:
		var next = {
			"VA": "RVA",
			"RVA": "Raw",
			"Raw": "VA",
		}
		ASM.set_column_title(0, next[ASM.get_column_title(0)])
	update_asm_view()
func _on_Disassembler_item_selected():
	if Input.is_action_pressed("ctrl"):
		return call_deferred("_on_Disassembler_item_activated")
	var selection = ASM.get_selected()
	var metadata = selection.get_metadata(0)
	if metadata == null:
		return
	hex_scroll_to(metadata[0], metadata[1])
	selected_asm_address = selection.get_metadata(0)[3]
func _on_Disassembler_item_activated():
	var selection = ASM.get_selected()
	var metadata = selection.get_metadata(3)
	var address = selection.get_metadata(0)
	var mnemonics = metadata[0]
	var operands = metadata[1]
	match mnemonics:
		"CALL":
			if operands.begins_with("0x"):
				go_to_function(operands.hex_to_int())
		"JMP":
			var s = operands.split(" ")
			s = s[s.size()-1]
			s = s.lstrip("[").rstrip("]").split("+")
			var rva = 0
			for l in s:
				if "0x" in l:
					rva += l.hex_to_int()
				elif l == "RIP" || l == "EIP":
					rva += address[3] + address[2]
			go_to_function(rva)
func go_to_function(rva, address = null):
	if rva in PE.ANALYSIS.functions:
		var func_info = PE.ANALYSIS.functions[rva]
		focused_function_rva = rva
		selected_asm_address = address
		update_asm_scrollbar_size()
		if address != null:
			asm_scroll_to_address(address)
		else:
			ASM_SLIDER.value = 0
			update_asm_view()
		if address == null:
			var file_offset = PE.RVA_to_file_offset(rva)
			hex_scroll_to(file_offset, file_offset + func_info.size)
		
		if address == null:
			var sel_rva = -1
			if FUNCS_TABLE.get_selected() != null:
				var sel_metadata = FUNCS_TABLE.get_selected().get_metadata(0)
				if sel_metadata is int:
					sel_rva = sel_metadata
			if sel_rva != rva:
				var root = FUNCS_TABLE.get_root()
				var section = root.get_children()
				var fn_tree_item = section.get_children()
				while fn_tree_item != null:
					var text = fn_tree_item.get_text(0)
					var metadata = fn_tree_item.get_metadata(0)
					if metadata is int && metadata == rva:
						fn_tree_item.select(0)
						FUNCS_TABLE.scroll_to_item(fn_tree_item)
						break
					
					fn_tree_item = fn_tree_item.get_next()
					if fn_tree_item == null:
						section = section.get_next()
						if section == null:
							break
						else:
							fn_tree_item = section.get_children()
		
		return true
	else:
		return false
	
# text drawing related stuff
onready var mono_font : Font = load("res://fonts/basis33.tres")
func draw_multicolored_string(parent : Control, text_array : Array, colors_array : Array, position : Vector2):
	var spacing = 0
	for i in text_array.size():
		var color = Color(1,1,1)
		if i < colors_array.size():
			color = colors_array[i]
		var text = text_array[i]
		parent.draw_string(mono_font, position + Vector2(spacing, 0), text, color)
		spacing += mono_font.get_string_size(text).x
func _custom_asm_bytes_draw(tree_item : TreeItem, rect : Rect2):
	var bytes = tree_item.get_metadata(1)
	bytes = bytes.strip_edges()
	while mono_font.get_string_size(bytes).x > rect.size.x:
		bytes = bytes.substr(0, bytes.length() - 4) + "..."
		if bytes == "...":
			break
	ASM.draw_string(mono_font, rect.position + Vector2(0, 9), bytes, Color(1,1,1,0.6))
func _custom_asm_opcodes_draw(tree_item : TreeItem, rect : Rect2):
	var metadata = tree_item.get_metadata(3)
	tree_item.set_tooltip(3, str(metadata[0], " ", metadata[1]))
	
	var mn_color = Color(1,1,1,0.6)
	match metadata[0]:
		"RET":
			mn_color = Color(1,1,0,0.8)
		"CALL":
			mn_color = Color(0.3,1,1,0.8)
		"NOP":
			mn_color = Color(1,1,1,0.3)
	
	if metadata[1] == "":
		ASM.draw_string(mono_font, rect.position + Vector2(0, 9), metadata[0], mn_color)
	else:
		var final_array_text = [metadata[0] + " "]
		var final_array_colors = [mn_color]
		
		var ops_split = metadata[1].split(", ")
		for o in ops_split.size():
			var op = ops_split[o]
			final_array_text.push_back(op)
			
			if "[" in op:
				final_array_colors.push_back(Color(0.3,1,1,0.5))
			elif "x" in op:
				final_array_colors.push_back(Color(0.8,1,0.5,0.5))
			else:
				final_array_colors.push_back(Color(1,1,1,0.3))
#			final_array_colors.push_back(Color(1,0.8,0.5,0.5))
			
			# add back comma
			if o < ops_split.size() - 1:
				final_array_text.push_back(", ")
				final_array_colors.push_back(Color(1,1,1,0.3))
			
		draw_multicolored_string(ASM, final_array_text, final_array_colors, rect.position + Vector2(0, 9))

############

# bottom-right log window
onready var LOG_BOX = $VSplitContainer/Footer/LogPrinter/Text

# Called when the node enters the scene tree for the first time.
func _ready():
	var _r = Log.connect("log_changed", LOG_BOX, "update")
	_r = load_user_data()
	_r = get_viewport().connect("gui_focus_changed", self, "_on_focus_change_intercept")
	_r = get_tree().root.connect("size_changed", self, "_on_viewport_size_changed")
	Log.generic(null, "Initializing...")
	GDN.root_node = self
	GDN.terminal_node = CONSOLE_TERMINAL
	GDN.GDN_INIT()
	LOG_BOX.bbcode_text = ""
	GDN.clear()
	_on_BtnClose_pressed()
	PE.load_prodid_enums()
	update_middle_panel_height()
	
	# syntax highlighting
	HEXVIEW_BYTES.clear_colors()
	HEXVIEW_BYTES.add_keyword_color("00", Color(1,1,1,0.20)) #"767676" #81ff9200
	
	# table columns
	ASM.set_column_title(0, "VA")
	ASM.set_column_title(1, "Bytes")
	ASM.set_column_title(2, "Symbols")
	ASM.set_column_title(3, "Opcodes")
	IMPORTS_TABLE.set_column_title(0, "Imports")
	EXPORTS_TABLE.set_column_title(0, "Exports")
	

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
onready var BTN_CHANGE_ADDR = $VSplitContainer/Main/Hex/Info/Control/Txt/BtnAddr
func _process(_delta):
#	log_do_scroll()
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
	if GDN.has_started_process_attached():
		BTN_VISIBLE_PROGRAM.disabled = true
		BTN_STOP.disabled = false
		BTN_PAUSE.disabled = false
		BTN_STEP_BACK.disabled = false
		BTN_STEP_FORWARD.disabled = false
		if GDN.is_paused: # paused / debugging
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
	if GDN.is_paused:
		BTN_PAUSE.text = "Resume"
	else:
		BTN_PAUSE.text = "Break"

func _input(_event):
	if Input.is_action_just_pressed("debug_start"):
		GDN.start()
	if Input.is_action_just_pressed("debug_stop"):
		GDN.stop()
	if Input.is_action_just_pressed("clear_console"):
		LOG_BOX.clear()
	if Input.is_action_just_pressed("ui_cancel"):
		if OPEN_DIALOG.visible:
			OPEN_DIALOG.hide()
		if GOTO_DIALOG.visible:
			GOTO_DIALOG.hide()
	if Input.is_action_just_pressed("go_to_address"):
		_on_BtnAddr_pressed()
	if Input.is_action_just_pressed("backspace"):
		fill_ImportExportEtcTables()
		update_info_extra_panels()
		Log.generic(null,"reloaded!")

func _on_focus_change_intercept(node):
	if node != BTN_RECENT && node.get_parent() != BTN_RECENT_LIST:
		close_recent_dropdown()

func _on_viewport_size_changed():
	yield(get_tree(), "idle_frame") # this is necessary for window events such as maximize/minimize
	update_middle_panel_height()

func _on_BtnOpen_pressed():
	OPEN_DIALOG.popup_centered()
func _on_BtnSave_pressed():
	pass # Replace with function body.
func _on_BtnClose_pressed():
	close_and_clear_all()

func _on_BtnRun_pressed():
	GDN.start()
func _on_BtnStop_pressed():
	GDN.stop()

func _on_BtnBreak_pressed():
	if GDN.is_paused:
		GDN.resume()
	else:
		GDN.pause()
func _on_BtnBack_pressed():
	GDN.step_back()
func _on_BtnStep_pressed():
	GDN.step_forward()

func _on_BtnClearLog_pressed():
	LOG_BOX.clear()

func _on_BtnVisibleProgram_toggled(button_pressed):
	GDN.hidden_process_window = !button_pressed

onready var GOTO_DIALOG = $GoToDialog
func _on_LineEdit_text_entered(new_text):
	if !new_text.begins_with("0x"):
		new_text = str("0x",new_text)
	var byte = new_text.hex_to_int()
	hex_scroll_to(byte, byte + 4)
	GOTO_DIALOG.hide()
func _on_BtnAddr_pressed():
	GOTO_DIALOG.popup()
	if byte_selection.size() > 0:
		$GoToDialog/LineEdit.text = "0x%08X" % [byte_selection[0]]
	else:
		$GoToDialog/LineEdit.text = "0x%s" % [HEXVIEW_ADDRESS.text.split("\n")[0]]
	$GoToDialog/LineEdit.grab_focus()
	$GoToDialog/LineEdit.select(2,-1)
	$GoToDialog/LineEdit.caret_position = 999999




