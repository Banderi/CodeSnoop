extends Node

enum PE_SIGNATURE {
	WIN32 = int("PE")
	WIN16 = int("NE")
	WIN3X_VxD = int("LE")
	OS2 = int("LX")
}
enum PE_TYPE {
	PE32 = 0x10B
	PE_ROM = 0x107
	PE32_64 = 0x20B
}
enum DATA_DIRECTORIES {
	EXPORT = 0						# .edata
	IMPORT = 1						# .idata
	RESOURCE = 2					# .rsrc
	EXCEPTION = 3					# .pdata
	SECURITY = 4					# ---> file offset to a separate part of the file
	BASERELOC = 5					# .reloc
	DEBUG = 6						# .debug
	COPYRIGHT = 7					# "Architecture" (reserved, must be 0)
	GLOBALPTR = 8					# RVA to be stored in the Global Pointer register (size must be 0)
	TLS = 9							# .tls
	LOAD_CONFIG = 10				# ??
	BOUND_IMPORT = 11				# ??
	IAT = 12						# ??
	DELAY_IMPORT = 13				# ---> file offset to a separate part of the file
	COM_DESCRIPTOR = 14				# .cormeta (OBJ only)
	NULL_END = 15					# (reserved, must be 0)
}
enum MACHINE_TYPES {
	UNKNOWN = 0x0
	ALPHA = 0x184					# Alpha AXP, 32-bit address space
	ALPHA64 = 0x284					# Alpha 64, 64-bit address space
	AM33 = 0x1d3					# Matsushita AM33
	AMD64 = 0x8664					# x64
	ARM = 0x1c0						# ARM little endian
	ARM64 = 0xaa64					# ARM64 little endian
	ARMNT = 0x1c4					# ARM Thumb-2 little endian
	AXP64 = 0x284					# AXP 64 (Same as Alpha 64)
	EBC = 0xebc						# EFI byte code
	I386 = 0x14c					# Intel 386 or later processors and compatible processors
	IA64 = 0x200					# Intel Itanium processor family
	LOONGARCH32 = 0x6232			# LoongArch 32-bit processor family
	LOONGARCH64 = 0x6264			# LoongArch 64-bit processor family
	M32R = 0x9041					# Mitsubishi M32R little endian
	MIPS16 = 0x266					# MIPS16
	MIPSFPU = 0x366					# MIPS with FPU
	MIPSFPU16 = 0x466				# MIPS16 with FPU
	POWERPC = 0x1f0					# Power PC little endian
	POWERPCFP = 0x1f1				# Power PC with floating point support
	R4000 = 0x166					# MIPS little endian
	RISCV32 = 0x5032				# RISC-V 32-bit address space
	RISCV64 = 0x5064				# RISC-V 64-bit address space
	RISCV128 = 0x5128				# RISC-V 128-bit address space
	SH3 = 0x1a2						# Hitachi SH3
	SH3DSP = 0x1a3					# Hitachi SH3 DSP
	SH4 = 0x1a6						# Hitachi SH4
	SH5 = 0x1a8						# Hitachi SH5
	THUMB = 0x1c2					# Thumb
	WCEMIPSV2 = 0x169				# MIPS little-endian WCE v2
}
enum IMAGE_CHARACTERISTICS {
	RELOCS_STRIPPED = 0x0001			# Image only, Windows CE, and Microsoft Windows NT and later. This indicates that the file does not contain base relocations and must therefore be loaded at its preferred base address.
										# If the base address is not available, the loader reports an error. The default behavior of the linker is to strip base relocations from executable (EXE) files.
	EXECUTABLE_IMAGE = 0x0002			# Image only. This indicates that the image file is valid and can be run. If this flag is not set, it indicates a linker error.
	LINE_NUMS_STRIPPED = 0x0004			# COFF line numbers have been removed. This flag is deprecated and should be zero.
	LOCAL_SYMS_STRIPPED = 0x0008		# COFF symbol table entries for local symbols have been removed. This flag is deprecated and should be zero.
	AGGRESSIVE_WS_TRIM = 0x0010			# Obsolete. Aggressively trim working set. This flag is deprecated for Windows 2000 and later and must be zero.
	LARGE_ADDRESS_AWARE = 0x0020		# Application can handle > 2-GB addresses.
	#
	BYTES_REVERSED_LO = 0x0080			# Little endian: the least significant bit (LSB) precedes the most significant bit (MSB) in memory. This flag is deprecated and should be zero.
	_32BIT_MACHINE = 0x0100				# Machine is based on a 32-bit-word architecture.
	DEBUG_STRIPPED = 0x0200				# Debugging information is removed from the image file.
	REMOVABLE_RUN_FROM_SWAP = 0x0400	# If the image is on removable media, fully load it and copy it to the swap file.
	NET_RUN_FROM_SWAP = 0x0800			# If the image is on network media, fully load it and copy it to the swap file.
	SYSTEM = 0x1000						# The image file is a system file, not a user program.
	DLL = 0x2000						# The image file is a dynamic-link library (DLL). Such files are considered executable files for almost all purposes, although they cannot be directly run.
	UP_SYSTEM_ONLY = 0x4000				# The file should be run only on a uniprocessor machine.
	BYTES_REVERSED_HI = 0x8000			# Big endian: the MSB precedes the LSB in memory. This flag is deprecated and should be zero.
}
enum IMAGE_SUBSYSTEM {
	UNKNOWN = 0						# An unknown subsystem
	NATIVE = 1						# Device drivers and native Windows processes
	WINDOWS_GUI = 2					# The Windows graphical user interface (GUI) subsystem
	WINDOWS_CUI = 3					# The Windows character subsystem
	#
	OS2_CUI = 5						# The OS/2 character subsystem
	#
	POSIX_CUI = 7					# The Posix character subsystem
	NATIVE_WINDOWS = 8				# Native Win9x driver
	WINDOWS_CE_GUI = 9				# Windows CE
	EFI_APPLICATION = 10			# An Extensible Firmware Interface (EFI) application
	EFI_BOOT_SERVICE_DRIVER = 11	# An EFI driver with boot services
	EFI_RUNTIME_DRIVER = 12			# An EFI driver with run-time services
	EFI_ROM = 13					# An EFI ROM image
	XBOX = 14						# XBOX
	#
	WINDOWS_BOOT_APPLICATION = 16	# Windows boot application
}
enum SECTION_CHARACTERISTICS {
	TYPE_NO_PAD = 0x00000008				# The section should not be padded to the next boundary. This flag is obsolete and is replaced by IMAGE_SCN_ALIGN_1BYTES. This is valid only for object files.
	#
	CNT_CODE = 0x00000020					# The section contains executable code.
	CNT_INITIALIZED_DATA = 0x00000040		# The section contains initialized data.
	CNT_UNINITIALIZED_DATA = 0x00000080		# The section contains uninitialized data.
	LNK_OTHER = 0x00000100					# Reserved for future use.
	LNK_INFO = 0x00000200					# The section contains comments or other information. The .drectve section has this type. This is valid for object files only.
	#
	LNK_REMOVE = 0x00000800					# The section will not become part of the image. This is valid only for object files.
	LNK_COMDAT = 0x00001000					# The section contains COMDAT data. For more information, see COMDAT Sections (Object Only). This is valid only for object files.
	GPREL = 0x00008000						# The section contains data referenced through the global pointer (GP).
	MEM_PURGEABLE = 0x00020000				# Reserved for future use.
	MEM_16BIT = 0x00020000					# Reserved for future use.
	MEM_LOCKED = 0x00040000					# Reserved for future use.
	MEM_PRELOAD = 0x00080000				# Reserved for future use.
	ALIGN_1BYTES = 0x00100000				# Align data on a 1-byte boundary. Valid only for object files.
	ALIGN_2BYTES = 0x00200000				# Align data on a 2-byte boundary. Valid only for object files.
	ALIGN_4BYTES = 0x00300000				# Align data on a 4-byte boundary. Valid only for object files.
	ALIGN_8BYTES = 0x00400000				# Align data on an 8-byte boundary. Valid only for object files.
	ALIGN_16BYTES = 0x00500000				# Align data on a 16-byte boundary. Valid only for object files.
	ALIGN_32BYTES = 0x00600000				# Align data on a 32-byte boundary. Valid only for object files.
	ALIGN_64BYTES = 0x00700000				# Align data on a 64-byte boundary. Valid only for object files.
	ALIGN_128BYTES = 0x00800000				# Align data on a 128-byte boundary. Valid only for object files.
	ALIGN_256BYTES = 0x00900000				# Align data on a 256-byte boundary. Valid only for object files.
	ALIGN_512BYTES = 0x00A00000				# Align data on a 512-byte boundary. Valid only for object files.
	ALIGN_1024BYTES = 0x00B00000			# Align data on a 1024-byte boundary. Valid only for object files.
	ALIGN_2048BYTES = 0x00C00000			# Align data on a 2048-byte boundary. Valid only for object files.
	ALIGN_4096BYTES = 0x00D00000			# Align data on a 4096-byte boundary. Valid only for object files.
	ALIGN_8192BYTES = 0x00E00000			# Align data on an 8192-byte boundary. Valid only for object files.
	LNK_NRELOC_OVFL = 0x01000000			# The section contains extended relocations.
	MEM_DISCARDABLE = 0x02000000			# The section can be discarded as needed.
	MEM_NOT_CACHED = 0x04000000				# The section cannot be cached.
	MEM_NOT_PAGED = 0x08000000				# The section is not pageable.
	MEM_SHARED = 0x10000000					# The section can be shared in memory.
	MEM_EXECUTE = 0x20000000				# The section can be executed as code.
	MEM_READ = 0x40000000					# The section can be read.
	MEM_WRITE = 0x80000000					# The section can be written to.
}
enum DLL_CHARACTERISTICS {
	HIGH_ENTROPY_VA = 0x0020		# Image can handle a high entropy 64-bit virtual address space.
	DYNAMIC_BASE = 0x0040			# DLL can be relocated at load time.
	FORCE_INTEGRITY = 0x0080		# Code Integrity checks are enforced.
	NX_COMPAT = 0x0100				# Image is NX compatible.
	NO_ISOLATION = 0x0200			# Isolation aware, but do not isolate the image.
	NO_SEH = 0x0400					# Does not use structured exception (SE) handling. No SE handler may be called in this image.
	NO_BIND = 0x0800				# Do not bind the image.
	APPCONTAINER = 0x1000			# Image must execute in an AppContainer.
	WDM_DRIVER = 0x2000				# A WDM driver.
	GUARD_CF = 0x4000				# Image supports Control Flow Guard.
	TERMINAL_SERVER_AWARE = 0x8000	# Terminal Server aware.
}
enum CERTIFICATE_REVISION {
	REV_1_0 = 0x0100
	REV_2_0 = 0x0200
}
enum CERTIFICATE_TYPE {
	X509 = 1						# bCertificate contains an X.509 Certificate
	PKCS_SIGNED_DATA = 2			# bCertificate contains a PKCS#7 SignedData structure
	RESERVED_1 = 3					# (reserved)
	TS_STACK_SIGNED = 4				# Terminal Server Protocol Stack Certificate signing
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

var asm_chunks = {}
func throw_file_read_error(msg):	
	Log.error(null,GlobalScope.Error.ERR_FILE_CORRUPT,msg)
	return false
func read_data_directory_section():
	return {
		"VirtualAddress": file.read("rva32"),
		"Size": file.read("u32")
	}
func read_asm_chunks():
	asm_chunks = {}
	if file != null:
		file.seek(0)
		
