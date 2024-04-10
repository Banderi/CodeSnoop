extends Control

# FILE
var file = null
func open_file(path):
	if IO.file_exists(path):
		close_file() # REMEMBER TO CLOSE THE FILE FIRST!
		Log.generic(null, "Opening file '%s'" % [path])
		file = IO.read(path)
		if file != null:
			GDNShell.shell_cmd = path
			
			# hex view
			update_hex_scrollbar_size()
			update_hex_view()
			
			# asm chunks & disassembler
			read_asm_chunks()
			update_asm_scrollbar_size()
			update_asm_view()
func close_file():
	GDNShell.stop()
	GDNShell.shell_cmd = null
	if file != null:
		file.close() # this is EXTREMELY IMPORTANT.
	file = null
	update_hex_scrollbar_size()
	update_hex_view()
	
	asm_chunks = {}
	$VSplitContainer/Main/Code/Chunks/List.clear()
	$VSplitContainer/Main/Code/Chunks/Data.clear()

##### CODING / MAIN PANELs
var code_height = 0
func update_code_panel_height():
	# use the hex view slider as a random reference point
	if code_height != $VSplitContainer/Main/Hex/VSlider.rect_size.y:
		code_height = $VSplitContainer/Main/Hex/VSlider.rect_size.y
		update_hex_scrollbar_size()
		update_hex_view()

# hex view panel
func hex_view_visible_lines():
	return floor(code_height / (16 + $VSplitContainer/Main/Hex.get("custom_constants/line_spacing"))) - 1
func update_hex_scrollbar_size():
	if file != null:
		var file_length = file.get_len()
		var lines_count = ceil(float(file_length) / 8.0)
		var line_start = lines_count - hex_view_visible_lines()
		$VSplitContainer/Main/Hex/VSlider.max_value = line_start
		$VSplitContainer/Main/Hex/VSlider.value = line_start
	else:
		$VSplitContainer/Main/Hex/VSlider.max_value = 0
func update_hex_view():
	var temp = ""
	if file != null:
		var byte_start = ($VSplitContainer/Main/Hex/VSlider.max_value - $VSplitContainer/Main/Hex/VSlider.value) * 8
		var byte_length = min(8 * hex_view_visible_lines(), file.get_len() - byte_start)
		file.seek(byte_start)
		var buffer = file.get_buffer(byte_length)
		var l = 0
		var b = 0
		temp += "%08X " % [byte_start]
		for byte in buffer:
			temp += str("%02X " % [byte])
			b += 1
			if b >= 8 && l < hex_view_visible_lines() - 1:
				b = 0
				l += 1
				temp += "\n%08X " % [byte_start + l * 8 + b]
	$VSplitContainer/Main/Hex.text = temp
func _on_VScrollBarHexView_scrolling():
	update_hex_view()

