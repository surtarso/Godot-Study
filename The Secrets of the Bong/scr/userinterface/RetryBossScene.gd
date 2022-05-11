extends Button

func _on_button_up():
	## SOFT RESET (doesnt reset ARREST, BRIBE and STONED count)
	PlayerData.tutorial_page = 0
	PlayerData.has_suit = false
	PlayerData.has_coffee_overdose = false
	PlayerData.just_used_smoke = false
	#if current scene != a boss room
	PlayerData.coffee = 0
	PlayerData.roaches = 0
	PlayerData.has_lighter = false
	PlayerData.has_weed = false
	
	get_tree().paused = false
	
	## reload
	var error_code = get_tree().reload_current_scene()
	##----------error 0 fix [no error message]
	if error_code != 0:
		print("ERROR: ", error_code)