		# DOS header
		if file.end_reached(): return throw_file_read_error("corrupt DOS header: file stops at %d"%[file.get_position()])
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
			"e_lfanew": file.read("u32", "0x%08X"),
		}
		var PE_header_offset = asm_chunks["_IMAGE_DOS_HEADER"].e_lfanew.value
		
		# DOS stub
		if file.end_reached(): return throw_file_read_error("corrupt DOS stub: file stops at %d"%[file.get_position()])
		asm_chunks["_IMAGE_DOS_STUB"] = file.read(64)
		
		# MSVC Link.exe "Rich" header
		if file.end_reached(): return throw_file_read_error("corrupt file: file stops at %d"%[file.get_position()])
		var msvclink_inj_size = PE_header_offset - file.get_position()
		if msvclink_inj_size > 0:
			# find the "Rich" signature first
			var link_start_offset = file.get_position()
			var rich_offset = link_start_offset
			while file.get_buffer(4) as Array != [0x52, 0x69, 0x63, 0x68]:
				file.seek(file.get_position() + 4)
				rich_offset = file.get_position()
				if rich_offset >= PE_header_offset:
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
				for _i in range(1, msvclink_inj_size/8):
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
						var remaining_size = PE_header_offset - file.get_position()
						asm_chunks["Link.exe_signature"][str("empty_",remaining_size,"_bytes")] = file.read(remaining_size)
						break
			else:
				file.seek(PE_header_offset - msvclink_inj_size)
				asm_chunks["unk_Link.exe_signature"] = file.read(msvclink_inj_size)
	
		# PE / COFF / NT header
		if file.end_reached(): return throw_file_read_error("corrupt PE headers: file stops at %d"%[file.get_position()])
		file.seek(PE_header_offset)
		asm_chunks["_IMAGE_NT_HEADERS"] = {
			"Signature": file.read("str4"),
			"FileHeader": {
				"Machine": file.read("u16", MACHINE_TYPES),
				"NumberOfSections": file.read("u16"),
				"TimeDateStamp": file.read("u32"),
				"PointerToSymbolTable": file.read("p32"),
				"NumberOfSymbols": file.read("u32"),
				"SizeOfOptionalHeader": file.read("u16"),
				"Characteristics": file.read("i16", "0x%04X")
			},
			"OptionalHeader": {}
		}
		
		# PE / COFF / NT optional header
		var is_PE32_64 = false
		var PE_magic_number = file.read("i16", PE_TYPE)
		is_PE32_64 = (PE_magic_number.value == PE_TYPE.PE32_64)
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
			"Subsystem": file.read("i16", IMAGE_SUBSYSTEM),
			"DllCharacteristics": file.read("i16", "0x%04X"),
			"SizeOfStackReserve": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfStackCommit": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfHeapReserve": file.read("u64") if is_PE32_64 else file.read("u32"),
			"SizeOfHeapCommit": file.read("u64") if is_PE32_64 else file.read("u32"),
			"LoaderFlags": file.read("u32"),
			"NumberOfRvaAndSizes": file.read("i32"),
			"DataDirectory": {}
		}
		if is_PE32_64: asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.erase("BaseOfData")
	
		# Data directories
		for i in range(0,16):
			asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory[DATA_DIRECTORIES.keys()[i]] = read_data_directory_section()
		
		# Section headers
		if file.end_reached(): return throw_file_read_error("corrupt section headers: file stops at %d"%[file.get_position()])
		asm_chunks["_SECTION_HEADERS"] = {}
		PE_SECTIONS_ARRAY = []
		for _i in range(0,asm_chunks._IMAGE_NT_HEADERS.FileHeader.NumberOfSections.value):
			var section = {
				"Name": file.read("str8"),
				"VirtualSize": file.read("u32"),
				"VirtualAddress": file.read("rva32"),
				"SizeOfRawData": file.read("u32"),
				"PointerToRawData": file.read("p32"),
				"PointerToRelocations": file.read("p32"),
				"PointerToLinenumbers": file.read("p32"),
				"NumberOfRelocations": file.read("u16"),
				"NumberOfLinenumbers": file.read("u16"),
				"Characteristics": file.read("u32"),
			}
			var section_name = DataStruct.as_text(section.Name)
			if section_name in asm_chunks["_SECTION_HEADERS"]:
				section_name += str(_i)
			asm_chunks["_SECTION_HEADERS"][section_name] = section
			PE_SECTIONS_ARRAY.push_back(section)
		asm_chunks["_SECTIONS"] = {} # we fill this section later, but it's positioned here.
		
		# COFF symbol table
		if !file.end_reached():
			var symbols_num = asm_chunks._IMAGE_NT_HEADERS.FileHeader.NumberOfSymbols.value
			if symbols_num > 0:
				coff_symbol_table_offset = asm_chunks._IMAGE_NT_HEADERS.FileHeader.PointerToSymbolTable.value
				file.seek(coff_symbol_table_offset)
				asm_chunks["_COFF_SYMBOLS_TABLE"] = file.read(18 * symbols_num)
			
				# COFF string table -- this will come right after the symbol table 99.99% of the cases..
				if file.get_position() < file.get_len():
					coff_string_table_offset = file.get_position()
					var string_table_size = file.read("u32") # this value includes the 4-byte size field itself, so 4 is the minimum.
					asm_chunks["_COFF_STRING_TABLE"] = {
						"TableSize": string_table_size,
						"Data": file.read(string_table_size.value - 4)
					}
					
					# move to the end of the section
					file.seek(coff_string_table_offset + string_table_size.value)
				else:
					coff_string_table_offset = -1
			else:
				coff_symbol_table_offset = -1
		
		# Attribute certificate table
		if !file.end_reached():
			if valid_data_directory("SECURITY"):
				var cert_table_offset = asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.DataDirectory.SECURITY.VirtualAddress.value
				var cert_table_size = asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.DataDirectory.SECURITY.Size.value
				asm_chunks["_ATTRIBUTE_CERTIFICATE_TABLE"] = []
				var adv = 0
				while adv < cert_table_size:
					file.seek(cert_table_offset + adv)
					var cert_entry = {
						"dwLength": file.read("u32"),
						"wRevision": file.read("i16", CERTIFICATE_REVISION),
						"wCertificateType": file.read("i16", CERTIFICATE_TYPE),
						"bCertificate": null,
					}
					cert_entry.bCertificate = file.read(cert_entry.dwLength.value - 8)
					asm_chunks["_ATTRIBUTE_CERTIFICATE_TABLE"].push_back(cert_entry)
					adv += ceil(float(cert_entry.dwLength.value) / 8.0) * 8
				if adv != cert_table_size:
					return throw_file_read_error("corrupt certificate table: expected %d bytes, found %d" % [cert_table_size, adv])
				else:
					Log.generic(null,"read %d certificate entries for %d total bytes" % [asm_chunks["_ATTRIBUTE_CERTIFICATE_TABLE"].size(), cert_table_size])
		
		##### DATA DIRECTORIES
		
		# .edata
		edata_table_offset = data_dir_offset("EXPORT")
		if edata_table_offset != -1:
			file.seek(edata_table_offset)
		
		# .idata
		IMPORT_TABLES.IMPORT.offset = data_dir_offset("IMPORT")
		if IMPORT_TABLES.IMPORT.offset != -1:
			# import directory table
			IMPORT_TABLES.IMPORT.raw_chunks = {}
			var next_offset = IMPORT_TABLES.IMPORT.offset
			while true:
				file.seek(next_offset)
				var chunk = {
					"OriginalFirstThunk": file.read("rva32"), # aka the RVA to the ImportLookupTable
					"TimeDateStamp": file.read("u32"),
					"ForwarderChain": file.read("u32"),
					"Name1": file.read("rva32"), # aka the RVA to the ASCII name of the DLL
					"FirstThunk": file.read("rva32") # RVA to ImportAddressTable thunk if the import is bound, or a copy of OriginalFirstThunk
				}
				next_offset = file.get_position()
				if chunk.OriginalFirstThunk.value == 0: # last entry reached?
					IMPORT_TABLES.IMPORT.raw_chunks["__empty_end"] = chunk
					break
				else:
					var name_rva = RVA_to_file_offset(chunk.Name1.value)
					var import_name = file.get_null_terminated_string(name_rva)
					IMPORT_TABLES.IMPORT.raw_chunks[import_name] = chunk
			
			# Import Lookup Tables
			IMPORT_TABLES.ILT = fill_thunk_table("OriginalFirstThunk")
			
			# Import Address Tables
			IMPORT_TABLES.IAT = fill_thunk_table("FirstThunk")
		
		# IAT
