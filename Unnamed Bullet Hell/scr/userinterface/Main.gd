extends Node



func _ready():
	var cursor = load("res://assets/arrow_16x16.png") #load cursor image
	Input.set_custom_mouse_cursor(cursor) #set cursor image
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	$Panel/VBoxContainer/PlayButton.grab_focus()

func _on_PlayButton_button_up():
	$Panel/AnimationPlayer.play("fadeout")
	yield($Panel/AnimationPlayer,"animation_finished")
	var _play = get_tree().change_scene("res://scr/userinterface/WorldSelect.tscn")

func _on_QuitButton_button_up():
	get_tree().quit()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
