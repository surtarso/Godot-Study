extends Control

onready var score: Label = get_node("Score")

func _ready():
	$Menu/ChanceSceneButton.grab_focus()
	##mouse mode and cursor
	var cursor = load("res://assets/userinterface/cursor.png")
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2(10,10))
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	## display score data
	score.text = score.text % [PlayerData.timer_str, PlayerData.arrested, PlayerData.has_bribed,
	PlayerData.has_stoned, PlayerData.roaches]
	
	#fadein animation
	$AnimationPlayer.play("fade in")
	yield($AnimationPlayer,"animation_finished")
	#icons dropping animations
	$AnimationPlayer.play("weed_lighter")
	yield($AnimationPlayer,"animation_finished")
	$bong_hit.play()
	$AnimationPlayer.play("warning_blink")

func _process(_delta):
	if not $end_stage_theme.playing: $end_stage_theme.play() #keeps the end music in loop