#		iat_offset = data_dir_offset("IAT")
		
		# Fill in the actual section data
		chunk_read_sections_data()
		
		return true

func chunk_read_sections_data():
	for i in asm_chunks["_SECTION_HEADERS"].size():
		var section_name = asm_chunks["_SECTION_HEADERS"].keys()[i]
		var section_info = asm_chunks["_SECTION_HEADERS"][section_name]
		var size = section_info.SizeOfRawData.value
		if size < 1:
			continue
		
		# determine if some data directory table has been found inside this section
		var mapped_subsections = []
		var section_start = section_info.PointerToRawData.value
		for dir_name in asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory:
			if dir_name == "SECURITY":
				continue # this does not map to a PE section
			if data_dir_section(dir_name) == section_info:
				mapped_subsections.push_back({
					"offset": data_dir_offset(dir_name),
					"size": asm_chunks["_IMAGE_NT_HEADERS"].OptionalHeader.DataDirectory[dir_name].Size.value,
					"name": dir_name
				})
		mapped_subsections.sort_custom(self, "sort_by_offset")
		
		# go through the found mapped subsections (if any) and read the file chunks accordingly, spacing out
		# with any unmapped data in between if necessary
		var chunk = {}
		file.seek(section_start)
		if mapped_subsections.size() == 0:
			chunk = file.read(size)
		else:
			var last_mapped_offset = section_start
			for s in range(0, mapped_subsections.size()):
				
				
				# unmapped bytes since the last mapped chunk
				file.seek(last_mapped_offset)
				var unammped_bytes = mapped_subsections[s].offset - last_mapped_offset
				if unammped_bytes > 0:
					chunk[str("unmapped",file.get_position())] = file.read(unammped_bytes)
					last_mapped_offset += unammped_bytes
				assert(last_mapped_offset == file.get_position())
				assert(last_mapped_offset == mapped_subsections[s].offset)
				
				# mapped chunk
				match mapped_subsections[s].name:
					"IMPORT":
						chunk[mapped_subsections[s].name] = IMPORT_TABLES.IMPORT.raw_chunks
						file.seek(file.get_position() + mapped_subsections[s].size)
					"IAT":
