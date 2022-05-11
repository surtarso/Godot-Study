extends Node

onready var player = get_node("Panel/Player")

func _ready():
	player.get_node("Sprite").play("default")
	player.get_node("Sprite/CPUParticles2D").modulate = Color.black
	$Panel/AnimationPlayer.play("fadein")
	var cursor = load("res://assets/arrow_16x16.png") #load cursor image
	Input.set_custom_mouse_cursor(cursor) #set cursor image
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$Panel/World1Button.grab_focus()


func _process(_delta):
	player.look_at($Panel.get_global_mouse_position())
	if Input.is_action_pressed("shoot"):
		player.get_node("Tween").interpolate_property(
			player, "position",
			player.position, $Panel.get_global_mouse_position() ,
			0.8,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		player.get_node("Tween").start()
	
	if Input.is_action_just_pressed("left"): 
		PlayerData.chosen_player = 0
		player.get_node("Sprite").play("default")
		player.get_node("Sprite/CPUParticles2D").modulate = Color.black
	
	if Input.is_action_just_pressed("right"): 
		PlayerData.chosen_player = 1
		player.get_node("Sprite").play("default2")
		player.get_node("Sprite/CPUParticles2D").modulate = Color.whitesmoke


func _on_World1_button_up():
	if player.get_node("Tween").is_active(): yield(player.get_node("Tween"),"tween_all_completed")
	var _play = get_tree().change_scene("res://scr/stage/World1.tscn")


func _unhandled_input(_event):
	if Input.is_action_just_pressed("esc"):
		var _back = get_tree().change_scene("res://scr/userinterface/Main.tscn")