# chunks list & chunk data panel
var asm_chunks = {}
func read_asm_chunks():
	asm_chunks = {}
	if file != null:
		file.seek(0)
		asm_chunks["_IMAGE_DOS_HEADER"]	= {
			"e_magic": file.read("str2"),
			"e_cblp": file.read("i16"),
			"e_cp": file.read("i16"),
			"e_crlc": file.read("i16"),
			"e_cparhdr": file.read("i16"),
			"e_minalloc": file.read("i16"),
			"e_maxalloc": file.read("i16"),
			"e_ss": file.read("i16"),
			"e_sp": file.read("i16"),
			"e_csum": file.read("i16"),
			"e_ip": file.read("i16"),
			"e_cs": file.read("i16"),
			"e_lfarlc": file.read("i16"),
			"e_ovno": file.read("i16"),
			"e_res": [
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16")
			],
			"e_oemid": file.read("i16"),
			"e_oeminfo": file.read("i16"),
			"e_res2": [
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16"),
				file.read("i16")
			],
			"e_lfanew": file.read("i32"),
		}
		var dos_stub_size = asm_chunks["_IMAGE_DOS_HEADER"].e_lfanew.value - 64
		asm_chunks["_IMAGE_DOS_STUB"] = file.read(dos_stub_size)
		assert(file.get_position() == asm_chunks["_IMAGE_DOS_HEADER"].e_lfanew.value)
		asm_chunks["_IMAGE_NT_HEADERS"] = {
			"Signature": file.read("str4"),
			"FileHeader": {
				"Machine": file.read("i16"),
				"NumberOfSections": file.read("i16"),
				"TimeDateStamp": file.read("i32"),
				"PointerToSymbolTable": file.read("i32"),
				"NumberOfSymbols": file.read("i32"),
				"SizeOfOptionalHeader": file.read("i16"),
				"Characteristics": file.read("i16")
			},
			"OptionalHeader": {
				"Magic": file.read("i16"),
				"MajorLinkerVersion": file.read("i8"),
				"MinorLinkerVersion": file.read("i8"),
				"SizeOfCode": file.read("i32"),
				"SizeOfInitializedData": file.read("i32"),
				"SizeOfUninitializedData": file.read("i32"),
				"AddressOfEntryPoint": file.read("i32", -1, "0x%08X"),
				"BaseOfCode": file.read("i32", -1, "0x%08X"),
				"ImageBase": file.read("i64", -1, "0x%016X"),
				"SectionAlignment": file.read("i32"),
				"FileAlignment": file.read("i32"),
				"MajorOperatingSystemVersion": file.read("i16"),
				"MinorOperatingSystemVersion": file.read("i16"),
				"MajorImageVersion": file.read("i16"),
				"MinorImageVersion": file.read("i16"),
				"MajorSubsystemVersion": file.read("i16"),
				"MinorSubsystemVersion": file.read("i16"),
				"Win32VersionValue": file.read("i32"),
				"SizeOfImage": file.read("i32"),
				"SizeOfHeaders": file.read("i32"),
				"CheckSum": file.read("i32"),
				"Subsystem": file.read("i16"),
				"DllCharacteristics": file.read("i16"),
				"SizeOfStackReserve": file.read("i64"),
				"SizeOfStackCommit": file.read("i64"),
				"SizeOfHeapReserve": file.read("i64"),
				"SizeOfHeapCommit": file.read("i64"),
				"LoaderFlags": file.read("i32"),
				"NumberOfRvaAndSizes": file.read("i32"),
				"DataDirectory": []
			}
		}
		for i in range(0,16):
			asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory.push_back({
				"VirtualAddress": file.read("i32", -1, "0x%08X"),
				"Size": file.read("i32")
			})
		print(DataStruct.as_text(asm_chunks._IMAGE_NT_HEADERS.Signature))
		fill_ChunkTable()
func fill_ChunkTable():
	$VSplitContainer/Main/Code/Chunks/List.clear()
	$VSplitContainer/Main/Code/Chunks/List.create_item()
	recursive_fill_ChunkTable(asm_chunks, null, null)
	DataStruct.schema_items_names = {}
	DataStruct.record_schema_names_recursive($VSplitContainer/Main/Code/Chunks/List.get_root().get_children())
func recursive_fill_ChunkTable(item, parent, itemname):
	# add the current one to the list
	var table_item = null
	if itemname != null:
		table_item = $VSplitContainer/Main/Code/Chunks/List.create_item(parent)
		table_item.collapsed = true
		table_item.set_metadata(0, [itemname,item])
		if itemname.begins_with("unk"):
			itemname = "??"
			table_item.set_custom_color(0, Color(1,1,1,0.3))
		elif itemname.begins_with("unused"):
			table_item.set_custom_color(0, Color(1,0.7,0.7,0.5))
#			table_item.set_custom_color(0, Color(1,1,1,0.3))
	
	var total_bytes = 0
	
	# follow through the childs
	if DataStruct.is_valid(item):
		total_bytes += item.size
	else:
		if item is Dictionary && item.has("value"):
			item = item.value
		if item is Dictionary:
			for k in item:
				if k == "offset" || k == "schema_index":
					continue
				total_bytes += recursive_fill_ChunkTable(item[k], table_item, str(k))
		elif item is Array:
			for e in item.size():
				total_bytes += recursive_fill_ChunkTable(item[e], table_item, str("[",e,"]"))
	
	if itemname != null:
		if item is Dictionary && "compressed_size" in item:
			table_item.set_text(0, str(itemname," (",total_bytes,") **"))
			table_item.set_custom_color(0, Color(0.8,0.8,0))
		else:
			table_item.set_text(0, str(itemname," (",total_bytes,")"))
	return total_bytes
func _on_ChunkTable_cell_selected():
	var selection = $VSplitContainer/Main/Code/Chunks/List.get_selected()
	var data = selection.get_metadata(0)
	$VSplitContainer/Main/Code/Chunks/Data.clear()
	$VSplitContainer/Main/Code/Chunks/Data.present(data[0], data[1])

# asm / disassembler
func update_asm_scrollbar_size():
	if file != null:
		pass
	else:
		$VSplitContainer/Main/Code/Asm/VSlider.max_value = 0
func update_asm_view():
	$VSplitContainer/Main/Code/Asm.clear()
	$VSplitContainer/Main/Code/Asm.create_item()
	if file != null:
		var tree_item = $VSplitContainer/Main/Code/Asm.create_item()
		tree_item.set_text(0,"asda")
func _on_VSlider_asm_scrolled():
	update_asm_view()