#						chunk[mapped_subsections[s].name] = file.read(mapped_subsections[s].size)
						chunk[mapped_subsections[s].name] = IMPORT_TABLES.IAT.raw_chunks
						file.seek(file.get_position() + mapped_subsections[s].size)
					_:
						chunk[mapped_subsections[s].name] = file.read(mapped_subsections[s].size)
				
				# advance pointer
				last_mapped_offset = mapped_subsections[s].offset + mapped_subsections[s].size
			
			# append any unmapped leftover bytes if present
			var bytes_left = (section_start + size) - file.get_position()
			if bytes_left > 0:
				chunk[str("unmapped",file.get_position())] = file.read(bytes_left)
		
		# update section name from COFF string format when needed
		if section_name.begins_with("/"):
			section_name = get_coff_string(section_name.to_int())
		asm_chunks["_SECTIONS"][section_name] = chunk
func is_PE32_64():
	return asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.Magic.value == PE_TYPE.PE32_64
		
## DATA DIRECTORIES & RVA
var PE_SECTIONS_ARRAY = []
func RVA_to_section(rva):
	if file == null:
		return null
	var section_idx = null
	for i in asm_chunks["_SECTION_HEADERS"].size():
		var section_name = asm_chunks["_SECTION_HEADERS"].keys()[i]
		var section_info = asm_chunks["_SECTION_HEADERS"][section_name]
		var section_rva = section_info.VirtualAddress.value
		var virtualsize = section_info.VirtualSize.value
		if rva >= section_rva && rva < section_rva + virtualsize:
			section_idx = i
	if section_idx != null:
		return PE_SECTIONS_ARRAY[section_idx]
	return null
