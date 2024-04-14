extends Node

func MAX(bs):
	return (1 << bs)
func u_to_i(unsigned, bs):
	return (unsigned + MAX(bs-1)) % MAX(bs) - MAX(bs-1)

func is_valid(item):
	return item is Dictionary && item.has("display_formatting")

func type_to_size(type):
	var size = -1
	match type:
		"u8","i8":
			size = 1
		"u16","i16":
			size = 2
		"u32","i32","p32":
			size = 4
		"u64","i64","p64":
			size = 8
	if type is int:
		size = type
		type = "bytes"
	elif type.begins_with("buf"):
		size = type.to_int()
		type = "bytes"
	elif type.begins_with("str"):
		size = type.to_int()
		type = "[char]"
	elif type.begins_with("p"):
		type = "addr"
	return [type, size]

var last_schema_memory_address = -1
func new(type, value, display_formatting = null, data_offset = -1, schema_index = -1):
	var meta = type_to_size(type)
	type = meta[0]
	var size = meta[1]
	
	var struct = {
		"type": type,
		"size": size,
		"value": value,
		"display_formatting": display_formatting,
		"offset": data_offset,
		"schema_index": schema_index,
	}
	
	# register to schema table...
	return struct
func xor_decrypt(bytes, key):
	var buffer = (bytes as Array).duplicate()
	for i in buffer.size():
		buffer[i] = buffer[i] ^ key[i % key.size()]
	return buffer

onready var stream = StreamPeerBuffer.new()
func convert_bytes_to_type(bytes, type):
	stream.data_array = bytes
	stream.seek(0)
	match type:
		"u8": return stream.get_8()
		"i8": return u_to_i(stream.get_8(),8)
		"u16": return stream.get_16()
		"i16": return u_to_i(stream.get_16(),16)
		"u32": return stream.get_32()
		"i32": return u_to_i(stream.get_32(),32)
		"u64","i64": return stream.get_64()
#		"i64": return u_to_i(stream.get_8(),8)
	return bytes
	
func as_text(item, with_value = null):
	if !is_valid(item):
		return "[ ... ]"
	if with_value == null:
		if item.has("xor"):
			with_value = xor_decrypt(item.value, item.xor)
		else:
			with_value = item.value
	
	# convert byte stream to correct type first
	if with_value is Array || with_value is PoolByteArray:
		with_value = convert_bytes_to_type(with_value, item.type)
	
	if item.display_formatting == null:
		match item.type:
			"[char]":
				return (with_value as PoolByteArray).get_string_from_ascii()
			"bytes":
				var bytes_text = "%02X %02X %02X %02X" % [with_value[0], with_value[1], with_value[2], with_value[3]]
				if with_value.size() <= 4:
					return "%02X %02X %02X %02X" % [with_value[0], with_value[1], with_value[2], with_value[3]]
				return "%02X %02X %02X..." % [with_value[0], with_value[1], with_value[2]]
			_:
				return str(with_value)
	else:
		match item.display_formatting:
			"bool":
				return str(with_value as bool)
			"string":
				return (with_value as PoolByteArray).get_string_from_ascii()
			"PRODID":
				return PE.PRODID[with_value][1]
			_:
				if item.type == "bytes":
					match item.display_formatting:
						"hex":
							return "0x" + (with_value as PoolByteArray).hex_encode().to_upper()
						_:
							return "[ ... ]"
				return item.display_formatting % [with_value]
func as_data_array(item):
	return [
		item.size,
		item.type,
		as_text(item)
	]
