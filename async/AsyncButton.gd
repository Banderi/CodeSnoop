extends Button
class_name AsyncButton

signal action_pressed
signal action_completed

func done(data):
	$Spinner.visible = false
	disabled = false
	emit_signal("action_completed", data)

func _on_AsyncBtn_pressed():
	$Spinner.visible = true
	disabled = true
	emit_signal("action_pressed")
