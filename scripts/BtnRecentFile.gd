extends Button

signal open_file(path)

func _on_BtnRecentFile_pressed():
	emit_signal("open_file",text)
