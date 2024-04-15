extends Node

enum PE_SIGNATURE {
	WIN32 = int("PE"),
	WIN16 = int("NE"),
	WIN3X_VxD = int("LE"),
	OS2 = int("LX"),
}
enum PE_TYPE {
	PE32 = 0x10B,
	PE_ROM = 0x107,
	PE32_64 = 0x20B
}
enum DATA_DIRECTORIES {
	IMAGE_DIRECTORY_ENTRY_EXPORT = 0,
	IMAGE_DIRECTORY_ENTRY_IMPORT = 1,
	IMAGE_DIRECTORY_ENTRY_RESOURCE = 2,
	IMAGE_DIRECTORY_ENTRY_EXCEPTION = 3,
	IMAGE_DIRECTORY_ENTRY_SECURITY = 4,
	IMAGE_DIRECTORY_ENTRY_BASERELOC = 5,
	IMAGE_DIRECTORY_ENTRY_DEBUG = 6,
	IMAGE_DIRECTORY_ENTRY_COPYRIGHT = 7,
	IMAGE_DIRECTORY_ENTRY_GLOBALPTR = 8,
	IMAGE_DIRECTORY_ENTRY_TLS = 9,
	IMAGE_DIRECTORY_ENTRY_LOAD_CONFIG = 10,
	IMAGE_DIRECTORY_ENTRY_BOUND_IMPORT = 11,
	IMAGE_DIRECTORY_ENTRY_IAT = 12,
	IMAGE_DIRECTORY_ENTRY_DELAY_IMPORT = 13,
	IMAGE_DIRECTORY_ENTRY_COM_DESCRIPTOR = 14,
	IMAGE_DIRECTORY_ENTRY_NULL_END = 15,
}
## PRODID FILE
var PRODID = []
var prodid_file = null
func load_prodid_enums():
	
	if prodid_file != null:
		prodid_file.close() # this is EXTREMELY IMPORTANT.
	prodid_file = IO.read("res://msobj140-msvcrt.lib")
	if prodid_file != null:
		prodid_file.seek(4)
		while prodid_file.get_position() < prodid_file.get_len():
			var offset = prodid_file.get_position()
			if offset > 6870:
				var a = 2
			var pid = prodid_file.read("u16").value
			var pidname = DataStruct.as_text(prodid_file.read("str32"))
			if pidname.begins_with("prodid"):
				pidname = pidname.strip_edges()
				PRODID.push_back([pid,pidname])
				if PRODID.size()-1 != pid:
					print(PRODID.size()-1," ",pid," ",pidname)
				prodid_file.seek(offset + 2 + pidname.length())
			else:
				prodid_file.seek(offset + 1)

## PE FILE
var file = null
func open_file(path):
	if IO.file_exists(path):
		close_file() # REMEMBER TO CLOSE THE FILE FIRST!
		Log.generic(null, "Opening file '%s'" % [path])
		file = IO.read(path)
		if PE.file != null:
			GDNShell.shell_cmd = path
			read_asm_chunks()
			return true
	# failure..?
	return false
func close_file():
	GDNShell.stop()
	GDNShell.shell_cmd = null
	if file != null:
		file.close() # this is EXTREMELY IMPORTANT.
	file = null
	asm_chunks = {}



var data_dirs_section_idx = []
#var sections_info = []
#var sections_data = []
#func get_section_info(idx):
#	pass
#func get_section_data(idx):
#	pass

var asm_chunks = {}
func read_data_directory_section():
	return {
		"VirtualAddress": file.read("p32"),
		"Size": file.read("u32")
	}
