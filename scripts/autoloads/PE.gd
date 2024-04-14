extends Node

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
