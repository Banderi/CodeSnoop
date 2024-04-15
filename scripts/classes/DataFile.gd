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

func read(type, schema_index : int = -1, optional_formatting = null):
	var offset = get_position()
	if type is int:
		type = str("buf",type)
	match type:
		"u8":
			return DataStruct.new(type, get_8(), optional_formatting, offset, schema_index)
		"i8":
			return DataStruct.new(type, u_to_i(get_8(),8), optional_formatting, offset, schema_index)
		"u16":
			return DataStruct.new(type, get_16(), optional_formatting, offset, schema_index)
		"i16":
			return DataStruct.new(type, u_to_i(get_16(),16), optional_formatting, offset, schema_index)
		"u32":
			return DataStruct.new(type, get_32(), optional_formatting, offset, schema_index)
		"i32":
			return DataStruct.new(type, u_to_i(get_32(),32), optional_formatting, offset, schema_index)
		"i64","u64":
			return DataStruct.new(type, get_64(), optional_formatting, offset, schema_index)
#		"i64":
#			return DataStruct.new(type, u_to_i(get_64(),64), optional_formatting, offset, schema_index)
		"p32":
			return DataStruct.new(type, u_to_i(get_32(),32), "0x%08X", offset, schema_index)
		"p64":
			return DataStruct.new(type, get_64(), "0x%016X", offset, schema_index)
		_:
			return DataStruct.new(type, get_buffer(str(type).to_int()), optional_formatting, offset, schema_index)
func read_grid(cell_size, schema_index : int = -1, optional_formatting = null):
	var offset = get_position()
	var total_size = 51984 * cell_size
	var data_item = DataStruct.new(str("grid",cell_size), get_buffer(total_size), optional_formatting, offset, schema_index)
	data_item.size = total_size
	return data_item

func read_zip_chunk(schema_index : int = -1):
	var offset = get_position()
	var size = read("u32")
	var compressed_data = read(size.value)
	var struct = {
		"compressed_size": size,
		"compressed_data": compressed_data,
		"data": {},
		"offset": offset,
		"schema_index": schema_index
	}
	DataStruct.record_schema_item(struct)
	return struct
func read_xor_encrypted(type, key_bytes, optional_formatting = null):
	var offset = get_position()
	var meta = DataStruct.type_to_size(type)
	var data_item = read(meta[1], -1, optional_formatting)
	data_item.type = meta[0]
#	data_item["raw"] = data_item.value
	data_item["xor"] = key_bytes
	return data_item