func RVA_to_file_offset(rva):
	var section = RVA_to_section(rva)
	if section == null:
		return null
	var offset_in_section = rva - section.VirtualAddress.value
	var raw_address = section.PointerToRawData.value + offset_in_section
	return raw_address
func valid_data_directory(dir_name):
	var chunk = asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[dir_name]
	if chunk.VirtualAddress.value > 0 && chunk.Size.value > 0:
		return true
	return false
func data_dir_offset(dir_name):
	if !valid_data_directory(dir_name):
		return -1
	return RVA_to_file_offset(asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[dir_name].VirtualAddress.value)
func data_dir_section(dir_name):
	if !valid_data_directory(dir_name):
		return null
	return RVA_to_section(asm_chunks._IMAGE_NT_HEADERS.OptionalHeader.DataDirectory[dir_name].VirtualAddress.value)
func sort_by_offset(a, b):
	if a is Dictionary:
		if a.offset < b.offset:
			return true
	elif a is Array:
		if a.size() == 0:
			return false
		if b.size() == 0 || a[0].offset < b[0].offset:
			return true
	return false

## COFF Symbol Table
var coff_symbol_table_offset = -1
func get_symbol(n):
	if file == null:
		return null
	var symbols_num = asm_chunks._IMAGE_NT_HEADERS.FileHeader.NumberOfSymbols.value
	if symbols_num == 0:
		return null
	file.seek(coff_symbol_table_offset + 18 * n)
	var shortname = null
	var shortname_4bytes = file.get_32()
	if shortname_4bytes == 0:
		shortname = file.read("p32")
	else:
		file.seek(file.get_position() - 4)
		shortname = file.read("utf8")
	var data = {
		"ShortName": shortname,
		"Value": file.read("i32"),
		"SectionNumber": file.read("i16"),
		"Type": file.read("i16"),
		"StorageClass": file.read("i8"),
		"NumberOfAuxSymbols": file.read("i8")
	}
	return data

