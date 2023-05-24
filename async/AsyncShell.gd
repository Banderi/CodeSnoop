extends AsyncButton

export(String) var cmd = ""

func _on_AsyncShellBtn_pressed():
	if !disabled:
		Shell.run(cmd, self, "done", true, true)
		$Spinner.visible = true
		disabled = true
		emit_signal("action_pressed")
