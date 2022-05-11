extends CheckBox

onready var click = get_node("../effects")

func _on_toggled(_button_pressed):
	OS.window_fullscreen = not OS.window_fullscreen #toggles full screen mode
	click.play()