## COFF String Table
var coff_string_table_offset = -1
func get_coff_string(offset):
	if coff_string_table_offset == -1:
		return null
	return file.get_null_terminated_string(coff_string_table_offset + offset)

## .edata
var edata_table_offset = -1

## Imports / IAT / ILT / function thunks
var iat_offset = -1
var IMPORT_TABLES = {
	"IMPORT": {
		"offset": -1,
		"raw_chunks": {}
	},
	"ILT": {},
	"IAT": {}
}
func read_thunk_chunk(is_PE32_64): # TODO: move the content parsing here!
	var data = null
	if !is_PE32_64:
		data = file.read(4)
	else:
		data = file.read(8)
	return data
func get_thunk_formatted_data(thunk_raw):
	if thunk_raw != null:
#		file.seek(offset); var is_ordinal = file.read("u8", "bool"); is_ordinal.value = is_ordinal.value & 0x80
#		file.seek(offset); var ordinal = file.read("u16")
#		file.seek(offset); var rva = file.read("u32"); rva.value = rva.value & ~0x80000000
		var thunk_data = {
			"is_ordinal": false,
			"ordinal": null,
			"rva": null,
			"hint": null,
			"fn_name": null
		}
		thunk_data.is_ordinal = thunk_raw.value[thunk_raw.value.size()-1] & 0x80
		if thunk_data.is_ordinal:
			thunk_data.ordinal = DataStruct.convert_bytes_to_type(thunk_raw.value, "u16")
		else:
			thunk_data.rva = DataStruct.convert_bytes_to_type(thunk_raw.value, "u32") & ~0x80000000
			var offset = RVA_to_file_offset(thunk_data.rva)
			file.seek(offset)
			thunk_data.hint = file.read("u16").value
			thunk_data.fn_name = file.get_null_terminated_string(offset + 2)
		return thunk_data
	return null