############

# bottom-right log window
var logger_lines = 0
var logger_autoscroll = true
onready var log_box = $VSplitContainer/Footer/LogPrinter
func log_do_scroll():
	if Log.LOG_CHANGED:
		log_box.text = ""
		logger_lines = Log.LOG_EVERYTHING.size()
		for l in Log.LOG_EVERYTHING:
			log_box.text += l + "\n"
		if logger_autoscroll:
			log_box.scroll_vertical = logger_lines-1
		Log.LOG_CHANGED = false

# Called when the node enters the scene tree for the first time.
func _ready():
	Log.generic(null, "Initializing...")
	GDNShell.root_node = self
	GDNShell.terminal_node = $VSplitContainer/Footer/Console/Terminal
	GDNShell.GDN_INIT()
	log_box.text = ""
	GDNShell.clear()
	close_file()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	log_do_scroll()
	$FPS.text = str(Engine.get_frames_per_second(), " FPS")
	
	# has file open?
	if file != null:
		$Top/Buttons/HBoxContainer2/BtnClose.disabled = false
		$Top/Buttons/HBoxContainer3/BtnRun.disabled = false
	else:
		$Top/Buttons/HBoxContainer2/BtnClose.disabled = true
		$Top/Buttons/HBoxContainer3/BtnRun.disabled = true
		$Top/Buttons/HBoxContainer3/BtnStop.disabled = true
	
	# has an active child process?
	if GDNShell.has_started_process_attached(): # process attached
		$Top/Buttons/HBoxContainer3/BtnStop.disabled = false
		$Top/Buttons/HBoxContainer/BtnBreak.disabled = false
		$Top/Buttons/HBoxContainer/BtnBack.disabled = false
		$Top/Buttons/HBoxContainer/BtnStep.disabled = false
		if GDNShell.is_paused: # paused / debugging
			$VSplitContainer/Footer/Console/Terminal.readonly = true
#			$Console/Terminal.set_color(Color(0.5,0.5,0.5))
#			$VSplitContainer/Footer/Console/Input.editable = false
#			$VSplitContainer/Footer/Console/Input.focus_mode = FOCUS_NONE
			$Top/Buttons/HBoxContainer/BtnBack.disabled = false
			$Top/Buttons/HBoxContainer/BtnStep.disabled = false
		else: # running!
			$VSplitContainer/Footer/Console/Terminal.readonly = false
#			$VSplitContainer/Footer/Console/Terminal.set_color(Color(1,1,1))
#			$VSplitContainer/Footer/Console/Input.editable = true
#			$VSplitContainer/Footer/Console/Input.focus_mode = FOCUS_ALL
			$Top/Buttons/HBoxContainer/BtnBack.disabled = true
			$Top/Buttons/HBoxContainer/BtnStep.disabled = true
	else: # no process / stopped
		$Top/Buttons/HBoxContainer3/BtnStop.disabled = true
		$VSplitContainer/Footer/Console/Terminal.readonly = true
#		$VSplitContainer/Footer/Console/Terminal.set_color(Color(0.5,0.5,0.5))
#		$VSplitContainer/Footer/Console/Input.editable = false
#		$VSplitContainer/Footer/Console/Input.focus_mode = FOCUS_NONE
		$Top/Buttons/HBoxContainer/BtnBreak.disabled = true
		$Top/Buttons/HBoxContainer/BtnBack.disabled = true
		$Top/Buttons/HBoxContainer/BtnStep.disabled = true
	
	# button text when paused
	if GDNShell.is_paused:
		$Top/Buttons/HBoxContainer/BtnBreak.text = "Resume"
	else:
		$Top/Buttons/HBoxContainer/BtnBreak.text = "Break"

func _input(event):
	if Input.is_action_just_pressed("debug_start"):
		GDNShell.start()
		$VSplitContainer/Footer/Console/Input.grab_focus()
	if Input.is_action_just_pressed("debug_stop"):
		GDNShell.stop()
	if Input.is_action_just_pressed("clear_console"):
		GDNShell.clear()
		Log.LOG_EVERYTHING = []
		Log.LOG_ENGINE = []
		Log.LOG_ERRORS = []
		log_box.text = "Log cleared."
	
	update_code_panel_height()

func _on_BtnOpen_pressed():
	open_file("E:/Git/CppTestApp/cmake-build-debug/CppTestApp.exe")
func _on_BtnSave_pressed():
	pass # Replace with function body.
func _on_BtnClose_pressed():
	GDNShell.stop()
	close_file()

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

func _on_Input_text_entered(new_text):
	GDNShell.send_string(new_text)
	$VSplitContainer/Footer/Console/Input.clear()