func read_asm_chunks():
	asm_chunks = {}
	if file != null:
		file.seek(0)
		
		# DOS header
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
			"e_lfanew": file.read("u32", 1, "0x%08X"),
		}
		
		# DOS stub
		asm_chunks["_IMAGE_DOS_STUB"] = file.read(64)
		var PE_offset = asm_chunks["_IMAGE_DOS_HEADER"].e_lfanew.value
		
		# MSVC Link.exe "Rich" header
		var msvclink_inj_size = PE_offset - file.get_position()
		if msvclink_inj_size > 0:
			
			# find the "Rich" signature first
			var link_start_offset = file.get_position()
			var rich_offset = link_start_offset
			while file.get_buffer(4) as Array != [0x52, 0x69, 0x63, 0x68]:
				file.seek(file.get_position() + 4)
				rich_offset = file.get_position()
				if rich_offset >= PE_offset:
					rich_offset = -1
					break # no "Rich" found?
			
			if rich_offset != -1:
				var key = file.read(4)
				file.seek(link_start_offset)
				asm_chunks["Link.exe_signature"] = {
					"sign_DanS": file.read_xor_encrypted("str4", key.value),
					"empty_padding": file.read_xor_encrypted(4, key.value),
					"values": []
				}
				
				# data fields: 8 bytes each
				for i in range(1, msvclink_inj_size/8):
					if file.get_position() < rich_offset:
						asm_chunks["Link.exe_signature"]["values"].push_back({
							"buildNumber": file.read_xor_encrypted("u16", key.value),
							"productID": file.read_xor_encrypted("u16", [key.value[2], key.value[3]], "PRODID"),
							"objectCount": file.read_xor_encrypted("u32", key.value),
						})
					elif file.get_position() == rich_offset: # the Rich field is just "Rich" + the XOR key
						asm_chunks["Link.exe_signature"]["sign_Rich"] = file.read("str4")
						asm_chunks["Link.exe_signature"]["key_checksum"] = key
					else:
						file.seek(file.get_position() + 4) # the last fields after Rich are empty
						var remaining_size = PE_offset - file.get_position()
						asm_chunks["Link.exe_signature"][str("empty_",remaining_size,"_bytes")] = file.read(remaining_size)
						break
			else:
				file.seek(PE_offset - msvclink_inj_size)
				asm_chunks["unk_Link.exe_signature"] = file.read(msvclink_inj_size)
	
		# PE / COFF / NT header
		file.seek(PE_offset)
		asm_chunks["_IMAGE_NT_HEADERS"] = {
			"Signature": file.read("str4"),
			"FileHeader": {
				"Machine": file.read("u16", 1, "0x%04X"),
				"NumberOfSections": file.read("u16"),
				"TimeDateStamp": file.read("u32"),
				"PointerToSymbolTable": file.read("p32"),
				"NumberOfSymbols": file.read("u32"),
				"SizeOfOptionalHeader": file.read("u16"),
				"Characteristics": file.read("i16")
			},
			"OptionalHeader": {}
		}
		
		# PE / COFF / NT optional header
		var PE_magic_number = file.read("i16")
		var is_PE32_64 = (PE_magic_number.value == PE_TYPE.PE32_64)
		asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader = {
			"Magic": PE_magic_number,
			"MajorLinkerVersion": file.read("i8"),
			"MinorLinkerVersion": file.read("i8"),
			"SizeOfCode": file.read("u32"),
			"SizeOfInitializedData": file.read("u32"),
			"SizeOfUninitializedData": file.read("u32"),
			"AddressOfEntryPoint": file.read("p32"),
			"BaseOfCode": file.read("p32"),
			# ... PE32 specifics
			"BaseOfData": file.read("p32") if !is_PE32_64 else null,
			# ...
			"ImageBase": file.read("p64") if is_PE32_64 else file.read("p32"),
			"SectionAlignment": file.read("u32"),
			"FileAlignment": file.read("u32"),
			"MajorOperatingSystemVersion": file.read("i16"),
			"MinorOperatingSystemVersion": file.read("i16"),
			"MajorImageVersion": file.read("i16"),
			"MinorImageVersion": file.read("i16"),
			"MajorSubsystemVersion": file.read("i16"),
			"MinorSubsystemVersion": file.read("i16"),
			"Win32VersionValue": file.read("i32"),
			"SizeOfImage": file.read("u32"),
			"SizeOfHeaders": file.read("u32"),
			"CheckSum": file.read("i32"),
			"Subsystem": file.read("i16"),
			"DllCharacteristics": file.read("i16"),
			"SizeOfStackReserve": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfStackCommit": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfHeapReserve": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfHeapCommit": file.read("u64") if is_PE32_64 else file.read("u32"),
			"LoaderFlags": file.read("u32"),
			"NumberOfRvaAndSizes": file.read("i32"),
			"DataDirectory": []
		}
		if is_PE32_64:
			asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.erase("BaseOfData")
		
		# Data directories
		for _i in range(0,16):
			asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory.push_back(read_data_directory_section())
		
		# Section headers
		asm_chunks["_SECTION_HEADERS"] = {}
		for _i in range(0,asm_chunks._IMAGE_NT_HEADERS.FileHeader.NumberOfSections.value):
			var section = {
				"Name": file.read("str8"),
				"Misc": file.read("u32"),
				"VirtualAddress": file.read("p32"),
				"SizeOfRawData": file.read("u32"),
				"PointerToRawData": file.read("p32"),
				"PointerToRelocations": file.read("p32"),
				"PointerToLinenumbers": file.read("p32"),
				"NumberOfRelocations": file.read("u16"),
				"NumberOfLinenumbers": file.read("u16"),
				"Characteristics": file.read("u32"),
			}
			var section_name = DataStruct.as_text(section.Name)
			asm_chunks["_SECTION_HEADERS"][section_name] = section
		
		# Sections data
		asm_chunks["_SECTIONS"] = {}
		for section_name in asm_chunks["_SECTION_HEADERS"]:
			var section_info = asm_chunks["_SECTION_HEADERS"][section_name]
			var size = section_info.SizeOfRawData.value
			if size < 1:
				continue
			var offset = section_info.PointerToRawData.value
			file.seek(offset)
			asm_chunks["_SECTIONS"][section_name] = file.read(size)

		# Compile lookups of data directories & section headers
		for i in range(0,16):
			var data_dir = asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory[i]
			var RVA = data_dir.VirtualAddress.value
			if RVA == 0x00000000:
				data_dirs_section_idx.push_back(-1)
			else:
				for s in asm_chunks["_SECTION_HEADERS"].keys().size():
					var section_name = asm_chunks["_SECTION_HEADERS"].keys()[s]
					var section_info = asm_chunks["_SECTION_HEADERS"][section_name]
					if section_info.VirtualAddress.value == RVA:
						data_dirs_section_idx.push_back(s)
						break