func fill_thunk_table(memberRvaName : String):
	# clear table data and refill
	var is_64 = is_PE32_64()
	var _raw_chunks = {}
	var _formatted = {}
	
	# construct table
	var _sorted_imports = []
	for import_name in IMPORT_TABLES.IMPORT.raw_chunks.keys():
		if import_name == "__empty_end": # the last one is empty.
			continue
		var chunk = IMPORT_TABLES.IMPORT.raw_chunks[import_name]
		var thunks = {}
		var offset = RVA_to_file_offset(chunk[memberRvaName].value)
		_raw_chunks[import_name] = {}
		_formatted[import_name] = {}
		if offset != null:
			var next_offset = offset
			while true:
				
				# read thunk
				file.seek(next_offset)
				var thunk_raw = read_thunk_chunk(is_64)
				next_offset = file.get_position()
				
				# last entry reached?
				if thunk_raw.value.count(0) == (8 if is_64 else 4):
					break
				else:
					# add thunk data to structured tables
					var thunk_formatted = get_thunk_formatted_data(thunk_raw)
					_raw_chunks[import_name][thunk_formatted.fn_name] = thunk_raw
					_formatted[import_name][thunk_formatted.fn_name] = thunk_formatted
		
		# record highest memory offset of each import's thunks data
		if _raw_chunks[import_name].size() != 0:
			var keys = _raw_chunks[import_name].keys()
			var first_thunk_offset = _raw_chunks[import_name][keys[0]].offset
			_sorted_imports.push_back({
				"name": import_name,
				"offset": first_thunk_offset
			})
	
	# sorted import names by their thunks memory layout
	_sorted_imports.sort_custom(self, "sort_by_offset")
	assert(IMPORT_TABLES.IMPORT.raw_chunks.size() == _sorted_imports.size() + 1) # IMPORT_TABLES.IMPORT contains one extra __empty_end
	
	# reorder the thunk tables...
	var final_table = {
		"raw_chunks": {},
		"formatted": {}
	}
	for _import in _sorted_imports:
		var import_name = _import.name
		final_table.raw_chunks[import_name] = _raw_chunks[import_name]
		final_table.formatted[import_name] = _formatted[import_name]
	return final_table
func get_import_thunk(table_name, import_id, thunk_id, formatted): # this does NOT check if the ids are within bounds.
	if formatted:
		return IMPORT_TABLES[table_name].formatted[import_id][thunk_id]
	else:
		return IMPORT_TABLES[table_name].raw_chunks[import_id][thunk_id]

# Dictionary of common PE file sections and descriptions. 
# Taken from here: http://www.hexacorn.com/blog/2016/12/15/pe-section-names-re-visited/
# Formatted by: https://gist.github.com/joenorton8014/a03499d2d170128c15d93f675d81295f

