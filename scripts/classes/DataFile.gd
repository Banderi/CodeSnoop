extends File
class_name DataFile

func MAX(bs):
	return DataStruct.MAX(bs)
func u_to_i(unsigned, bs):
	return DataStruct.u_to_i(unsigned, bs)

func get_null_terminated_string(offset):
	seek(offset)
	var null_byte = str(0x00)
	var csv = get_csv_line(null_byte)
	return csv[0]

func end_reached():
	return get_position() >= get_len()

func read(type, optional_formatting = null):
	var offset = get_position()
	if type is int:
		type = str("buf",type)
	match type:
		"u8":
			return DataStruct.new(type, get_8(), optional_formatting, offset)
		"i8":
			return DataStruct.new(type, u_to_i(get_8(),8), optional_formatting, offset)
		"u16":
			return DataStruct.new(type, get_16(), optional_formatting, offset)
		"i16":
			return DataStruct.new(type, u_to_i(get_16(),16), optional_formatting, offset)
		"u32":
			return DataStruct.new(type, get_32(), optional_formatting, offset)
		"i32":
			return DataStruct.new(type, u_to_i(get_32(),32), optional_formatting, offset)
		"i64","u64":
			return DataStruct.new(type, get_64(), optional_formatting, offset)
#		"i64":
#			return DataStruct.new(type, u_to_i(get_64(),64), optional_formatting, offset)
		"p32", "rva32":
			return DataStruct.new(type, u_to_i(get_32(),32), "0x%08X", offset)
		"p64", "rva64":
			return DataStruct.new(type, get_64(), "0x%016X", offset)
		_:
			return DataStruct.new(type, get_buffer(str(type).to_int()), optional_formatting, offset)

func read_xor_encrypted(type, key_bytes, optional_formatting = null):
	var meta = DataStruct.type_to_size(type)
	var data_item = read(meta[1], optional_formatting)
	data_item.type = meta[0]
	data_item["xor"] = key_bytes
	return data_item
