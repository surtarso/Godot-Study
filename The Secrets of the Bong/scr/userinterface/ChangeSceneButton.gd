extends Button

export(String, FILE) var next_scene: = "" # add next scene path

func _ready():
	grab_focus()
	
func _on_button_up():
	PlayerData.reset() #resets (playerdata)
	get_tree().paused = false #unpauses the game so the menu works
	
	## print only non 0 errors [0 = no errors]
	var error_code = get_tree().change_scene(next_scene)
	if error_code != 0:
		print("ERROR: ", error_code)