var COMMON_SECTIONS = {
	".00cfg":"Control Flow Guard CFG section added by newer versions of Visual Studio",
	".apiset":"a section present inside the apisetschema.dll",
	".arch":"Alpha-architecture section",
	".autoload_text":"cygwin/gcc; the Cygwin DLL uses a section to avoid copying certain data on fork.",
	".bindat":"Binary data also used by one of the downware installers based on LUA",
	".bootdat":"section that can be found inside Visual Studio files; contains palette entries",
	".bss":"Uninitialized Data Section",
	".BSS":"Uninitialized Data Section",
	".buildid":"gcc/cygwin; Contains debug information if overlaps with debug directory",
	".CLR_UEF":".CLR Unhandled Exception Handler section; see https://github.com/dotnet/coreclr/blob/master/src/vm/excep.h",
	".code":"Code Section",
	".cormeta":".CLR Metadata Section",
	".complua":"Binary data, most likely compiled LUA also used by one of the downware installers based on LUA",
	".CRT":"Initialized Data Section  C RunTime",
	".cygwin_dll_common":"cygwin section containing flags representing Cygwin’s capabilities; refer to cygwin.sc and wincap.cc inside Cygwin run-time",
	".data":"Data Section",
	".DATA":"Data Section",
	".data1":"Data Section",
	".data2":"Data Section",
	".data3":"Data Section",
	".debug":"Debug info Section",
	".debug$F":"Debug info Section Visual C++ version <7.0",
	".debug$P":"Debug info Section Visual C++ debug information precompiled information",
	".debug$S":"Debug info Section Visual C++ debug information symbolic information",
	".debug$T":"Debug info Section Visual C++ debug information type information",
	".drectve ":"directive section temporary, linker removes it after processing it; should not appear in a final PE image",
	".didat":"Delay Import Section",
	".didata":"Delay Import Section",
	".edata":"Export Data Section",
	".eh_fram":"gcc/cygwin; Exception Handler Frame section",
	".export":"Alternative Export Data Section",
	".fasm":"FASM flat Section",
	".flat":"FASM flat Section",
	".gfids":"section added by new Visual Studio 14.0; purpose unknown",
	".giats":"section added by new Visual Studio 14.0; purpose unknown",
	".gljmp":"section added by new Visual Studio 14.0; purpose unknown",
	".glue_7t":"ARMv7 core glue functions thumb mode",
	".glue_7":"ARMv7 core glue functions 32-bit ARM mode",
	".idata":"Initialized Data Section  Borland",
	".idlsym":"IDL Attributes registered SEH",
	".impdata":"Alternative Import data section",
	".itext":"Code Section  Borland",
	".ndata":"Nullsoft Installer section",
	".orpc":"Code section inside rpcrt4.dll",
	".pdata":"Exception Handling Functions Section PDATA records",
	".rdata":"Read-only initialized Data Section  MS and Borland",
	".reloc":"Relocations Section",
	".rodata":"Read-only Data Section",
	".rsrc":"Resource section",
	".sbss":"GP-relative Uninitialized Data Section",
	".script":"Section containing script",
	".shared":"Shared section",
	".sdata":"GP-relative Initialized Data Section",
	".srdata":"GP-relative Read-only Data Section",
	".stab":"Created by Haskell compiler GHC",
	".stabstr":"Created by Haskell compiler GHC",
	".sxdata":"Registered Exception Handlers Section",
	".text":"Code Section",
	".text0":"Alternative Code Section",
	".text1":"Alternative Code Section",
	".text2":"Alternative Code Section",
	".text3":"Alternative Code Section",
	".textbss":"Section used by incremental linking",
	".tls":"Thread Local Storage Section",
	".tls$":"Thread Local Storage Section",
	".udata":"Uninitialized Data Section",
	".vsdata":"GP-relative Initialized Data",
	".xdata":"Exception Information Section",
	".wixburn":"Wix section; see https://github.com/wixtoolset/wix3/blob/develop/src/burn/stub/StubSection.cpp",
	".wpp_sf ":"section that is most likely related to WPP Windows software trace PreProcessor; not sure how it is used though; the code inside the section is just a bunch of routines that call FastWppTraceMessage that in turn calls EtwTraceMessage",
	"BSS":"Uninitialized Data Section  Borland",
	"CODE":"Code Section Borland",
	"DATA":"Data Section Borland",
	"DGROUP":"Legacy data group section",
	"edata":"Export Data Section",
	"idata":"Initialized Data Section  C RunTime",
	"INIT":"INIT section drivers",
	"minATL":"Section that can be found inside some ARM PE files; purpose unknown; .exe files on Windows 10 also include this section as well; its purpose is unknown, but it contains references to ___pobjectentryfirst,___pobjectentrymid,___pobjectentrylast pointers used by Microsoft::WRL::Details::ModuleBase::… methods described e.g. here, and also referenced by .pdb symbols; so, looks like it is being used internally by Windows Runtime C++ Template Library WRL which is a successor of Active Template Library ATL; further research needed",
	"PAGE":"PAGE section drivers",
	"rdata":"Read-only Data Section",
	"sdata":"Initialized Data Section",
	"shared":"Shared section",
	"Shared":"Shared section",
	"testdata":"section containing test data can be found inside Visual Studio files",
	"text":"Alternative Code Section"
}
