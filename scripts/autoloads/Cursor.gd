extends Node

var backdrop = null
var cursor_shape = null
func push(cursor):
	cursor_shape = cursor
func cursor_setting_loop():
	if cursor_shape == null:
		cursor_shape = Input.CURSOR_ARROW
	backdrop.set_default_cursor_shape(cursor_shape)
	cursor_shape = null
