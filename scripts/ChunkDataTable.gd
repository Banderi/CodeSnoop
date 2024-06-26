extends Tree

func _ready():
	clear()

const MAX_COLUMNS = 99

func set_editable(table_item):
	if table_item != null:
		for c in columns-1:
			table_item.set_editable(c+1,true)

func clear():
	.clear()
	var _root = create_item()
	columns = 1
	set_column_title(0,"")
func add_array_member(label, data):
	var table_item = create_item()
	
	# columns width
	set_column_min_width(0, 2)
	for c in min(MAX_COLUMNS, data.size()):
		set_column_min_width(c + 1, 5)
	
	# index / label (column 0)
	table_item.set_text(0, str(label))
	
	# fill in the data!
	if DataStruct.is_valid(data):
		table_item.set_text(1, DataStruct.as_text(data))
	elif data is Array:
		for d in min(MAX_COLUMNS, data.size()):
			table_item.set_text(d + 1, str(data[d]))
	elif data is Dictionary:
		for d in min(MAX_COLUMNS, data.size()):
			var item = data[data.keys()[d]]
			if DataStruct.is_valid(item):
				table_item.set_text(d + 1, DataStruct.as_text(data[data.keys()[d]]))
			if item is String:
				table_item.set_text(d + 1, str(item))
	else:
		table_item.set_text(1, data.text())
	return table_item
func add_raw_field(label, data):
	var table_item = create_item()
	
	# index / label (column 0)
	if label.begins_with("unk") || label.begins_with("unmapped"):
		table_item.set_text(0, "??")
		table_item.set_custom_color(0, Color(1,1,1,0.3))
	elif label.begins_with("unused"):
		table_item.set_text(0, str(label))
		table_item.set_custom_color(0, Color(1,1,1,0.3))
	else:
		table_item.set_text(0, str(label))
	
	# fill in the data!
	for i in data.size():
		table_item.set_text(i + 1, str(data[i]))
	return table_item

func present(key, data):
	
	# this MUST be an array of EQUAL FORMAT dictionary elements!!
	# EVERY final raw field MUST have a key/name!!
	if data is Array || (data is Dictionary && data.has("value") && data.value is Array):
		if data.has("value"):
			data = data.value
		if DataStruct.is_valid(data[0]):
			columns = 4 # index, size, value
			set_column_title(0, "#")
			set_column_title(1, "Size")
			set_column_title(2, "Type")
			set_column_title(3, "Value")
			set_column_min_width(0, 3)
			set_column_min_width(1, 4)
			set_column_min_width(2, 4)
			set_column_min_width(3, 9)
			
			var array_size = data.size()
			if array_size > 1000:
				add_raw_field("...", DataStruct.as_data_array(data[0]))
			else:
				for e in data.size():
					add_raw_field(str(e), DataStruct.as_data_array(data[e]))
			return
		elif data[0] is Dictionary:
			columns = int(min(MAX_COLUMNS + 1, data[0].size() + 1)) # column 0 is reserved for index
			set_column_title(0,"#")
			for c in min(MAX_COLUMNS, data[0].size()):
				set_column_title(c + 1, str(data[0].keys()[c]))
			
			
			var array_size = data.size()
			if array_size > 1000:
				add_array_member("...", data[0])
			else:
				for e in data.size():
					add_array_member(str(e), data[e])
			return
	elif data is Dictionary && data.get("_display_as_array", false) == true: # this is eh.... not worth it.
		var first_element = data[data.keys()[1]]
		var num_columns = first_element.keys().size()
		columns = int(min(MAX_COLUMNS + 1, num_columns + 1)) # column 0 is reserved for name
		set_column_title(0,"Name")
		for c in min(MAX_COLUMNS, num_columns):
			set_column_title(c + 1, str(first_element.keys()[c]))
		for element in data:
			if element == "_display_as_array":
				continue
			add_array_member(element, data[element])
		return
	
	# any other case: raw data field items
	columns = 4 # name, size, type, value
	set_column_title(0, "Name")
	set_column_title(1, "Size")
	set_column_title(2, "Type")
	set_column_title(3, "Value")
	set_column_min_width(0, 10)
	set_column_min_width(1, 4)
	set_column_min_width(2, 5)
	set_column_min_width(3, 8)
	if DataStruct.is_valid(data):
		add_raw_field(key, DataStruct.as_data_array(data))
	elif data is Dictionary:
		for element in data:
			if DataStruct.is_valid(data[element]):
				add_raw_field(element, DataStruct.as_data_array(data[element]))
			else:
				if element == "offset" || element == "schema_index" || element == "xor":
					continue
				add_raw_field(element, ["..."])
