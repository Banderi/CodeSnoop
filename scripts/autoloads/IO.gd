extends Node
# ANTIMONY3 IO MODULE VER. 1.0

# directory IO
func get_folder_split_path(path):
	# this only legally accepts full paths with a file name at the end!
	var result = path.rsplit('/', false, 1)
	if result.size() == 1:
		return ["", result[0]]
	result[0] += '/'
	return result
func get_file_name(path):
	return get_folder_split_path(path)[1]
func dir_contents(path):
	var dir = Directory.new()
	var err = dir.open(path)
	if err != OK:
		Log.error(null,err,str("could not access directory '",path,"'"))
		return null
	else:
		var results = {
			"folders":{},
			"files":{}
		}
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name != "." && file_name != ".." :
				var file_data = metadata(
					str(path,"/",file_name) if !path.ends_with("/") else str(path,file_name)
				)
				if dir.current_is_dir():
					results.folders[file_name] = file_data
				else:
					results.files[file_name] = file_data
			file_name = dir.get_next()
		return results
func find_most_recent_file(path):
	var results = dir_contents(path)

	var most_recent_timestamp = -1
	var most_recent_file = null
	for file_name in results.files:
		var file = results.files[file_name]
		if file.modified_timestamp > most_recent_timestamp:
			most_recent_timestamp = file.modified_timestamp
			most_recent_file = file_name
	return most_recent_file

# basic IO
func write(path, data, create_folder_if_missing = true, password = ""):
	var err = -1

	# check path
	var split_path = get_folder_split_path(path)
	var dir = Directory.new()
	if !dir.dir_exists(split_path[0]):
		if create_folder_if_missing:
			err = dir.make_dir_recursive(split_path[0])
			if err != OK:
				Log.error(null,err,str("could not create directory at '",split_path[0],"' for file '",split_path[1],"'"))
				return false
		else:
			Log.error(null,7,str("directory '",split_path[0],"' not found for file '",split_path[1],"'"))
			return false
#	if data is Resource:
#		err = ResourceSaver.save(path, data)
#		if err != OK:
#			Log.error(null,err,str("could not write to file '",path,"'"))
#			return false
#		Log.generic(null,str("file '",path,"' written successfully!"))
#		return true
#	else:

	# init stream
	var file = DataFile.new()
	if password == "":
		err = file.open(path, File.WRITE)
	else:
		err = file.open_encrypted_with_pass(path, File.WRITE, password)
	if err != OK:
		Log.error(null,err,str("could not write to file '",path,"'"))
		return false

	# write data
	if data is String:
		file.store_string(data)
	else:
		file.store_var(data, true)

	# close stream
	file.close()
	Log.generic(null,str("file '",path,"' written successfully!"))
	return true
func read(path, password = ""):
	# init stream
	var file = DataFile.new()
	var err = -1
	if password == "":
		err = file.open(path, File.READ)
	else:
		err = file.open_encrypted_with_pass(path, File.READ, password)
	if err != OK:
		Log.error(null,err,str("could not read file '",path,"'"))
		return null
	
	Log.generic(null,str("file '",path,"' read successfully!"))
	return file
func read_as(path, type, password = ""):
	var file = read(path, password)
	var data = null
	if file != null:
		match type:
			0:
				data = file.get_as_text()
			1:
				data = file.get_var(true)
		file.close() # remember to close the file stream!
	return data
func read_as_text(path, password = ""):
	return read_as(path, 0, password)
func read_as_var(path, password = ""):
	return read_as(path, 1, password)
func file_exists(path):
	var file = DataFile.new()
	return file.file_exists(path)
func metadata(path):
	var file = DataFile.new()
	var err = file.open(path, File.READ)
	if err != OK:
		Log.error(null,err,str("could not read file '",path,"'"))
		return null
	var data = {
		"extension": path.get_extension(),
		"modified_timestamp": file.get_modified_time(path),
		"modified_datetime": OS.get_datetime_from_unix_time(file.get_modified_time(path)),
		"md5": file.get_md5(path),
		"length": file.get_len(),
	}
	file.close()
	return data
func delete(path):
	var dir = Directory.new()
	var err = dir.remove(path)
	if err != OK:
		Log.error(null,err,str("could not delete file '",path,"'"))
		return false
	return true
func move_file(path, to, remove_previous = true, overwrite = false):
	if !overwrite && file_exists(to):
		Log.error(null,GlobalScope.Error.ERR_ALREADY_EXISTS,str("could not move file from '",path,"' to '",to,"'"))
		return false
	var dir = Directory.new()
	var err = dir.copy(path, to)
	if err != OK:
		Log.error(null,err,str("could not move file from '",path,"' to '",to,"'"))
		return false
	if remove_previous:
		err = dir.remove(path)
		if err != OK:
			Log.error(null,err,str("could not delete file '",path,"'"))
			return false
	return true

# code by @DanielKotzer https://godotforums.org/d/20958-extracting-the-content-of-a-zip-file/4
func unzip(zip_file, destination):
	# load Gdunzip addon script
	var gdunzip = load("res://addons/gdunzip/gdunzip.gd").new()
	var r = gdunzip.load(zip_file)
	if !r:
		Log.error(null,GlobalScope.Error.ERR_CANT_OPEN,str("could not load zip file '",zip_file,"'"))
		return false

	# read zip file contents and adds them to project's virtual workspace
	var _res = ProjectSettings.load_resource_pack(zip_file)

	# extract single files from project workspace and write to disk
	for f in gdunzip.files:
		if !export_virtual_file(f, destination):
			return false
	return true
func export_virtual_file(file_name, destination):
	# open read stream
	var file = DataFile.new()
	if file.file_exists("res://" + file_name):
		file.open(("res://" + file_name), File.READ)
		var content = file.get_buffer(file.get_len())
		file.close()

		# create directory if it doesn't exist
		var base_dir = destination + file_name.get_base_dir()
		var dir = Directory.new()
		dir.make_dir(base_dir)

		# open write stream
		file = DataFile.new()
		file.open(destination + file_name, File.WRITE)
		file.store_buffer(content)
		file.close()
		return true
	return false
